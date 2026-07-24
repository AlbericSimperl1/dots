import QtQuick
import Quickshell
import Quickshell.Io

Text {
    id: upd
    visible: hasUpdate
    property bool hasUpdate: false
    color: "#fff7e5"
    font.family: "JetBrainsMono Nerd Font Mono"
    font.pixelSize: 16
    text: ""

    Process {
        id: proc
        command: ["bash", "-lc", "omarchy-update-available"]
        stdout: SplitParser {
            onRead: (line) => upd.hasUpdate = line.trim().length > 0
        }
    }

    Timer { interval: 21600000; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", "omarchy-update"])
    }
}
