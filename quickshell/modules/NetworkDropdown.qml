// // import QtQuick
// // import QtQuick.Controls
// // import QtQuick.Layouts
// // import Quickshell
// // import Quickshell.Io

// // Item {
// //     id: dropdownRoot

// //     property var network: null
// //     property color fg: "#fff7e5"
// //     property color accent: "#ebd9b9"
// //     property color muted: Qt.rgba(1, 0.95, 0.82, 0.78)
// //     property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
// //     property color borderCol: "#eb2e2e3d"
// //     property string fontFamily: "JetBrainsMono Nerd Font Mono"

// //     property string selectedSsid: ""
// //     property string connectingSsid: ""

// //     // Sla het wachtwoord lokaal op per actieve SSID zodat re-renders de tekst niet wissen
// //     property string currentPassword: ""

// //     opacity: visible ? 1 : 0

// //     function attemptConnect(ssid, password) {
// //         dropdownRoot.connectingSsid = ssid;
// //         let cmd = [];
// //         if (password && password.length > 0) {
// //             cmd = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
// //         } else {
// //             cmd = ["nmcli", "device", "wifi", "connect", ssid];
// //         }

// //         Quickshell.execDetached(cmd);
// //         dropdownRoot.selectedSsid = "";
// //         dropdownRoot.currentPassword = "";

// //         if (dropdownRoot.network) {
// //             dropdownRoot.network.refreshNetworkData();
// //         }
// //     }

// //     Rectangle {
// //         anchors.fill: parent
// //         color: "transparent"
// //         clip: true

// //         ColumnLayout {
// //             anchors.fill: parent
// //             anchors.leftMargin: 5
// //             anchors.rightMargin: 5
// //             anchors.topMargin: 4
// //             anchors.bottomMargin: 10
// //             spacing: 8

// //             // Header
// //             RowLayout {
// //                 Layout.fillWidth: true

// //                 Text {
// //                     text: "Wi-Fi"
// //                     color: dropdownRoot.fg
// //                     font.family: dropdownRoot.fontFamily
// //                     font.pixelSize: 13
// //                     font.bold: true
// //                     Layout.fillWidth: true
// //                 }

// //                 Text {
// //                     text: "󰑐"
// //                     color: dropdownRoot.muted
// //                     font.family: dropdownRoot.fontFamily
// //                     font.pixelSize: 15

// //                     MouseArea {
// //                         anchors.fill: parent
// //                         cursorShape: Qt.PointingHandCursor
// //                         onClicked: if (dropdownRoot.network)
// //                             dropdownRoot.network.refreshNetworkData()
// //                     }
// //                 }

// //                 Text {
// //                     text: (dropdownRoot.network && dropdownRoot.network.state) ? "ON" : "OFF"
// //                     color: (dropdownRoot.network && dropdownRoot.network.state) ? dropdownRoot.accent : dropdownRoot.muted
// //                     font.family: dropdownRoot.fontFamily
// //                     font.pixelSize: 15

// //                     MouseArea {
// //                         anchors.fill: parent
// //                         cursorShape: Qt.PointingHandCursor
// //                         onClicked: {
// //                             if (!dropdownRoot.network)
// //                                 return;
// //                             if (dropdownRoot.network.state) {
// //                                 Quickshell.execDetached(["nmcli", "radio", "wifi", "off"]);
// //                             } else {
// //                                 Quickshell.execDetached(["nmcli", "radio", "wifi", "on"]);
// //                             }
// //                             dropdownRoot.network.refreshNetworkData();
// //                         }
// //                     }
// //                 }
// //             }

// //             ListView {
// //                 id: wifiListView
// //                 Layout.fillWidth: true
// //                 Layout.fillHeight: true
// //                 model: dropdownRoot.network ? dropdownRoot.network.networks : []
// //                 clip: true
// //                 spacing: 6

// //                 ScrollBar.vertical: ScrollBar {
// //                     policy: ScrollBar.AsNeeded
// //                 }

// //                 delegate: Column {
// //                     width: wifiListView.width
// //                     spacing: 4

// //                     Rectangle {
// //                         width: parent.width
// //                         height: 36
// //                         radius: 6
// //                         color: modelData.connected ? dropdownRoot.softFill : "transparent"
// //                         border.color: modelData.connected ? dropdownRoot.borderCol : "transparent"

