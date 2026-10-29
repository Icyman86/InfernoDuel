#!/usr/bin/env bash
# Build an unsigned device IPA. AltStore signs it locally using the owner's account.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "$(uname -s)" != Darwin ] || ! command -v xcodebuild >/dev/null; then
  printf 'An iPhone IPA requires macOS with full Xcode. Use the iOS GitHub Actions workflow or a Mac.\n' >&2
  exit 2
fi
xcrun --sdk iphoneos --show-sdk-path
./tools/export_ios_project.sh
xcodebuild -project builds/ios/InfernoDuel.xcodeproj -scheme InfernoDuel \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath "$PWD/builds/ios-derived" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' \
  DEVELOPMENT_TEAM='' ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
  DEBUG_INFORMATION_FORMAT=dwarf build
python3 tools/package_ios.py builds/ios-derived/Build/Products/Release-iphoneos/InfernoDuel.app
