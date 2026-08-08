import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: dropdownRoot

    property var network: null
    property color fg: "#fff7e5"
    property color accent: "#fff7e5"
    property color muted: "#ffffff"
    property color softFill: "#ffffff"
    property color borderCol: "#eb2e2e3d"
    property string fontFamily: "JetBrainsMono Nerd Font Mono"

    property string selectedSsid: ""
    property string passwordInput: ""

    opacity: visible ? 1 : 0

    // Herbruikbare knop
    component NetButton: Rectangle {
        id: btn
        property string glyph: ""
        property bool active: false
        signal pressed

        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: 1
        color: active ? dropdownRoot.accent : dropdownRoot.softFill
        border.color: dropdownRoot.borderCol
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: btn.active ? "#111117" : dropdownRoot.fg
            font.family: dropdownRoot.fontFamily
            font.pixelSize: 15
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

                // Linker kolom met status en IP/Snelheden - neemt exact alle beschikbare ruimte in
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: dropdownRoot.network ? (dropdownRoot.network.activeType === "ethernet" ? "󰈀" : "󰤨") : "󰤮"
                            color: dropdownRoot.accent
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 16
                        }

                        Text {
                            text: {
                                if (!dropdownRoot.network)
                                    return "Netwerk";
                                if (dropdownRoot.network.connected)
                                    return dropdownRoot.network.activeSsid || "Verbonden";
                                return "Niet verbonden";
                            }
                            color: dropdownRoot.fg
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!dropdownRoot.network || !dropdownRoot.network.connected)
                                return "Wi-Fi: " + (dropdownRoot.network && dropdownRoot.network.wifiEnabled ? "Aan" : "Uit");
                            return "IP: " + dropdownRoot.network.ipAddress + "  |  ↓ " + dropdownRoot.network.rxSpeed + "  ↑ " + dropdownRoot.network.txSpeed;
                        }
                        color: dropdownRoot.muted
                        font.family: dropdownRoot.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                // Rechter knoppen - vast verankerd aan de rechterzijde
                RowLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    spacing: 6

                    NetButton {
                        glyph: dropdownRoot.network && dropdownRoot.network.wifiEnabled ? "󰤨" : "󰤭"
                        active: dropdownRoot.network && dropdownRoot.network.wifiEnabled
                        onPressed: if (dropdownRoot.network)
                            dropdownRoot.network.toggleWifi()
                    }

                    NetButton {
                        glyph: "󰑐"
                        onPressed: if (dropdownRoot.network)
                            dropdownRoot.network.triggerRescan()
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

            // Inline wachtwoordinvoerveld
            RowLayout {
                Layout.fillWidth: true
                visible: dropdownRoot.selectedSsid !== ""
                spacing: 6

                TextField {
                    id: pwdField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    placeholderText: "Wachtwoord voor " + dropdownRoot.selectedSsid
                    placeholderTextColor: dropdownRoot.muted
                    echoMode: TextInput.Password
                    color: dropdownRoot.fg
                    font.family: dropdownRoot.fontFamily
                    font.pixelSize: 13

                    background: Rectangle {
                        color: dropdownRoot.softFill
                        radius: 1
                        border.color: dropdownRoot.borderCol
                        border.width: 1
                    }
                    onTextChanged: dropdownRoot.passwordInput = text
                    onAccepted: {
                        if (dropdownRoot.network) {
                            dropdownRoot.network.connectToNetwork(dropdownRoot.selectedSsid, dropdownRoot.passwordInput);
                            dropdownRoot.selectedSsid = "";
                            dropdownRoot.passwordInput = "";
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 28
                    radius: 1
                    color: dropdownRoot.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Verbind"
                        color: "#111117"
                        font.family: dropdownRoot.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (dropdownRoot.network) {
                                dropdownRoot.network.connectToNetwork(dropdownRoot.selectedSsid, dropdownRoot.passwordInput);
                                dropdownRoot.selectedSsid = "";
                                dropdownRoot.passwordInput = "";
                            }
                        }
                    }
                }

                NetButton {
                    glyph: "✕"
                    onPressed: {
                        dropdownRoot.selectedSsid = "";
                        dropdownRoot.passwordInput = "";
                    }
                }
            }

            // Wi-Fi Netwerken Lijst
            ListView {
                id: wifiListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 5
                model: (dropdownRoot.network && dropdownRoot.network.wifiEnabled) ? dropdownRoot.network.accessPoints : []

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Rectangle {
                    required property var modelData
                    width: wifiListView.width
                    height: 30
                    radius: 1
                    color: modelData.active ? Qt.rgba(dropdownRoot.accent.r, dropdownRoot.accent.g, dropdownRoot.accent.b, 0.25) : dropdownRoot.softFill
                    border.color: modelData.active ? dropdownRoot.accent : dropdownRoot.borderCol
                    border.width: modelData.active ? 1 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: dropdownRoot.network ? dropdownRoot.network.getWifiIcon(modelData.signal, true, true) : "󰤨"
                            color: modelData.active ? dropdownRoot.accent : dropdownRoot.fg
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 15
                        }

                        Text {
                            text: modelData.ssid
                            color: dropdownRoot.fg
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 14
                            font.bold: modelData.active
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: modelData.secured
                            text: "🔒"
                            color: dropdownRoot.muted
                            font.pixelSize: 12
                        }

                        Text {
                            text: modelData.signal + "%"
                            color: dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.active) {
                                dropdownRoot.network.disconnectNetwork(modelData.ssid);
                            } else if (modelData.secured) {
                                dropdownRoot.selectedSsid = modelData.ssid;
                            } else {
                                dropdownRoot.network.connectToNetwork(modelData.ssid, "");
                            }
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    visible: wifiListView.count === 0

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (!dropdownRoot.network || !dropdownRoot.network.wifiEnabled)
                                return "Wi-Fi staat uit";
                            return "Scannen naar netwerken...";
                        }
                        color: dropdownRoot.muted
                        font.family: dropdownRoot.fontFamily
                        font.pixelSize: 13
                    }
                }
            }
        }
    }
}
