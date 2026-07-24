import QtQuick
import Quickshell

Text {
    id: dateText
    color: "#fff7e5"
    font.family: "JetBrainsMono Nerd Font Mono"
    font.pixelSize: 14
    font.weight: Font.ExtraBold

    function fmt() {
        return " " + Qt.formatDateTime(new Date(), "hh:mm - dd/MM");
    }
    text: fmt()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: dateText.text = dateText.fmt()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: Quickshell.execDetached(["/usr/bin/rencal"])
    }
}
