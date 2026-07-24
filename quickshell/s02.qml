
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

ShellRoot {
    id: root

    // ---- Kleuren & afmetingen ----
    readonly property color barBg: '#6b575757'
    readonly property color fg: "#FFE8B3"
    readonly property color accent: "#EED09B"
    readonly property color inactivePill: "#a7323232"
    readonly property color borderCol: "#eb2e2e3d"
    readonly property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
    readonly property color muted: Qt.rgba(1, 0.91, 0.7, 0.78)

    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"

    readonly property int barHeight: 30
    readonly property int barHeightL: 24
    readonly property int barHeightR: 26
    readonly property int dockHeight: 70
    readonly property int collapsedHeight: 4

    readonly property int collapsedWidth: 130
    readonly property int expandedWidthL: 320
    readonly property int expandedWidthR: 365
    readonly property int dockWidth: 300
    readonly property int musicExpandedHeight: 250
    readonly property int networkExpandedHeight: 200
    readonly property int notchDepth: 10
    readonly property int cornerRadius: 7



    Variants {
        model: Quickshell.screens

        // ================= GESPLITSTE LINKER NOTCH =================
        PanelWindow {
            id: leftPanel

            required property var modelData
            property bool leftHovered: false
            property bool leftExpanded: leftHovered

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            margins.left: 20
            width: leftExpanded ? Math.min(root.expandedWidthL, Math.max(root.collapsedWidth, leftLayout.implicitWidth + (root.notchDepth * 2) + 20)) : root.collapsedWidth
            height: leftExpanded ? root.barHeightL : 12 // Vaste, makkelijk triggerbare hover-zone
            // Op 0 gezet zodat ook de top panelen windows niet naar beneden duwen
            exclusiveZone: 0

            anchors {
                top: true
                left: true
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
                            duration: 20
                            easing.type: Easing.InOutQuad
                        }

                    }

                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: root.barHeightL
                    opacity: leftPanel.leftExpanded ? 1 : 0
                    visible: opacity > 0

                    RowLayout {
                        id: leftLayout

                        anchors.left: parent.left
                        anchors.leftMargin: root.notchDepth + 10
                        anchors.right: parent.right
                        anchors.rightMargin: root.notchDepth + 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Workspaces {
                        }

                        ClockModule {
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 30
                        }

                    }

                }

            }

            BackgroundEffect.blurRegion: Region {
                item: leftNotchBg
            }

            Behavior on width {
                NumberAnimation {
                    duration: 17
                    easing.type: Easing.InOutQuad
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
            width: rightExpanded ? root.expandedWidthR : root.collapsedWidth
            height: {
                if (musicOpen)
                    return root.musicExpandedHeight;

                if (networkOpen)
                    return root.networkExpandedHeight;

                if (bluetoothOpen)
                    return 200;

                if (rightExpanded)
                    return root.barHeightR;

                return 12; // Vaste, makkelijk triggerbare hover-zone in rust
            }
            // Op 0 gezet zodat de status dropdowns en popups over vensters heen vallen
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

                interval: 300
                repeat: false
                onTriggered: {
                    if (!rightPanel.rightHovered && rightPanel.musicOpen)
                        rightPanel.musicOpen = false;

                }
            }

            Timer {
                id: networkCloseTimer

                interval: 300
                repeat: false
                onTriggered: {
                    if (!rightPanel.rightHovered && rightPanel.networkOpen)
                        rightPanel.networkOpen = false;

                }
            }

            Timer {
                id: bluetoothCloseTimer

                interval: 300
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
                            return 200;

                        if (rightPanel.rightExpanded)
                            return root.barHeightR;

                        return root.collapsedHeight;
                    }
                    fillColor: rightPanel.rightExpanded ? root.barBg : root.inactivePill

                    Behavior on height {
                        NumberAnimation {
                            duration: 10
                            easing.type: Easing.InOutQuad
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

                            CpuModule {
                            }

                            PowerModule {
                            }

                            BatteryModule {
                            }

                            DateModule {
                            }

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
                                                    font.pixelSize: 10
                                                }

                                                Item {
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: music.trackLength > 0 ? music.fmtTime(music.trackLength) : "--:--"
                                                    color: root.muted
                                                    font.family: root.fontFamily
                                                    font.pixelSize: 10
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
                                                onWheel: (wheel) => {
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

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 10
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

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 10
                                }

                            }

                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 10
                        }

                    }

                }

            }

            BackgroundEffect.blurRegion: Region {
                item: rightNotchBg
            }

            Behavior on width {
                NumberAnimation {
                    duration: 17
                    easing.type: Easing.InOutQuad
                }

            }

        }

    }

    // ---- HERBRUIKBARE NOTCH COMPONENT (ZONDER CONFLICTERENDE ANCHORS) ----
    // component NotchBackground: Shape {
    //     id: shapeBg

    //     property color fillColor: '#ff000000'
    //     readonly property real actualNd: Math.min(root.notchDepth, shapeBg.height * 0.5)
    //     readonly property real actualCr: Math.min(root.cornerRadius, shapeBg.height - actualNd)
    //     property bool expanded: rightHovered || musicOpen || networkOpen || bluetoothOpen || leftHovered

    //     layer.enabled: true
    //     layer.samples: 4

    //     ShapePath {
    //         // fillColor: expanded ?  shapeBg.fillColor: '#000000'
    //         fillColor: '#6d919191'
    //         strokeColor: expanded ?  '#5fffffff': '#000000'


    //         strokeWidth: expanded ? 1 : 5
    //         startX: 0
    //         startY: 0

    //         // Top edge van links naar rechts
    //         PathLine {
    //             x: shapeBg.width
    //             y: 0
    //         }

    //         // Rechter concave overgangshoek
    //         PathQuad {
    //             x: shapeBg.width - shapeBg.actualNd
    //             y: shapeBg.actualNd
    //             controlX: shapeBg.width - shapeBg.actualNd
    //             controlY: 0
    //         }

    //         // Rechter verticale wand
    //         PathLine {
    //             x: shapeBg.width - shapeBg.actualNd
    //             y: shapeBg.height - shapeBg.actualCr
    //         }

    //         // Rechtsonder convexe hoek
    //         PathArc {
    //             x: shapeBg.width - shapeBg.actualNd - shapeBg.actualCr
    //             y: shapeBg.height
    //             radiusX: shapeBg.actualCr
    //             radiusY: shapeBg.actualCr
    //             useLargeArc: false
    //             direction: PathArc.Clockwise
    //         }

    //         // Onderkant strak naar links
    //         PathLine {
    //             x: shapeBg.actualNd + shapeBg.actualCr
    //             y: shapeBg.height
    //         }

    //         // Linksonder convexe hoek
    //         PathArc {
    //             x: shapeBg.actualNd
    //             y: shapeBg.height - shapeBg.actualCr
    //             radiusX: shapeBg.actualCr
    //             radiusY: shapeBg.actualCr
    //             useLargeArc: false
    //             direction: PathArc.Clockwise
    //         }

    //         // Linker verticale wand omhoog
    //         PathLine {
    //             x: shapeBg.actualNd
    //             y: shapeBg.actualNd
    //         }

    //         // Linkerboven concave overgangshoek
    //         PathQuad {
    //             x: 0
    //             y: 0
    //             controlX: shapeBg.actualNd
    //             controlY: 0
    //         }

    //     }

    // }


     //! shell.qml — Complete MacBook Notches & Windhawk Dock (verbeterde versie)
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