// //                         RowLayout {
// //                             anchors.fill: parent
// //                             anchors.leftMargin: 10
// //                             anchors.rightMargin: 10
// //                             spacing: 8

// //                             Text {
// //                                 text: {
// //                                     const sig = parseInt(modelData.signal);
// //                                     if (isNaN(sig))
// //                                         return "󰤯";
// //                                     if (sig > 75)
// //                                         return "󰤨";
// //                                     if (sig > 50)
// //                                         return "󰤥";
// //                                     if (sig > 25)
// //                                         return "󰤢";
// //                                     return "󰤟";
// //                                 }
// //                                 color: dropdownRoot.fg
// //                                 font.family: dropdownRoot.fontFamily
// //                                 font.pixelSize: 15
// //                             }

// //                             Text {
// //                                 text: modelData.ssid
// //                                 color: dropdownRoot.fg
// //                                 font.family: dropdownRoot.fontFamily
// //                                 font.pixelSize: 13
// //                                 font.bold: modelData.connected
// //                                 Layout.fillWidth: true
// //                                 elide: Text.ElideRight
// //                             }

// //                             Text {
// //                                 text: dropdownRoot.connectingSsid === modelData.ssid ? "Verbinden..." : (modelData.connected ? "󰄬" : (modelData.secure ? "󰌾" : ""))
// //                                 color: modelData.connected ? dropdownRoot.accent : dropdownRoot.muted
// //                                 font.family: dropdownRoot.fontFamily
// //                                 font.pixelSize: 13
// //                             }
// //                         }

// //                         MouseArea {
// //                             anchors.fill: parent
// //                             cursorShape: Qt.PointingHandCursor
// //                             onClicked: {
// //                                 if (modelData.connected)
// //                                     return;

// //                                 if (modelData.secure) {
// //                                     if (dropdownRoot.selectedSsid === modelData.ssid) {
// //                                         dropdownRoot.selectedSsid = "";
// //                                         dropdownRoot.currentPassword = "";
// //                                     } else {
// //                                         dropdownRoot.selectedSsid = modelData.ssid;
// //                                         dropdownRoot.currentPassword = "";
// //                                     }
// //                                 } else {
// //                                     dropdownRoot.attemptConnect(modelData.ssid, "");
// //                                 }
// //                             }
// //                         }
// //                     }

// //                     // Inline Wachtwoord Veld
// //                     Rectangle {
// //                         visible: dropdownRoot.selectedSsid === modelData.ssid && !modelData.connected
// //                         width: parent.width
// //                         height: visible ? 34 : 0
// //                         color: Qt.rgba(0, 0, 0, 0.25)
// //                         radius: 6

// //                         // Blokkeer dat de achterliggende MouseArea reageert op kliks binnen het vak
// //                         MouseArea {
// //                             anchors.fill: parent
// //                             onPressed: mouse => mouse.accepted = true
// //                             onClicked: mouse => mouse.accepted = true
// //                         }

// //                         RowLayout {
// //                             anchors.fill: parent
// //                             anchors.margins: 3
// //                             spacing: 6

// //                             TextField {
// //                                 id: pwdInput
// //                                 Layout.fillWidth: true
// //                                 Layout.fillHeight: true
// //                                 placeholderText: "Wachtwoord..."
// //                                 echoMode: TextInput.Password
// //                                 font.family: dropdownRoot.fontFamily
// //                                 font.pixelSize: 12
// //                                 color: dropdownRoot.fg
// //                                 verticalAlignment: TextInput.AlignVCenter
// //                                 focus: true

// //                                 text: dropdownRoot.currentPassword
// //                                 onTextChanged: dropdownRoot.currentPassword = text

// //                                 Component.onCompleted: forceActiveFocus()
// //                                 onVisibleChanged: {
// //                                     if (visible)
// //                                         forceActiveFocus();
// //                                 }

// //                                 background: Rectangle {
// //                                     color: Qt.rgba(1, 1, 1, 0.08)
// //                                     radius: 4
// //                                     border.color: pwdInput.activeFocus ? dropdownRoot.accent : dropdownRoot.borderCol
// //                                 }

// //                                 onAccepted: dropdownRoot.attemptConnect(modelData.ssid, pwdInput.text)
// //                             }

