import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: root

    property int brightnessPct: 100
    readonly property color fg: "#fff7e5"
    readonly property color accent: "#fff7e5"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    Process {
        id: brightProc
        running: true
        command: ["bash", "-c", "while true; do brightnessctl -m | cut -d',' -f4 | tr -d '%'; sleep 2; done"]

        stdout: SplitParser {
            onRead: line => {
                let val = parseInt(line.trim());
                if (!isNaN(val))
                    root.brightnessPct = val;
            }
        }
    }

    Text {
        text: {
            if (root.brightnessPct > 75)
                return "󰃠";
            if (root.brightnessPct > 50)
                return "󰃟";
            if (root.brightnessPct > 25)
                return "󰃞";
            return "󰃝";
        }
        color: root.accent
        font.family: root.fontFamily
        font.pixelSize: 15

        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                Quickshell.execDetached(["brightnessctl", "set", "+5%"]);
                root.brightnessPct = Math.min(100, root.brightnessPct + 5);
            } else {
                Quickshell.execDetached(["brightnessctl", "set", "5%-"]);
                root.brightnessPct = Math.max(1, root.brightnessPct - 5);
            }
        }

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["omarchy-toggle-nightlight"]);
            } else if (mouse.button === Qt.LeftButton) {
                let target = root.brightnessPct > 50 ? "30%" : "100%";
                Quickshell.execDetached(["brightnessctl", "set", target]);
            }
        }
    }
}
