import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var screen: null
    property bool open: false
    readonly property color fg: "#fff7e5"
    readonly property color accent: "#fff7e5"
    readonly property color muted: "#ffffff"
    readonly property color softFill: "#ffffff"
    readonly property string fontFamily: "JetBrainsMono Nerd Font Mono"
    
    // Properties voor netwerkdata
    property string statusText: "Geen verbinding"
    property string ipAddresses: "N/A"
    property string connectionDetails: "N/A"
    property string statsText: "Download: 0 KB/s | Upload: 0 KB/s"
    
    // De array waar shell.qml naar luistert voor de dropdown
    property var networks: []
    
    // 0 = disconnected, -1 = ethernet, 1..4 = wifi signaalsterkte
    property int state: 0
    readonly property var wifiIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
    property string iconText: {
        if (state === -1) return "󰈀";
        if (state === 0) return "󰤮";
        return wifiIcons[Math.max(0, Math.min(wifiIcons.length - 1, state))];
    }

    implicitWidth: 18
    implicitHeight: 18

    Text {
        id: netIcon
        anchors.centerIn: parent
        color: root.open ? root.accent : root.fg
        text: root.iconText
        font.family: root.fontFamily
        font.pixelSize: 18
        font.bold: true
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: netMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { root.open = !root.open }
    }

    // 1. Algemene Netwerkstatus
    Process {
        id: netProc
        running: true
        command: ["bash", "-lc",
            "while true; do " +
            "  eth=down; " +
            "  for c in /sys/class/net/en*/carrier /sys/class/net/eth*/carrier; do " +
            "    [ -f \"$c\" ] && [ \"$(cat \"$c\" 2>/dev/null)\" = \"1\" ] && eth=up; " +
            "  done; " +
            "  if [ \"$eth\" = up ]; then " +
            "    echo eth; " +
            "  else " +
            "    q=$(awk 'NR==3{print $3}' /proc/net/wireless 2>/dev/null); " +
            "    if [ -n \"$q\" ]; then pct=$(( ${q%.*} * 100 / 70 )); echo \"$pct\"; else echo down; fi; " +
            "  fi; " +
            "  sleep 3; " +
            "done"]
        stdout: SplitParser {
            onRead: (line) => {
                line = line.trim();
                if (line === "eth") { 
                    root.state = -1; 
                    root.statusText = "Verbonden via Ethernet";
                    return; 
                }
                if (line === "down" || line === "") { 
                    root.state = 0; 
                    root.statusText = "Geen verbinding";
                    return; 
                }
                const sig = parseInt(line);
                if (isNaN(sig)) { 
                    root.state = 0; 
                    root.statusText = "Fout bij detecteren verbinding";
                    return; 
                }
                root.state = sig > 80 ? 4 : sig > 60 ? 3 : sig > 40 ? 2 : 1;
                root.statusText = `WiFi signaal: ${sig}%`;
            }
        }
    }

    // 2. IP Adressen
    Process {
        id: ipProc
        running: true
        command: ["bash", "-lc", 
            "while true; do " +
            "  ip_route=$(ip route | grep -E 'default via' | head -n1); " +
            "  if [[ -n \"$ip_route\" ]]; then " +
            "    iface=$(echo \"$ip_route\" | awk '{print $5}'); " +
            "    ipv4=$(ip addr show \"$iface\" 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1); " +
            "    ipv6=$(ip addr show \"$iface\" 2>/dev/null | grep 'inet6 ' | grep -v '::1' | grep -v 'fe80' | awk '{print $2}' | head -n1); " +
            "    echo \"IPv4: ${ipv4:-N/A}, IPv6: ${ipv6:-N/A}\"; " +
            "  else " +
            "    echo \"N/A\"; " +
            "  fi; " +
            "  sleep 10; " +
            "done"]
        stdout: SplitParser {
            onRead: (line) => { root.ipAddresses = line.trim(); }
        }
    }

    // 3. Actieve Verbindingsdetails
    Process {
        id: connDetailsProc
        running: true
        command: ["bash", "-lc",
            "while true; do " +
            "  ssid=$(nmcli -t -f name,device connection show --active 2>/dev/null | grep -E '(wlan|wifi)' | cut -d: -f1); " +
            "  if [[ -n \"$ssid\" ]]; then " +
            "    signal=$(iwconfig 2>/dev/null | grep 'Signal level' | awk -F '=' '{print $3}' | cut -d' ' -f1); " +
            "    freq=$(iwconfig 2>/dev/null | grep 'Frequency' | awk -F ':' '{print $2}' | cut -d' ' -f2); " +
            "    echo \"WiFi: $ssid (Signaal: ${signal:-N/A} dBm, Freq: ${freq:-N/A})\"; " +
            "  else " +
            "    eth_dev=$(ip route | grep default | awk '{print $5}' | grep -E '^(en|eth)'); " +
            "    if [[ -n \"$eth_dev\" ]]; then " +
            "      speed=$(ethtool \"$eth_dev\" 2>/dev/null | grep Speed | awk '{print $2}'); " +
            "      echo \"Ethernet: $eth_dev (Snelheid: ${speed:-Onbekend})\"; " +
            "    else " +
            "      echo \"Status: Geen actieve verbinding\"; " +
            "    fi; " +
            "  fi; " +
            "  sleep 15; " +
            "done"]
        stdout: SplitParser {
            onRead: (line) => { root.connectionDetails = line.trim(); }
        }
    }

    // 4. Netwerksnelheid Statistieken
    Process {
        id: statsProc
        running: true
        command: ["bash", "-c",
            "prev_rx=0; prev_tx=0; prev_time=$(date +%s.%N); " +
            "while true; do " +
            "  rx_bytes=0; tx_bytes=0; " +
            "  for dev in /sys/class/net/*/statistics/rx_bytes; do " +
            "    if [[ -f \"$dev\" ]] && [[ \"$(basename $(dirname $dev))\" != 'lo' ]]; then " +
            "      bytes=$(cat \"$dev\"); " +
            "      rx_bytes=$((rx_bytes + bytes)); " +
            "    fi; " +
            "  done; " +
            "  for dev in /sys/class/net/*/statistics/tx_bytes; do " +
            "    if [[ -f \"$dev\" ]] && [[ \"$(basename $(dirname $dev))\" != 'lo' ]]; then " +
            "      bytes=$(cat \"$dev\"); " +
            "      tx_bytes=$((tx_bytes + bytes)); " +
            "  fi; done; " +
            "  curr_time=$(date +%s.%N); " +
            "  time_diff=$(echo \"$curr_time - $prev_time\" | bc -l); " +
            "  if (( $(echo \"$time_diff > 1\" | bc -l) )); then " +
            "    rx_rate=0; tx_rate=0; " +
            "    if [ $prev_rx -gt 0 ]; then " +
            "      rx_diff=$((rx_bytes - prev_rx)); tx_diff=$((tx_bytes - prev_tx)); " +
            "      rx_rate=$(echo \"scale=2; $rx_diff / 1024 / $time_diff\" | bc); " +
            "      tx_rate=$(echo \"scale=2; $tx_diff / 1024 / $time_diff\" | bc); " +
            "    fi; " +
            "    printf 'Download: %.1f KB/s | Upload: %.1f KB/s\\n' \"$rx_rate\" \"$tx_rate\"; " +
            "    prev_rx=$rx_bytes; prev_tx=$tx_bytes; prev_time=$curr_time; " +
            "  fi; " +
            "  sleep 2; " +
            "done"]
        stdout: SplitParser {
            onRead: (line) => { root.statsText = line.trim(); }
        }
    }

    // 5. DE NMCLI WIFI SCANNER (Kogelvrij via AWK)
    Process {
        id: wifiScanProc
        running: true
        command: ["bash", "-lc", 
            "while true; do " +
            "  networks_string=$(nmcli --mode tabular --fields SSID,SIGNAL,SECURITY device wifi list --rescan yes 2>/dev/null | " +
            "    grep -vE '^(SSID|--)' | " +
            "    awk 'length($0) > 0 { " +
            "      sec=$NF; sig=$(NF-1); " +
            "      $NF=\"\"; $(NF-1)=\"\"; " +
            "      gsub(/^[ \t]+|[ \t]+$/, \"\", $0); " +
            "      ssid=$0; " +
            "      if (length(ssid) > 0) print ssid \"|\" sig \"|\" sec; " +
            "    }' | sort -u -t'|' -k1,1 | sort -t'|' -k2 -nr | paste -sd ';' -); " +
            "  echo \"$networks_string\"; " +
            "  sleep 15; " +
            "done"]
        stdout: SplitParser {
            onRead: (line) => {
                const t = line.trim();
                if (t === "") {
                    root.networks = [];
                    return;
                }
                const parts = t.split(";");
                const vals = [];
                for (let i = 0; i < parts.length; i++) {
                    if (!parts[i]) continue;
                    const netDetails = parts[i].split("|");
                    if (netDetails.length >= 2 && netDetails[0].trim() !== "") {
                        vals.push({
                            "ssid": netDetails[0].trim(),
                            "signal": netDetails[1].trim(),
                            "security": netDetails[2] ? netDetails[2].trim() : ""
                        });
                    }
                }
                // Atomische update naar de lijst
                root.networks = vals;
            }
        }
    }

    // Refresh functie
    function refreshNetworkData() {
        netProc.running = false;
        ipProc.running = false;
        connDetailsProc.running = false;
        statsProc.running = false;
        wifiScanProc.running = false;
        root.networks = [];
        
        Qt.callLater(function() {
            netProc.running = true;
            ipProc.running = true;
            connDetailsProc.running = true;
            statsProc.running = true;
            wifiScanProc.running = true;
        });
    }
}