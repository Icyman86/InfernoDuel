# Inferno Duel: Legends — full roster + move lab v0.5.0

Made by Rens de Gee en Ted Sondervan.

[Download Android v0.5.0 APK](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.5.0-android/releases/android-v0.5.0/InfernoDuel-Android-v0.5.0.apk)

All **ten fighters** are playable, with **69 attacks/abilities**. The Fighters
page now has a live animated move lab: AUTO tours moves, and tapping a move
performs it with the same controller, projectiles, damage and costs as combat.
Original source sheets and all ten intro movies remain available. Nine new
reference-guided atlas images supply the five missing sets and additional
recognizable kick/bite/slam/wing poses. Original artwork remains unchanged.

Hold FORWARD / BACK / GUARD plus LIGHT, SPECIAL or ULT to perform named variants.
The move lab shows the exact binding, damage and meter cost. GUARD is also the
modifier on touchscreens. Armor halves damage; power buffs add 20%; Rebirth
costs 35 meter to escape hitstun and heal 8 HP; Eternal Flame costs 100 to heal
25 HP. Neither revives a KO. Volleys are capped at three single-hit objects.

Movement uses physics interpolation, responsive acceleration/reversal, a
160 ms attack buffer and a 120 ms landing jump buffer. Sprite poses blend over
55 ms and use velocity-driven gait and small secondary motion. These are
illustrated key-pose animations; some abilities share poses, and final balance,
more in-betweens and hands-on device feel remain open to refinement.

## Install

Android 7.0+ / API 24, a **64-bit ARM or x86_64 Android OS**, OpenGL ES 3.0 and
multitouch. The universal APK is approximately 151 MB (144 MiB), stored in Git LFS.
The direct link serves the APK; a checkout needs `git lfs pull`.

This sideloadable preview uses the same local development certificate as v0.4.0
and versionCode 500, so it can update that APK in place. Allow installation from
your downloading browser/file manager when Android asks. A differently signed
older build may need uninstalling first. No private keys are published. This is
not a Play Store release; no Internet permission or accounts are needed.

PLAY · TOUCH VS CPU is the phone default. 2 PLAYERS · SHARED TABLET has independent
cyan/orange pads for two people. Pick fighters, READY both sides, and enter the
arena. Left pad moves/jumps/guards, right pad attacks. ULT needs 100% meter.
Tap Ⅱ to pause; Android Back navigates or pauses. Lift and touch again after
countdown, pause and round changes.

## Validation

**1,055 automated assertions passed**, plus eight original artwork hashes and
full decoding of all ten films. This includes 896 headless gameplay/artwork/move
checks, 35 touch checks, 84 move-lab GUI/render checks, 9 Linux visual checks and
31 earlier sheet/intro/expansion visual checks. Every fighter's CPU won a full
normal-health match against a passive player. Every named move was executed and
its exact damage/effects/costs checked. The separate native Linux release package
passed menu/move lab/select/fight/damage/pause and normal Quit, exit 0.

The final APK passed export, v2/v3 signature, 16-KiB alignment, payload and CRC
checks. **Native Android end-to-end and physical phone/tablet acceptance are
not verified for v0.5.0.** The prior cloud TCG/SwiftShader emulator limitations
remain documented; source/Linus tests are not represented as device tests.
Hardware performance, audio, vendor cutouts, ergonomics and balance need real
devices and human play.

`SHA256SUMS` identifies the exact APK. `validation/` includes logs, source hashes,
native Linux evidence and representative move-lab/combat screenshots. See
[TEST_LOG](../../docs/TEST_LOG.md), [Android instructions](../../docs/ANDROID.md)
and [artwork provenance](../../docs/ART_PIPELINE.md).
