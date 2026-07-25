import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: dropdownRoot

    property var music: null
    property color fg: "#fff7e5"
    property color accent: "#fff7e5"
    property color muted: "#ffffff"
    property color softFill: "#ffffff"
    property color borderCol: "#eb2e2e3d"
    property string fontFamily: "JetBrainsMono Nerd Font Mono"

    opacity: visible ? 1 : 0

    // Herbruikbare knop binnen de muziekdropdown
    component MusicButton: Rectangle {
        id: btn

        property string glyph: ""
        property bool big: false

        signal pressed

        Layout.preferredWidth: big ? 30 : 22
        Layout.preferredHeight: big ? 30 : 22
        radius: width / 2
        color: "#3b2e2e3d"
        border.color: enabled ? dropdownRoot.borderCol : "#3b2e2e3d"
        border.width: 1
        opacity: enabled ? 1 : 0.45

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: dropdownRoot.fg
            font.family: dropdownRoot.fontFamily
            font.pixelSize: btn.big ? 14 : 11
        }

        MouseArea {
            anchors.fill: parent
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.pressed()
        }
    }

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

                    Connections {
                        target: dropdownRoot.music
                        function onCavaBarsChanged() {
                            cavaCanvas.requestPaint();
                        }
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        if (!dropdownRoot.music)
                            return;

                        const vals = dropdownRoot.music.cavaBars || [];
                        const count = vals.length || 32;
                        const slot = width / count;
                        const mid = height / 2;
                        const maxH = height * 0.45;
                        ctx.fillStyle = dropdownRoot.accent;
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
                        text: dropdownRoot.music ? dropdownRoot.music.title : ""
                        color: dropdownRoot.fg
                        font.family: dropdownRoot.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: dropdownRoot.music ? dropdownRoot.music.artist : ""
                        color: dropdownRoot.muted
                        font.family: dropdownRoot.fontFamily
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
                        enabled: dropdownRoot.music && dropdownRoot.music.activePlayer && dropdownRoot.music.activePlayer.canGoPrevious
                        onPressed: dropdownRoot.music.activePlayer.previous()
                    }

                    MusicButton {
                        glyph: dropdownRoot.music && dropdownRoot.music.isPlaying ? "󰏤" : "󰐊"
                        enabled: dropdownRoot.music && dropdownRoot.music.hasPlayer
                        big: true
                        onPressed: dropdownRoot.music.activePlayer.togglePlaying()
                    }

                    MusicButton {
                        glyph: "󰒭"
                        enabled: dropdownRoot.music && dropdownRoot.music.activePlayer && dropdownRoot.music.activePlayer.canGoNext
                        onPressed: dropdownRoot.music.activePlayer.next()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 15
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: dropdownRoot.music ? dropdownRoot.music.fmtTime(dropdownRoot.music.trackPosition) : "0:00"
                            color: dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 11
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: dropdownRoot.music && dropdownRoot.music.trackLength > 0 ? dropdownRoot.music.fmtTime(dropdownRoot.music.trackLength) : "--:--"
                            color: dropdownRoot.muted
                            font.family: dropdownRoot.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: dropdownRoot.softFill

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: dropdownRoot.music ? Math.max(parent.height, parent.width * dropdownRoot.music.progressRatio) : 0
                            radius: parent.radius
                            color: dropdownRoot.accent
                            opacity: dropdownRoot.music && dropdownRoot.music.canSeek ? 0.9 : 0.45
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: dropdownRoot.music && dropdownRoot.music.canSeek
                            cursorShape: Qt.PointingHandCursor
                            onPressed: dropdownRoot.music.seekToRatio(mouse.x / width)
                            onPositionChanged: {
                                if (pressed)
                                    dropdownRoot.music.seekToRatio(mouse.x / width);
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
                color: dropdownRoot.borderCol
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
                    text: (dropdownRoot.music ? dropdownRoot.music.volumePct : 0) + "%"
                    color: dropdownRoot.fg
                    font.family: dropdownRoot.fontFamily
                    font.pixelSize: 11
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 4
                    Layout.alignment: Qt.AlignHCenter
                    radius: 2
                    color: dropdownRoot.softFill

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: parent.height * ((dropdownRoot.music ? dropdownRoot.music.volumePct : 0) / 100)
                        radius: parent.radius
                        color: dropdownRoot.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onPressed: dropdownRoot.music.setVolume((1 - mouse.y / height) * 100)
                        onPositionChanged: {
                            if (pressed)
                                dropdownRoot.music.setVolume((1 - mouse.y / height) * 100);
                        }
                        onWheel: wheel => {
                            if (wheel.angleDelta.y > 0)
                                dropdownRoot.music.bumpVolume(5);
                            else
                                dropdownRoot.music.bumpVolume(-5);
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: dropdownRoot.music && dropdownRoot.music.volumeMuted ? "󰝟" : "󰕾"
                    color: dropdownRoot.music && dropdownRoot.music.volumeMuted ? dropdownRoot.muted : dropdownRoot.fg
                    font.family: dropdownRoot.fontFamily
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
