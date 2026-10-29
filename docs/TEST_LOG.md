# Android preview v0.4.0 — 29 October 2026

Source milestone: `289326f`. Standard Godot 4.6.3; Android release templates
verified against the official SHA-512 sums. Google SDK components were checked
against their repository checksums. Linux remains supported.

| Check on the final source / artifact | Result |
| --- | --- |
| Original artwork integrity | PASS — all 8 original SHA-256 hashes unchanged |
| Headless integration/combat | PASS — 70 passed, 0 failed |
| Artwork/animation | PASS — 229 passed, 0 failed |
| Fighter expansion | PASS — 45 passed, 0 failed |
| Intro film decode | PASS — all 10 films, 193 frames each |
| Rendered Linux regression | PASS — 9 checks, 0 failures |
| Rendered multitouch suite | PASS — 33 passed, 0 failed |
| Reproducible Android export/signing script | PASS — exit 0, no engine/script errors |
| Final APK payload and CRCs | PASS — ARM64 + x86_64, compiled touch scripts, all ten films |
| APK signing and native alignment | PASS — APK v2/v3 signatures; `zipalign -c -P 16 4` |
| Manifest | PASS — package `org.infernoduel.legends`, version 0.4.0/code 400, min API 24, target 36, landscape, small through xlarge screens |
| Native Android end-to-end acceptance of final APK | NOT COMPLETED — software-emulator limitation, described below |
| Physical phone/tablet acceptance | NOT RUN — no physical Android device attached |

The touch suite exercises actual ScreenTouch, ScreenDrag and canceled events:
simultaneous move/attack, damage from touch, one press edge per hold, independent
finger release, drag-off release, keyboard isolation, guard/jump/special/ultimate,
touch pause/resume, mobile options, background clearing, round/reset invalidation
and two simultaneous players. Ten layout checks use actual SubViewports at five
phone/tablet sizes (16:9, 16:10, 4:3 and wide phone), both solo and shared modes,
and reject clipped or overlapping controls. These are software-injected touches;
they do not establish physical digitizer behavior or comfort.

## Android emulator evidence and limit

An earlier signed candidate installed successfully on an Android 15/API 35
x86_64 emulator. The cloud host has no `/dev/kvm`; the emulator uses slow TCG CPU
emulation. Its direct SwiftShader GLES driver failed Godot shader linking with
`Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`.
This rendering attempt is **not a pass**. Restarting the same AVD with the
supported `-gpu swangle` backend reached GLES 3.1 initialization and
`OnGodotMainLoopStarted` without those shader errors, but did not establish a
complete interactive Android game flow.

A readback/hash comparison correctly detected that the installed candidate was
older than the final download. Attempts to replace it with the final APK timed
out in Android's package installer, including after the final APK had been
successfully transferred. The native result therefore must not be attributed to
the final APK. The final download is build/signature/payload verified; its native
menu-to-fight flow still needs on-device acceptance. No physical-phone result,
runtime performance claim, or fully passed emulator smoke test is made.

The preview is signed with a local development key, not a production Play Store
key. Its exact checksum, source hashes and successful test logs are in
`releases/android-v0.4.0/`. Real-phone/tablet checks should cover installing this
exact APK, menu/select/fight/result/rematch, multiple fingers, Android Back,
pause/background/resume, audio, cutouts, frame rate and tablet shared-player
ergonomics. See `docs/ANDROID.md` for build and install commands.

# Linux v0.3.0 validation, 28 October 2026

Engine: Godot **4.6.3.stable.official.7d41c59c4**, standard Linux x86_64,
Compatibility renderer, 60 Hz physics. Rendered tests use Xvfb 1280×720 and Mesa
llvmpipe. Input is automated; no two-human keyboard test is claimed.

| Required check | Result |
| --- | --- |
| Immutable original artwork | PASS — 8/8 SHA-256 hashes |
| Godot editor import | PASS — exit 0, no script/engine errors |
| Original integration/combat suite | PASS — 70 checks, 0 failures |
| Sprite/avatar/state suite | PASS — 229 checks, 0 failures |
| Fighter expansion suite | PASS — 45 checks, 0 failures |
| Ten film files | PASS — full decode, 193 frames each, distinct close-up/kick images |
| Base rendered integration | PASS — 9 checks, 0 failures |
| Expansion rendered integration | PASS — 31 checks, 0 failures |
| Native release-engine + PCK | PASS — startup, X11 menu/gallery/film/select/fight/pause/quit |

The 344 gameplay/artwork checks cover the original flow plus five playable fighters,
new attacks, block/chip, meter costs, PoisonBoy projectile single-hit behavior,
Chainveil range/pull, Cheese Rat ball/trap/ultimate, trap expiry and the three-object
per-owner cap. Each new CPU fighter completes a full normal-health match against
a passive player. The new three fighters have distinct animation sets and previews.

