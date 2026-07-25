import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
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
    readonly property color barBg: '#6b575757'
    readonly property color fg: '#fff7e5'
    readonly property color accent: '#ebd9b9'
    readonly property color inactivePill: "#a7323232"
    readonly property color borderCol: "#eb2e2e3d"
    readonly property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
    readonly property color muted: Qt.rgba(1, 0.95, 0.82, 0.78)

    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"

    readonly property int barHeight: 30
    readonly property int barHeightL: 24
    readonly property int barHeightR: 26
    readonly property int dockHeight: 70
    readonly property int collapsedHeight: 4

    readonly property int collapsedWidth: 130
    readonly property int expandedWidthL: 480
    readonly property int expandedWidthR: 445
    readonly property int musicExpandedHeight: 250
    readonly property int networkExpandedHeight: 200
    readonly property int bluetoothExpandedHeight: 200
    readonly property int notchDepth: 5
    readonly property int cornerRadius: 11

    Variants {
        model: Quickshell.screens

        // ================= GESPLITSTE LINKER NOTCH =================
        PanelWindow {
            id: leftPanel

            required property var modelData
            property bool leftHovered: false
            property bool leftHoveredDelayed: false
            property bool leftExpanded: leftHoveredDelayed

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            margins.left: 10

            property int contentWidth: leftLayout.implicitWidth + root.notchDepth * 2 + 20
            property int targetWidth: Math.min(root.expandedWidthL, Math.max(root.collapsedWidth, contentWidth))

            width: targetWidth
            height: leftExpanded ? root.barHeightL : root.collapsedHeight
            exclusiveZone: 0

            anchors {
                top: true
                left: true
            }

            Timer {
                id: leftCloseTimer
                interval: 20
                onTriggered: leftPanel.leftHoveredDelayed = false
            }

            onLeftHoveredChanged: {
                if (leftHovered) {
                    leftCloseTimer.stop();
                    leftHoveredDelayed = true;
                } else {
                    leftCloseTimer.start();
                }
            }

            Item {
                anchors.fill: parent

                HoverHandler {
                    id: leftHover
                    onHoveredChanged: leftPanel.leftHovered = hovered
                }

                NotchBackground {
                    id: leftNotchBg
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: leftPanel.leftExpanded ? root.barHeightL : root.collapsedHeight
                    fillColor: leftPanel.leftExpanded ? root.barBg : root.inactivePill

                    Behavior on height {
                        NumberAnimation {
                            duration: 2
                            easing.type: Easing.Linear
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: root.barHeightL
                    opacity: leftPanel.leftExpanded ? 1 : 0
                    enabled: leftPanel.leftExpanded

                    RowLayout {
                        id: leftLayout
                        anchors.left: parent.left
                        anchors.leftMargin: root.notchDepth + 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Workspaces {}
                        Apps {}
                    }
                }
            }

            BackgroundEffect.blurRegion: Region {
                item: leftNotchBg
            }

            Behavior on width {
                NumberAnimation {
                    duration: 10
                    easing.type: Easing.Linear
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        // ================= GESPLITSTE RECHTER NOTCH =================
        PanelWindow {
            id: rightPanel
            focusable: true
            required property var modelData
            property bool rightHovered: false
            property bool musicOpen: false
            property bool networkOpen: false
            property bool bluetoothOpen: false
            property bool rightExpanded: rightHovered || musicOpen || networkOpen || bluetoothOpen

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            margins.right: 20
            width: root.expandedWidthR
            height: {
                if (musicOpen)
                    return root.musicExpandedHeight;
                if (networkOpen)
                    return root.networkExpandedHeight;
                if (bluetoothOpen)
                    return root.bluetoothExpandedHeight;
                if (rightExpanded)
                    return root.barHeightR;
                return 12;
            }
            exclusiveZone: 0
            onRightHoveredChanged: {
                if (!rightHovered && musicOpen)
                    musicCloseTimer.start();
                else if (rightHovered)
                    musicCloseTimer.stop();

                if (!rightHovered && networkOpen)
                    networkCloseTimer.start();
                else if (rightHovered)
                    networkCloseTimer.stop();

                if (!rightHovered && bluetoothOpen)
                    bluetoothCloseTimer.start();
                else if (rightHovered)
                    bluetoothCloseTimer.stop();
            }
            onMusicOpenChanged: {
                music.open = musicOpen;
                if (musicOpen) {
                    musicCloseTimer.stop();
                    network.open = false;
                    bluetoothOpen = false;
                }
            }
            onNetworkOpenChanged: {
                network.open = networkOpen;
                if (networkOpen) {
                    networkCloseTimer.stop();
                    music.open = false;
                    bluetoothOpen = false;
                }
            }
            onBluetoothOpenChanged: {
                if (bluetooth)
                    bluetooth.open = bluetoothOpen;
                if (bluetoothOpen) {
                    bluetoothCloseTimer.stop();
                    music.open = false;
                    network.open = false;
                }
            }

            anchors {
                top: true
                right: true
            }

            Timer {
                id: musicCloseTimer
                interval: 30
                repeat: false
                onTriggered: {
                    if (!rightPanel.rightHovered && rightPanel.musicOpen)
                        rightPanel.musicOpen = false;
                }
            }

            Timer {
                id: networkCloseTimer
                interval: 30
                repeat: false
                onTriggered: {
                    if (!rightPanel.rightHovered && rightPanel.networkOpen)
                        rightPanel.networkOpen = false;
                }
            }

            Timer {
                id: bluetoothCloseTimer
                interval: 30
                repeat: false
                onTriggered: {
                    if (!rightPanel.rightHovered && rightPanel.bluetoothOpen)
                        rightPanel.bluetoothOpen = false;
                }
            }

            Item {
                anchors.fill: parent

                HoverHandler {
                    id: rightHover
                    onHoveredChanged: rightPanel.rightHovered = hovered
                }

                NotchBackground {
                    id: rightNotchBg
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: {
                        if (rightPanel.musicOpen)
                            return root.musicExpandedHeight;
                        if (rightPanel.networkOpen)
                            return root.networkExpandedHeight;
                        if (rightPanel.bluetoothOpen)
                            return root.bluetoothExpandedHeight;
                        if (rightPanel.rightExpanded)
                            return root.barHeightR;
                        return root.collapsedHeight;
                    }
                    fillColor: rightPanel.rightExpanded ? root.barBg : root.inactivePill

                    Behavior on height {
                        NumberAnimation {
                            duration: 1
                            easing.type: Easing.Linear
                        }
                    }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: rightPanel.height
                    opacity: rightPanel.rightExpanded ? 1 : 0
                    visible: opacity > 0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.top: parent.top
                        anchors.leftMargin: root.notchDepth + 17
                        anchors.rightMargin: root.notchDepth + 10
                        spacing: 1

                        RowLayout {
                            id: systemRow
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.barHeight
                            spacing: 15

                            MusicModule {
                                id: music
                                screen: rightPanel.modelData
                                fg: root.fg
                                accent: root.accent
                                muted: root.muted
                                softFill: root.softFill
                                borderCol: root.borderCol
                                fontFamily: root.fontFamily
                                onOpenChanged: {
                                    rightPanel.musicOpen = open;
                                }
                            }

                            // Network {
                            //     id: network
                            //     fg: root.fg
                            //     accent: root.accent
                            //     muted: root.muted
                            //     softFill: root.softFill
                            //     borderCol: root.borderCol
                            //     fontFamily: root.fontFamily
                            //     onOpenChanged: {
                            //         rightPanel.networkOpen = open;
                            //     }
                            // }

                            Network {
                                id: network
                                fg: root.fg
                                accent: root.accent
                                muted: root.muted
                                softFill: root.softFill
                                borderCol: root.borderCol
                                fontFamily: root.fontFamily
                                onOpenChanged: rightPanel.networkOpen = open
                            }

                            // Bluetooth {
                            //     id: bluetooth
                            //     onOpenChanged: {
                            //         rightPanel.bluetoothOpen = open;
                            //     }
                            // }

                            HyprStream {}
                            Cpu {}
                            Power {}
                            Brightness {}
                            Battery {}
                            DateModule {}
                        }

                        // ---- Muziekbediening Dropdown ----
                        MusicDropdown {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: rightPanel.musicOpen
                            music: music
                            fg: root.fg
                            accent: root.accent
                            muted: root.muted
                            softFill: root.softFill
                            borderCol: root.borderCol
                            fontFamily: root.fontFamily
                        }

                        // ---- Netwerkinformatie Dropdown ----
                        // NetworkDropdown {
                        //     Layout.fillWidth: true
                        //     Layout.fillHeight: true
                        //     visible: rightPanel.networkOpen
                        //     network: network
                        //     fg: root.fg
                        //     accent: root.accent
                        //     muted: root.muted
                        //     softFill: root.softFill
                        //     borderCol: root.borderCol
                        //     fontFamily: root.fontFamily
                        // }

                        NetworkDropdown {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: rightPanel.networkOpen
                            network: network
                            fg: root.fg
                            accent: root.accent
                            muted: root.muted
                            softFill: root.softFill
                            borderCol: root.borderCol
                            fontFamily: root.fontFamily
                        }
                        // ---- Bluetooth Dropdown ----
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: rightPanel.bluetoothOpen
                            opacity: rightPanel.bluetoothOpen ? 1 : 0

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                clip: true

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: root.notchDepth + 5
                                    anchors.rightMargin: root.notchDepth + 5
                                    anchors.topMargin: 4
                                    anchors.bottomMargin: 10
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "Bluetooth"
                                            color: root.fg
                                            font.family: root.fontFamily
                                            font.pixelSize: 13
                                            font.bold: true
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: bluetooth.state ? "" : ""
                                            color: bluetooth.state ? root.accent : root.muted
                                            font.family: root.fontFamily
                                            font.pixelSize: 20

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (bluetooth.state)
                                                        Quickshell.execDetached(["bluetoothctl", "power", "off"]);
                                                    else
                                                        Quickshell.execDetached(["bluetoothctl", "power", "on"]);
                                                }
                                            }
                                        }
                                    }

                                    ListView {
                                        id: btListView
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        model: bluetooth.devices || []
                                        clip: true
                                        spacing: 7

                                        ScrollBar.vertical: ScrollBar {
                                            policy: ScrollBar.AsNeeded
                                        }

                                        delegate: Rectangle {
                                            width: btListView.width
                                            height: 32
                                            radius: 6
                                            color: root.softFill

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 8

                                                Text {
                                                    text: modelData.connected ? "󰂱" : "󰂯"
                                                    color: modelData.connected ? root.accent : root.fg
                                                    font.family: root.fontFamily
                                                    font.pixelSize: 15
                                                }

                                                Text {
                                                    text: modelData.name || modelData.mac || "Onbekend apparaat"
                                                    color: root.fg
                                                    font.family: root.fontFamily
                                                    font.pixelSize: 13
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    text: modelData.connected ? "" : ""
                                                    color: root.accent
                                                    font.family: root.fontFamily
                                                    font.pixelSize: 13
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.connected)
                                                        Quickshell.execDetached(["bluetoothctl", "disconnect", modelData.mac]);
                                                    else
                                                        Quickshell.execDetached(["bluetoothctl", "connect", modelData.mac]);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            BackgroundEffect.blurRegion: Region {
                item: rightNotchBg
            }

            Behavior on width {
                NumberAnimation {
                    duration: 1
                    easing.type: Easing.Linear
                }
            }
        }
    }

    // ---- HERBRUIKBARE NOTCH COMPONENT ----
    component NotchBackground: Shape {
        id: shapeBg
        antialiasing: true

        property color fillColor: '#ff000000'
        readonly property real actualNd: Math.min(root.notchDepth, shapeBg.height * 0.5)
        readonly property real actualCr: Math.min(root.cornerRadius, shapeBg.height - actualNd)
        property bool expanded: rightHovered || musicOpen || networkOpen || bluetoothOpen || leftHovered

        layer.enabled: true
        layer.samples: 8

        ShapePath {
            fillColor: '#8d111117'
            strokeColor: '#2cffffff'
            strokeWidth: 2

            startX: shapeBg.width
            startY: 0

            PathQuad {
                x: shapeBg.width - shapeBg.actualNd
                y: shapeBg.actualNd
                controlX: shapeBg.width - shapeBg.actualNd
                controlY: 0
            }

            PathLine {
                x: shapeBg.width - shapeBg.actualNd
                y: shapeBg.height - shapeBg.actualCr
            }

            PathArc {
                x: shapeBg.width - shapeBg.actualNd - shapeBg.actualCr
                y: shapeBg.height
                radiusX: shapeBg.actualCr
                radiusY: shapeBg.actualCr
                useLargeArc: false
                direction: PathArc.Clockwise
            }

            PathLine {
                x: shapeBg.actualNd + shapeBg.actualCr
                y: shapeBg.height
            }

            PathArc {
                x: shapeBg.actualNd
                y: shapeBg.height - shapeBg.actualCr
                radiusX: shapeBg.actualCr
                radiusY: shapeBg.actualCr
                useLargeArc: false
                direction: PathArc.Clockwise
            }

            PathLine {
                x: shapeBg.actualNd
                y: shapeBg.actualNd
            }

            PathQuad {
                x: 0
                y: 0
                controlX: shapeBg.actualNd
                controlY: 0
            }
        }
    }
}
