#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
render_dir=${INTRO_RENDER_DIR:-/tmp/inferno-intro-renders}
mkdir -p "$render_dir" assets/intros
if [ "$#" -gt 0 ]; then
  fighter_ids=("$@")
else
  mapfile -t fighter_ids < <(python3 -c 'import json; print("\n".join(f["id"] for f in json.load(open("data/fighters.json"))["fighters"]))')
fi
for fighter_id in "${fighter_ids[@]}"; do
  "${GODOT_BIN:-godot}" --path "$PWD" --audio-driver Dummy --write-movie "$render_dir/$fighter_id.avi" --fixed-fps 30 --disable-vsync tests/render_intro.tscn -- "$fighter_id" > "$render_dir/$fighter_id.log" 2>&1
  if rg -q 'SCRIPT ERROR|^ERROR:' "$render_dir/$fighter_id.log"; then cat "$render_dir/$fighter_id.log"; exit 1; fi
  ffmpeg -hide_banner -loglevel error -y -i "$render_dir/$fighter_id.avi" -c:v libtheora -q:v 7 -c:a libvorbis -q:a 3 "assets/intros/$fighter_id.ogv"
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "assets/intros/$fighter_id.ogv"
done
