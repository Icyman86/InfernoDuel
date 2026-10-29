# Inferno Duel: Legends — V7 / 0.7.0

Made by Rens de Gee en Ted Sondervan.

[Download Android V7 APK](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.7.0-android/releases/android-v0.7.0/InfernoDuel-Android-v0.7.0.apk)

## What changed

**Six-character sessions.** CREATE SESSION opens a temporary room on the host
device and shows six random letters/numbers. The guest enters only those symbols
and taps CONNECT. All endpoint details are handled internally; no addresses are
displayed or entered. Both devices must run V7 on the same Wi-Fi with peer traffic
allowed. No extra server/account is hosted. Each chooses/readies their own fighter.
CANCEL SESSION closes a waiting room. Leaving ends the other device's match.

**Character presentations.** Fighters replaces the old movement tour/dummy/move
list with ten portrait cards and one short presentation per legend: a lit 3D
podium, perspective camera, extruded textured character silhouette and one signature
move, followed by a stationary breathing sprite. Replay, original reference sheet
and existing intro films remain available. This is a 2.5D use of existing illustrated
art, not ten new fully modelled/rigged 3D characters. Original pixels are unchanged.

**Modern combat UI.** A proportional left thumbstick with deadzone, BLOCK next
to it, large right ATTACK and smaller HEAVY/SPECIAL/ULT/JUMP around it. Readiness
rings show real special cooldown and ultimate meter. Round markers, health bars
and timer have cleaner styling. Multiple fingers can move/attack together. Stick
ownership stays with the initial thumb until release/cancel, even beyond its base.
Hold a direction or BLOCK with attacks for variants; ULT requires 100 meter.

Native device resolution, ten playable fighters, 69 moves, all original sheets and
ten intro films are retained. Android has one control set per device and no local
shared-screen versus. PLAY · TOUCH VS CPU remains offline. Android Back / Ⅱ and
backgrounding pause. All network pause requests must be released before resuming;
rematch needs both votes.

## Connection scope

The host phone/tablet manages the temporary session; the other device discovers
it by six-character code using local UDP, then opens a direct connection. **Same
Wi-Fi is required.** Guest Wi-Fi isolation/firewalls may prevent discovery. A code
alone cannot locate a private device across unrelated networks or bypass carrier
NAT. V7 has no Internet directory/relay/NAT-traversal service; different Wi-Fi
networks or 4G/5G are not automatically supported. No external hosting was deployed.
See [NETWORK](../../docs/NETWORK.md).

## Install / update

Android 7.0+ (API 24), 64-bit ARM or x86_64 Android OS, OpenGL ES 3.0 and multitouch.
Universal APK: 151,014,243 bytes (about 144 MiB), stored in Git LFS.
The direct link downloads the APK; a checkout needs git lfs pull. Allow installation
from the downloading browser/file manager. VersionCode 700 and the same retained
V6 development certificate allow an in-place update. No private keys are published.
This remains a sideload preview, not a Play Store release. INTERNET and
ACCESS_NETWORK_STATE are normal permissions for direct UDP networking.

## Validation

1,174 distinct automated assertions passed, plus a rendered repeat of the 25
real-network assertions. Eight original SHA-256 checks and ten full film decodes
passed separately. Tests cover all ten full presentation silhouettes, actual
signature-to-idle transitions, analog touch/drag/cancel, real broadcast room lookup,
ENet damage/pause/results/rematch/disconnect, native framebuffers and no visible
addresses. The native Linux release-engine package passes OS keyboard menu,
presentation, select, arena, combat, actual health damage, pause and normal Quit,
exit 0. Final logs have no engine/script errors or leaked-instance warnings.

The exact APK passes export, CRC/payload, v2/v3 signature, 16-KiB alignment,
manifest and retained-certificate checks. **Native Android end-to-end, physical
phone/tablet Wi-Fi, digitizer/cutout/audio and thermal/FPS acceptance are not
verified.** No physical device is attached. Linux/local-process results are not
Android device results. The 3D entrance uses existing art; physical rendering
performance and final human feel remain to be reviewed. Guest smoothing has no
prediction/rollback. See [TEST_LOG](../../docs/TEST_LOG.md) and [Android](../../docs/ANDROID.md).

Source milestone: 4d684ec12520b1df647e1d4825fc5437ef70b7df. SHA256SUMS identifies this APK;
validation/ retains source hashes, final logs, rendered evidence and native smoke
harness. Each future update gets a fresh version/code/path/tag. Older releases
and this V7 remain available; published APKs/tags are not overwritten.
