import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Kleuren & Font overnemen uit de hoofd-shell
    readonly property color fg: "#fff7e5"
    readonly property color accent: "#fff7e5"
    readonly property color muted: Qt.rgba(1, 0.91, 0.7, 0.78)
    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"
    // Interne variabelen voor de batterijstatus
    property int batteryPercentage: 0
    property bool isCharging: false

    implicitWidth: mainLayout.implicitWidth
    implicitHeight: 18

    // Handmatige Linux sysfs monitor als fallback/vervanger voor UPower
    Process {
        id: batteryMonitor

        running: true
        // SCRIPT: Zoekt de actieve batterij (meestal BAT0 of BAT1) en leest percentage + status uit
        command: ["bash", "-c", "while true; do " + "  bat_dir=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1); " + "  if [ -n \"$bat_dir\" ]; then " + "    pct=$(cat \"$bat_dir/capacity\"); " + "    status=$(cat \"$bat_dir/status\"); " + "    echo \"$pct|$status\"; " + "  else " + "    echo \"0|Unknown\"; " + "  fi; " + "  sleep 5; " + "done"]

        stdout: SplitParser {
            onRead: line => {
                let parts = line.trim().split("|");
                if (parts.length >= 2) {
                    root.batteryPercentage = parseInt(parts[0]) || 0;
                    root.isCharging = (parts[1] === "Charging");
                }
            }
        }
    }

    RowLayout {
        id: mainLayout

        anchors.centerIn: parent
        spacing: 4

        Text {
            text: ""
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: 14
            font.weight: Font.Bold
        }
        // 1. Batterij Icoon (Dynamisch op basis van het percentage en de laadstatus)

        Text {
            color: root.isCharging ? root.accent : root.fg // Accentkleur bij opladen
            font.family: root.fontFamily
            font.pixelSize: 16
            text: {
                const pct = root.batteryPercentage;
                if (root.isCharging) {
                    if (pct >= 90)
                        return "󰂋";

                    if (pct >= 80)
                        return "󰂊";

                    if (pct >= 70)
                        return "󰢞";

                    if (pct >= 60)
                        return "󰂉";

                    if (pct >= 50)
                        return "󰢝";

                    if (pct >= 40)
                        return "󰂈";

                    if (pct >= 30)
                        return "󰂇";

                    if (pct >= 20)
                        return "󰂆";

                    return "󰢜";
                } else {
                    if (pct >= 90)
                        return "󰁹";

                    if (pct >= 80)
                        return "󰂂";

                    if (pct >= 70)
                        return "󰂁";

                    if (pct >= 60)
                        return "󰂀";

                    if (pct >= 50)
                        return "󰁿";

                    if (pct >= 40)
                        return "󰁾";

                    if (pct >= 30)
                        return "󰁽";

                    if (pct >= 20)
                        return "󰁼";

                    if (pct >= 10)
                        return "󰁻";

                    return "󰁺";
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: Quickshell.execDetached(["omarchy-menu", "power"])
        }
    }
}
