import QtQuick
import Quickshell
import Quickshell.Io

Text {
    id: clock
    color: '#fff7e5'
    font.family: "JetBrainsMono Nerd Font Mono"
    font.pixelSize: 15
    font.weight: Font.ExtraBold

    function fmt() {
        const d = new Date();
        return Qt.formatDateTime(d, " hh:mm");
    }
    text: fmt()

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: clock.text = clock.fmt()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["kitty", "peaclock"]);
            } else if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", "omarchy-tz-select"]);
            }
        }
    }
}
