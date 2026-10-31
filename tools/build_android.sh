#!/usr/bin/env bash
# Sideloadable preview, using the official release engine and a local debug key.
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin=${GODOT_BIN:-godot}
: "${ANDROID_HOME:?Set ANDROID_HOME to the Android SDK directory}"
: "${JAVA_HOME:?Set JAVA_HOME to a Java installation containing bin/java and bin/keytool}"
build_tools=${ANDROID_BUILD_TOOLS:-35.0.1}
signer="$ANDROID_HOME/build-tools/$build_tools/apksigner"
aligner="$ANDROID_HOME/build-tools/$build_tools/zipalign"
test -x "$signer"
test -x "$aligner"
test -x "$JAVA_HOME/bin/keytool"
mkdir -p builds/android
"$godot_bin" --headless --path "$PWD" --editor --quit
# The editor has now created its user settings. Update only the two SDK paths;
# running a replacement SceneTree inside the editor leaves editor RIDs behind.
python3 - <<'PY'
import json, os, re
from pathlib import Path
settings = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'godot/editor_settings-4.6.tres'
text = settings.read_text()
for name, value in [('android_sdk_path', os.environ['ANDROID_HOME']), ('java_sdk_path', os.environ['JAVA_HOME'])]:
    key = 'export/android/' + name
    line = key + ' = ' + json.dumps(str(Path(value).resolve()))
    if re.search(r'^' + re.escape(key) + r' = .*$', text, flags=re.M):
        text = re.sub(r'^' + re.escape(key) + r' = .*$', lambda _: line, text, flags=re.M)
    else:
        text += '\n' + line + '\n'
settings.write_text(text)
PY
version=$(python3 -c 'import re; print(re.search(r"config/version=\"([^\"]+)\"", open("project.godot").read())[1])')
suffix=${ANDROID_OUTPUT_SUFFIX:-}
unsigned="builds/android/InfernoDuel-Android-v$version$suffix-unsigned.apk"
output="builds/android/InfernoDuel-Android-v$version$suffix.apk"
"$godot_bin" --headless --path "$PWD" --export-release "${ANDROID_PRESET:-Android}" "$unsigned"
# Android's standard development credentials are public by design. Never use
# this key for Play Store distribution. Keep private production keys out of Git.
keystore="${XDG_DATA_HOME:-$HOME/.local/share}/godot/keystores/debug.keystore"
if [ ! -f "$keystore" ]; then
  mkdir -p "$(dirname "$keystore")"
  "$JAVA_HOME/bin/keytool" -genkeypair -keystore "$keystore" -storepass android \
    -alias androiddebugkey -keypass android -dname "CN=Android Debug,O=Android,C=US" \
    -keyalg RSA -keysize 2048 -validity 10000 -storetype JKS
fi
# The normal package must keep V11's public signing identity. A fresh editor
# can create a different debug key; that key is only valid for the preview ID.
if [ "${ANDROID_PRESET:-Android}" = Android ]; then
  python3 - "$JAVA_HOME/bin/keytool" "$keystore" <<'CHECK_CERT'
import subprocess, sys, re
result = subprocess.run([sys.argv[1], '-list', '-v', '-keystore', sys.argv[2],
                         '-storepass', 'android', '-alias', 'androiddebugkey',
                         '-J-Duser.language=en'], capture_output=True, text=True, check=True)
match = re.search(r'SHA256:\s*([A-Fa-f0-9:]+)', result.stdout)
expected = 'bf325c42dd009bd6a6309692bfbbf46a9b3448a807a8718a284e0b8a8c5ab48c'
if not match or match.group(1).replace(':', '').lower() != expected:
    raise SystemExit('V11 signing key is required for Android updates. Use ANDROID_PRESET="Android Preview" and ANDROID_OUTPUT_SUFFIX=-preview for a separate test app.')
CHECK_CERT
fi
"$signer" sign --ks "$keystore" --ks-key-alias androiddebugkey \
  --ks-pass pass:android --key-pass pass:android --out "$output" "$unsigned"
"$signer" verify --verbose --print-certs "$output"
"$aligner" -c -P 16 4 "$output"
python3 tools/verify_apk.py "$output"
sha256sum "$output" > "$output.sha256"
printf 'Built: %s/%s\n' "$PWD" "$output"
