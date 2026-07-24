import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland

Item {
    id: root

    property var screen: null
    property bool open: false
    readonly property color fg: "#fff7e5"
    readonly property color accent: "#fff7e5"
    readonly property color muted: "#ffffff"
    readonly property color softFill: "#ffffff"
    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"
    property int volumePct: 0
    property bool volumeMuted: false
    property var cavaBars: []

    readonly property var ignoredPlayers: ["zen-browser", "firefox", "youtube"]
    readonly property var activePlayer: {
        const players = Mpris.players.values || [];
        let fallback = null;
        for (let i = 0; i < players.length; i++) {
            const p = players[i];
            if (!p) continue;
            const id = ((p.identity || "") + " " + (p.desktopEntry || "") + " " + (p.dbusName || "")).toLowerCase();
            if (ignoredPlayers.some((name) => id.includes(name))) continue;
            if (p.isPlaying) return p;
            if (!fallback && p.playbackState !== MprisPlaybackState.Stopped) fallback = p;
        }
        return fallback;
    }
    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.isPlaying
    readonly property string title: hasPlayer && activePlayer.trackTitle ? activePlayer.trackTitle : "Geen track"
    readonly property string artist: hasPlayer && activePlayer.trackArtist ? activePlayer.trackArtist : (hasPlayer && activePlayer.identity ? activePlayer.identity : "Geen artiest")
    readonly property real trackLength: hasPlayer && activePlayer.lengthSupported ? Math.max(0, activePlayer.length) : 0
    readonly property bool canSeek: hasPlayer && activePlayer.canSeek && trackLength > 0
    property real trackPosition: 0
    readonly property real progressRatio: trackLength > 0 ? Math.max(0, Math.min(1, trackPosition / trackLength)) : 0

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
    function fmtTime(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0))
        const m = Math.floor(s / 60)
        const ss = String(s % 60).padStart(2, "0")
        return m + ":" + ss
    }
    function syncPosition() {
        if (!activePlayer || !activePlayer.positionSupported) { trackPosition = 0; return }
        trackPosition = Math.max(0, activePlayer.position)
    }
    function seekToRatio(r) {
        if (!canSeek) return
        const target = clamp(r, 0, 1) * trackLength
        activePlayer.position = target
        trackPosition = target
    }
    function setVolume(v) {
        const next = clamp(Math.round(v), 0, 100)
        Quickshell.execDetached(["pamixer", "--set-volume", String(next)])
        volumePct = next
        if (volumeMuted && next > 0) { Quickshell.execDetached(["pamixer", "-u"]); volumeMuted = false }
    }
    function bumpVolume(delta) { setVolume(volumePct + delta) }

    implicitWidth: 18
    implicitHeight: 18

    Text {
        id: note
        anchors.centerIn: parent
        color: root.open ? root.accent : root.fg
        text: ""
        font.family: root.fontFamily
        font.pixelSize: 18
        font.bold: true
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: noteMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { root.open = !root.open }
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) root.bumpVolume(5)
            else root.bumpVolume(-5)
        }
    }

    // Volume poll
    Process {
        id: volumeProc
        running: true
        command: ["bash", "-lc", "while true; do v=$(pamixer --get-volume 2>/dev/null); m=$(pamixer --get-mute 2>/dev/null); printf '%s|%s\\n' \"${v:-0}\" \"${m:-false}\"; sleep 1; done"]
        onExited: running = true
        stdout: SplitParser {
            onRead: (line) => {
                const parts = line.trim().split("|")
                const v = parseInt(parts[0])
                if (!isNaN(v)) root.volumePct = root.clamp(v, 0, 100)
                root.volumeMuted = parts[1] === "true"
            }
        }
    }

    // Cava (visualizer)
    Process {
        id: cavaProc

        running: root.open && root.isPlaying
        command: ["bash", "-lc", "cfg=$(mktemp); " + "printf '%s\\n' '[general]' 'bars = 32' 'framerate = 40' 'sensitivity = 145' '[input]' 'method = pipewire' '[output]' 'method = raw' 'raw_target = /dev/stdout' 'data_format = ascii' 'ascii_max_range = 12' 'bar_delimiter = 59' 'frame_delimiter = 10' 'channels = mono' '[smoothing]' 'noise_reduction = 0.55' > \"$cfg\"; " + "cava -p \"$cfg\"; code=$?; rm -f \"$cfg\"; exit $code"]

        stdout: SplitParser {
            onRead: (line) => {
                const parts = line.trim().split(";");
                const vals = [];
                for (let i = 0; i < parts.length; i++) {
                    const v = parseInt(parts[i]);
                    vals.push(isNaN(v) ? 0 : Math.max(0, Math.min(1, v / 12)));
                }
                root.cavaBars = vals;
                cavaCanvas.requestPaint();
            }
        }

    }

    // Positie-update
    Timer {
        interval: 500; repeat: true; running: root.hasPlayer
        onTriggered: {
            if (root.isPlaying && root.trackLength > 0)
                root.trackPosition = Math.min(root.trackLength, root.trackPosition + 0.5)
            else root.syncPosition()
        }
    }
    Connections {
        target: root.activePlayer
        enabled: root.activePlayer !== null
        function onPositionChanged() { root.syncPosition() }
        function onTrackTitleChanged() { root.syncPosition() }
    }
}