import QtQuick
import Quickshell
import Quickshell.Io

Text {
    id: sr
    visible: active
    property bool active: false
    text: "⏺"
    color: active ? "#ff0000" : "transparent"
    font.family: "JetBrainsMono Nerd Font Mono"
    font.pixelSize: 16

    Process {
        id: proc
        command: ["bash", "-lc", "$OMARCHY_PATH/default/waybar/indicators/screen-recording.sh"]
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const data = JSON.parse(line);
                    sr.active = data.class === "active" || data.text === "active";
                } catch (e) { /* ignore malformed output */ }
            }
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: proc.running = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["omarchy-capture-screenrecording"])
    }
}
