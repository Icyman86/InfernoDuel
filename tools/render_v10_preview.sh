#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
preview_project=$(mktemp -d)
trap 'rm -rf "$preview_project"' EXIT
# Movie Maker reads the project's initial viewport before scene startup.
# An isolated config records the phone ratio without changing the game config.
python3 - "$PWD" "$preview_project" <<'PY'
from pathlib import Path
import sys
root, target = map(Path, sys.argv[1:])
text = (root/'project.godot').read_text().replace('viewport_height=720', 'viewport_height=582')
(target/'project.godot').write_text(text)
for name in ['assets', 'data', 'scripts', 'scenes', 'tests', '.godot']:
    (target/name).symlink_to(root/name, target_is_directory=True)
PY
mkdir -p builds/android
"${GODOT_BIN:-godot}" --path "$preview_project" --audio-driver Dummy \
  --write-movie "$preview_project/preview.avi" --fixed-fps 60 --disable-vsync \
  tests/v10_preview.tscn -- --touch
ffmpeg -hide_banner -loglevel error -y -i "$preview_project/preview.avi" \
  -c:v libx264 -threads 2 -crf 21 -pix_fmt yuv420p -r 60 -movflags +faststart -an \
  builds/android/InfernoDuel-Preview-v0.10.0.mp4
ffmpeg -hide_banner -loglevel error -i builds/android/InfernoDuel-Preview-v0.10.0.mp4 -f null -
