import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Item {
    id: root

    property bool open: false
    property color fg: "#fff7e5"
    property color accent: "#ebd9b9"
    property color muted: Qt.rgba(1, 0.95, 0.82, 0.78)
    property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
    property color borderCol: "#eb2e2e3d"
    property string fontFamily: "JetBrainsMono Nerd Font Mono"

    // Netwerk status via Quickshell.Networking API
    readonly property bool state: Networking.wifi.enabled
    readonly property var networks: Networking.wifi.networks

    function refreshNetworkData() {
        Networking.wifi.scan();
    }

    implicitWidth: 18
    implicitHeight: 18

    Text {
        id: wifiIcon
        anchors.centerIn: parent
        color: root.open ? root.accent : root.fg

        text: {
            if (!root.state)
                return "󰤭"; // Wifi uit

            // Bepaal icoon op basis van signaalsterkte van actieve verbinding
            let activeSignal = 0;
            for (let i = 0; i < root.networks.length; i++) {
                if (root.networks[i].connected) {
                    activeSignal = root.networks[i].signal;
                    break;
                }
            }

            if (activeSignal === 0)
                return "󰤯"; // Niet verbonden
            if (activeSignal > 75)
                return "󰤨";
            if (activeSignal > 50)
                return "󰤥";
            if (activeSignal > 25)
                return "󰤢";
            return "󰤟";
        }

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
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }
}