The 40 rendered checks include all three individual gallery sheets, all ten real
intro buttons decoding 1280×720 video, replay from the beginning, clip completion,
Esc returning to the same fighter, and the three new fighters reaching combat.
Gallery keyboard focus now returns to the selected fighter. Source screenshots
are generated in `/tmp/inferno-visual/` and `/tmp/inferno-v03-visual/`.

`tools/verify_intros.py` uses FFprobe/FFmpeg to decode each film, verify its 30 FPS,
6.43-second duration and 193-frame count, and compare actual video frames. This
is separate from Godot's real-time playback tests. All ten films were rendered
from the deterministic cinematic timeline. The shoe/claw close-up and camera-kick
framing were also visually inspected. Crystal Fang/Phoenix Reign retain their
original claw feet, as confirmed by the user.

The independent native bundle uses the official Linux **release template**, not
the editor engine used by v0.1/v0.2. Matching version and official ZIP-entry CRC32
were checked. Template SHA-256:
`2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`.
The wrapper uses adjacent PCK discovery. X11 actions exercised PoisonBoy's own
sheet, its actual movie inside the pack, return to the same sheet, PoisonBoy versus
Chainveil, attacks, pause and normal Quit. Representative screenshots are retained
in `docs/screenshots/`. Release `validation/` includes logs and source hashes.

No final required check reported script errors, engine errors or instance leaks.
The initial sandboxed editor check could not create its local socket; repeating
through the supported execution permission path passed. Xvfb still reports that
V-Sync switching is unsupported; this is a virtual-display limitation. Review
caught a low Cheese Ball spawn, corrected to the caster's hand height before the
final combat validation and package. No source sheet pixels were changed.

## Remaining acceptance and scope

Physical F5 interaction, two humans sharing a real keyboard, hardware ghosting,
real speaker output and gameplay balance still require manual testing. The new
sets use keyed illustrated poses; extra in-betweens and final artist review remain
useful. Nachtelf, Spinegrin, Lava Stone, Crystal Fang and Phoenix Reign have avatars,
sheets and intros but are not yet combat-ready. Complete extra move lists, Story,
rebinding, recorded music/voice and Android remain future milestones.

## Historical validation below (v0.1 / v0.2)

These entries describe earlier builds. Their missing-artwork, two-fighter and
editor-engine limitations are superseded by the v0.3 status above.

# Validation — 27 October 2026

Engine: Godot **4.6.3.stable.official.7d41c59c4**, standard Linux x86_64,
Compatibility renderer, fixed 60 Hz physics. Cloud virtual display: Xvfb 1280×720,
Mesa llvmpipe OpenGL 4.5. Tests used generated input, not two humans on a keyboard.
See `builds/validation/source.sha256` for the exact implementation-file hashes
of the validated build (generated by packaging). This historical entry describes validation before the v0.1 publication.

## Completed

| Check | Result | Evidence / limits |
| --- | --- | --- |
| Original artwork integrity | PASS — 8/8 | SHA-256 via `python3 tools/verify_assets.py` |
| Godot editor import | PASS — exit 0 | `godot --headless --path . --editor --quit`, no engine/script errors |
| Automated integration/combat | PASS — 70 checks, 0 failures; exit 0 | `tools/test.sh`; underlying output scanned for runtime errors and leaks |
| Rendered integration | PASS — 9 checks, 0 failures; exit 0 | `godot --path . --audio-driver Dummy tests/visual.tscn` under Xvfb |
| Native X11 keyboard input | PASS | `xdotool`: menu → both ready keys → arena → fight; simultaneous move and attack keys |
| Linux engine + PCK package | PASS — startup exit 0 | `builds/linux/PLAY.sh --headless --quit-after 15`; full editor engine bundled because export templates absent |
| Packaged native window | PASS | X11 keyboard flow: menu → select → arena → simultaneous move/attack → pause; no runtime errors |
| Physical F5 key in editor | NOT RUN | Main scene loaded and rendered directly; F5 entry point is configured, but no human editor interaction claimed |
| Two humans / physical keyboard ghosting | NOT RUN | Requires the target keyboard; software injection cannot prove hardware rollover |
| Real sound output | NOT RUN | Synthesized streams exist; validation used headless/Dummy audio, not speakers |
| Production template export | NOT RUN | Matching export templates are not installed; repeatable release export command supplied in README |

## Automated coverage

The 70 checks cover boot/menu and ten roster slots; independent character cursors;
unavailable roster feedback; both confirmations; countdown input lock; all sixteen
physical mappings; simultaneous move/attack events; edge triggering; state clearing;
movement; same-tick damage trades; hit meter; one hit per activation; directional
ground guard/chip; out-of-range misses; special cooldown; 120 ms follow-up buffering;
light-to-special recovery cancel; ultimate cost/damage; Bullet ground-shock projectile;
light/light/heavy three-hit combo; escape immunity; jump/no double jump; gravity;
arena boundaries; pause timer; cleared resume inputs; focus-loss pause; paused Options;
timeout winner; per-round meter retention; equal-timeout replay; draw round numbering;
double KO; complete scripted 2–1 match; rematch resets; restart confirmation/cancel;
all ten gallery sheets; Story preview; Easy CPU approach/damage; full CPU match against
a passive player; mirror-match state separation; and saved settings.

