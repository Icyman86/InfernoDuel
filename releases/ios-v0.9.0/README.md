# Inferno Duel 0.9 — iPhone export and installation

[Download the Mac/Xcode build package](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.9.0-ios-project/releases/ios-v0.9.0/InfernoDuel-Xcode-v0.9.0.zip)

**This ZIP is not an installable IPA.** It contains the complete verified Xcode
export, official Godot iOS engine, game pack and standalone BUILD_IPA.command.
A Mac with full Xcode can build it without installing Godot. The generated
unsigned IPA is then signed and installed through AltStore Classic + AltServer
using the owner's Apple Account. See [the Dutch installation guide](IPHONE_INSTALLATIE.md).

For a build without your own Mac, open the
[iPhone GitHub workflow](https://github.com/Icyman86/InfernoDuel/actions/workflows/ios.yml),
choose Run workflow from main with release_tag v0.9.0-ios, and start it.
Only after success does the workflow publish the device IPA to the
[iOS release](https://github.com/Icyman86/InfernoDuel/releases/tag/v0.9.0-ios).

No IPA has been built here: this cloud executor runs Linux, not macOS/Xcode.
Git pushes succeeded, but no Actions run started and the Actions API returned
Forbidden, so a repository owner must start the workflow. No working iPhone
installation or Metal/device/Wi-Fi/FPS acceptance is claimed.

The exported source passes 1,004 gameplay/art/roster, touch, native-layout,
iOS/mobile/unicast and actual multi-process network assertions. All exported PCK
file hashes, compiled platform code, ten fighters, 69 moves, 49 action clips,
ten films, landscape metadata and ARM64 device engine presence pass. Original
art hashes remain unchanged. The archive itself passes complete ZIP CRC checks.
Source: 068c3f6aa2c25dcf79d502a5de04a7715159c59c; archive: 203,444,092 bytes; SHA256SUMS records its hash.
Validation logs are included under validation/.

The app targets iOS 15+, ARM64, native resolution and landscape. iPhone uses
bounded private-/24 unicast discovery; use Android as host with the retained
Android V9 APK. CPU play works independently of discovery. Physical iPhone
behavior remains unverified. Version 0.9.0 and the previous Android release are
retained as requested. An APK or source-code ZIP cannot be installed on an iPhone.
