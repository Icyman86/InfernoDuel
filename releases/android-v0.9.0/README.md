# Inferno Duel: Legends — V9 / 0.9.0

Made by Rens de Gee en Ted Sondervan.

[Download Android V9 APK](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.9.0-android/releases/android-v0.9.0/InfernoDuel-Android-v0.9.0.apk)

[Watch/download the combat animation preview](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.9.0-android/releases/android-v0.9.0/InfernoDuel-CombatPreview-v0.9.0.mp4)

## Continuous attacks and steadier walking

All ten fighters now have continuous anticipation, chamber, extension/contact,
recovery and idle return across 49 attack clips. Another 266 bidirectional motion
fields align the existing drawings; eased in-betweens render throughout the move.
A planted support-foot pivot keeps kicks stable. The Fighters podium uses the
same signature interpolation and retains the same lit character, camera and rings.

Walking uses 54 re-analyzed fields with stable torso/ground anchors. Two-step
stride lengths, less extra bounce and zero grounded offsets reduce hopping and
sliding. Gait follows actual resolved locomotion distance, including partial
thumbstick input, wall/opponent collision and smoothed guest snapshots. Starts,
brakes, pivots, jumping/landing and guard transitions remain character-specific.

This animates existing illustrated artwork. Original PNG pixels and source sheets
remain unchanged; these are derived in-betweens, not independently hand-drawn
frames or new fully rigged 3D models. Limb occlusion/warping artifacts can remain.

## Combat UI and usable ultimates

Angular dark HUD plates frame the health and animated energy bars. At 100 meter
the ultimate bar pulses gold, with a matching halo around the ULT touch button.
Every fighter has **200 HP**. Clean received damage grants **35% of actual damage
as meter, rounded up**; guard retains four. Costs, base damage, hitboxes and
60-Hz simulation remain. The meter caps at 100 and an ultimate spends 100.
All ten fighters pass a normal-input test earning, spending and landing an
ultimate from full health and zero meter while the opponent is still alive.

The preview shows all ten heavy attacks in scripted slow motion and a
ready-meter UI fixture. It is recorded offline at 60 video FPS, 1280×720,
1,111 frames / 18.516667 seconds. It is not a live frame-rate or combat-balance
measurement. Separate normal-input tests establish meter availability.

## Install and retained features

Android 7.0+ / API 24, 64-bit ARM or x86_64 Android OS, OpenGL ES 3.0 and multitouch.
The universal APK is 153,018,490 bytes (about 146 MiB), stored in Git LFS.
The direct link serves the APK; a source checkout needs git lfs pull.
VersionCode 900 and the retained V4–V8 development certificate permit an in-place
update. This is a sideload preview, not a Play Store release. No keys are published.

Native device resolution, ten playable fighters, 69 moves, ten films, left
thumbstick/BLOCK, right ATTACK and surrounding skills remain. Six-character
host-device sessions connect directly on the same Wi-Fi without external hosting.
Install V9 on both devices. Android has no shared-screen local versus; offline
CPU remains. Different networks / 4G / 5G need a relay/NAT traversal service,
which is not included. See [NETWORK](../../docs/NETWORK.md).

## Validation and limits

**1,512 distinct automated source assertions pass**, plus a real rendered network
repeat and direct quality repeat. Checks cover all moves/fighters, whole attack
clips and support feet, actual rendered in-betweens/gold pixels, wall/opponent
gait, 200-HP HUD, normal-input ultimate use, healing, pause, multitouch, persistent
podiums, discovery, ENet and native framebuffer sizes. Eight original art hashes
and ten intro films pass separately. The native Linux release engine + PCK passes
menu/Fighters/select/arena/fight/visible damage/pause and normal Quit.

The exact APK passes export, payload/CRC, v2/v3 signing, 16-KiB native alignment,
manifest/version/ABI and retained-certificate checks. Final logs have no engine
or script errors or leaked instances. SHA256SUMS identifies both artifacts;
validation/ contains logs, screenshots, source hashes and the native smoke helper.
Source milestone: 1585cef923872b11d5282d90c7ff2d10a608e6e9.

Rendering targets 60 FPS at native resolution. Short final Linux llvmpipe
software-renderer runs measured 59.87 FPS at 1280×720 and 43.62 FPS at 2400×1080.
The wide workload misses 60 FPS; these are not a controlled speedup comparison
or phone GPU measurements. Physical Android installation, Wi-Fi, digitizer,
cutouts, audio, thermals and frame pacing are unverified: no device is attached.
See [TEST_LOG](../../docs/TEST_LOG.md) for exact methods and limits.
Older published APKs and tags are retained; V9 gets its own version/code/path/tag.
