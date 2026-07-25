import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: dropdownRoot

    property var bluetooth: null
    property color fg: "#fff7e5"
    property color accent: "#fff7e5"
    property color muted: "#ffffff"
    property color softFill: "#ffffff"
    property color borderCol: "#eb2e2e3d"
    property string fontFamily: "JetBrainsMono Nerd Font Mono"

    opacity: visible ? 1 : 0

    // Herbruikbare knop
    component BtButton: Rectangle {
        id: btn
        property string glyph: ""
        property bool active: false
        signal pressed

        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: 6
        color: active ? dropdownRoot.accent : dropdownRoot.softFill
        border.color: dropdownRoot.borderCol
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: btn.active ? "#111117" : dropdownRoot.fg
            font.family: dropdownRoot.fontFamily
            font.pixelSize: 13
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.pressed()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.topMargin: 2
            anchors.bottomMargin: 6
            spacing: 8

            // Header Status & Quick Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Linker kolom met status en Batterij/Details
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: dropdownRoot.bluetooth ? dropdownRoot.bluetooth.getBtIcon(dropdownRoot.bluetooth.connected, dropdownRoot.bluetooth.btEnabled) : "󰂲"
                            color: dropdownRoot.accent
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 14
                        }

                        Text {
                            text: {
                                if (!dropdownRoot.bluetooth)
                                    return "Bluetooth";
                                if (dropdownRoot.bluetooth.connected)
                                    return dropdownRoot.bluetooth.activeDevice || "Verbonden";
                                return "Niet verbonden";
                            }
                            color: dropdownRoot.fg
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!dropdownRoot.bluetooth || !dropdownRoot.bluetooth.btEnabled)
                                return "Bluetooth: Uit";
                            if (dropdownRoot.bluetooth.connected && dropdownRoot.bluetooth.batteryLevel >= 0)
                                return "Batterij: " + dropdownRoot.bluetooth.batteryLevel + "%";
                            return "Bluetooth: Aan";
                        }
                        color: dropdownRoot.muted
                        font.family: dropdownRoot.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }

                // Rechter knoppen - vast verankerd aan de rechterzijde
                RowLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    spacing: 6

                    BtButton {
                        glyph: dropdownRoot.bluetooth && dropdownRoot.bluetooth.btEnabled ? "󰂯" : "󰂲"
                        active: dropdownRoot.bluetooth && dropdownRoot.bluetooth.btEnabled
                        onPressed: if (dropdownRoot.bluetooth)
                            dropdownRoot.bluetooth.toggleBt()
                    }

                    BtButton {
                        glyph: "󰑐"
                        onPressed: if (dropdownRoot.bluetooth)
                            dropdownRoot.bluetooth.triggerScan()
                    }
                }
            }

            // Scheidingslijn
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: dropdownRoot.borderCol
                opacity: 0.4
            }

            // Bluetooth Apparaten Lijst
            ListView {
                id: btListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 5
                model: (dropdownRoot.bluetooth && dropdownRoot.bluetooth.btEnabled) ? dropdownRoot.bluetooth.devices : []

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    required property var modelData
                    width: btListView.width
                    height: 30
                    radius: 6
                    color: modelData.connected ? Qt.rgba(dropdownRoot.accent.r, dropdownRoot.accent.g, dropdownRoot.accent.b, 0.25) : dropdownRoot.softFill
                    border.color: modelData.connected ? dropdownRoot.accent : dropdownRoot.borderCol
                    border.width: modelData.connected ? 1 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: dropdownRoot.bluetooth ? dropdownRoot.bluetooth.getDeviceIcon(modelData.name) : "󰂱"
                            color: modelData.connected ? dropdownRoot.accent : dropdownRoot.fg
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 13
                        }

                        Text {
                            text: modelData.name
                            color: dropdownRoot.fg
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 12
                            font.bold: modelData.connected
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: modelData.paired
                            text: "󰌹"
                            color: dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 11
                        }

                        Text {
                            visible: modelData.battery >= 0
                            text: modelData.battery + "%"
                            color: dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.connected) {
                                dropdownRoot.bluetooth.disconnectDevice(modelData.mac);
                            } else {
                                dropdownRoot.bluetooth.connectDevice(modelData.mac);
                            }
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    visible: btListView.count === 0

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (!dropdownRoot.bluetooth || !dropdownRoot.bluetooth.btEnabled)
                                return "Bluetooth staat uit";
                            return "Scannen naar apparaten...";
                        }
                        color: dropdownRoot.muted
                        font.family: dropdownRoot.fontFamily
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
