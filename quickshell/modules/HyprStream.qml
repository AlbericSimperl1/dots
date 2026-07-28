import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: root

    property bool open: false
    property bool isRunning: false

    spacing: 0

    // --- Bar Visuals ---
    Text {
        text: root.isRunning ? "" : "" // iPad / Tablet Nerd Font icon
        color: root.isRunning ? "#ff0000" : "#fff7e5"
        font.family: "JetBrainsMono Nerd Font Mono"
        font.pixelSize: 21
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["hyprStream"])
    }

    // --- Backend Processen ---

    // 1. Check elke 2 seconden of het proces/de stream actief is
    Process {
        id: checkProc
        // Tip: Vervang 'hyprStream' door het proces van de encoder/stream als je app altijd open staat
        command: ["pgrep", "-x", "hyprStream"]
        onExited: code => {
            root.isRunning = (code === 0);
        }
    }

    // 2. Starten van de applicatie
    Process {
        id: startProc
        // Gebruik eventueel het volledige pad (bijv. "/home/gebruiker/.local/bin/hyprpad" of "/usr/bin/hyprStream")
        // omdat Quickshell niet altijd alle shell-PATHs overneemt.
        command: ["hyprStream"]
        onStarted: root.isRunning = true
    }

    // 3. Stoppen van de applicatie
    Process {
        id: stopProc
        command: ["pkill", "-x", "hyprStream"]
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            // Zorg dat de Process niet opnieuw getriggerd wordt als hij nog bezig is
            if (!checkProc.running) {
                checkProc.running = true;
            }
        }
    }

    function toggle() {
        if (root.isRunning) {
            stopProc.running = true;
        } else {
            startProc.running = true;
        }
    }
}
