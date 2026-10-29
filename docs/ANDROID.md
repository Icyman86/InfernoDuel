# Android preview v0.4.0

The first Android milestone adds native Godot touch play to the existing Linux
prototype. Five fighters and ten intro films are included. No browser wrapper,
accounts, online services or Internet permission are required.

## Install and play

Download the APK linked in the main README. Requirements: Android 7.0 / API 24 or
later, a 64-bit ARM or x86_64 Android OS, OpenGL ES 3.0 and multitouch. The target
SDK is 36. Both phones and tablets run in landscape; 32-bit Android is unsupported.
The 125 MiB universal APK includes ARM64 and x86_64 in the same signed file.

Enable installation from the downloading browser/file manager if Android asks.
This preview uses a local Android development key. Keep that keystore locally to
sign future updates; builds made with another key require uninstalling the old
app first (which clears its settings). Production distribution needs a private
release key and an Android App Bundle / store validation as a separate step.
No keystore or password file is committed to Git.

Choose PLAY for phone/solo play against CPU. On tablets, 2 PLAYERS provides two
independent sets of touch controls. Pick the fighters with the cards and EDIT
P1/P2 buttons, then READY both and enter the arena. The left pair moves, JUMP
jumps, GUARD blocks while facing the attacker; LIGHT, HEAVY, SPECIAL and ULT
trigger attacks. Ultimate requires 100% meter. Buttons can be held with different
fingers; releasing or dragging outside releases that contact. Countdown, round
changes, pause and focus changes clear old contacts; lift and touch again when
play resumes. Two people sharing a small phone screen is possible but cramped;
solo is the phone default. Menus, gallery, movies, options and results use taps.

Android Back navigates back or pauses the fight. The on-screen pause button
provides resume, restart, options and main menu. Backgrounding the app pauses
combat and clears touches. Audio sliders persist locally; Android options replace
desktop window controls with mobile instructions. Display safe-area fitting avoids
cutouts and system bars. The game does not claim a physical device performance or
ergonomics guarantee from desktop/emulator tests.

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
./tools/test.sh                       # existing 344 gameplay/artwork assertions + ten films
./tools/test_touch.sh                 # requires a graphical display; 33 touch checks
godot --path . --audio-driver Dummy tests/visual.tscn
godot --path . -- --touch              # manual desktop preview of the touch UI
```

The rendered touch suite injects real screen-touch/drag/cancel events. It covers
multiple contacts, single attack edges and damage, drag release, keyboard/touch
independence, pause/resume, background input clearing, mobile options, Android
back routing and independent shared-player controls. Layout checks use actual
SubViewports at 1280x720, 1920x1080, 1280x800, 1024x768 and 1600x720, in both
solo and shared modes. They reject overlapping or clipped controls. This does
not simulate a particular vendor's cutout or digitizer hardware.

APK checks are separate from gameplay tests: `apksigner verify --verbose`,
`zipalign -c -P 16 4`, `python3 tools/verify_apk.py <file>`, manifest inspection,
and native Android install/launch. See TEST_LOG and the release validation files
for actual results and limits. Godot 4.6 uses an exported launcher alias; start
`org.infernoduel.legends/com.godot.game.GodotAppLauncher`, not its internal activity.

Physical phone/tablet multitouch, speaker quality, thermal behavior, vendor
cutouts, suspend/resume over long periods and two-human ergonomics still need
on-device acceptance. Story, five additional combat sets, online multiplayer
and Play Store publication remain outside this preview.