The scripted 2–1 fixture reduces HP to six before each final exchange to exercise
round transitions deterministically. The separate CPU full-match check uses normal
100 HP, attacks, cooldowns and 60-second timers, without health shortcuts.

The nine rendered checks cover keyboard entry into versus, both ready confirmations,
simultaneous movement and damage in the real physics loop, frozen pause timer,
Options focus, fullscreen, gallery focus, and a 960×540 window retaining the logical
1280×720 interface. Eight screenshots are generated under `/tmp/inferno-visual/`.
Representative screenshots are retained in `docs/screenshots/`.

## Diagnosed and fixed during development

- Options and Gallery initially lacked an initial keyboard focus target.
- Draw replay initially incremented the round number; it now retries the same round.
- Confirmation dialogs now hide before being freed and ignore duplicate opening.
- SFX now use a bounded 12-voice pool; fast simulation tests wait for playback cleanup.
- The initial resize assertion incorrectly expected manual stage scaling despite Godot's
  canvas stretch already maintaining the logical viewport. The corrected check verifies
  actual window dimensions plus logical UI dimensions; the saved screenshot confirms it.
- Restricted command sandbox blocks proxy access and local editor/X11 sockets. Native
  network/graphical validation used the supported escalation path. Writable XDG paths
  under `/workspace/.runtime/` avoid attempting writes into read-only home directories.
- Xvfb reports unsupported V-Sync mode switching. Rendering continues normally; this is
  a virtual-display limitation, not a demonstrated gameplay defect.

## Manual acceptance checklist — still required

1. Open `project.godot` in Godot 4.6.3 on Linux and press F5.
2. Play a full match with two people on the same physical keyboard. Test A+F while
   the other player uses Right+I, and W+H while the other holds Down+O.
3. Check key rollover/ghosting, held keys during focus loss, ergonomics, and input feel.
4. Check actual audio, fullscreen, windowed mode, confirmation dialogs and rematch.
5. Review balance, geometry readability, and collision/combos using F3 hitboxes.

## Known scope gaps

Only SharkByte and Bullet are playable. Combat characters and arena are explicit
geometric prototypes; supplied sheets are only gallery references. No validated
sprite animation, final music/voice, complete ten-fighter move sets, rebinding,
Story campaign, Android build, or production export-template validation yet.

# Visual build v0.2 — 28 October 2026

This update supersedes the v0.1 geometric-renderer and missing-animation notes
above. SharkByte and Bullet now use illustrated reference-derived sprite sets;
all ten roster fighters have distinct original-sheet avatars. See ART_PIPELINE.md.

| Required check | Current outcome |
| --- | --- |
| Original source hashes | PASS: 8/8 unchanged |
| Editor import + gameplay/flow suite | PASS: 70 checks, zero failures, exit 0 |
| Sprite/avatar suite | PASS: 103 checks, zero failures, exit 0 |
| Rendered Linux integration | PASS: 9 checks, zero failures, exit 0 |
| Deterministic animation showcase | PASS: recorded 496 frames at 30 FPS, 16.5 seconds; all ten animation states shown |

No script errors, runtime errors or leaked-instance warnings occurred in the final
required checks. The virtual-display V-Sync warning remains the same platform
limitation as in v0.1. The showcase is a scripted artwork review rather than a
human-played match. Renderer telemetry averaged about 10 ms GPU and 2 ms CPU per
recorded frame on llvmpipe; this is not a frame-rate guarantee for another machine.

Visual review covered the original likeness references, alpha cutouts, portrait
identity/cropping, frame isolation, idle/walk, block, jump, light/heavy timing,
special/ultimate silhouettes, hit reactions, KO and both player facings. Generated
frames with clipped silhouettes/adjacent-art contamination were replaced or
isolated using texture meshes before integration. The six-frame walk replaces the
first four-step walk attempt. No original character sheet was edited.

The revised hurtbox height, strike height and body separation match the larger
rendered characters; the full combat suite remains green. Actual physical keyboard
rollover, two-human play and real speaker output still require manual testing.
Eight characters have avatars but are not yet playable. More artist-authored
in-betweens and a final likeness/animation review remain useful follow-up work.

The final v0.2 native engine + PCK bundle also booted outside the editor (exit 0),
and its X11 menu → avatars → arena → simultaneous movement/attacks → pause flow
was exercised without runtime errors. Package evidence and implementation hashes
are included in the release's `validation/` directory. The native bundle uses the
full installed Godot engine; a stripped export-template build is still untested.
