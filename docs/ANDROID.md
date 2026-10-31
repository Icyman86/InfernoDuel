# Android V17

Nieuwste build: [menuherstel en vier storylevels](V17_ANDROID.md).
Installeer over de bestaande preview; beide apparaten gebruiken V17 voor wifi.

# Android V16

Nieuwste build: [Bamboo Blade, Sawtina en coins](V16_ANDROID.md).
De V16-preview werkt de bestaande preview bij; beide spelers gebruiken V16 voor een sessie.

# V15 / 0.15.0 — Crystal Fang zijn mijn

Zie [V15 Android](V15_ANDROID.md) voor de vierde arena en de preview-update.

# V14 / 0.14.0 — aparte arena/ultimate-preview

Zie [V14 Android](V14_ANDROID.md) voor de gekozen maps, random/host-keuze,
ultimate power en het aparte preview-pakket dat naast V11 installeert.
De eerdere signing- en releasegegevens hieronder blijven historische V11/V10-informatie.

# V11 / 0.11.0 portrait update

VersionCode 1100; same signing certificate and installation requirements as V10.
Character select uses ten new frontal half-body shots looking at the player.
Both players need V11 for sessions. V10 implementation details follow.

# Android V10 / 0.10.0

V10 uses the native device resolution and modernizes the combat controls and
Fighters screen. The hosting device creates a temporary session with six random
letters/numbers; the other device connects with only that code. IP addresses are
absent from the UI. No external server needs to be hosted for same-Wi-Fi play.

## Install and play

Download the APK in README. Android 7.0+ (API 24), a 64-bit ARM or x86_64 Android
OS, OpenGL ES 3.0 and multitouch are required. Target SDK: 36. Landscape phones
and tablets are supported; 32-bit Android is not. This sideload preview uses the
retained v0.4–v0.9 development certificate and versionCode 1000 for in-place
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
move, then keeps the same lit character, 3D podium and rings during breathing idle. It uses extruded illustrated silhouettes
from the existing validated atlases (2.5D), not fully modelled skeletal characters.
REPLAY PRESENTATION, ORIGINAL SHEET and PLAY INTRO remain available. The old
move-lab animation tour and executable move list have been removed.

V10 adds 240 separately illustrated poses: twelve walk and twelve heavy poses for
every fighter. The renderer switches intact drawings without UV interpolation,
mesh morphing or crossfade ghosts. Heavy contact remains aligned with the active
hitbox. The remaining attacks use their existing drawn keys. Walking advances
from actual resolved travel, including wall/opponent stops. Character select has
ten new high-resolution half-body portraits with subtle rigid image motion.
The Fighters podium keeps its lit character and rings after the signature.
Angular combat panels and animated ultimate gauges pulse gold at 100 meter,
along with the ULT touch button. Every fighter has 200 HP. Clean incoming damage
also grants ceil(damage × 0.35) meter; guard grants four and meter caps at 100.
Normal attack costs, damage, hitboxes and 60-Hz physics remain as documented.
New drawings are reference-guided generated art, not original user artwork or
motion capture. Twelve illustrated poses per cycle are distinct from render FPS. The render cap targets 60 FPS;
real-device frame rates are unverified.

The viewport tracks real surface pixels. Scenery extends across the entire
screen, with a stable floor under the fighters. Fighters use uniform scaling;
HUD and touch controls use the same safe area. The combat simulation keeps its
fixed logical bounds for consistent play across devices. No fixed 1280×720 render
target is forced. Six native framebuffer sizes cover wide phones, 16:9 and 4:3
tablets, including OnePlus 13R 2780×1264; this is Linux layout testing rather than
a physical OnePlus run. Normal
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
idle transitions, and TEST_NETWORK_RENDERED=1 ./tools/test_v10.sh for room codes,
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
none is hosted or included in V10. Every update gets its own version/code/path/tag.
