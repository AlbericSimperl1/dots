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

    // Bluetooth status eigenschappen
    property bool connected: false
    property string activeDevice: ""
    property string activeMac: ""
    property int batteryLevel: -1 // -1 = geen batterij-info
    property bool btEnabled: true
    property string statusMessage: ""

    // Lijst van Bluetooth apparaten: [{ mac: string, name: string, connected: bool, paired: bool, battery: int }]
    property var devices: []

    function getBtIcon(isConnected, isEnabled) {
        if (!isEnabled)
            return "󰂲";
        if (isConnected)
            return "󰂱";
        return "󰂯";
    }

    function getDeviceIcon(name) {
        const lower = name.toLowerCase();
        if (lower.includes("headphone") || lower.includes("headset") || lower.includes("buds") || lower.includes("airpods") || lower.includes("wh-"))
            return "󰋋";
        if (lower.includes("mouse") || lower.includes("mx master"))
            return "󰍽";
        if (lower.includes("keyboard") || lower.includes("keychron"))
            return "󰌌";
        if (lower.includes("phone") || lower.includes("iphone") || lower.includes("galaxy"))
            return "󰄜";
        if (lower.includes("controller") || lower.includes("gamepad") || lower.includes("dualsense") || lower.includes("xbox"))
            return "󰊴";
        return "󰂱";
    }

    function toggleBt() {
        Quickshell.execDetached(["bluetoothctl", "power", btEnabled ? "off" : "on"]);
    }

    function triggerScan() {
        Quickshell.execDetached(["bash", "-c", "bluetoothctl --timeout 5 scan on &"]);
    }

    function connectDevice(mac) {
        root.statusMessage = "Verbinden...";
        Quickshell.execDetached(["bluetoothctl", "connect", mac]);
    }

    function disconnectDevice(mac) {
        Quickshell.execDetached(["bluetoothctl", "disconnect", mac]);
    }

    function pairDevice(mac) {
        Quickshell.execDetached(["bluetoothctl", "pair", mac]);
    }

    implicitWidth: 18
    implicitHeight: 18

    Text {
        id: btIcon
        anchors.centerIn: parent
        color: root.open ? root.accent : (root.connected ? root.fg : root.muted)
        text: root.getBtIcon(root.connected, root.btEnabled)
        font.family: root.fontFamily
        font.pixelSize: 19
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

    // Monitoring van Bluetooth status (Aan/Uit, actieve verbinding, MAC en batterij)
    Process {
        id: btStatusProc
        running: true
        command: ["bash", "-lc", "while true; do " + "pwr=$(bluetoothctl show 2>/dev/null | grep 'Powered: yes' || true); " + "if [ -n \"$pwr\" ]; then bt_on=\"enabled\"; else bt_on=\"disabled\"; fi; " + "conn=$(bluetoothctl devices Connected 2>/dev/null | head -n 1); " + "mac=$(echo \"$conn\" | awk '{print $2}'); " + "name=$(echo \"$conn\" | cut -d' ' -f3-); " + "bat=\"\"; " + "if [ -n \"$mac\" ]; then " + "bat=$(bluetoothctl info \"$mac\" 2>/dev/null | awk -F'[() ]+' '/Battery Percentage/ {print $4; exit}'); " + "fi; " + "printf '%s|%s|%s|%s\\n' \"$bt_on\" \"${name:-}\" \"${mac:-}\" \"${bat:--1}\"; " + "sleep 2; " + "done"]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split("|");
                if (parts.length >= 4) {
                    root.btEnabled = parts[0] === "enabled";
                    root.activeDevice = parts[1] || "";
                    root.activeMac = parts[2] || "";
                    root.connected = root.activeMac !== "";
                    root.batteryLevel = parseInt(parts[3]) || -1;
                }
            }
        }
    }

    // Bluetooth Apparaten Scanner (actief wanneer de dropdown geopend is en Bluetooth aan staat)
    Process {
        id: btScanProc
        running: root.open && root.btEnabled
        command: ["bash", "-lc", "while true; do " + "bluetoothctl devices 2>/dev/null | while read -r _ mac name; do " + "if [ -n \"$mac\" ]; then " + "dev_info=$(bluetoothctl info \"$mac\" 2>/dev/null); " + "conn=$(echo \"$dev_info\" | grep 'Connected: yes' || true); " + "paired=$(echo \"$dev_info\" | grep 'Paired: yes' || true); " + "bat=$(echo \"$dev_info\" | awk -F'[() ]+' '/Battery Percentage/ {print $4; exit}'); " + "is_conn=\"no\"; [ -n \"$conn\" ] && is_conn=\"yes\"; " + "is_paired=\"no\"; [ -n \"$paired\" ] && is_paired=\"yes\"; " + "printf '%s|%s|%s|%s|%s\\n' \"$mac\" \"$name\" \"$is_conn\" \"$is_paired\" \"${bat:--1}\"; " + "fi; " + "done; " + "echo '---END---'; " + "sleep 4; " + "done"]
        property var tempList: []
        stdout: SplitParser {
            onRead: line => {
                const l = line.trim();
                if (l === "---END---") {
                    root.devices = btScanProc.tempList;
                    btScanProc.tempList = [];
                    return;
                }
                const parts = l.split("|");
                if (parts.length >= 5) {
                    btScanProc.tempList.push({
                        mac: parts[0],
                        name: parts[1] || parts[0],
                        connected: parts[2] === "yes",
                        paired: parts[3] === "yes",
                        battery: parseInt(parts[4]) || -1
                    });
                }
            }
        }
    }
}
