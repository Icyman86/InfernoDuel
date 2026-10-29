#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p builds/v8-benchmark
python3 - <<'PY'
from pathlib import Path
import subprocess
prefix = 'v0.7.0-android:'
script = subprocess.check_output(['git','show',prefix+'scripts/combat/fighter_visual.gd'],text=True)
script = script.replace('class_name FighterVisual\n','').replace('res://assets/shaders/fighter.gdshader','res://builds/v8-benchmark/baseline.gdshader')
Path('builds/v8-benchmark/baseline_visual.gd').write_text(script)
Path('builds/v8-benchmark/baseline.gdshader').write_text(subprocess.check_output(['git','show',prefix+'assets/shaders/fighter.gdshader'],text=True))
PY
for resolution in 1280x720 2400x1080; do
  "${GODOT_BIN:-godot}" --path "$PWD" --audio-driver Dummy tests/motion_benchmark.tscn -- --baseline "--size=$resolution"
  "${GODOT_BIN:-godot}" --path "$PWD" --audio-driver Dummy tests/motion_benchmark.tscn -- "--size=$resolution"
done