ShellRoot {
    id: root

    // ============================================================
    //  CENTRALE CONSTANTEN – pas hier alles aan voor een andere look
    // ============================================================
    readonly property QtObject c: QtObject {
        // Kleuren
        readonly property color barBg: '#6b575757'
        readonly property color fg: "#FFE8B3"
        readonly property color accent: "#EED09B"
        readonly property color inactivePill: "#a7323232"
        readonly property color borderCol: "#eb2e2e3d"
        readonly property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
        readonly property color muted: Qt.rgba(1, 0.91, 0.7, 0.78)

        // Typografie
        readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"

        // Afmetingen bars
        readonly property int barHeightL: 24   // linker notch hoogte
        readonly property int barHeightR: 26   // rechter notch hoogte (compact)
        readonly property int dockHeight: 70   // nog niet gebruikt

        // Notch basisafmetingen
        readonly property int collapsedHeight: 4      // hoogte in ingeklapte toestand (triggerzone)
        readonly property int collapsedWidth: 130
        readonly property int expandedWidthL: 320
        readonly property int expandedWidthR: 365
        readonly property int notchDepth: 10
        readonly property int cornerRadius: 7

        // Dropdowns
        readonly property int musicExpandedHeight: 250
        readonly property int networkExpandedHeight: 200
        // eventueel bluetooth height: 200 (wordt hier niet gebruikt)

        // Animatiesnelheden (in ms) – pas aan naar smaak
        readonly property int widthAnimDuration: 170
        readonly property int heightAnimDuration: 200
        readonly property int fadeAnimDuration: 100
    }

    // ============================================================
    //  HERBRUIKBARE COMPONENTEN
    // ============================================================

    // --- Notch-achtergrond met concave hoeken ---
    component NotchBackground: Shape {
        id: shapeBg

        // Eigenschappen die je van buitenaf instelt
        property color fillColor: '#000000'
        property int notchDepth: 10
        property int cornerRadius: 7
        property bool expanded: false

        // Afgeleide waarden die de vorm bepalen
        readonly property real actualNd: Math.min(notchDepth, shapeBg.height * 0.5)
        readonly property real actualCr: Math.min(cornerRadius, shapeBg.height - actualNd)

        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor: shapeBg.fillColor
            strokeColor: shapeBg.expanded ? '#5fffffff' : '#00000000'
            strokeWidth: shapeBg.expanded ? 1 : 5
            startX: 0; startY: 0

            // Bovenrand
            PathLine { x: shapeBg.width; y: 0 }

            // Rechter concave inkeping
            PathQuad {
                x: shapeBg.width - shapeBg.actualNd
                y: shapeBg.actualNd
                controlX: shapeBg.width - shapeBg.actualNd
                controlY: 0
            }

            // Rechter verticale lijn
            PathLine {
                x: shapeBg.width - shapeBg.actualNd
                y: shapeBg.height - shapeBg.actualCr
            }

            // Rechteronder hoek (convex)
            PathArc {
                x: shapeBg.width - shapeBg.actualNd - shapeBg.actualCr
                y: shapeBg.height
                radiusX: shapeBg.actualCr; radiusY: shapeBg.actualCr
                useLargeArc: false
                direction: PathArc.Clockwise
            }

            // Onderrand
            PathLine {
                x: shapeBg.actualNd + shapeBg.actualCr
                y: shapeBg.height
            }

            // Linkeronder hoek (convex)
            PathArc {
                x: shapeBg.actualNd
                y: shapeBg.height - shapeBg.actualCr
                radiusX: shapeBg.actualCr; radiusY: shapeBg.actualCr
                useLargeArc: false
                direction: PathArc.Clockwise
            }

            // Linker verticale lijn
            PathLine {
                x: shapeBg.actualNd
                y: shapeBg.actualNd
            }

            // Linker concave inkeping
            PathQuad {
                x: 0; y: 0
                controlX: shapeBg.actualNd
                controlY: 0
            }
        }
    }

    // --- Verticale slider (voor volume) ---
    component VerticalSlider: Item {
        id: sliderRoot
        property real value: 0.0      // 0.0 – 1.0
        property real sliderHeight: parent.height
        property color fillColor: root.c.accent
        property color bgColor: root.c.softFill
        property real knobSize: 6

        implicitWidth: 4
        implicitHeight: sliderHeight

        Rectangle {
            anchors.fill: parent
            radius: width/2
            color: sliderRoot.bgColor
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * sliderRoot.value
            radius: parent.width/2
            color: sliderRoot.fillColor
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPressed: sliderRoot.value = 1 - mouse.y / height
            onPositionChanged: if (pressed) sliderRoot.value = 1 - mouse.y / height
            onWheel: (wheel) => {
                let step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                sliderRoot.value = Math.max(0, Math.min(1, sliderRoot.value + step));
            }
        }
    }

    // --- Muziekknop ---
    component MusicButton: Rectangle {
        id: btn
        property string glyph: ""
        property bool big: false
        signal pressed()

        Layout.preferredWidth: big ? 30 : 22
        Layout.preferredHeight: big ? 30 : 22
        radius: width / 2
        color: enabled ? "#3b2e2e3d" : "#3b2e2e3d"
        border.color: enabled ? root.c.borderCol : "#3b2e2e3d"
        border.width: 1
        opacity: enabled ? 1 : 0.45

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: root.c.fg
            font.family: root.c.fontFamily
            font.pixelSize: btn.big ? 14 : 11
        }

        MouseArea {
            anchors.fill: parent
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.pressed()
        }
    }

    // --- Auto-close timer (sluit popup na vertrek muis) ---
    component AutoCloseTimer: Timer {
        id: timer
        property bool hovered: false   // bind aan paneel.hovered
        property bool open: false      // bind aan de open-state van de popup
        interval: 300
        repeat: false

        // Start alleen als muis weg is en popup open staat
        function check() {
            if (!hovered && open) start();
            else stop();
        }

        onHoveredChanged: check()
        onOpenChanged: check()
        onTriggered: open = false
    }

    // ============================================================
    //  LINKER NOTCH PANEEL
    // ============================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: leftPanel

            required property var modelData
            property bool leftHovered: false
            property bool leftExpanded: leftHovered   // eenvoudig: open bij hover

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            margins.left: 20
            exclusiveZone: 0

            anchors { top: true; left: true }

            // Breedte past zich aan aan de content, maar blijft binnen limieten
            width: leftExpanded
                   ? Math.min(root.c.expandedWidthL,
                              Math.max(root.c.collapsedWidth,
                                       leftLayout.implicitWidth + root.c.notchDepth * 2 + 20))
                   : root.c.collapsedWidth
            height: leftExpanded ? root.c.barHeightL : 12   // 12px triggerzone in rust

            Item {
                anchors.fill: parent
                HoverHandler { id: leftHover; onHoveredChanged: leftPanel.leftHovered = hovered }

                // Achtergrond met notchevorm
                NotchBackground {
                    id: leftNotchBg
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: leftPanel.leftExpanded ? root.c.barHeightL : root.c.collapsedHeight
                    fillColor: leftPanel.leftExpanded ? root.c.barBg : root.c.inactivePill
                    expanded: leftPanel.leftExpanded
                    notchDepth: root.c.notchDepth
                    cornerRadius: root.c.cornerRadius

                    Behavior on height {
                        NumberAnimation { duration: root.c.heightAnimDuration; easing.type: Easing.InOutQuad }
                    }
                }

                // Content: alleen zichtbaar wanneer uitgeklapt
                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: root.c.barHeightL
                    opacity: leftPanel.leftExpanded ? 1 : 0
                    visible: opacity > 0

                    RowLayout {
                        id: leftLayout
                        anchors.left: parent.left
                        anchors.leftMargin: root.c.notchDepth + 10
                        anchors.right: parent.right
                        anchors.rightMargin: root.c.notchDepth + 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Workspaces { }   // jij moet deze modules in aparte bestanden hebben
                        ClockModule { }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: root.c.fadeAnimDuration }
                    }
                }
            }

            BackgroundEffect.blurRegion: Region { item: leftNotchBg }

            Behavior on width {
                NumberAnimation { duration: root.c.widthAnimDuration; easing.type: Easing.InOutQuad }
            }
        }
    }

    // ============================================================
    //  RECHTER NOTCH PANEEL
    // ============================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: rightPanel

            required property var modelData
            property bool rightHovered: false
            property bool musicOpen: false
            property bool networkOpen: false
            // property bool bluetoothOpen: false   // later te activeren
            property bool rightExpanded: rightHovered || musicOpen || networkOpen // || bluetoothOpen

            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            margins.right: 20
            exclusiveZone: 0

            anchors { top: true; right: true }

            // Breedte en hoogte wisselen per toestand
            width: rightExpanded ? root.c.expandedWidthR : root.c.collapsedWidth
            height: {
                if (musicOpen) return root.c.musicExpandedHeight;
                if (networkOpen) return root.c.networkExpandedHeight;
                // if (bluetoothOpen) return 200;
                if (rightExpanded) return root.c.barHeightR;
                return 12;   // triggerzone
            }

            // Auto-close timers (sluiten popups na verlaten paneel)
            AutoCloseTimer {
                id: musicCloseTimer
                hovered: rightPanel.rightHovered
                open: rightPanel.musicOpen
            }
            AutoCloseTimer {
                id: networkCloseTimer
                hovered: rightPanel.rightHovered
                open: rightPanel.networkOpen
            }
            // AutoCloseTimer { id: bluetoothCloseTimer; ... }   // later

            // Zorg dat open states consistent blijven (maar één popup tegelijk)
            onMusicOpenChanged: {
                music.open = musicOpen;
                if (musicOpen) {
                    networkOpen = false;
                    // bluetoothOpen = false;
                }
            }
            onNetworkOpenChanged: {
                network.open = networkOpen;
                if (networkOpen) {
                    musicOpen = false;
                    // bluetoothOpen = false;
                }
            }
            // onBluetoothOpenChanged: { ... }   // later

            Item {
                anchors.fill: parent
                HoverHandler { id: rightHover; onHoveredChanged: rightPanel.rightHovered = hovered }

                // Notch achtergrond
                NotchBackground {
                    id: rightNotchBg
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: {
                        if (rightPanel.musicOpen) return root.c.musicExpandedHeight;
                        if (rightPanel.networkOpen) return root.c.networkExpandedHeight;
                        // if (bluetoothOpen) return 200;
                        if (rightPanel.rightExpanded) return root.c.barHeightR;
                        return root.c.collapsedHeight;
                    }
                    fillColor: rightPanel.rightExpanded ? root.c.barBg : root.c.inactivePill
                    expanded: rightPanel.rightExpanded
                    notchDepth: root.c.notchDepth
                    cornerRadius: root.c.cornerRadius

                    Behavior on height {
                        NumberAnimation { duration: root.c.heightAnimDuration; easing.type: Easing.InOutQuad }
                    }
                }

                // Content container
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
                        anchors.leftMargin: root.c.notchDepth + 17
                        anchors.rightMargin: root.c.notchDepth + 10
                        spacing: 1

                        // ----- Systeembalk (altijd zichtbaar in uitgeklapte staat) -----
                        RowLayout {
                            id: systemRow
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.c.barHeightR
                            spacing: 15

                            MusicModule {
                                id: music
                                screen: rightPanel.modelData
                                onOpenChanged: rightPanel.musicOpen = open
                            }

                            NetworkModuleNEW {
                                id: network
                                onOpenChanged: rightPanel.networkOpen = open
                            }

                            CpuModule { }
                            PowerModule { }
                            BatteryModule { }
                            DateModule { }
                        }

                        // ================= MUSIC DROPDOWN =================
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

                                    // Linkerhelft: canvas, titel, knoppen, progress
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 6

                                        // CAVA visualisatie – je kunt de refresh frequentie later aanpassen
                                        Canvas {
                                            id: cavaCanvas
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.minimumHeight: 36
                                            renderTarget: Canvas.Image
                                            renderStrategy: Canvas.Threaded
                                            onPaint: {
                                                var ctx = getContext("2d");
                                                ctx.clearRect(0, 0, width, height);
                                                var vals = music.cavaBars || [];
                                                var count = vals.length || 32;
                                                var slot = width / count;
                                                var mid = height / 2;
                                                var maxH = height * 0.45;
                                                ctx.fillStyle = root.c.accent;
                                                for (var i = 0; i < count; i++) {
                                                    var value = vals.length ? vals[i] : 0;
                                                    var h = Math.max(2, value * maxH);
                                                    var barW = Math.max(2, Math.min(6, slot * 0.4));
                                                    var x = Math.round(i * slot + (slot - barW) / 2);
                                                    ctx.globalAlpha = 0.35 + value * 0.65;
                                                    ctx.fillRect(x, mid - h, barW, h * 2);
                                                }
                                                ctx.globalAlpha = 1;
                                            }
                                            onWidthChanged: requestPaint()
                                            onHeightChanged: requestPaint()
                                        }

                                        // Titel & artiest
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                Layout.fillWidth: true
                                                text: music.title
                                                color: root.c.fg
                                                font.family: root.c.fontFamily
                                                font.pixelSize: 16
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: music.artist
                                                color: root.c.muted
                                                font.family: root.c.fontFamily
                                                font.pixelSize: 14
                                                font.weight: Font.DemiBold
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                            }
                                        }

                                        // Afspeelknoppen
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

                                        // Voortgangsbalk (horizontaal)
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.bottomMargin: 15
                                            spacing: 2

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text {
                                                    text: music.fmtTime(music.trackPosition)
                                                    color: root.c.muted
                                                    font.family: root.c.fontFamily
                                                    font.pixelSize: 10
                                                }
                                                Item { Layout.fillWidth: true }
                                                Text {
                                                    text: music.trackLength > 0 ? music.fmtTime(music.trackLength) : "--:--"
                                                    color: root.c.muted
                                                    font.family: root.c.fontFamily
                                                    font.pixelSize: 10
                                                }
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 4
                                                radius: 2
                                                color: root.c.softFill

                                                Rectangle {
                                                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                                    width: Math.max(parent.height, parent.width * music.progressRatio)
                                                    radius: parent.radius
                                                    color: root.c.accent
                                                    opacity: music.canSeek ? 0.9 : 0.45
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    enabled: music.canSeek
                                                    cursorShape: Qt.PointingHandCursor
                                                    onPressed: music.seekToRatio(mouse.x / width)
                                                    onPositionChanged: if (pressed) music.seekToRatio(mouse.x / width)
                                                }
                                            }
                                        }
                                    }

                                    // Scheidingslijn
                                    Rectangle {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: 1
                                        Layout.topMargin: 4; Layout.bottomMargin: 4
                                        color: root.c.borderCol
                                        opacity: 0.3
                                    }

                                    // Rechterkolom: volumeregeling
                                    ColumnLayout {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: 24
                                        Layout.topMargin: 15; Layout.bottomMargin: 12
                                        spacing: 4

                                        Text {
                                            id: volText
                                            Layout.alignment: Qt.AlignHCenter
                                            text: music.volumePct + "%"
                                            color: root.c.fg
                                            font.family: root.c.fontFamily
                                            font.pixelSize: 11
                                        }

                                        VerticalSlider {
                                            id: volumeSlider
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: 4
                                            Layout.alignment: Qt.AlignHCenter
                                            value: music.volumePct / 100
                                            onValueChanged: music.setVolume(value * 100)
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: music.volumeMuted ? "󰝟" : "󰕾"
                                            color: music.volumeMuted ? root.c.muted : root.c.fg
                                            font.family: root.c.fontFamily
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

                            Behavior on opacity { NumberAnimation { duration: root.c.fadeAnimDuration } }
                        }

                        // ================= NETWORK DROPDOWN =================
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
                                    anchors.leftMargin: root.c.notchDepth + 5
                                    anchors.rightMargin: root.c.notchDepth + 5
                                    anchors.topMargin: 4
                                    anchors.bottomMargin: 10
                                    spacing: 8

                                    // Header: titel + refresh + toggle
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "Wi-Fi"
                                            color: root.c.fg
                                            font.family: root.c.fontFamily
                                            font.pixelSize: 13
                                            font.bold: true
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: "  "
                                            color: root.c.muted
                                            font.family: root.c.fontFamily
                                            font.pixelSize: 15
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: network.refreshNetworkData()
                                            }
                                        }
                                        Text {
                                            text: network.state !== 0 ? "" : ""
                                            color: network.state !== 0 ? root.c.accent : root.c.muted
                                            font.family: root.c.fontFamily
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

                                    // Lijst met wifi-netwerken
                                    ListView {
                                        id: wifiListView
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        model: network.networks
                                        clip: true
                                        spacing: 7

                                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                                        delegate: Rectangle {
                                            width: wifiListView.width
                                            height: 32
                                            radius: 6
                                            color: root.c.softFill

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10; anchors.rightMargin: 10
                                                spacing: 8

                                                Text {
                                                    text: {
                                                        var signalVal = parseInt(modelData.signal);
                                                        if (isNaN(signalVal)) return "󰤯";
                                                        if (signalVal > 80) return "󰤨";
                                                        if (signalVal > 60) return "󰤥";
                                                        if (signalVal > 40) return "󰤢";
                                                        if (signalVal > 20) return "󰤟";
                                                        return "󰤯";
                                                    }
                                                    color: root.c.fg
                                                    font.family: root.c.fontFamily
                                                    font.pixelSize: 15
                                                }
                                                Text {
                                                    text: modelData.ssid
                                                    color: root.c.fg
                                                    font.family: root.c.fontFamily
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
                                                    color: root.c.muted
                                                    font.family: root.c.fontFamily
                                                    font.pixelSize: 15
                                                }
                                                Text {
                                                    text: ""
                                                    color: root.c.muted
                                                    font.family: root.c.fontFamily
                                                    font.pixelSize: 20
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Quickshell.execDetached(["nmcli", "device", "wifi", "connect", modelData.ssid])
                                            }
                                        }
                                    }
                                }
                            }

                            Behavior on opacity { NumberAnimation { duration: root.c.fadeAnimDuration } }
                        }

                        // ================= (BLUETOOTH DROPDOWN – later toe te voegen) =================
                        // Item { ... }
                    }

                    Behavior on opacity { NumberAnimation { duration: root.c.fadeAnimDuration } }
                }
            }

            BackgroundEffect.blurRegion: Region { item: rightNotchBg }

            Behavior on width {
                NumberAnimation { duration: root.c.widthAnimDuration; easing.type: Easing.InOutQuad }
            }
        }
    }
}

    // ---- HERBRUIKBARE KNOPSJABLOON ----
    component MusicButton: Rectangle {
        id: btn

        property string glyph: ""
        property bool big: false

        signal pressed()

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