// //                             Button {
// //                                 Layout.preferredWidth: 65
// //                                 Layout.fillHeight: true
// //                                 text: "Connect"
// //                                 onClicked: dropdownRoot.attemptConnect(modelData.ssid, pwdInput.text)
// //                             }
// //                         }
// //                     }
// //                 }
// //             }
// //         }
// //     }
// // }

// // NetworkDropdown.qml
// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts
// import Quickshell
// import Quickshell.Networking

// Item {
//     id: dropdownRoot

//     property var network: null          // verwijzing naar Network.qml
//     property color fg: "#fff7e5"
//     property color accent: "#ebd9b9"
//     property color muted: Qt.rgba(1, 0.95, 0.82, 0.78)
//     property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
//     property color borderCol: "#eb2e2e3d"
//     property string fontFamily: "JetBrainsMono Nerd Font Mono"

//     // Huidig geselecteerde SSID voor wachtwoordweergave
//     property string selectedSsid: ""
//     property string currentPassword: ""

//     // Verbindingshulp
//     function attemptConnect(ssid, password) {
//         if (!network)
//             return;
//         var wifi = network.wifiDevice;
//         if (!wifi)
//             return;
//         // Zoek het netwerkobject op basis van SSID
//         var target = wifi.networks.find(n => n.ssid === ssid);
//         if (target) {
//             network.connectToNetwork(target, password);
//             selectedSsid = "";
//             currentPassword = "";
//         }
//     }

//     // Toggle WiFi
//     function toggleWifi() {
//         if (!network)
//             return;
//         var wifi = network.wifiDevice;
//         if (!wifi)
//             return;
//         wifi.enabled = !wifi.enabled;
//     }

//     opacity: visible ? 1 : 0

//     Rectangle {
//         anchors.fill: parent
//         color: "transparent"
//         clip: true

//         ColumnLayout {
//             anchors.fill: parent
//             anchors.margins: 8
//             spacing: 8

//             // Header: titel, refresh, toggle
//             RowLayout {
//                 Layout.fillWidth: true
//                 Text {
//                     text: "Wi‑Fi"
//                     color: fg
//                     font.family: fontFamily
//                     font.pixelSize: 13
//                     font.bold: true
//                     Layout.fillWidth: true
//                 }
//                 Text {
//                     text: "󰑐"   // refresh icoon
//                     color: muted
//                     font.family: fontFamily
//                     font.pixelSize: 15
//                     MouseArea {
//                         anchors.fill: parent
//                         cursorShape: Qt.PointingHandCursor
//                         onClicked: {
//                             if (network && network.wifiDevice)
//                                 network.wifiDevice.scan(); // start nieuwe scan
//                         }
//                     }
//                 }
//                 Text {
//                     text: network && network.state ? "ON" : "OFF"
//                     color: network && network.state ? accent : muted
//                     font.family: fontFamily
//                     font.pixelSize: 15
//                     MouseArea {
//                         anchors.fill: parent
//                         cursorShape: Qt.PointingHandCursor
//                         onClicked: toggleWifi()
//                     }
//                 }
//             }

//             // Lijst van netwerken
//             ListView {
//                 id: wifiListView
//                 Layout.fillWidth: true
//                 Layout.fillHeight: true
//                 model: network ? network.networks : []
//                 clip: true
//                 spacing: 6

//                 ScrollBar.vertical: ScrollBar {
//                     policy: ScrollBar.AsNeeded
//                 }

//                 delegate: Column {
//                     width: wifiListView.width
//                     spacing: 4

//                     Rectangle {
//                         width: parent.width
//                         height: 36
//                         radius: 6
//                         color: modelData.connected ? softFill : "transparent"
//                         border.color: modelData.connected ? borderCol : "transparent"

//                         RowLayout {
//                             anchors.fill: parent
//                             anchors.margins: 4
//                             spacing: 8

//                             Text {
//                                 text: {
//                                     var sig = modelData.signalStrength;
//                                     if (sig > 75)
//                                         return "󰤨";
//                                     if (sig > 50)
//                                         return "󰤥";
//                                     if (sig > 25)
//                                         return "󰤢";
//                                     return "󰤟";
//                                 }
//                                 color: fg
//                                 font.family: fontFamily
//                                 font.pixelSize: 15
//                             }
//                             Text {
//                                 text: modelData.ssid
//                                 color: fg
//                                 font.family: fontFamily
//                                 font.pixelSize: 13
//                                 font.bold: modelData.connected
//                                 Layout.fillWidth: true
//                                 elide: Text.ElideRight
//                             }
//                             Text {
//                                 text: modelData.connected ? "󰄬" : (modelData.secure ? "󰌾" : "")
//                                 color: modelData.connected ? accent : muted
//                                 font.family: fontFamily
//                                 font.pixelSize: 13
//                             }
//                         }

