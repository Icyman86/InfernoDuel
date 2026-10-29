# Inferno Duel: Legends — V6 / 0.6.0

Made by Rens de Gee en Ted Sondervan.

[Download Android V6 APK](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.6.0-android/releases/android-v0.6.0/InfernoDuel-Android-v0.6.0.apk)

V6 renders at the actual device surface resolution, including changes. The arena
keeps its proportions and the touch controls fit the safe area. Android local
versus / shared-tablet mode is replaced by **CONNECT · SESSION CODE** between two
devices. Each chooses their own fighter and uses one local touchpad. Offline
**PLAY · TOUCH VS CPU** remains available. All ten fighters, 69 moves, animated
interactive move lab and ten intro films from V5 are retained.

## Connect two devices

Both devices must run V6 and be on the same Wi-Fi / reachable IPv4 network.
Host: CREATE SESSION, then COPY CODE. Guest: paste the complete ID6 code and
CONNECT. Choose and ready your own fighter; both ready starts the fight. Either
player may pause; all pause requests must be released to continue. Rematch needs
both players. Leaving stops the other device's match with a connection message.

**Direct codes require a reachable host.** Other Wi-Fi networks or 4G/5G need
routing or a relay. V6 includes no public relay, matchmaking or automatic NAT
traversal. Guest Wi-Fi isolation/firewalls may prevent even same-Wi-Fi play.
See [connection instructions](../../docs/NETWORK.md).

## Install / update

Android 7.0+ (API 24), 64-bit ARM or x86_64 Android OS, OpenGL ES 3.0 and multitouch.
Universal APK: 151,001,589 bytes (approximately 144 MiB), stored in Git LFS.
The link downloads the APK; a source checkout needs git lfs pull. Allow installation
from your downloading browser/file manager when Android asks. VersionCode 600 and
the same retained v0.4/v0.5 development certificate support an in-place update.
This is a sideload preview, not a Play Store release. The APK requests INTERNET
and ACCESS_NETWORK_STATE for direct network play. No account or keys are required.

## Validation

1,135 distinct automated assertions passed; the 25 real multi-process network
assertions also passed with rendering (1,160 successful assertion executions).
Eight original artwork hashes and ten full film decodes passed separately. Native
framebuffer checks cover seven phone/tablet/window sizes up to 2560×1440. A native
Linux release-engine + PCK passed the menu, move lab, select, fight, visible damage,
pause and normal Quit with exit 0. Final suites have no script/engine errors or
leaked-instance warnings.

The final APK passes export, CRC/payload, manifest, v2/v3 signature and 16-KiB
alignment checks. Native Android end-to-end, two physical devices over Wi-Fi,
real multitouch, cutouts, sound and high-resolution thermal/FPS acceptance are
**not verified** in this cloud environment. Loopback/Linux tests do not establish
Android device acceptance. Guest smoothing has no prediction/rollback. Details:
[TEST_LOG](../../docs/TEST_LOG.md), [Android build](../../docs/ANDROID.md).

Source milestone: 41fd91c3556bafc8a7a73523b042556a8c2d7c3d. SHA256SUMS identifies this exact APK;
validation/ contains final logs, results, source hashes and rendered evidence.
Future updates receive a new version, versionCode, APK path and tag. V6 and all
previous published APKs/tags are retained.
