#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
./tools/test_v8.sh
log_file=$(mktemp)
trap 'rm -f "$log_file"' EXIT
status=0
timeout 90 "${GODOT_BIN:-godot}" --headless --path "$PWD" tests/quality.tscn > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then exit "$status"; fi
if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked' "$log_file"; then exit 1; fi
rg -q 'QUALITY RESULT: [1-9][0-9]* passed, 0 failed' "$log_file"
if [ -n "${DISPLAY:-}" ]; then
  status=0
  timeout 120 "${GODOT_BIN:-godot}" --path "$PWD" --audio-driver Dummy --fixed-fps 60 tests/quality_visual.tscn -- --touch > "$log_file" 2>&1 || status=$?
  cat "$log_file"
  if [ "$status" -ne 0 ]; then exit "$status"; fi
  if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked' "$log_file"; then exit 1; fi
  rg -q 'QUALITY VISUAL RESULT: [1-9][0-9]* passed, 0 failed' "$log_file"
fi
