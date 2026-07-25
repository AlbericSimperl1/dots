import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: dropdownRoot

    property var network: null
    property color fg: "#fff7e5"
    property color accent: "#ebd9b9"
    property color muted: Qt.rgba(1, 0.95, 0.82, 0.78)
    property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
    property color borderCol: "#eb2e2e3d"
    property string fontFamily: "JetBrainsMono Nerd Font Mono"

    opacity: visible ? 1 : 0

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            anchors.topMargin: 4
            anchors.bottomMargin: 10
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Wi-Fi"
                    color: dropdownRoot.fg
                    font.family: dropdownRoot.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: " "
                    color: dropdownRoot.muted
                    font.family: dropdownRoot.fontFamily
                    font.pixelSize: 15

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dropdownRoot.network.refreshNetworkData()
                    }
                }

                Text {
                    text: dropdownRoot.network.state ? "" : ""
                    color: dropdownRoot.network.state ? dropdownRoot.accent : dropdownRoot.muted
                    font.family: dropdownRoot.fontFamily
                    font.pixelSize: 20

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (dropdownRoot.network.state)
                                Quickshell.execDetached(["nmcli", "radio", "wifi", "off"]);
                            else
                                Quickshell.execDetached(["nmcli", "radio", "wifi", "on"]);
                        }
                    }
                }
            }

            ListView {
                id: wifiListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: dropdownRoot.network ? dropdownRoot.network.networks : []
                clip: true
                spacing: 7

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    width: wifiListView.width
                    height: 32
                    radius: 6
                    color: dropdownRoot.softFill

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: {
                                const signalVal = parseInt(modelData.signal);
                                if (isNaN(signalVal))
                                    return "󰤯";
                                if (signalVal > 80)
                                    return "󰤨";
                                if (signalVal > 60)
                                    return "󰤥";
                                if (signalVal > 40)
                                    return "󰤢";
                                if (signalVal > 20)
                                    return "󰤟";
                                return "󰤯";
                            }
                            color: dropdownRoot.fg
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 15
                        }

                        Text {
                            text: modelData.ssid
                            color: dropdownRoot.fg
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 15
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: {
                                if (modelData.connected)
                                    return "";
                                if (modelData.secure)
                                    return "";
                                return "";
                            }
                            color: modelData.connected ? dropdownRoot.accent : dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 15
                        }

                        Text {
                            text: ""
                            color: dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 20
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", modelData.ssid]);
                        }
                    }
                }
            }
        }
    }
}
