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
    readonly property int collapsedHeight: 4

    readonly property int collapsedWidth: 130
    readonly property int expandedWidthL: 380
    readonly property int expandedWidthR: 430
    readonly property int musicExpandedHeight: 250
    readonly property int networkExpandedHeight: 220
    readonly property int bluetoothExpandedHeight: 220
    readonly property int notchDepth: 5
    readonly property int cornerRadius: 11

    // ================= GESPLITSTE LINKER NOTCH =================
    Variants {
        model: Quickshell.screens

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
                interval: 200
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
                            duration: 150
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
                        spacing: 6

                        Workspaces {}
                        ClockModule {}
                    }
                }
            }

            BackgroundEffect.blurRegion: Region {
                item: leftNotchBg
            }

            Behavior on width {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.Linear
                }
            }
        }
    }

    // ================= GESPLITSTE RECHTER NOTCH =================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: rightPanel

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
                if (!rightHovered) {
                    if (musicOpen)
                        musicCloseTimer.start();
                    if (networkOpen)
                        networkCloseTimer.start();
                    if (bluetoothOpen)
                        bluetoothCloseTimer.start();
                } else {
                    musicCloseTimer.stop();
                    networkCloseTimer.stop();
                    bluetoothCloseTimer.stop();
                }
            }

            onMusicOpenChanged: {
                music.open = musicOpen;
                if (musicOpen) {
                    networkOpen = false;
                    bluetoothOpen = false;
                }
            }
            onNetworkOpenChanged: {
                network.open = networkOpen;
                if (networkOpen) {
                    musicOpen = false;
                    bluetoothOpen = false;
                }
            }
            onBluetoothOpenChanged: {
                bluetooth.open = bluetoothOpen;
                if (bluetoothOpen) {
                    musicOpen = false;
                    networkOpen = false;
                }
            }

            anchors {
                top: true
                right: true
            }

            Timer {
                id: musicCloseTimer
                interval: 150
                onTriggered: rightPanel.musicOpen = false
            }
            Timer {
                id: networkCloseTimer
                interval: 150
                onTriggered: rightPanel.networkOpen = false
            }
            Timer {
                id: bluetoothCloseTimer
                interval: 150
                onTriggered: rightPanel.bluetoothOpen = false
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
                    height: parent.height
                    fillColor: rightPanel.rightExpanded ? root.barBg : root.inactivePill

                    Behavior on height {
                        NumberAnimation {
                            duration: 150
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
                        anchors.leftMargin: root.notchDepth + 12
                        anchors.rightMargin: root.notchDepth + 12
                        spacing: 2

                        // ---- HOOFDBANK SENSORS & CONTROLS ----
                        RowLayout {
                            id: systemRow
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.barHeightR
                            spacing: 12

                            MusicModule {
                                id: music
                                onOpenChanged: rightPanel.musicOpen = open
                            }

                            BluetoothModule {
                                id: bluetooth
                                onOpenChanged: rightPanel.bluetoothOpen = open
                            }

                            NetworkModule {
                                id: network
                                onOpenChanged: rightPanel.networkOpen = open
                            }

                            BrightnessModule {}
                            CpuModule {}
                            BatteryModule {}
                            PowerModule {}
                            DateModule {}
                        }

                        // ---- 1. MUZIEK DROPDOWN ----
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: rightPanel.musicOpen

                            RowLayout {
                                anchors.fill: parent
                                spacing: 14

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Text {
                                        Layout.fillWidth: true
                                        text: music.title || "Geen media"
                                        color: root.fg
                                        font.family: root.fontFamily
                                        font.pixelSize: 15
                                        font.bold: true
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: music.artist || "Onbekend"
                                        color: root.muted
                                        font.family: root.fontFamily
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 12

                                        MusicButton {
                                            glyph: "󰒮"
                                            onPressed: music.activePlayer.previous()
                                        }
                                        MusicButton {
                                            glyph: music.isPlaying ? "󰏤" : "󰐊"
                                            big: true
                                            onPressed: music.activePlayer.togglePlaying()
                                        }
                                        MusicButton {
                                            glyph: "󰒭"
                                            onPressed: music.activePlayer.next()
                                        }
                                    }
                                }
                            }
                        }

                        // ---- 2. NETWERK DROPDOWN ----
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: rightPanel.networkOpen

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Wi-Fi Netwerken"
                                        color: root.fg
                                        font.family: root.fontFamily
                                        font.bold: true
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "  "
                                        color: root.muted
                                        font.family: root.fontFamily
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: network.refreshNetworkData()
                                        }
                                    }
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    model: network.networks
                                    clip: true
                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 28
                                        radius: 4
                                        color: root.softFill
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            Text {
                                                text: modelData.ssid
                                                color: root.fg
                                                font.family: root.fontFamily
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: ""
                                                color: root.muted
                                                font.family: root.fontFamily
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: Quickshell.execDetached(["nmcli", "device", "wifi", "connect", modelData.ssid])
                                        }
                                    }
                                }
                            }
                        }

                        // ---- 3. BLUETOOTH DROPDOWN ----
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: rightPanel.bluetoothOpen

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Bluetooth Apparaten"
                                        color: root.fg
                                        font.family: root.fontFamily
                                        font.bold: true
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: bluetooth.powered ? "󰂯 Aan" : "󰂲 Uit"
                                        color: bluetooth.powered ? root.accent : root.muted
                                        font.family: root.fontFamily
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: bluetooth.toggleBluetooth()
                                        }
                                    }
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    model: bluetooth.devices
                                    clip: true
                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 30
                                        radius: 5
                                        color: root.softFill
                                        border.color: modelData.paired ? root.accent : "transparent"
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8

                                            Text {
                                                text: "󰂯"
                                                color: modelData.paired ? root.accent : root.muted
                                                font.family: root.fontFamily
                                            }
                                            Text {
                                                text: modelData.name || "Onbekend"
                                                color: root.fg
                                                font.family: root.fontFamily
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: modelData.paired ? "Koppeling" : "Verbinden"
                                                color: root.muted
                                                font.family: root.fontFamily
                                                font.pixelSize: 11
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: bluetooth.connectDevice(modelData.mac)
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
                    duration: 150
                    easing.type: Easing.Linear
                }
            }
        }
    }

    // ---- HERBRUIKBARE NOTCH VORM ----
    component NotchBackground: Shape {
        id: shapeBg
        antialiasing: true

        property color fillColor: '#ff000000'
        readonly property real actualNd: Math.min(root.notchDepth, shapeBg.height * 0.5)
        readonly property real actualCr: Math.min(root.cornerRadius, shapeBg.height - actualNd)

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

    // ---- HERBRUIKBARE KNOPSJABLOON ----
    component MusicButton: Rectangle {
        id: btn

        property string glyph: ""
        property bool big: false
        signal pressed

        Layout.preferredWidth: big ? 32 : 24
        Layout.preferredHeight: big ? 32 : 24
        radius: width / 2
        color: "#3b2e2e3d"
        border.color: root.borderCol
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: btn.big ? 14 : 11
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.pressed()
        }
    }
}
