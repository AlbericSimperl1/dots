import QtQuick 2.15
import Quickshell 1.0
import Quickshell.Io 1.0

Item {
    id: root
    width: parent ? parent.width : 300
    height: 40

    // Aantal balken (moet overeenkomen met de config!)
    property int barCount: 32
    property color barColor: "#fff7e5"

    // Array met hoogtes (0..1)
    property var barHeights: []

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Threaded

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (!barHeights || barHeights.length === 0) return;

            var barWidth = width / barHeights.length;
            var spacing = barWidth * 0.15;
            var drawWidth = barWidth - spacing;

            for (var i = 0; i < barHeights.length; i++) {
                var h = barHeights[i] * height;
                var x = i * barWidth + spacing / 2;
                ctx.fillStyle = barColor;
                ctx.fillRect(x, height - h, drawWidth, h);
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // Start cava met het vaste config-bestand
    Process {
        id: cavaProc
        command: ["cava", "-p", "/home/" + Qt.environmentVariable("USER") + "/.config/cava/quickshell.conf"]
        running: true

        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.trim().split(/\s+/);
                var normalized = [];
                for (var i = 0; i < parts.length && i < root.barCount; i++) {
                    var val = parseInt(parts[i], 10);
                    normalized.push(Math.min(val / 12, 1));
                }
                while (normalized.length < root.barCount) normalized.push(0);
                root.barHeights = normalized;
                canvas.requestPaint();
            }
        }

        onExited: {
            if (exitCode !== 0) {
                console.warn("Cava crashed, restarting...");
                running = true;
            }
        }
    }

    // Linksklik = play/pause, rechtsklik = terminal
    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["playerctl", "play-pause"])
        onRightClicked: Quickshell.execDetached(["kitty", "cava"])
    }
}