# Inferno Duel: Legends — V8 / 0.8.0

Made by Rens de Gee en Ted Sondervan.

[Download Android V8 APK](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.8.0-android/releases/android-v0.8.0/InfernoDuel-Android-v0.8.0.apk)

[Watch/download the scripted 60-fps movement preview](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.8.0-android/releases/android-v0.8.0/InfernoDuel-MovementPreview-v0.8.0.mp4)

## Persistent character podium

The entrance now retains the same 3D character, lights, camera, podium and rings.
After the move, the camera settles and the character breathes/sways in place.
There is no replacement by a different 2D sprite. Original sheet, return and replay
preserve the existing world and rings. All ten characters are covered by tests.

## Continuous movement

All ten fighters have start, brake, backstep, pivot, rise, apex, fall, landing and
guard-entry/exit clips, with individual stride, breathing, weight and lean profiles.
Walking uses 54 bidirectional motion fields analyzed from the existing pose art:
the GPU aligns adjacent poses and draws intermediate poses in one pass. Gait follows
analog movement speed and reverses for backstepping. Geometry and small GPU data
textures are cached; foot-pivot transforms, facing transitions and pause/round
resets improve continuity. Hitboxes, attacks, HP/meter and 60-Hz physics remain.

This uses motion-interpolated artwork and authored curves, not 60 independently
hand-drawn images per second or new fully modelled 3D characters. Original artwork
pixels and pose counts are unchanged. Small limb/occlusion warping can remain.
The video is a scripted offline animation review of all ten fighters, recorded at
60 FPS; it is not a live performance or human-play acceptance claim.

## Performance scope

Rendering targets 60 FPS while preserving native device resolution. Separate
actual wall-clock tests on the Linux llvmpipe software renderer measured about
59.92 FPS at 1280×720 and 41.24 FPS at 2400×1080 for V8. V7 was about 59.92 and
43.48 FPS in the same short workload. Animation continuity is improved; a general
engine speedup is not claimed, and wide software rendering does not reach 60 FPS.
Physical phone/tablet GPU performance, thermals and frame pacing remain unverified.
See [TEST_LOG](../../docs/TEST_LOG.md) for method, exact timings and limits.

## Install / retained features

Android 7.0+ (API 24), a 64-bit ARM or x86_64 Android OS, OpenGL ES 3.0 and multitouch.
Universal APK: 151,547,244 bytes (about 145 MiB), in Git LFS.
A checkout needs git lfs pull. Allow installation from your downloading browser
if Android asks. VersionCode 800 and the retained V7 development certificate allow
an in-place update. This remains a sideload preview, not a Play Store release.
No private keystores are published.

Native resolution, all ten playable fighters, 69 attacks, ten films, the modern
thumbstick/block/attack/skill controls and six-character host-device sessions remain.
Android has no shared-screen local versus; offline CPU remains available. Install
V8 on both devices for sessions. Same-Wi-Fi peer traffic is required; no external
hosting is needed there. Different networks / 4G / 5G still require a relay or NAT
traversal service, which is not included. See [NETWORK](../../docs/NETWORK.md).

## Validation

1,332 distinct automated source assertions passed, plus rendered network and
recorded movement repeats. Eight original hashes, ten films and the new complete
1,188-frame / 19.8-second MP4 decode passed separately. The exact APK passes
export, CRC/payload, compiled movement scripts/data, v2/v3 signatures, 16-KiB
alignment, manifest and update-certificate checks. The native Linux release engine
passes menu, podium, selection, combat, real damage, pause and normal Quit.
Final required logs have no script/engine errors or instance leaks.

No physical Android installation, Wi-Fi, digitizer, audio, cutout, thermal or
60-FPS acceptance is claimed. No device is attached. Original art remains unchanged.
Source milestone: 1a5085751190c78f748fd65fcb317fee0d2675df. SHA256SUMS identifies the APK and video;
validation/ includes final logs, timing data, source hashes, screenshots and the
native smoke harness. Every update gets a new version/code/path/tag; older releases
and this V8 remain available without overwriting published APKs or tags.
