import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool open: false
    property var devices: []
    property bool powered: false
    property bool scanning: false

    readonly property color fg: "#FFE8B3"
    readonly property color accent: "#EED09B"
    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"

    // Dynamische breedte en hoogte: als hij open is, neemt hij de ruimte van de dropdown in, anders gewoon 18x18
    implicitWidth: root.open && root.powered ? Math.max(180, deviceListColumn.implicitWidth) : 18
    implicitHeight: root.open && root.powered ? mainContainer.implicitHeight : 18

    // Zorgt ervoor dat elementen die buiten de 18x18 vallen niet zomaar random ergens over tekenen als root.open false is
    clip: false 

    Column {
        id: mainContainer
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: 8

        // Het Bluetooth-icoon (altijd zichtbaar)
        Text {
            id: icon
            width: 18
            height: 18
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: root.powered ? (root.open ? root.accent : root.fg) : "#555555"
            text: "󰂯"
            font.family: root.fontFamily
            font.pixelSize: 14
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open = !root.open
            }
        }

        // De lijst met apparaten, schuift netjes mee in de layout
        Column {
            id: deviceListColumn
            visible: root.open && root.powered
            spacing: 6
            padding: 4

            Repeater {
                model: root.devices

                delegate: Rectangle {
                    width: 180 // Vaste, propere breedte voor de lijst-items zodat het niet verspringt
                    height: 28
                    color: itemMouse.containsMouse ? "#222222" : "#111111"
                    radius: 4
                    border.color: modelData.paired ? root.accent : "#333333"
                    border.width: 1

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        spacing: 8

                        Text {
                            text: "󰂯"
                            color: modelData.paired ? root.accent : "#555555"
                            font.family: root.fontFamily
                            font.pixelSize: 11
                        }

                        Text {
                            // Kapt te lange namen (zoals je AirPods Pro - Find My) netjes af
                            text: modelData.name ? (modelData.name.length > 18 ? modelData.name.substring(0, 16) + "..." : modelData.name) : "Onbekend"
                            color: root.fg
                            font.family: root.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            if (!modelData.paired) {
                                root.pairDevice(modelData.mac);
                            }
                            root.connectDevice(modelData.mac);
                            root.open = false;
                        }
                    }
                }
            }

            // Toon dit als er niks gevonden is
            Text {
                visible: root.devices.length === 0
                text: "Geen apparaten..."
                color: "#555555"
                font.family: root.fontFamily
                font.pixelSize: 11
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // --- Jouw originele Process logica blijft ongewijzigd ---
    Process {
        id: bt
        running: true
        command: ["bash", "-c", 
            "while true; do " +
            "  power=$(bluetoothctl show | grep 'Powered: yes' > /dev/null && echo 'on' || echo 'off'); " +
            "  echo \"POWER:$power\"; " +
            "  paired=$(bluetoothctl paired-devices | grep '^Device' | awk '{fc=substr($0, index($0, $3)); print $2\"|\"fc}' | tr '\\n' '#'); " +
            "  echo \"PAIRED:$paired\"; " +
            "  timeout 4s bluetoothctl scan on >/dev/null 2>&1 & " +
            "  sleep 4; " +
            "  scanned=$(bluetoothctl devices | grep '^Device' | awk '{fc=substr($0, index($0, $3)); print $2\"|\"fc}' | tr '\\n' '#'); " +
            "  echo \"SCANNED:$scanned\"; " +
            "  sleep 6; " +
            "done"]
        
        stdout: SplitParser {
            onRead: (line) => {
                line = line.trim();
                if (line.startsWith("POWER:")) {
                    root.powered = (line.substring(6) === "on");
                } else if (line.startsWith("PAIRED:")) {
                    let deviceStr = line.substring(7);
                    let devicePairs = deviceStr.split("#").filter(d => d.length > 0);
                    let newDevices = [];
                    for (let d of devicePairs) {
                        let parts = d.split("|");
                        if (parts.length >= 2) newDevices.push({ "mac": parts[0], "name": parts[1], "paired": true });
                    }
                    let scannedStr = root.lastScannedDevices;
                    let scannedPairs = scannedStr.split("#").filter(d => d.length > 0);
                    for (let d of scannedPairs) {
                        let parts = d.split("|");
                        if (parts.length >= 2) {
                            let existingIndex = newDevices.findIndex(dev => dev.mac === parts[0]);
                            if (existingIndex === -1) newDevices.push({ "mac": parts[0], "name": parts[1], "paired": false });
                        }
                    }
                    root.devices = newDevices;
                } else if (line.startsWith("SCANNED:")) {
                    root.lastScannedDevices = line.substring(8);
                    let newDevices = [...root.devices.filter(d => d.paired)];
                    let scannedPairs = root.lastScannedDevices.split("#").filter(d => d.length > 0);
                    for (let d of scannedPairs) {
                        let parts = d.split("|");
                        if (parts.length >= 2) {
                            let existingIndex = newDevices.findIndex(dev => dev.mac === parts[0]);
                            if (existingIndex === -1) newDevices.push({ "mac": parts[0], "name": parts[1], "paired": false });
                        }
                    }
                    root.devices = newDevices;
                }
            }
        }
    }
    
    property string lastScannedDevices: ""

    function toggleBluetooth() {
        if (root.powered) { root.powered = false; Quickshell.exec(["bluetoothctl", "power", "off"]); }
        else { root.powered = true; Quickshell.exec(["bluetoothctl", "power", "on"]); }
    }
    function connectDevice(mac) { Quickshell.exec(["bluetoothctl", "connect", mac]); }
    function disconnectDevice(mac) { Quickshell.exec(["bluetoothctl", "disconnect", mac]); }
    function pairDevice(mac) { Quickshell.exec(["bluetoothctl", "pair", mac]); }
    function removeDevice(mac) { Quickshell.exec(["bluetoothctl", "remove", mac]); }
}