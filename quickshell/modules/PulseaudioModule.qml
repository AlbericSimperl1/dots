import QtQuick
import Quickshell
import Quickshell.Io

Text {
    id: vol
    color: "#fff7e5"
    font.family: "JetBrainsMono Nerd Font Mono"
    font.pixelSize: 14
    font.weight: Font.Bold

    property int volumePct: 0
    property bool muted: false

    text: muted ? "" : (volumePct + "% |")

    Process {
        id: proc
        running: true
        command: ["bash", "-lc",
            "while true; do " +
            "  v=$(pamixer --get-volume 2>/dev/null); " +
            "  m=$(pamixer --get-mute 2>/dev/null); " +
            "  echo \"${v:-0}|${m:-false}\"; " +
            "  sleep 1; " +
            "done"]
        stdout: SplitParser {
            onRead: (line) => {
                const parts = line.trim().split("|");
                const v = parseInt(parts[0]);
                if (!isNaN(v)) vol.volumePct = v;
                vol.muted = parts[1] === "true";
            }
        }

        
   onExited: (exitCode, exitStatus) => {
        proc.running = true; // herstart automatisch als het proces onverwacht stopt
    }    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["omarchy-launch-audio"]);
            } else if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["pamixer", "-t"]);
            }
        }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) Quickshell.execDetached(["pamixer", "-i", "2"]);
            else Quickshell.execDetached(["pamixer", "-d", "2"]);
        }
    }
}
