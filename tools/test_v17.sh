#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${DISPLAY:?Set DISPLAY to an available X server}"
apk=${1:-builds/android/InfernoDuel-Android-v0.17.0-preview.apk}
log_dir=/tmp/inferno-v17
mkdir -p "$log_dir"
timeout 120 "${GODOT_BIN:-godot}" --path "$PWD" --audio-driver Dummy tests/story_menu.tscn > "$log_dir/story-menu.log" 2>&1
if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked' "$log_dir/story-menu.log"; then cat "$log_dir/story-menu.log"; exit 1; fi
rg 'V17 STORY MENU RESULT: [1-9][0-9]* passed, 0 failed' "$log_dir/story-menu.log"
python3 tools/verify_apk.py "$apk"
python3 tools/test_apk_ui.py "$apk"
