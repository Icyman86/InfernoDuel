# Android V7 / 0.7.0

V7 uses the native device resolution and modernizes the combat controls and
Fighters screen. The hosting device creates a temporary session with six random
letters/numbers; the other device connects with only that code. IP addresses are
absent from the UI. No external server needs to be hosted for same-Wi-Fi play.

## Install and play

Download the APK in README. Android 7.0+ (API 24), a 64-bit ARM or x86_64 Android
OS, OpenGL ES 3.0 and multitouch are required. Target SDK: 36. Landscape phones
and tablets are supported; 32-bit Android is not. This sideload preview uses the
retained v0.4/v0.5/v0.6 development certificate and versionCode 700 for in-place
updates. It is not a Play Store release; private production signing is separate.

CONNECT · SESSION CODE: host taps CREATE SESSION and shares six characters.
Guest enters the code and taps CONNECT. Keep both games open on the same Wi-Fi.
The host advertises a room over local UDP; the guest finds it automatically and
opens the direct ENet connection. Each chooses/readies their own fighter. No
address entry or selection is needed. CANCEL closes the room and allows another
one. No Android local/shared-tablet versus exists. PLAY · TOUCH VS CPU remains
offline. See NETWORK.md for peer isolation, firewall and Internet limitations.

Combat has a left thumbstick with a deadzone and proportional horizontal motion,
BLOCK next to it, and a large ATTACK button on the right. HEAVY, SPECIAL, ULT and
JUMP sit around ATTACK. Special cooldown and ultimate meter appear as rings.
Hold a direction or BLOCK with attacks for directional variants. ULT needs 100
meter. The stick retains its owning finger beyond its base and clamps its range;
release/cancel recenters it. A second finger cannot take it over. Attack contacts
release when dragged outside. Multiple contacts can move, block and attack.
Android Back / Ⅱ pauses; backgrounding, rounds and countdown clear contacts.
Lift and touch again after transitions. Either connected player can pause; all
pause requests must be released before continuing. Rematch needs both votes.

Fighters has one perspective 3D podium presentation per selection, one signature
move, then stationary breathing idle. It uses extruded illustrated silhouettes
from the existing validated atlases (2.5D), not fully modelled skeletal characters.
REPLAY PRESENTATION, ORIGINAL SHEET and PLAY INTRO remain available. The old
move-lab animation tour and executable move list have been removed.

The viewport tracks real surface pixels; the logical arena preserves proportions
inside the safe rectangle. No fixed 1280×720 render target is forced. Normal
INTERNET and ACCESS_NETWORK_STATE permissions support direct UDP play. Broadcast
discovery uses IPv4 UDP, not multicast; there is no hosted directory or relay.

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

## Validation and limits

Run ./tools/test.sh for gameplay/artwork/roster and films, ./tools/test_touch.sh
for injected multitouch, ./tools/test_gallery.sh for all ten presentations and
idle transitions, and TEST_NETWORK_RENDERED=1 ./tools/test_v7.sh for room codes,
real broadcast discovery/ENet processes, native framebuffers and mobile UI.
Graphical tests need DISPLAY; headless tests are not native Android execution.

The final APK is checked by apksigner, zipalign -c -P 16 4, full archive CRCs,
compiled-script/payload inspection and aapt manifest inspection. For launching
Godot 4.6 use org.infernoduel.legends/com.godot.game.GodotAppLauncher.
No keystores are committed; retain the local development key for future updates.

Native Android end-to-end and physical two-device Wi-Fi acceptance still need
real phones/tablets. No devices are attached; earlier software-emulator limits
remain documented in TEST_LOG. Check this exact APK for installation/update,
room create/join/cancel, owned touch movement and attacks, pause/background,
results/rematch/disconnect, real multitouch, cutouts, speakers, thermals and frame
rate at native resolution. Linux/loopback results do not establish those results.
Different Wi-Fi networks / 4G / 5G generally need a relay or NAT traversal service;
none is hosted or included in V7. Every update gets its own version/code/path/tag.
