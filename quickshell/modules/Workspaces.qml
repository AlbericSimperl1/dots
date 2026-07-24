import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

RowLayout {
    id: wsRow
    spacing: 3

    // persistent-workspaces: "*": 6  -> toon altijd workspace 1..6
    property int persistentCount: 6

    property var icons: ({
        "1": "", "2": "", "3": "",
        "4": "", "5": "", "6": ""
    })

    Repeater {
        model: persistentCount
        delegate: Rectangle {
            id: pill
            required property int index
            property int wsId: index + 1
            property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
            property bool isEmpty: {
                for (const ws of Hyprland.workspaces.values) {
                    if (ws.id === wsId) return false;
                }
                return true;
            }
            property bool hovered: false

            Layout.preferredHeight: 5
            Layout.preferredWidth: isActive ? 65 : (isEmpty ? 20 : 40)
            Layout.alignment: Qt.AlignVCenter
            radius: 100
            color: isActive
                ? "#fff7e5"
                : (hovered ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.25))

            Behavior on Layout.preferredWidth { NumberAnimation { duration: 1 } }
            Behavior on color { ColorAnimation { duration: 100 } }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: pill.hovered = true
                onExited: pill.hovered = false

                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: Hyprland.dispatch("workspace " + pill.wsId)
            }
        }
    }
}
