# Android preview V6 / v0.6.0

Native Godot touch play includes all ten fighters, 69 attacks/abilities, the
interactive animated move lab and ten intro films. V6 renders at the device's
actual surface resolution and replaces Android shared-screen versus with direct
session-code play between two devices. Offline CPU remains available. The APK
now requests normal INTERNET and ACCESS_NETWORK_STATE permissions for ENet UDP;
there is no account or hosted matchmaking service.

## Install and play

Download the APK linked in the main README. Requirements: Android 7.0 / API 24 or
later, a 64-bit ARM or x86_64 Android OS, OpenGL ES 3.0 and multitouch. The target
SDK is 36. Phones and tablets run in landscape; 32-bit Android is unsupported.
The universal APK contains both ARM64 and x86_64 engines.

Enable installation from the downloading browser/file manager if Android asks.
This preview uses the same retained local development certificate as v0.4/v0.5,
with versionCode 600, allowing an in-place update. Keep the keystore locally for
future updates. Production distribution needs a private release key and separate
store validation. No keystore or password file is committed to Git.

For two players, choose CONNECT · SESSION CODE on each device. On the same Wi-Fi,
one player selects the Wi-Fi IPv4 address and taps CREATE SESSION, then shares
the complete ID6 code. The other pastes the code and taps CONNECT. Each chooses
and readies their own fighter; the match starts when both are ready. Each device
has one touchpad. There is no Android local/shared-tablet versus. Direct codes
require an actually reachable host: guest Wi-Fi isolation and firewalls can block
it. Different networks / 4G / 5G need routing or a relay; V6 does not include a
public relay or automatic NAT traversal. See [NETWORK.md](NETWORK.md).

Choose PLAY · TOUCH VS CPU for offline solo. Select the fighters, using EDIT CPU
for the opponent, then READY both and enter the arena. Left controls move, jump
and guard; right controls perform light, heavy, special and ultimate. Ultimate
needs 100 meter. Hold forward/back/guard with attacks for directional variants;
the move lab lists the exact bindings. Guard plus special works with two contacts.
Drag outside or release to stop a contact; countdown, rounds, pause and focus
changes clear contacts. Lift and touch again when play resumes.

Android Back returns or pauses. The pause button opens resume, options and main
menu; offline play also offers restart. Backgrounding pauses combat and clears
touches. Either connected player can pause; both must release their pause request
before the match continues. Results offer a mutual-vote rematch. Leaving ends the
session for the other player, with a readable reconnect message.

The viewport follows native surface dimensions, including resize changes. Menus,
arena and touch controls scale into the safe area while preserving proportions;
the logical 1280×720 arena is not a fixed rendering resolution. Options reports
current surface pixels. High-DPI, wide-phone and tablet layouts are supported;
physical vendor cutouts and performance still need on-device acceptance.

## Reproduce the APK

Use the standard Godot **4.6.3** editor, the official matching export templates,
Java (this build used OpenJDK 21), Python 3, Android SDK platform-tools and
build-tools **35.0.1**. Android platform 35 is present in the tested SDK;
non-Gradle export uses the official template compiled against SDK 36. Android
Studio, Gradle and the NDK are unnecessary for this GDScript/template build.
Install SDK components from Google and templates from the official Godot release;
retain their published checksum/signature validation.

```bash
export ANDROID_HOME=/workspace/.runtime/android-sdk
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export XDG_DATA_HOME=/workspace/.runtime/data
export XDG_CONFIG_HOME=/workspace/.runtime/config
export XDG_CACHE_HOME=/workspace/.runtime/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
cd /workspace/InfernoDuel
./tools/build_android.sh
```

Adjust paths for another machine. The script initializes editor imports, updates
only the current user's SDK paths, exports with the release engine, signs with
the local development keystore, checks APK v2/v3 signatures, checks 16-KiB native
alignment, inspects the payload and writes SHA-256. Output is under
`builds/android/`. Android export enables ETC2/ASTC imports; Linux continues using
the Compatibility renderer and existing imports. Keep `builds/` and local
keystores out of Git. Fetching the published APK through a checkout requires Git LFS.

## Tests

```bash
./tools/test.sh                       # 896 gameplay/artwork/move checks + ten films
./tools/test_touch.sh                 # requires a graphical display; 35 touch checks
godot --path . --audio-driver Dummy tests/visual.tscn
./tools/test_gallery.sh               # 84 actual gallery clicks/render checks
TEST_NETWORK_RENDERED=1 ./tools/test_v6.sh # session, real peers and native-resolution checks
godot --path . -- --touch              # manual desktop preview of the touch UI
```

The touch suite injects screen-touch/drag/cancel events and checks multiple
contacts, attack edges and damage, drag release, keyboard isolation, pause/resume,
background clearing, Android Back, directional abilities and mobile options.
The legacy two-pad component layout is tested in isolation for desktop reuse;
it cannot be entered through Android's menu or match routes.

V6 adds 35 session/code/input checks, a real three-process network test (host,
rejected invitation and valid guest; 25 checks, also repeated with rendering),
and 20 rendered native-resolution/routing checks. Actual framebuffer readbacks
cover 960×540, 1280×720, 1920×1080, 2560×1440, 1280×800, 1024×768 and 2400×1080.
This does not simulate a vendor cutout or physical digitizer. Network validation
uses loopback UDP with separate Godot processes, not two physical Android devices.

APK checks are separate: apksigner verification, 16-KiB zipalign, full archive
CRCs, payload inspection and manifest inspection. Godot 4.6's exported launcher
alias is org.infernoduel.legends/com.godot.game.GodotAppLauncher.

The final APK is export/signature/alignment/payload verified; game source and the
native Linux release package are tested on Linux. Native Android end-to-end
acceptance remains unverified: no phone/tablet is attached, and earlier software
emulator limitations are recorded in TEST_LOG. Test this exact APK on two devices
for installation/update, Wi-Fi invitations, both owned selections, movement,
attacks, pause/background/resume, rematch and disconnect. Check speakers, thermal
behavior, real multitouch, cutouts and high-resolution frame rate. No physical
Android success or public Internet service is claimed.

Every published change receives a new version/code, path and tag. Published APKs
are retained; future releases must not silently replace V6.
