#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
log_file=$(mktemp)
trap 'rm -f "$log_file"' EXIT
status=0
args=(--headless)
extra=()
if [ "${TEST_V12_RENDERED:-0}" = 1 ]; then args=(); extra=(--rendered); fi
timeout 180 "${GODOT_BIN:-godot}" "${args[@]}" --path "$PWD" --audio-driver Dummy tests/v12.tscn -- "${extra[@]}" > "$log_file" 2>&1 || status=$?
cat "$log_file"
if [ "$status" -ne 0 ]; then exit "$status"; fi
if rg -q 'SCRIPT ERROR|^ERROR:|instances leaked' "$log_file"; then exit 1; fi
rg -q 'V12 RESULT: [1-9][0-9]* passed, 0 failed' "$log_file"
