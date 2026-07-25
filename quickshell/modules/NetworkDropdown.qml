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

    property string selectedSsid: ""
    property string connectingSsid: ""

    // Sla het wachtwoord lokaal op per actieve SSID zodat re-renders de tekst niet wissen
    property string currentPassword: ""

    opacity: visible ? 1 : 0

    function attemptConnect(ssid, password) {
        dropdownRoot.connectingSsid = ssid;
        let cmd = [];
        if (password && password.length > 0) {
            cmd = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        } else {
            cmd = ["nmcli", "device", "wifi", "connect", ssid];
        }

        Quickshell.execDetached(cmd);
        dropdownRoot.selectedSsid = "";
        dropdownRoot.currentPassword = "";

        if (dropdownRoot.network) {
            dropdownRoot.network.refreshNetworkData();
        }
    }

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

            // Header
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
                    text: "󰑐"
                    color: dropdownRoot.muted
                    font.family: dropdownRoot.fontFamily
                    font.pixelSize: 15

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (dropdownRoot.network)
                            dropdownRoot.network.refreshNetworkData()
                    }
                }

                Text {
                    text: (dropdownRoot.network && dropdownRoot.network.state) ? "ON" : "OFF"
                    color: (dropdownRoot.network && dropdownRoot.network.state) ? dropdownRoot.accent : dropdownRoot.muted
                    font.family: dropdownRoot.fontFamily
                    font.pixelSize: 15

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!dropdownRoot.network)
                                return;
                            if (dropdownRoot.network.state) {
                                Quickshell.execDetached(["nmcli", "radio", "wifi", "off"]);
                            } else {
                                Quickshell.execDetached(["nmcli", "radio", "wifi", "on"]);
                            }
                            dropdownRoot.network.refreshNetworkData();
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
                spacing: 6

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Column {
                    width: wifiListView.width
                    spacing: 4

                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: 6
                        color: modelData.connected ? dropdownRoot.softFill : "transparent"
                        border.color: modelData.connected ? dropdownRoot.borderCol : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: {
                                    const sig = parseInt(modelData.signal);
                                    if (isNaN(sig))
                                        return "󰤯";
                                    if (sig > 75)
                                        return "󰤨";
                                    if (sig > 50)
                                        return "󰤥";
                                    if (sig > 25)
                                        return "󰤢";
                                    return "󰤟";
                                }
                                color: dropdownRoot.fg
                                font.family: dropdownRoot.fontFamily
                                font.pixelSize: 15
                            }

                            Text {
                                text: modelData.ssid
                                color: dropdownRoot.fg
                                font.family: dropdownRoot.fontFamily
                                font.pixelSize: 13
                                font.bold: modelData.connected
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: dropdownRoot.connectingSsid === modelData.ssid ? "Verbinden..." : (modelData.connected ? "󰄬" : (modelData.secure ? "󰌾" : ""))
                                color: modelData.connected ? dropdownRoot.accent : dropdownRoot.muted
                                font.family: dropdownRoot.fontFamily
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected)
                                    return;

                                if (modelData.secure) {
                                    if (dropdownRoot.selectedSsid === modelData.ssid) {
                                        dropdownRoot.selectedSsid = "";
                                        dropdownRoot.currentPassword = "";
                                    } else {
                                        dropdownRoot.selectedSsid = modelData.ssid;
                                        dropdownRoot.currentPassword = "";
                                    }
                                } else {
                                    dropdownRoot.attemptConnect(modelData.ssid, "");
                                }
                            }
                        }
                    }

                    // Inline Wachtwoord Veld
                    Rectangle {
                        visible: dropdownRoot.selectedSsid === modelData.ssid && !modelData.connected
                        width: parent.width
                        height: visible ? 34 : 0
                        color: Qt.rgba(0, 0, 0, 0.25)
                        radius: 6

                        // Blokkeer dat de achterliggende MouseArea reageert op kliks binnen het vak
                        MouseArea {
                            anchors.fill: parent
                            onPressed: mouse => mouse.accepted = true
                            onClicked: mouse => mouse.accepted = true
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 6

                            TextField {
                                id: pwdInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                placeholderText: "Wachtwoord..."
                                echoMode: TextInput.Password
                                font.family: dropdownRoot.fontFamily
                                font.pixelSize: 12
                                color: dropdownRoot.fg
                                verticalAlignment: TextInput.AlignVCenter
                                focus: true

                                text: dropdownRoot.currentPassword
                                onTextChanged: dropdownRoot.currentPassword = text

                                Component.onCompleted: forceActiveFocus()
                                onVisibleChanged: {
                                    if (visible)
                                        forceActiveFocus();
                                }

                                background: Rectangle {
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    radius: 4
                                    border.color: pwdInput.activeFocus ? dropdownRoot.accent : dropdownRoot.borderCol
                                }

                                onAccepted: dropdownRoot.attemptConnect(modelData.ssid, pwdInput.text)
                            }

                            Button {
                                Layout.preferredWidth: 65
                                Layout.fillHeight: true
                                text: "Connect"
                                onClicked: dropdownRoot.attemptConnect(modelData.ssid, pwdInput.text)
                            }
                        }
                    }
                }
            }
        }
    }
}
