import QtQuick
import Quickshell

Text {
    color: "#fff7e5"
    font.family: "JetBrainsMono Nerd Font Mono"
    font.pixelSize: 20
    text: "󰍛"

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["kitty", "btop"])
    }
}
