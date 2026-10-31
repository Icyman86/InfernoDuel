#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
log=$(mktemp)
trap 'rm -f "$log"' EXIT
status=0
timeout 120 "${GODOT_BIN:-godot}" --path "$PWD" --audio-driver Dummy tests/arenas_ultimate.tscn -- --touch > "$log" 2>&1 || status=$?
cat "$log"
if [ "$status" -ne 0 ]; then exit "$status"; fi
if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked|^FAIL' "$log"; then exit 1; fi
rg -q 'ARENAS ULTIMATE RESULT: [1-9][0-9]* passed, 0 failed' "$log"
