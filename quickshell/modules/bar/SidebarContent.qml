import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

// 1. Importeer de bovenliggende map (modules/) waar WorkspacesV.qml staat:
import ".."

// 2. Importeer de componentenmap (modules/components/) voor ClockV.qml:
import "../components"

ColumnLayout {
    id: barRoot

    property var activePlayer: null
    property string fontFamily: "JetBrainsMono Nerd Font Mono"
    property color fgColor: "#fff7e5"
    property bool isMediaOpen: false
    signal mediaClicked(real clickY)

    width: 38
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.topMargin: 16
    anchors.bottomMargin: 16
    spacing: 0

    // Workspaces
    Workspaces {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
    }

    Item {
        Layout.fillHeight: true
    }

    // Klok
    Clock {
        Layout.alignment: Qt.AlignHCenter
        fontFamily: barRoot.fontFamily
        fgColor: barRoot.fgColor
    }

    Item {
        Layout.fillHeight: true
    }

    // Snelkoppelingen & Icoontjes
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        Layout.fillWidth: true
        spacing: 16

        // Media Trigger (Blanco vak blijft klikbaar om te sluiten)
        Item {
            id: mediaWidget
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 24
            implicitHeight: 24

            readonly property string artUrl: barRoot.activePlayer && barRoot.activePlayer.trackArtUrl ? barRoot.activePlayer.trackArtUrl : ""

            // Enkel het Visuele gedeelte verbergen als het paneel open is:
            Item {
                anchors.fill: parent
                visible: !barRoot.isMediaOpen

                Image {
                    id: mediaArt
                    anchors.fill: parent
                    source: mediaWidget.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 6
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: mediaArt
                    maskSource: maskRect
                    visible: mediaArt.status === Image.Ready && mediaWidget.artUrl !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: mediaArt.status !== Image.Ready || mediaWidget.artUrl === ""
                    text: "📻"
                    color: barRoot.fgColor
                    font.family: barRoot.fontFamily
                    font.pixelSize: 16
                }
            }

            // De MouseArea blijft op deze plek in de sidebar ALTIJD actief:
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let mapped = mediaWidget.mapToItem(barRoot.parent, 0, 0);
                    barRoot.mediaClicked(mapped.y + mediaWidget.height / 2);
                }
            }
        }

        // Bluetooth
        Text {
            text: ""
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 23
            Layout.alignment: Qt.AlignHCenter
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["noctalia", "msg", "panel-toggle", "control-center"])
            }
        }

        // Settings / System
        Text {
            text: "⚙"
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 23
            Layout.alignment: Qt.AlignHCenter
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["noctalia", "msg", "panel-toggle", "control-center"])
            }
        }

        // Notifications
        Text {
            text: "󰂚"
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 23
            Layout.alignment: Qt.AlignHCenter
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["noctalia", "msg", "panel-toggle", "tray-drawer"])
            }
        }

        // Session / Power
        Text {
            text: "⏻"
            color: barRoot.fgColor
            font.family: barRoot.fontFamily
            font.pixelSize: 23
            Layout.alignment: Qt.AlignHCenter
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["wlogout", "-b", "5"])
            }
        }
    }
}
