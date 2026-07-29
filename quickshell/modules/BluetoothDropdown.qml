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

    // Gefilterde apparatenlijsten (Omarchy-stijl)
    readonly property var connectedDevices: (bluetooth && bluetooth.btEnabled && bluetooth.devices) ? bluetooth.devices.filter(d => d.connected) : []
    readonly property var availableDevices: (bluetooth && bluetooth.btEnabled && bluetooth.devices) ? bluetooth.devices.filter(d => !d.connected) : []

    // Herbruikbare knop
    component BtButton: Rectangle {
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

    // Herbruikbaar Apparaat-item
    component DeviceRow: Rectangle {
        id: devRow
        property var deviceData: null

        Layout.fillWidth: true
        implicitHeight: 32
        radius: 1
        color: (deviceData && deviceData.connected) ? Qt.rgba(dropdownRoot.accent.r, dropdownRoot.accent.g, dropdownRoot.accent.b, 0.25) : dropdownRoot.softFill
        border.color: (deviceData && deviceData.connected) ? dropdownRoot.accent : dropdownRoot.borderCol
        border.width: (deviceData && deviceData.connected) ? 0 : 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Text {
                text: dropdownRoot.bluetooth && devRow.deviceData ? dropdownRoot.bluetooth.getDeviceIcon(devRow.deviceData.name) : "󰂱"
                color: (devRow.deviceData && devRow.deviceData.connected) ? dropdownRoot.accent : dropdownRoot.fg
                font.family: dropdownRoot.fontFamily
                font.pixelSize: 16
            }

            Text {
                text: devRow.deviceData ? devRow.deviceData.name : ""
                color: dropdownRoot.fg
                font.family: dropdownRoot.fontFamily
                font.pixelSize: 14
                font.bold: devRow.deviceData && devRow.deviceData.connected
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                visible: devRow.deviceData && devRow.deviceData.paired
                text: "󰌹"
                color: dropdownRoot.muted
                font.family: dropdownRoot.fontFamily
                font.pixelSize: 13
            }

            Text {
                visible: devRow.deviceData && devRow.deviceData.battery >= 0
                text: devRow.deviceData ? devRow.deviceData.battery + "%" : ""
                color: dropdownRoot.muted
                font.family: dropdownRoot.fontFamily
                font.pixelSize: 12
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!devRow.deviceData)
                    return;
                if (devRow.deviceData.connected) {
                    dropdownRoot.bluetooth.disconnectDevice(devRow.deviceData.mac);
                } else {
                    dropdownRoot.bluetooth.connectDevice(devRow.deviceData.mac);
                }
            }
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
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: dropdownRoot.bluetooth ? dropdownRoot.bluetooth.getBtIcon(dropdownRoot.bluetooth.connected, dropdownRoot.bluetooth.btEnabled) : "󰂯"
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
                            font.pixelSize: 16
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
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                // Rechter knoppen
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

            // Hoofdscheidingslijn
            Rectangle {
                Layout.fillWidth: true
                height: 2
                color: Color.white
                opacity: 0.17
            }

            // Apparatenlijst met secties & scroll
            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: deviceColumn.implicitHeight
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: deviceColumn
                    width: flick.width
                    spacing: 8

                    // Geen apparaten / Bluetooth uit melding
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        visible: !dropdownRoot.bluetooth || !dropdownRoot.bluetooth.btEnabled || (dropdownRoot.connectedDevices.length === 0 && dropdownRoot.availableDevices.length === 0)

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (!dropdownRoot.bluetooth || !dropdownRoot.bluetooth.btEnabled)
                                    return "Bluetooth staat uit";
                                return "Scannen naar apparaten...";
                            }
                            color: dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 13
                        }
                    }

                    // --- SECTIE: VERBONDEN (CONNECTED) ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: dropdownRoot.connectedDevices.length > 0

                        Text {
                            text: "VERBONDEN"
                            color: dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            opacity: 0.6
                            Layout.leftMargin: 4
                        }

                        Repeater {
                            model: dropdownRoot.connectedDevices
                            delegate: DeviceRow {
                                deviceData: modelData
                            }
                        }
                    }

                    // Tussenscheidingslijn tussen Verbonden en Beschikbaar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Color.white
                        opacity: 0.17
                        visible: dropdownRoot.connectedDevices.length > 0 && dropdownRoot.availableDevices.length > 0
                        Layout.topMargin: 2
                        Layout.bottomMargin: 2
                    }

                    // --- SECTIE: BESCHIKBAAR (AVAILABLE) ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: dropdownRoot.availableDevices.length > 0

                        Text {
                            text: "BESCHIKBAAR"
                            color: dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            opacity: 0.6
                            Layout.leftMargin: 4
                        }

                        Repeater {
                            model: dropdownRoot.availableDevices
                            delegate: DeviceRow {
                                deviceData: modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
