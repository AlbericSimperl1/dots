import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool open: false
    property color fg: "#fff7e5"
    property color accent: "#ebd9b9"
    property color muted: Qt.rgba(1, 0.95, 0.82, 0.78)
    property color softFill: Qt.rgba(0.025, 0.04, 0.06, 0.32)
    property color borderCol: "#eb2e2e3d"
    property string fontFamily: "JetBrainsMono Nerd Font Mono"

    property bool state: false
    property var networks: []

    // Houdt bij van welk netwerk de wachtwoord-input momenteel openstaat
    property string selectedSsid: ""
    property string connectingSsid: ""

    function refreshNetworkData() {
        Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]);
        nmcliProc.running = false;
        nmcliProc.running = true;
    }

    // Verbinden met een netwerk (met of zonder wachtwoord)
    function attemptConnect(ssid, password) {
        root.connectingSsid = ssid;
        let cmd = [];
        if (password && password.length > 0) {
            cmd = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        } else {
            cmd = ["nmcli", "device", "wifi", "connect", ssid];
        }

        Quickshell.execDetached(cmd);
        // Sluit het wachtwoordveld na verzenden
        root.selectedSsid = "";
    }

    implicitWidth: 18
    implicitHeight: 18

    readonly property string scanScript: `
while true; do
    status=$(nmcli radio wifi 2>/dev/null || echo "disabled")

    nets=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null \
        | awk -F':' '$2 != "" && $2 != "SSID" {
            active = ($1 == "*") ? 1 : 0;
            ssid = $2;
            sig = ($3 ~ /^[0-9]+$/) ? $3 + 0 : 0;
            sec = ($4 != "" && $4 != "--") ? 1 : 0;

            if (!(ssid in seen) || active == 1 || sig > max_sig[ssid]) {
                seen[ssid] = 1;
                max_sig[ssid] = sig;
                is_act[ssid] = active;
                is_sec[ssid] = sec;
            }
        }
        END {
            for (s in seen) {
                print is_act[s] "\t" s "\t" max_sig[s] "\t" is_sec[s]
            }
        }' \
        | jq -R -s -c '
            [split("\n")[] | select(length > 0) | split("\t") | {
                connected: (.[0] == "1"),
                ssid: .[1],
                signal: (.[2] | tonumber),
                secure: (.[3] == "1")
            }] | sort_by(.connected, .signal) | reverse
        ')

    if [ -z "$nets" ]; then nets="[]"; fi

    jq -n -c --arg st "$status" --argjson net "$nets" '{state: $st, networks: $net}'
    sleep 4
done
`

    Process {
        id: nmcliProc
        running: true
        command: ["bash", "-c", root.scanScript]

        stdout: SplitParser {
            onRead: line => {
                let trimmed = line.trim();
                if (trimmed.length === 0)
                    return;

                try {
                    const data = JSON.parse(trimmed);
                    root.state = (data.state === "enabled");
                    root.networks = data.networks || [];

                    // Reset verbindingsstatus als de netwerkstatus verandert
                    if (root.connectingSsid) {
                        let target = root.networks.find(n => n.ssid === root.connectingSsid);
                        if (target && target.connected) {
                            root.connectingSsid = "";
                        }
                    }
                } catch (e) {
                    console.log("Network parse error: " + e);
                }
            }
        }
    }

    Text {
        id: wifiIcon
        anchors.centerIn: parent
        color: root.open ? root.accent : root.fg

        text: {
            if (!root.state)
                return "󰤭";

            let activeSignal = -1;
            for (let i = 0; i < root.networks.length; i++) {
                if (root.networks[i].connected) {
                    activeSignal = root.networks[i].signal;
                    break;
                }
            }

            if (activeSignal < 0)
                return "󰤯";
            if (activeSignal > 75)
                return "󰤨";
            if (activeSignal > 50)
                return "󰤥";
            if (activeSignal > 25)
                return "󰤢";
            return "󰤟";
        }

        font.family: root.fontFamily
        font.pixelSize: 19
        font.bold: true

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }
}
