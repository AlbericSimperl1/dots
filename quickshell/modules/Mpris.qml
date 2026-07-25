import QtQuick
import Quickshell.Services.Mpris

Text {
    id: mpris
    color: "#fff7e5"
    font.family: "JetBrainsMono Nerd Font Mono"
    font.pixelSize: 20
    font.weight: Font.Bold

    readonly property var ignored: ["zen-browser", "firefox", "youtube"]

    readonly property var activePlayer: {
        for (const p of Mpris.players.values) {
            const id = (p.identity || "").toLowerCase();
            if (ignored.some(i => id.includes(i))) continue;
            return p;
        }
        return null;
    }

    visible: activePlayer !== null
    text: {
        if (!activePlayer) return "";
        if (activePlayer.playbackState === MprisPlaybackState.Playing) return "\uf04b"; // nf-fa-play
        if (activePlayer.playbackState === MprisPlaybackState.Paused) return "\uf04c";  // nf-fa-pause
        return "\uf04d";                                                                 // nf-fa-stop
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (mpris.activePlayer) mpris.activePlayer.togglePlaying();
        }
    }
}
