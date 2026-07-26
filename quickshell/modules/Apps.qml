import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Hyprland

RowLayout {
    id: launcherRoot
    spacing: 10

    property var apps: [
        {
            icon: "zen-browser",
            fallback: "file:///usr/share/icons/hicolor/scalable/apps/zen-browser.svg",
            exec: "zen-browser" // Binary in plaats van .desktop
        },
        {
            icon: "zed",
            fallback: "file:///usr/share/icons/hicolor/scalable/apps/zed.svg",
            exec: "zeditor"
        },
        {
            icon: "spotify",
            fallback: "file:///usr/share/icons/hicolor/scalable/apps/spotify.svg",
            exec: "spotify"
        },
        {
            icon: "discord",
            fallback: "file:///usr/share/icons/hicolor/scalable/apps/discord.svg",
            exec: "discord"
        },
        {
            icon: "org.gnome.Nautilus",
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
                anchors.margins: 3
                fillMode: Image.PreserveAspectFit

                // Dwing Qt om het icoon op hoge resolutie te renderen
                sourceSize: Qt.size(64, 64)
                smooth: true
                mipmap: true

                // Zoek het pad op via Quickshell's native icon resolver, anders fallback
                source: {
                    let path = Quickshell.iconPath(modelData.icon);
                    return path !== "" ? path : "image://icon/" + modelData.icon;
                }

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
                    // Betrouwbare detach execution via shell
                    Quickshell.execDetached(["sh", "-c", modelData.exec]);
                }
            }
        }
    }
}
