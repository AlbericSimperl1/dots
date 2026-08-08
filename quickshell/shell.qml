//@ pragma IconTheme MacTahoe-dark
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls
import QtQuick.Shapes 1.15
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import "./modules"

ShellRoot {
    id: root

    // ---- Kleuren & afmetingen ----
    readonly property color barBg: '#ee111117'
    readonly property color fg: '#fff7e5'
    readonly property color accent: '#ebd9b9'
    readonly property color inactivePill: "#44ffffff"
    readonly property color borderCol: "#2cffffff"
    readonly property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
    readonly property color muted: Qt.rgba(1, 0.95, 0.82, 0.78)

    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"
    readonly property int sidebarWidth: 38
    readonly property int marginSize: 2
    readonly property int cornerRadius: 8

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: sidebarPanel

            required property var modelData

            property bool musicOpen: false
            property bool networkOpen: false
            property bool bluetoothOpen: false
            property bool popupOpen: musicOpen || networkOpen || bluetoothOpen

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            color: "transparent"

            // Marges van de PanelWindow voor het floating effect
            margins.top: root.marginSize
            margins.bottom: root.marginSize
            margins.left: root.marginSize

            width: root.sidebarWidth + (popupOpen ? 310 : 0)

            // Exclusieve zone telt de marge op zodat vensters in Hyprland netjes aansluiten met een 2px gap
            exclusiveZone: root.sidebarWidth + (root.marginSize * 2)

            anchors {
                top: true
                bottom: true
                left: true
            }

            // ---- SLANKE FLOATING SIDEBAR ----
            Rectangle {
                id: sidebarBg
                width: root.sidebarWidth
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                color: root.barBg
                border.color: root.borderCol
                border.width: 1
                radius: root.cornerRadius

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 16
                    anchors.bottomMargin: 16
                    spacing: 0

                    // ---- BOVEN: Verticaal Caelestia Workspace Indicators ----
                    ColumnLayout {
                        id: workspaceContainer
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        spacing: 8

                        // ---- BOVEN: Workspaces ----
                        WorkspacesV {
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    // ---- MIDDEN: Verticale Klok (H / H / M / M) ----
                    ColumnLayout {
                        id: clockLayout
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 0

                        // "HHmm" geeft een string van 4 cijfers (bijv. "2113")
                        property string timeStr: Qt.formatDateTime(clockTimer.currentDate, "HHmm")

                        Repeater {
                            model: 4

                            Text {
                                text: clockLayout.timeStr.charAt(index)
                                color: index < 2 ? root.fg : root.muted
                                font.family: root.fontFamily
                                font.pixelSize: 18
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter

                                Layout.bottomMargin: index === 1 ? 8 : 0
                            }
                        }

                        Timer {
                            id: clockTimer
                            property date currentDate: new Date()
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: currentDate = new Date()
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    // ---- ONDER: Tray & Systeem Iconen ----
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                        Layout.fillWidth: true
                        spacing: 12

                        // HyprStream {
                        //     Layout.alignment: Qt.AlignHCenter
                        // }

                        MusicModule {
                            id: music
                            Layout.alignment: Qt.AlignHCenter
                            screen: sidebarPanel.modelData
                            fg: root.fg
                            accent: root.accent
                            muted: root.muted
                            softFill: "transparent"
                            borderCol: root.borderCol
                            fontFamily: root.fontFamily
                            onOpenChanged: {
                                sidebarPanel.musicOpen = open;
                                if (open) {
                                    network.open = false;
                                    bluetooth.open = false;
                                }
                            }
                        }

                        Network {
                            id: network
                            Layout.alignment: Qt.AlignHCenter
                            fg: root.fg
                            accent: root.accent
                            muted: root.muted
                            softFill: root.softFill
                            borderCol: root.borderCol
                            fontFamily: root.fontFamily
                            onOpenChanged: {
                                sidebarPanel.networkOpen = open;
                                if (open) {
                                    music.open = false;
                                    bluetooth.open = false;
                                }
                            }
                        }

                        Bluetooth {
                            id: bluetooth
                            Layout.alignment: Qt.AlignHCenter
                            fg: root.fg
                            accent: root.accent
                            muted: root.muted
                            softFill: root.softFill
                            borderCol: root.borderCol
                            fontFamily: root.fontFamily
                            onOpenChanged: {
                                sidebarPanel.bluetoothOpen = open;
                                if (open) {
                                    music.open = false;
                                    network.open = false;
                                }
                            }
                        }

                        // Cpu {
                        //     Layout.alignment: Qt.AlignHCenter
                        // }
                        Brightness {
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Battery {
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Power {
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            // ---- POPUP FLYOUTS ----
            Rectangle {
                id: popupMenu
                visible: sidebarPanel.popupOpen
                anchors.left: sidebarBg.right
                anchors.leftMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0
                width: 290
                height: 250
                color: root.barBg
                border.color: root.borderCol
                border.width: 1
                radius: root.cornerRadius

                MusicDropdown {
                    anchors.fill: parent
                    anchors.margins: 8
                    visible: sidebarPanel.musicOpen
                    music: music
                    fg: root.fg
                    accent: root.accent
                    muted: root.muted
                    softFill: root.softFill
                    borderCol: root.borderCol
                    fontFamily: root.fontFamily
                }

                NetworkDropdown {
                    anchors.fill: parent
                    anchors.margins: 8
                    visible: sidebarPanel.networkOpen
                    network: network
                    fg: root.fg
                    accent: root.accent
                    muted: root.muted
                    softFill: root.softFill
                    borderCol: root.borderCol
                    fontFamily: root.fontFamily
                }

                BluetoothDropdown {
                    anchors.fill: parent
                    anchors.margins: 8
                    visible: sidebarPanel.bluetoothOpen
                    bluetooth: bluetooth
                    fg: root.fg
                    accent: root.accent
                    muted: root.muted
                    softFill: root.softFill
                    borderCol: root.borderCol
                    fontFamily: root.fontFamily
                }
            }

            BackgroundEffect.blurRegion: Region {
                item: sidebarBg
            }
        }
    }
}
