#!/usr/bin/env bash
set -u

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
state_file="$state_dir/music-eq.json"
preset_dir="$HOME/.config/easyeffects/output"
preset_name="quickshell_live_eq"
preset_file="$preset_dir/$preset_name.json"

mkdir -p "$state_dir" "$preset_dir"

default_state='{"b1":0,"b2":0,"b3":0,"b4":0,"b5":0,"b6":0,"b7":0,"b8":0,"b9":0,"b10":0,"preset":"Flat","pending":false}'

ensure_state() {
    if [ ! -s "$state_file" ]; then
        printf '%s\n' "$default_state" > "$state_file"
    fi
}

write_state() {
    python3 - "$state_file" "$@" <<'PY'
import json
import sys

path = sys.argv[1]
args = sys.argv[2:]
try:
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
except Exception:
    data = {f"b{i}": 0 for i in range(1, 11)}
    data.update({"preset": "Flat", "pending": False})

if args[0] == "band":
    idx = max(1, min(10, int(args[1])))
    value = max(-12, min(12, int(args[2])))
    data[f"b{idx}"] = value
    data["preset"] = "Custom"
    data["pending"] = True
elif args[0] == "preset":
    name = args[1]
    presets = {
        "Flat":    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Bass":    [5, 7, 5, 2, 1, 0, 0, 0, 1, 2],
        "Treble":  [-2, -1, 0, 1, 2, 3, 4, 5, 6, 6],
        "Vocal":   [-2, -1, 1, 3, 5, 5, 4, 2, 1, 0],
        "Pop":     [2, 4, 2, 0, 1, 2, 4, 2, 1, 2],
        "Rock":    [5, 4, 2, -1, -2, -1, 2, 4, 5, 6],
        "Jazz":    [3, 3, 1, 1, 1, 1, 2, 1, 2, 3],
    }
    values = presets.get(name, presets["Flat"])
    for i, val in enumerate(values, 1):
        data[f"b{i}"] = val
    data["preset"] = name if name in presets else "Flat"
    data["pending"] = False
elif args[0] == "saved":
    data["pending"] = False

with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, separators=(",", ":"))
    fh.write("\n")
PY
}

apply_eq() {
    python3 - "$state_file" "$preset_file" <<'PY'
import json
import sys

state_path, preset_path = sys.argv[1], sys.argv[2]
with open(state_path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

slider_map = {0: 0, 1: 3, 2: 6, 3: 9, 4: 12, 5: 15, 6: 18, 7: 21, 8: 24, 9: 27}
freqs = [32, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000,
         1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000,
         20000, 22000, 24000, 24000]
gains = [float(data.get(f"b{i}", 0)) for i in range(1, 11)]
bands = {}

for i in range(32):
    gain = 0.0
    for slider_idx, band_idx in slider_map.items():
        if i == band_idx:
            gain = gains[slider_idx]
            break
    bands[f"band{i}"] = {
        "frequency": freqs[i],
        "gain": gain,
        "mode": "Bell",
        "mute": False,
        "q": 1.0,
        "solo": False,
        "width": 1.0,
        "slope": "x1",
    }

preset = {
    "output": {
        "blocklist": [],
        "plugins_order": ["equalizer"],
        "equalizer": {
            "bypass": False,
            "input-gain": 0.0,
            "output-gain": 0.0,
            "left": bands,
            "right": bands,
            "mode": "IIR",
            "num-bands": 32,
            "split-channels": False,
        },
    }
}

with open(preset_path, "w", encoding="utf-8") as fh:
    json.dump(preset, fh, indent=2)
PY

    if command -v easyeffects >/dev/null 2>&1; then
        easyeffects -l "$preset_name" >/dev/null 2>&1 &
    fi
}

ensure_state

case "${1:-get}" in
    get)
        cat "$state_file"
        ;;
    set_band)
        write_state band "${2:-1}" "${3:-0}"
        ;;
    apply)
        write_state saved
        apply_eq
        ;;
    preset)
        write_state preset "${2:-Flat}"
        apply_eq
        ;;
    *)
        printf 'usage: %s {get|set_band N VALUE|apply|preset NAME}\n' "$0" >&2
        exit 2
        ;;
esac
