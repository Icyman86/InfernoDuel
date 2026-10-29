#!/usr/bin/env bash
# Generates an Xcode project; this does not claim to build an installable IPA.
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin=${GODOT_BIN:-godot}
mkdir -p builds/ios
"$godot_bin" --headless --path "$PWD" --editor --import
"$godot_bin" --headless --path "$PWD" --export-release iOS builds/ios/InfernoDuel.ipa
python3 tools/verify_ios.py --project builds/ios
printf 'Xcode project exported: %s/builds/ios/InfernoDuel.xcodeproj\n' "$PWD"
