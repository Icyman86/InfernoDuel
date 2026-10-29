# Inferno Duel: Legends — Android preview v0.4.0

Made by Rens de Gee en Ted Sondervan.

[Download the APK directly](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.4.0-android/releases/android-v0.4.0/InfernoDuel-Android-v0.4.0.apk)

Android 7.0+, **64-bit ARM or x86_64 Android OS**, OpenGL ES 3.0, multitouch.
Landscape phones and tablets. This APK includes both engines and all ten films;
it is approximately 125 MiB and stored in Git LFS. Download the actual APK through
the link above; a checkout uses `git lfs pull`.

Install from your browser/downloads, allowing that installation source when
Android asks. This is a sideloadable **test version signed with a local
development key**, not a Play Store release. No Internet permission or accounts
are needed. Rebuilds with another signing key require uninstalling the old app.

PLAY · TOUCH VS CPU is the phone default. 2 PLAYERS · SHARED TABLET provides
independent cyan/orange pads for two people on the same screen. Choose fighters,
READY both sides and enter the arena. Left pad moves/jumps/guards; right pad
attacks. ULT needs 100% meter. Tap Ⅱ to pause; Android Back navigates or pauses.
Lift and touch again after countdowns, pauses or round transitions.

The final artifact passed export, APK v2/v3 signature, 16-KiB alignment, payload
and CRC checks. The source passed 344 gameplay/artwork assertions, 33 rendered
touch checks, 9 rendered Linux checks and full decoding of ten films.
**Native Android end-to-end validation of this final APK is incomplete.** The
cloud software emulator encountered a SwiftShader shader limit; ANGLE reached
the engine main loop with an earlier candidate, but installing the final APK
timed out. No real phone/tablet was available. Please treat this as a preview
requiring device acceptance, not a certified fully tested Android release.

`SHA256SUMS` identifies the exact download. `validation/` contains build/test logs,
source hashes and emulator diagnostic evidence. See [the full test log](../../docs/TEST_LOG.md)
and [Android build instructions](../../docs/ANDROID.md).
