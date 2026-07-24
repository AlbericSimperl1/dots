// CavaModule.qml — "custom/cava" { exec: "~/.config/waybar/cava.sh" }
import QtQuick
import Quickshell
import Quickshell.Io

Text {
    id: cava
    color: "#fff7e5"
    font.family: "JetBrainsMono Nerd Font Mono"
    font.pixelSize: 16
    text: ""

    Process {
        id: proc
        command: ["bash", "-lc", "~/.config/waybar/cava.sh"]
        running: true
        stdout: SplitParser {
            onRead: (line) => cava.text = line
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["playerctl", "play-pause"]);
            } else if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["playerctl", "next"]);
            }
        }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) Quickshell.execDetached(["pamixer", "-i", "5"]);
            else Quickshell.execDetached(["pamixer", "-d", "5"]);
        }
    }
}
