import QtQuick 2.15
import QtQuick.Layouts 1.15

RowLayout {
    id: launcherRoot
    spacing: 4

    // Hier voeg je eenvoudig nieuwe apps toe
    property var apps: [
        {
            icon: "image://icon/zen-browser",
            fallback: "file:///usr/share/icons/hicolor/scalable/apps/zen-browser.svg",
            exec: "zen-browser.desktop"
        },
        {
            icon: "image://icon/discord",
            fallback: "file:///usr/share/icons/hicolor/scalable/apps/discord.svg",
            exec: "discord"
        },
        {
            icon: "image://icon/spotify",
            fallback: "file:///usr/share/icons/hicolor/scalable/apps/spotify.svg",
            exec: "spotify"
        },
        {
            icon: "image://icon/zed",
            fallback: "file:///usr/share/icons/hicolor/scalable/apps/zed.svg",
            exec: "zed"
        },
        {
            icon: "image://icon/org.gnome.Nautilus",
            fallback: "",
            exec: "nautilus"
        }
    ]

    Repeater {
        model: launcherRoot.apps

        Rectangle {
            id: buttonBg
            implicitWidth: 25
            implicitHeight: 25
            radius: 8
            color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            Image {
                id: appIcon
                anchors.fill: parent
                anchors.margins: 5
                fillMode: Image.PreserveAspectFit
                source: modelData.icon

                onStatusChanged: {
                    if (status === Image.Error && modelData.fallback && modelData.fallback !== "") {
                        source = modelData.fallback;
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Start via Hyprland dispatch (werkt altijd in Hyprland)
                    Hyprland.dispatch("exec " + modelData.exec);
                }
            }
        }
    }
}