//                         MouseArea {
//                             anchors.fill: parent
//                             cursorShape: Qt.PointingHandCursor
//                             onClicked: {
//                                 if (modelData.connected)
//                                     return;
//                                 if (modelData.secure) {
//                                     if (selectedSsid === modelData.ssid) {
//                                         selectedSsid = "";
//                                         currentPassword = "";
//                                     } else {
//                                         selectedSsid = modelData.ssid;
//                                         currentPassword = "";
//                                     }
//                                 } else {
//                                     attemptConnect(modelData.ssid, "");
//                                 }
//                             }
//                         }
//                     }

//                     // Inline wachtwoordveld
//                     Rectangle {
//                         visible: selectedSsid === modelData.ssid && !modelData.connected
//                         width: parent.width
//                         height: visible ? 34 : 0
//                         color: Qt.rgba(0, 0, 0, 0.25)
//                         radius: 6

//                         MouseArea {
//                             anchors.fill: parent
//                             onPressed: mouse => mouse.accepted = true
//                             onClicked: mouse => mouse.accepted = true
//                         }

//                         RowLayout {
//                             anchors.fill: parent
//                             anchors.margins: 3
//                             spacing: 6

//                             TextField {
//                                 id: pwdInput
//                                 Layout.fillWidth: true
//                                 Layout.fillHeight: true
//                                 placeholderText: "Wachtwoord..."
//                                 echoMode: TextInput.Password
//                                 font.family: fontFamily
//                                 font.pixelSize: 12
//                                 color: fg
//                                 verticalAlignment: TextInput.AlignVCenter
//                                 focus: true
//                                 text: currentPassword
//                                 onTextChanged: currentPassword = text
//                                 Component.onCompleted: forceActiveFocus()
//                                 background: Rectangle {
//                                     color: Qt.rgba(1, 1, 1, 0.08)
//                                     radius: 4
//                                     border.color: pwdInput.activeFocus ? accent : borderCol
//                                 }
//                                 onAccepted: attemptConnect(modelData.ssid, pwdInput.text)
//                             }
//                             Button {
//                                 Layout.preferredWidth: 65
//                                 Layout.fillHeight: true
//                                 text: "Connect"
//                                 onClicked: attemptConnect(modelData.ssid, pwdInput.text)
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }

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

        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
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

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    RowLayout {
                        spacing: 6
                        Text {
                            text: dropdownRoot.network ? (dropdownRoot.network.activeType === "ethernet" ? "󰈀" : "󰤨") : "󰤮"
                            color: dropdownRoot.accent
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 14
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
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        text: {
                            if (!dropdownRoot.network || !dropdownRoot.network.connected)
                                return "Wi-Fi: " + (dropdownRoot.network && dropdownRoot.network.wifiEnabled ? "Aan" : "Uit");
                            return "IP: " + dropdownRoot.network.ipAddress + "  |  ↓ " + dropdownRoot.network.rxSpeed + "  ↑ " + dropdownRoot.network.txSpeed;
                        }
                        color: dropdownRoot.muted
                        font.family: dropdownRoot.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }

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

            // Scheidingslijn
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: dropdownRoot.borderCol
                opacity: 0.4
            }

            // Inline wachtwoordinvoerveld (verschijnt wanneer je op een beveiligd netwerk klikt)
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
                    font.pixelSize: 11

                    background: Rectangle {
                        color: dropdownRoot.softFill
                        radius: 5
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
                    radius: 5
                    color: dropdownRoot.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Verbind"
                        color: "#111117"
                        font.family: dropdownRoot.fontFamily
                        font.pixelSize: 11
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
                    radius: 6
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
                            font.pixelSize: 13
                        }

                        Text {
                            text: modelData.ssid
                            color: dropdownRoot.fg
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 12
                            font.bold: modelData.active
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: modelData.secured
                            text: "🔒"
                            color: dropdownRoot.muted
                            font.pixelSize: 10
                        }

                        Text {
                            text: modelData.signal + "%"
                            color: dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 10
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

                // Status als Wi-Fi uit staat of er geen netwerken worden gevonden
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
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
