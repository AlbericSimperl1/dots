// LayoutModule.qml — toggelt Hyprland's "general:layout" tussen dwindle (tiled)
// en een tweede layout (bv. "scroller" van het hyprscroller-plugin).
// Pas altLayout hieronder aan als jouw scroll-plugin een andere naam gebruikt.
import QtQuick
import Quickshell
import Quickshell.Io

Text {
    id: layoutMod
    color: "#FFE8B3"
    font.family: "JetBrainsMono Nerd Font Mono"
    font.pixelSize: 16

    readonly property string altLayout: "scrolling" // pas aan naar jouw plugin-naam
    property string current: "dwindle"

    text: current === "dwindle" ? "T |" : "S |" // grid-icoon vs horizontale pijlen

    Process {
        id: poll
        running: true
        command: ["bash", "-lc",
            "while true; do hyprctl getoption general:layout | awk '/str:/{print $2}'; sleep 2; done"]
        stdout: SplitParser {
            onRead: (line) => {
                line = line.trim();
                if (line.length > 0) layoutMod.current = line;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            const next = layoutMod.current === "dwindle" ? layoutMod.altLayout : "dwindle";
            Quickshell.execDetached(["hyprctl", "keyword", "general:layout", next]);
            layoutMod.current = next; // optimistisch al updaten, poll bevestigt nadien
        }
    }
}
