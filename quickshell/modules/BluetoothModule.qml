import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: root

    property bool open: false
    property var devices: []
    property bool powered: false
    property string lastScannedDevices: ""

    readonly property color fg: "#fff7e5"
    readonly property color accent: "#ebd9b9"
    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"

    spacing: 4

    Text {
        text: root.powered ? "󰂯" : "󰂲"
        color: root.powered ? (root.open ? root.accent : root.fg) : "#666666"
        font.family: root.fontFamily
        font.pixelSize: 14

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open = !root.open
        }
    }

    Process {
        id: bt
        running: true
        command: ["bash", "-c", "while true; do " + "  power=$(bluetoothctl show | grep 'Powered: yes' > /dev/null && echo 'on' || echo 'off'); " + "  echo \"POWER:$power\"; " + "  paired=$(bluetoothctl paired-devices | grep '^Device' | awk '{fc=substr($0, index($0, $3)); print $2\"|\"fc}' | tr '\\n' '#'); " + "  echo \"PAIRED:$paired\"; " + "  timeout 3s bluetoothctl scan on >/dev/null 2>&1 & " + "  sleep 3; " + "  scanned=$(bluetoothctl devices | grep '^Device' | awk '{fc=substr($0, index($0, $3)); print $2\"|\"fc}' | tr '\\n' '#'); " + "  echo \"SCANNED:$scanned\"; " + "  sleep 5; " + "done"]

        stdout: SplitParser {
            onRead: line => {
                line = line.trim();
                if (line.startsWith("POWER:")) {
                    root.powered = (line.substring(6) === "on");
                } else if (line.startsWith("PAIRED:")) {
                    let deviceStr = line.substring(7);
                    let devicePairs = deviceStr.split("#").filter(d => d.length > 0);
                    let newDevices = [];
                    for (let d of devicePairs) {
                        let parts = d.split("|");
                        if (parts.length >= 2)
                            newDevices.push({
                                "mac": parts[0],
                                "name": parts[1],
                                "paired": true
                            });
                    }
                    root.devices = newDevices;
                }
            }
        }
    }

    function toggleBluetooth() {
        if (root.powered)
            Quickshell.execDetached(["bluetoothctl", "power", "off"]);
        else
            Quickshell.execDetached(["bluetoothctl", "power", "on"]);
    }

    function connectDevice(mac) {
        Quickshell.execDetached(["bluetoothctl", "connect", mac]);
    }
}
