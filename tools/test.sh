#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tools/verify_assets.py
log_file=$(mktemp)
trap 'rm -f "$log_file"' EXIT
status=0
timeout 90 "${GODOT_BIN:-godot}" --headless --path "$PWD" --editor --quit > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then exit "$status"; fi
if rg -q 'SCRIPT ERROR|^ERROR:' "$log_file"; then exit 1; fi
status=0
timeout 90 "${GODOT_BIN:-godot}" --headless --path "$PWD" tests/run.tscn > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then exit "$status"; fi
if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked' "$log_file"; then exit 1; fi
rg -q 'RESULT: [1-9][0-9]* passed, 0 failed' "$log_file"

status=0
timeout 90 "${GODOT_BIN:-godot}" --headless --path "$PWD" tests/art.tscn > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then exit "$status"; fi
if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked' "$log_file"; then exit 1; fi
rg -q 'ART RESULT: [1-9][0-9]* passed, 0 failed' "$log_file"

status=0
timeout 90 "${GODOT_BIN:-godot}" --headless --path "$PWD" tests/expansion.tscn > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then exit "$status"; fi
if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked' "$log_file"; then exit 1; fi
rg -q 'EXPANSION RESULT: [1-9][0-9]* passed, 0 failed' "$log_file"
python3 tools/verify_intros.py
