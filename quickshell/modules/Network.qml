// Network.qml
import QtQuick
import Quickshell
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

    // De WiFi-device (meestal de eerste)
    readonly property WifiDevice wifiDevice: WifiDevice.allDevices.length > 0 ? WifiDevice.allDevices[0] : null
    readonly property bool state: wifiDevice ? wifiDevice.enabled : false

    // Lijst van alle netwerken (gesorteerd, verbonden eerst)
    readonly property var networks: {
        if (!wifiDevice)
            return [];
        var list = wifiDevice.networks;
        // Sorteer: verbonden eerst, dan op signaalsterkte (aflopend)
        list.sort((a, b) => {
            if (a.connected && !b.connected)
                return -1;
            if (!a.connected && b.connected)
                return 1;
            return b.signalStrength - a.signalStrength;
        });
        return list;
    }

    // Huidig verbonden netwerk
    readonly property WifiNetwork activeNetwork: wifiDevice ? wifiDevice.activeNetwork : null

    // Functie om te verbinden (met of zonder wachtwoord)
    function connectToNetwork(network, password) {
        if (!network)
            return;
        if (network.secure && password && password.length > 0) {
            network.connect(password);
        } else if (!network.secure) {
            network.connect();
        }
        // Sluit eventueel de dropdown
        root.open = false;
    }

    // Signaalsterkte voor icoon
    function signalIcon() {
        if (!state)
            return "󰤭";  // uit
        var net = activeNetwork;
        if (!net)
            return "󰤯";    // geen verbinding
        var sig = net.signalStrength;
        if (sig > 75)
            return "󰤨";
        if (sig > 50)
            return "󰤥";
        if (sig > 25)
            return "󰤢";
        return "󰤟";
    }

    implicitWidth: 18
    implicitHeight: 18

    // Icoon
    Text {
        id: wifiIcon
        anchors.centerIn: parent
        text: root.signalIcon()
        color: root.open ? root.accent : root.fg
        font.family: root.fontFamily
        font.pixelSize: 19
        font.bold: true
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    // Klik om dropdown te openen/sluiten
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }
}
