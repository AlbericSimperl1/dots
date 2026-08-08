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
    readonly property color barBg: '#8d111117'
    readonly property color fg: '#fff7e5'
    readonly property color accent: '#ebd9b9'
    readonly property color inactivePill: "#a7323232"
    readonly property color borderCol: "#2cffffff"
    readonly property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
    readonly property color muted: Qt.rgba(1, 0.95, 0.82, 0.78)

    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"

    readonly property int barHeight: 20
    readonly property int barHeightL: 26
    readonly property int barHeightR: 26
    readonly property int collapsedHeight: 2

    readonly property int collapsedWidth: 130
    readonly property int expandedWidthL: 480
    readonly property int expandedWidthR: 440
    readonly property int musicExpandedHeight: 250
    readonly property int bluetoothExpandedHeight: 250
    readonly property int networkExpandedHeight: 250
    readonly property int cornerRadius: 15

    Variants {
        model: Quickshell.screens

        // ================= GESPLITSTE LINKER PANEL =================
        PanelWindow {
            id: leftPanel

            required property var modelData
            property bool leftHovered: false
            property bool leftHoveredDelayed: false
            property bool leftExpanded: leftHoveredDelayed

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            margins.left: -1
            margins.top: -1

            property int contentWidth: leftLayout.implicitWidth + 20
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

                PanelBackground {
                    id: leftBg
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: leftPanel.leftExpanded ? root.barHeightL : root.collapsedHeight
                    fillColor: leftPanel.leftExpanded ? root.barBg : root.inactivePill
                    roundCorner: "bottomRight"

                    Behavior on height {
                        NumberAnimation {
                            duration: 40
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
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Workspaces {}
                        Apps {}
                        Clock {}
                    }
                }
            }

            BackgroundEffect.blurRegion: Region {
                item: leftBg
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

        // ================= GESPLITSTE RECHTER PANEL =================
        PanelWindow {
            id: rightPanel

            focusable: true
            required property var modelData
            property bool rightHovered: false
            property bool rightHoveredDelayed: false
            property bool musicOpen: false
            property bool networkOpen: false
            property bool bluetoothOpen: false
            property bool rightExpanded: rightHoveredDelayed || musicOpen || networkOpen || bluetoothOpen

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"
            margins.right: -1
            margins.top: -1

            property int contentWidth: systemRow.implicitWidth + 20
            property int targetWidth: (musicOpen || networkOpen || bluetoothOpen) ? root.expandedWidthR : Math.min(root.expandedWidthR, Math.max(root.collapsedWidth, contentWidth))

            width: targetWidth
            height: {
                if (musicOpen)
                    return root.musicExpandedHeight;
                if (networkOpen)
                    return root.networkExpandedHeight;
                if (bluetoothOpen)
                    return root.bluetoothExpandedHeight;
                if (rightExpanded)
                    return root.barHeightR;
                return root.collapsedHeight;
            }
            exclusiveZone: 0

            anchors {
                top: true
                right: true
            }

            Timer {
                id: rightCloseTimer
                interval: 20
                onTriggered: rightPanel.rightHoveredDelayed = false
            }

            onRightHoveredChanged: {
                if (rightHovered) {
                    rightCloseTimer.stop();
                    rightHoveredDelayed = true;
                } else {
                    rightCloseTimer.start();
                }

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
                }
            }

            onNetworkOpenChanged: {
                network.open = networkOpen;
                if (networkOpen) {
                    networkCloseTimer.stop();
                    music.open = false;
                }
            }

            onBluetoothOpenChanged: {
                bluetooth.open = bluetoothOpen;
                if (bluetoothOpen) {
                    bluetoothCloseTimer.stop();
                    music.open = false;
                    network.open = false;
                }
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

                PanelBackground {
                    id: rightBg
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
                    roundCorner: "bottomLeft"
                    onWidthChanged: rightBlur.changed()
                    onHeightChanged: rightBlur.changed()

                    Behavior on height {
                        NumberAnimation {
                            duration: 40
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
                        anchors.leftMargin: 5
                        anchors.rightMargin: 0
                        spacing: 1

                        RowLayout {
                            id: systemRow
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.barHeight
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0

                            ModuleItem {
                                MusicModule {
                                    id: music
                                    screen: rightPanel.modelData
                                    fg: root.fg
                                    accent: root.accent
                                    muted: root.muted
                                    softFill: "transparent"
                                    borderCol: root.borderCol
                                    fontFamily: root.fontFamily
                                    onOpenChanged: {
                                        rightPanel.musicOpen = open;
                                        if (open) {
                                            network.open = false;
                                            bluetooth.open = false;
                                        }
                                    }
                                }
                            }

                            ModuleItem {
                                Network {
                                    id: network
                                    fg: root.fg
                                    accent: root.accent
                                    muted: root.muted
                                    softFill: "transparent"
                                    borderCol: root.borderCol
                                    fontFamily: root.fontFamily
                                    onOpenChanged: {
                                        rightPanel.networkOpen = open;
                                        if (open) {
                                            music.open = false;
                                            bluetooth.open = false;
                                        }
                                    }
                                }
                            }

                            ModuleItem {
                                Bluetooth {
                                    id: bluetooth
                                    fg: root.fg
                                    accent: root.accent
                                    muted: root.muted
                                    softFill: "transparent"
                                    borderCol: root.borderCol
                                    fontFamily: root.fontFamily
                                    onOpenChanged: {
                                        rightPanel.bluetoothOpen = open;
                                        if (open) {
                                            music.open = false;
                                            network.open = false;
                                        }
                                    }
                                }
                            }

                            ModuleItem {
                                HyprStream {}
                            }
                            ModuleItem {
                                Cpu {}
                            }
                            ModuleItem {
                                Power {}
                            }
                            ModuleItem {
                                Brightness {}
                            }
                            ModuleItem {
                                Battery {}
                            }
                            ModuleItem {
                                DateModule {}
                            }
                        }

                        // ---- Dropdowns ----
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

                        BluetoothDropdown {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: rightPanel.bluetoothOpen
                            bluetooth: bluetooth
                            fg: root.fg
                            accent: root.accent
                            muted: root.muted
                            softFill: root.softFill
                            borderCol: root.borderCol
                            fontFamily: root.fontFamily
                        }

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
                    }
                }
            }

            BackgroundEffect.blurRegion: Region {
                id: rightBlur
                item: rightBg
            }

            Behavior on width {
                NumberAnimation {
                    duration: 10
                    easing.type: Easing.Linear
                }
            }
        }
    }

    // ---- HERBRUIKBARE HOVER PILL COMPONENT ----
    component HoverPill: Rectangle {
        id: buttonBg
        default property alias content: container.children

        Layout.fillHeight: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitWidth: container.implicitWidth + 5

        radius: 1
        color: hoverHandler.hovered ? Qt.rgba(1, 0, 0, 0.85) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
        }

        RowLayout {
            id: container
            anchors.centerIn: parent
            spacing: 0
        }
    }

    // ---- HERBRUIKBARE PANEL BACKGROUND COMPONENT ----
    component PanelBackground: Shape {
        id: bg
        property color fillColor: root.barBg
        property color strokeColor: root.borderCol
        property real radius: root.cornerRadius
        property string roundCorner: "bottomRight" // "bottomRight" of "bottomLeft"

        readonly property real r: Math.min(bg.radius, bg.height)
        antialiasing: true
        layer.enabled: true
        layer.samples: 12
        anchors.fill: parent
        asynchronous: true
        containsMode: Shape.FillContains

        ShapePath {
            fillColor: '#33030510'
            strokeColor: '#55edf0f3'
            strokeWidth: 1

            startX: 0
            startY: 0

            PathLine {
                x: bg.width
                y: 0
            }

            PathLine {
                x: bg.width
                y: bg.roundCorner === "bottomRight" ? bg.height - bg.r : bg.height
            }

            PathArc {
                x: bg.roundCorner === "bottomRight" ? bg.width - bg.r : bg.width
                y: bg.height
                radiusX: bg.roundCorner === "bottomRight" ? bg.r : 0
                radiusY: bg.roundCorner === "bottomRight" ? bg.r : 0
                direction: PathArc.Clockwise
            }

            PathLine {
                x: bg.roundCorner === "bottomLeft" ? bg.r : 0
                y: bg.height
            }

            PathArc {
                x: 0
                y: bg.roundCorner === "bottomLeft" ? bg.height - bg.r : bg.height
                radiusX: bg.roundCorner === "bottomLeft" ? bg.r : 0
                radiusY: bg.roundCorner === "bottomLeft" ? bg.r : 0
                direction: PathArc.Clockwise
            }

            PathLine {
                x: 0
                y: 0
            }
        }
    }
}
