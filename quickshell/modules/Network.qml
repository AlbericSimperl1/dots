import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    property var screen: null
    property bool open: false
    property color fg: "#fff7e5"
    property color accent: "#fff7e5"
    property color muted: "#ffffff"
    property color softFill: "#ffffff"
    property color borderCol: "#eb2e2e3d"
    property string fontFamily: "JetBrainsMono Nerd Font Mono"

    // Netwerk status eigenschappen
    property bool connected: false
    property string activeSsid: ""
    property string activeType: "none" // "wifi", "ethernet", "none"
    property int signalStrength: 0
    property string ipAddress: ""
    property string rxSpeed: "0 B/s"
    property string txSpeed: "0 B/s"
    property bool wifiEnabled: true
    property string statusMessage: ""

    // Lijst van Wi-Fi Access Points: [{ active: bool, ssid: string, signal: int, security: string, secured: bool }]
    property var accessPoints: []

    function formatBytes(bytes) {
        if (bytes < 1024)
            return bytes + " B";
        if (bytes < 1024 * 1024)
            return (bytes / 1024).toFixed(1) + " KB";
        return (bytes / (1024 * 1024)).toFixed(1) + " MB";
    }

    function getWifiIcon(signal, isConnected, isEnabled) {
        if (!isEnabled)
            return "󰤭";
        if (!isConnected)
            return "󰤮";
        if (signal >= 80)
            return "󰤨";
        if (signal >= 60)
            return "󰤥";
        if (signal >= 40)
            return "󰤢";
        if (signal >= 20)
            return "󰤟";
        return "󰤯";
    }

    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
    }

    function triggerRescan() {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]);
    }

    function connectToNetwork(ssid, password) {
        root.statusMessage = "Verbinden met " + ssid + "...";
        let args = ["nmcli", "dev", "wifi", "connect", ssid];
        if (password && password.length > 0) {
            args.push("password");
            args.push(password);
        }
        Quickshell.execDetached(args);
    }

    function disconnectNetwork(ssid) {
        Quickshell.execDetached(["nmcli", "con", "down", "id", ssid]);
    }

    implicitWidth: 18
    implicitHeight: 18

    Text {
        id: netIcon
        anchors.centerIn: parent
        color: root.open ? root.accent : (root.connected ? root.fg : root.muted)
        text: {
            if (root.activeType === "ethernet")
                return "󰈀";
            return root.getWifiIcon(root.signalStrength, root.connected, root.wifiEnabled);
        }
        font.family: root.fontFamily
        font.pixelSize: 23
        font.bold: true

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.open = !root.open;
        }
    }

    // Monitoring van netwerkstatus (Wi-Fi/Ethernet status, IP, SSID, Signaalsterkte)
    Process {
        id: netStatusProc
        running: true
        command: ["bash", "-lc", "while true; do " + "wifi_on=$(nmcli radio wifi 2>/dev/null || echo 'disabled'); " + "dev_info=$(nmcli -t -f TYPE,STATE,CONNECTION dev 2>/dev/null | grep ':connected' | head -n 1); " + "dev_type=$(echo \"$dev_info\" | cut -d: -f1); " + "dev_conn=$(echo \"$dev_info\" | cut -d: -f3); " + "ip_addr=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}'); " + "sig=0; " + "if [ \"$dev_type\" = \"802-11-wireless\" ] || [ \"$dev_type\" = \"wifi\" ]; then " + "sig=$(nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | awk -F':' '$1==\"yes\" {print $2; exit}'); " + "fi; " + "printf '%s|%s|%s|%s|%s\\n' \"$wifi_on\" \"${dev_type:-none}\" \"${dev_conn:-}\" \"${sig:-0}\" \"${ip_addr:-}\"; " + "sleep 2; " + "done"]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split("|");
                if (parts.length >= 5) {
                    root.wifiEnabled = parts[0] === "enabled";
                    const devType = parts[1];
                    root.activeType = (devType.includes("wireless") || devType === "wifi") ? "wifi" : (devType.includes("ethernet") ? "ethernet" : "none");
                    root.connected = root.activeType !== "none";
                    root.activeSsid = parts[2] || "";
                    root.signalStrength = parseInt(parts[3]) || 0;
                    root.ipAddress = parts[4] || "";
                }
            }
        }
    }

    // Bandbreedte monitoring (RX / TX snelheden direct uit sysfs)
    Process {
        id: speedProc
        running: true
        command: ["bash", "-lc", "while true; do " + "iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}'); " + "if [ -n \"$iface\" ] && [ -d \"/sys/class/net/$iface/statistics\" ]; then " + "r1=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0); " + "t1=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo 0); " + "sleep 1; " + "r2=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0); " + "t2=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo 0); " + "printf '%s|%s\\n' \"$((r2 - r1))\" \"$((t2 - t1))\"; " + "else " + "printf '0|0\\n'; " + "sleep 1; " + "fi; " + "done"]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split("|");
                if (parts.length >= 2) {
                    const rx = parseInt(parts[0]) || 0;
                    const tx = parseInt(parts[1]) || 0;
                    root.rxSpeed = root.formatBytes(rx) + "/s";
                    root.txSpeed = root.formatBytes(tx) + "/s";
                }
            }
        }
    }

    // Wi-Fi Access Points scanner (actief zolang de dropdown open is)
    Process {
        id: wifiScanProc
        running: root.open && root.wifiEnabled
        command: ["bash", "-lc", "while true; do " + "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | awk -F':' '$2!=\"\" {print $1\"|\"$2\"|\"$3\"|\"$4}' | awk '!seen[$2]++'; " + "echo '---END---'; " + "sleep 4; " + "done"]
        property var tempList: []
        stdout: SplitParser {
            onRead: line => {
                const l = line.trim();
                if (l === "---END---") {
                    root.accessPoints = wifiScanProc.tempList;
                    wifiScanProc.tempList = [];
                    return;
                }
                const parts = l.split("|");
                if (parts.length >= 4) {
                    wifiScanProc.tempList.push({
                        active: parts[0] === "*",
                        ssid: parts[1],
                        signal: parseInt(parts[2]) || 0,
                        security: parts[3] || "Open",
                        secured: parts[3] !== "" && parts[3] !== "--" && !parts[3].toLowerCase().includes("open")
                    });
                }
            }
        }
    }
}
