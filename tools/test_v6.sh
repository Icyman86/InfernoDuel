#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
log_file=$(mktemp)
trap 'rm -f "$log_file"' EXIT
status=0
timeout 60 "${GODOT_BIN:-godot}" --headless --path "$PWD" tests/session.tscn > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then exit "$status"; fi
if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked' "$log_file"; then exit 1; fi
rg -q 'SESSION RESULT: [1-9][0-9]* passed, 0 failed' "$log_file"
NETWORK_RENDERED=0 python3 tools/test_network.py
if [ "${TEST_NETWORK_RENDERED:-0}" = 1 ]; then
  NETWORK_RENDERED=1 python3 tools/test_network.py
fi
if [ -n "${DISPLAY:-}" ]; then
  status=0
  timeout 100 "${GODOT_BIN:-godot}" --path "$PWD" --audio-driver Dummy tests/v6_visual.tscn -- --touch > "$log_file" 2>&1 || status=$?
  cat "$log_file"
  if [ "$status" -ne 0 ]; then exit "$status"; fi
  if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked' "$log_file"; then exit 1; fi
  rg -q 'V6 VISUAL RESULT: [1-9][0-9]* passed, 0 failed' "$log_file"
fi
