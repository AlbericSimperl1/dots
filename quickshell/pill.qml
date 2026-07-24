// notches

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
    readonly property color barBg: '#6b000207'
    readonly property color fg: '#fff7e5'
    readonly property color accent: '#ebd9b9'
    readonly property color inactivePill: '#ff000000'
    readonly property color borderCol: "#eb1e1e2d"
    readonly property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
    readonly property color muted: Qt.rgba(1, 0.95, 0.82, 0.78)

    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"

    readonly property int barHeight: 30
    readonly property int barHeightL: 24
    readonly property int barHeightR: 26
    readonly property int dockHeight: 70
    readonly property int collapsedHeight: 3
    readonly property int floatGap: 6                  // Afstand waarmee het paneel zweeft bij expanded

    readonly property int collapsedWidth: 130
    readonly property int expandedWidthL: 370
    readonly property int expandedWidthR: 345
    readonly property int musicExpandedHeight: 250
    readonly property int networkExpandedHeight: 200
    readonly property int notchDepth: 10
    readonly property int cornerRadius: 8

    Variants {
        model: Quickshell.screens

        // ================= GESPLITSTE LINKER NOTCH =================
        PanelWindow {
            id: leftPanel

            required property var modelData
            property bool leftHovered: false
            property bool leftHoveredDelayed: false          // <-- vertraagde hover voor inklap
            property bool leftExpanded: leftHoveredDelayed   // <-- nu gekoppeld aan de vertraagde waarde

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            margins.left: 10

            // Stabiele breedte-bepaling (layout is altijd zichtbaar)
            property int contentWidth: leftLayout.implicitWidth + root.notchDepth * 2 + 20
            property int targetWidth: Math.min(root.expandedWidthL, Math.max(root.collapsedWidth, contentWidth))

            width: targetWidth
            height: leftExpanded ? (root.barHeightL + root.floatGap) : root.collapsedHeight
            exclusiveZone: 0

            anchors {
                top: true
                left: true
            }

            // Timer om inklappen even uit te stellen en zo oscillatie te voorkomen
            Timer {
                id: leftCloseTimer
                interval: 20   // 20 ms vertraging
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

                // Interne zwevende container op basis van topMargin
                Item {
                    anchors.fill: parent
                    anchors.topMargin: leftPanel.leftExpanded ? root.floatGap : 0

                    Behavior on anchors.topMargin {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutQuad
                        }
                    }

                    NotchBackground {
                        id: leftNotchBg
                        anchors.fill: parent
                        fillColor: leftPanel.leftExpanded ? root.barBg : root.inactivePill
                        strokeWidth: leftPanel.leftExpanded ? 2 : 0
                    }

                    // Inhoud – blijft altijd zichtbaar, maar werkt alleen als de bar open is
                    Item {
                        anchors.fill: parent
                        height: root.barHeightL
                        opacity: leftPanel.leftExpanded ? 1 : 0
                        enabled: leftPanel.leftExpanded

                        RowLayout {
                            id: leftLayout
                            anchors.left: parent.left
                            anchors.leftMargin: root.notchDepth + 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Workspaces {}
                            ClockModule {}
                        }
                    }
                }
            }

            BackgroundEffect.blurRegion: Region {
                item: leftNotchBg
            }

            Behavior on width {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        // ================= GESPLITSTE RECHTER NOTCH =================
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
                let baseH = root.collapsedHeight; // Vaste, makkelijk triggerbare hover-zone in rust
                if (musicOpen)
                    baseH = root.musicExpandedHeight;
                else if (networkOpen)
                    baseH = root.networkExpandedHeight;
                else if (bluetoothOpen)
                    baseH = 200;
                else if (rightExpanded)
                    baseH = root.barHeightR;

                return rightExpanded ? (baseH + root.floatGap) : baseH;
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

                // Interne zwevende container op basis van topMargin
                Item {
                    anchors.fill: parent
                    anchors.topMargin: rightPanel.rightExpanded ? root.floatGap : 0

                    Behavior on anchors.topMargin {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutQuad
                        }
                    }

                    NotchBackground {
                        id: rightNotchBg
                        anchors.fill: parent
                        fillColor: rightPanel.rightExpanded ? root.barBg : root.inactivePill
                        strokeWidth: rightPanel.rightExpanded ? 2 : 0
                    }

                    Item {
                        anchors.fill: parent
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
                                    onOpenChanged: {
                                        rightPanel.musicOpen = open;
                                    }
                                }

                                NetworkModuleNEW {
                                    id: network
                                    onOpenChanged: {
                                        rightPanel.networkOpen = open;
                                    }
                                }

                                CpuModule {}
                                PowerModule {}
                                BatteryModule {}
                                DateModule {}
                            }

                            // ---- Muziekbediening ----
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: rightPanel.musicOpen
                                opacity: rightPanel.musicOpen ? 1 : 0

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    clip: true

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 18

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            spacing: 6

                                            Canvas {
                                                id: cavaCanvas
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.minimumHeight: 36
                                                renderTarget: Canvas.Image
                                                renderStrategy: Canvas.Threaded
                                                onPaint: {
                                                    const ctx = getContext("2d");
                                                    ctx.clearRect(0, 0, width, height);
                                                    const vals = music.cavaBars || [];
                                                    const count = vals.length || 32;
                                                    const slot = width / count;
                                                    const mid = height / 2;
                                                    const maxH = height * 0.45;
                                                    ctx.fillStyle = root.accent;
                                                    for (let i = 0; i < count; i++) {
                                                        const value = vals.length ? vals[i] : 0;
                                                        const h = Math.max(2, value * maxH);
                                                        const barW = Math.max(2, Math.min(6, slot * 0.4));
                                                        const x = Math.round(i * slot + (slot - barW) / 2);
                                                        ctx.globalAlpha = 0.35 + value * 0.65;
                                                        ctx.fillRect(x, mid - h, barW, h * 2);
                                                    }
                                                    ctx.globalAlpha = 1;
                                                }
                                                onWidthChanged: requestPaint()
                                                onHeightChanged: requestPaint()
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: music.title
                                                    color: root.fg
                                                    font.family: root.fontFamily
                                                    font.pixelSize: 16
                                                    font.bold: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: music.artist
                                                    color: root.muted
                                                    font.family: root.fontFamily
                                                    font.pixelSize: 14
                                                    font.weight: Font.DemiBold
                                                    horizontalAlignment: Text.AlignHCenter
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignHCenter
                                                spacing: 12

                                                MusicButton {
                                                    glyph: "󰒮"
                                                    enabled: music.activePlayer && music.activePlayer.canGoPrevious
                                                    onPressed: music.activePlayer.previous()
                                                }

                                                MusicButton {
                                                    glyph: music.isPlaying ? "󰏤" : "󰐊"
                                                    enabled: music.hasPlayer
                                                    big: true
                                                    onPressed: music.activePlayer.togglePlaying()
                                                }

                                                MusicButton {
                                                    glyph: "󰒭"
                                                    enabled: music.activePlayer && music.activePlayer.canGoNext
                                                    onPressed: music.activePlayer.next()
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.bottomMargin: 15
                                                spacing: 2

                                                RowLayout {
                                                    Layout.fillWidth: true

                                                    Text {
                                                        text: music.fmtTime(music.trackPosition)
                                                        color: root.muted
                                                        font.family: root.fontFamily
                                                        font.pixelSize: 11
                                                    }

                                                    Item {
                                                        Layout.fillWidth: true
                                                    }

                                                    Text {
                                                        text: music.trackLength > 0 ? music.fmtTime(music.trackLength) : "--:--"
                                                        color: root.muted
                                                        font.family: root.fontFamily
                                                        font.pixelSize: 11
                                                    }
                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 4
                                                    radius: 2
                                                    color: root.softFill

                                                    Rectangle {
                                                        anchors.left: parent.left
                                                        anchors.top: parent.top
                                                        anchors.bottom: parent.bottom
                                                        width: Math.max(parent.height, parent.width * music.progressRatio)
                                                        radius: parent.radius
                                                        color: root.accent
                                                        opacity: music.canSeek ? 0.9 : 0.45
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        enabled: music.canSeek
                                                        cursorShape: Qt.PointingHandCursor
                                                        onPressed: music.seekToRatio(mouse.x / width)
                                                        onPositionChanged: {
                                                            if (pressed)
                                                                music.seekToRatio(mouse.x / width);
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: 1
                                            Layout.topMargin: 4
                                            Layout.bottomMargin: 4
                                            color: root.borderCol
                                            opacity: 0.3
                                        }

                                        ColumnLayout {
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: 24
                                            Layout.topMargin: 15
                                            Layout.bottomMargin: 12
                                            spacing: 4

                                            Text {
                                                id: volText
                                                Layout.alignment: Qt.AlignHCenter
                                                text: music.volumePct + "%"
                                                color: root.fg
                                                font.family: root.fontFamily
                                                font.pixelSize: 11
                                            }

                                            Rectangle {
                                                Layout.fillHeight: true
                                                Layout.preferredWidth: 4
                                                Layout.alignment: Qt.AlignHCenter
                                                radius: 2
                                                color: root.softFill

                                                Rectangle {
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom
                                                    height: parent.height * (music.volumePct / 100)
                                                    radius: parent.radius
                                                    color: root.accent
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.margins: -8
                                                    cursorShape: Qt.PointingHandCursor
                                                    hoverEnabled: true
                                                    onPressed: music.setVolume((1 - mouse.y / height) * 100)
                                                    onPositionChanged: {
                                                        if (pressed)
                                                            music.setVolume((1 - mouse.y / height) * 100);
                                                    }
                                                    onWheel: wheel => {
                                                        if (wheel.angleDelta.y > 0)
                                                            music.bumpVolume(5);
                                                        else
                                                            music.bumpVolume(-5);
                                                    }
                                                }
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: music.volumeMuted ? "󰝟" : "󰕾"
                                                color: music.volumeMuted ? root.muted : root.fg
                                                font.family: root.fontFamily
                                                font.pixelSize: 13

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: Quickshell.execDetached(["pamixer", "-t"])
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ---- Netwerkinformatie Dropdown ----
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: rightPanel.networkOpen
                                opacity: rightPanel.networkOpen ? 1 : 0

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
                                                text: "Wi-Fi"
                                                color: root.fg
                                                font.family: root.fontFamily
                                                font.pixelSize: 13
                                                font.bold: true
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: "  "
                                                color: root.muted
                                                font.family: root.fontFamily
                                                font.pixelSize: 15

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: network.refreshNetworkData()
                                                }
                                            }

                                            Text {
                                                text: network.state !== 0 ? "" : ""
                                                color: network.state !== 0 ? root.accent : root.muted
                                                font.family: root.fontFamily
                                                font.pixelSize: 20

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (network.state !== 0)
                                                            Quickshell.execDetached(["nmcli", "radio", "wifi", "off"]);
                                                        else
                                                            Quickshell.execDetached(["nmcli", "radio", "wifi", "on"]);
                                                        network.refreshNetworkData();
                                                    }
                                                }
                                            }
                                        }

                                        ListView {
                                            id: wifiListView
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            model: network.networks
                                            clip: true
                                            spacing: 7

                                            ScrollBar.vertical: ScrollBar {
                                                policy: ScrollBar.AsNeeded
                                            }

                                            delegate: Rectangle {
                                                width: wifiListView.width
                                                height: 32
                                                radius: 6
                                                color: root.softFill

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
                                                        color: root.fg
                                                        font.family: root.fontFamily
                                                        font.pixelSize: 15
                                                    }

                                                    Text {
                                                        text: modelData.ssid
                                                        color: root.fg
                                                        font.family: root.fontFamily
                                                        font.pixelSize: 15
                                                        Layout.fillWidth: true
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        text: {
                                                            if (network.connectionDetails.indexOf(modelData.ssid) !== -1 && network.state !== 0)
                                                                return "";
                                                            if (modelData.security && modelData.security !== "" && modelData.security !== "--")
                                                                return "";
                                                            return "";
                                                        }
                                                        color: root.muted
                                                        font.family: root.fontFamily
                                                        font.pixelSize: 15
                                                    }

                                                    Text {
                                                        text: ""
                                                        color: root.muted
                                                        font.family: root.fontFamily
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
                        }
                    }
                }
            }

            BackgroundEffect.blurRegion: Region {
                item: rightNotchBg
            }

            Behavior on width {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    // ---- HERBRUIKBARE NOTCH COMPONENT (GESLOTEN SQUIRCLE) ----
    component NotchBackground: Shape {
        id: shapeBg
        antialiasing: true

        property color fillColor: '#fd000208'
        property color strokeColor: '#2ceeeeef'
        property int strokeWidth: 2
        property real cornerRadius: root.cornerRadius

        layer.enabled: true
        layer.samples: 8

        // Offset voor de helft van de lijndikte zodat de stroke van 2px niet clipt aan de randen
        readonly property real sw: strokeWidth / 2
        readonly property real w: Math.max(0, width - strokeWidth)
        readonly property real h: Math.max(0, height - strokeWidth)

        // Squircle krommingsberekening (G2 continuïteit)
        readonly property real cr: Math.min(cornerRadius, Math.min(w, h) / 2)
        readonly property real cl: Math.min(cr * 1.45, Math.min(w, h) / 2)
        readonly property real cp: cl * 0.5523

        ShapePath {
            fillColor: shapeBg.fillColor
            strokeColor: shapeBg.strokeColor
            strokeWidth: shapeBg.strokeWidth

            startX: shapeBg.sw + shapeBg.cl
            startY: shapeBg.sw

            // Bovenrand
            PathLine {
                x: shapeBg.sw + shapeBg.w - shapeBg.cl
                y: shapeBg.sw
            }

            // Rechtsboven
            PathCubic {
                x: shapeBg.sw + shapeBg.w
                y: shapeBg.sw + shapeBg.cl
                control1X: shapeBg.sw + shapeBg.w - shapeBg.cl + shapeBg.cp
                control1Y: shapeBg.sw
                control2X: shapeBg.sw + shapeBg.w
                control2Y: shapeBg.sw + shapeBg.cl - shapeBg.cp
            }

            // Rechterwand
            PathLine {
                x: shapeBg.sw + shapeBg.w
                y: shapeBg.sw + shapeBg.h - shapeBg.cl
            }

            // Rechtsonder
            PathCubic {
                x: shapeBg.sw + shapeBg.w - shapeBg.cl
                y: shapeBg.sw + shapeBg.h
                control1X: shapeBg.sw + shapeBg.w
                control1Y: shapeBg.sw + shapeBg.h - shapeBg.cl + shapeBg.cp
                control2X: shapeBg.sw + shapeBg.w - shapeBg.cl + shapeBg.cp
                control2Y: shapeBg.sw + shapeBg.h
            }

            // Onderrand
            PathLine {
                x: shapeBg.sw + shapeBg.cl
                y: shapeBg.sw + shapeBg.h
            }

            // Linksonder
            PathCubic {
                x: shapeBg.sw
                y: shapeBg.sw + shapeBg.h - shapeBg.cl
                control1X: shapeBg.sw + shapeBg.cl - shapeBg.cp
                control1Y: shapeBg.sw + shapeBg.h
                control2X: shapeBg.sw
                control2Y: shapeBg.sw + shapeBg.h - shapeBg.cl + shapeBg.cp
            }

            // Linkerwand
            PathLine {
                x: shapeBg.sw
                y: shapeBg.sw + shapeBg.cl
            }

            // Linkerboven
            PathCubic {
                x: shapeBg.sw + shapeBg.cl
                y: shapeBg.sw
                control1X: shapeBg.sw
                control1Y: shapeBg.sw + shapeBg.cl - shapeBg.cp
                control2X: shapeBg.sw + shapeBg.cl - shapeBg.cp
                control2Y: shapeBg.sw
            }
        }
    }

    // ---- HERBRUIKBARE KNOPSJABLOON ----
    component MusicButton: Rectangle {
        id: btn

        property string glyph: ""
        property bool big: false

        signal pressed

        Layout.preferredWidth: big ? 30 : 22
        Layout.preferredHeight: big ? 30 : 22
        radius: width / 2
        color: enabled ? "#3b2e2e3d" : "#3b2e2e3d"
        border.color: enabled ? root.borderCol : "#3b2e2e3d"
        border.width: 1
        opacity: enabled ? 1 : 0.45

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: btn.big ? 14 : 11
        }

        MouseArea {
            anchors.fill: parent
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.pressed()
        }
    }
}
