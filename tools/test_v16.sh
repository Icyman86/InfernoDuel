#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${DISPLAY:?Set DISPLAY to an available X server for the rendered checks}"
log_dir=${V16_TEST_LOG_DIR:-/tmp/inferno-v16-checks}
mkdir -p "$log_dir"
run_scene() {
  local name=$1
  shift
  timeout 100 "${GODOT_BIN:-godot}" --path "$PWD" --audio-driver Dummy "$@" "tests/$name.tscn" > "$log_dir/$name.log" 2>&1
  if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked' "$log_dir/$name.log"; then cat "$log_dir/$name.log"; return 1; fi
  rg 'RESULT: [1-9][0-9]* passed, 0 failed' "$log_dir/$name.log"
}
python3 tools/verify_assets.py
python3 tools/verify_intros.py
run_scene progression --headless
run_scene session --headless
run_scene v16_visual
./tools/test_gallery.sh > "$log_dir/gallery.log" 2>&1
rg 'GALLERY VISUAL RESULT:' "$log_dir/gallery.log"
./tools/test_arenas_ultimate.sh > "$log_dir/arenas-ultimate.log" 2>&1
rg 'RESULT: [1-9][0-9]* passed, 0 failed' "$log_dir/arenas-ultimate.log"
python3 tools/test_network.py > "$log_dir/network.log" 2>&1
rg 'NETWORK RESULT:' "$log_dir/network.log"
