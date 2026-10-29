# INFERNO DUEL: LEGENDS

**Native fighting game for Linux and Android — Godot 4 / GDScript.**
Made by Rens de Gee en Ted Sondervan.

Based on the supplied v1.1 Word specification and Linux starter package.
The original design documents remain in `docs/`; the current implementation
and its limits are described here and in `docs/TEST_LOG.md`.

## Android APK — phones and tablets

[Download Android V9 (0.9.0) APK](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.9.0-android/releases/android-v0.9.0/InfernoDuel-Android-v0.9.0.apk)

Android 7.0+ with a **64-bit ARM or x86_64 Android OS**, OpenGL ES 3.0 and
multitouch. Install the APK from your browser/downloads; allow installation from
that source when Android asks. This is a sideloadable preview signed with a local
development key, not a Play Store release. See [Android build and validation](docs/ANDROID.md).

Play in landscape. **CONNECT · SESSION CODE** lets the hosting device create a
temporary room with **six letters/numbers**. The guest types that code and taps
CONNECT. No address is displayed or entered. Both devices must be on the same
Wi-Fi with peer traffic allowed; discovery and combat connect directly without
a separate server or account. Each player chooses and readies their own fighter.
Android has one touchpad per device and no local versus. Other Wi-Fi networks or
4G/5G need an external relay/NAT traversal service; the code alone does not bypass
routers. No such service is bundled. See [session setup](docs/NETWORK.md).

**PLAY · TOUCH VS CPU** remains offline. The new combat UI has a proportional
**left thumbstick**, BLOCK alongside it, a large right **ATTACK** button, and
smaller HEAVY, SPECIAL, ULT and JUMP buttons around it. Rings show actual special
cooldown and ultimate meter. Slide the stick to move; release to stop. Hold a
direction or BLOCK with an attack for directional variants. ULT needs 100 meter.
Tap **Ⅱ** or Android Back to pause; backgrounding also pauses and clears touches.
In connected play all pause requests must be released before resuming.

Rendering follows the device's actual surface resolution, including changes.
The arena keeps its proportions inside the safe display area; touch controls fit
phone and tablet aspect ratios. Lift and touch again after countdown, rounds or
pause. Physical-device ergonomics, cutouts and performance still need acceptance.

The APK is stored in Git LFS because it includes both native engines and all ten
intro movies. A source checkout needs `git lfs pull` to fetch it; the download
link above serves the APK directly. Linux play and keyboard controls remain supported.

## Earlier Linux download — v0.3.0

[Download Linux v0.3.0](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.3.0/releases/v0.3.0/InfernoDuel-Linux-v0.3.tar.xz)

Extract the archive and run `InfernoDuel-Linux/PLAY.sh`. Godot does not need to
be installed separately. This earlier archive has five fighters; rebuild from current source for all ten and the current character showcase. Linux x86_64 and OpenGL 3.3 are required.

## Play / F5

1. Install the standard **Godot 4.6.3** editor (no .NET, browser, or Android SDK).
2. Import `project.godot`, open the project, and press **F5**.
3. Choose **LOCAL VERSUS** or **SOLO VS CPU**.
4. Ready both player slots with **F** and **I**, then press **Enter** for the arena.
   In solo, choose the CPU opponent using the P2 controls or the mouse P2-edit button.

From a Linux terminal with Godot in PATH:

```bash
cd InfernoDuel
./tools/run.sh
```

All **ten fighters** are playable in local versus and against CPU: SharkByte,
Bullet, Nachtelf, PoisonBoy, Spinegrin, Chainveil, Cheese Rat, Lava Stone,
Crystal Fang and Phoenix Reign. Every fighter has animated selection art and a
complete basic/special/ultimate set; the full roster has **69 attacks/abilities**.

**FIGHTERS** is now a character showcase. Ten portrait cards select each legend.
A short entrance uses the existing illustrated character art as an extruded,
textured silhouette on a lit perspective **3D podium**, performs one signature
move, then keeps the **same lit character and rings** on screen with breathing
and a small idle sway. The camera settles; the 3D view is retained.
REPLAY PRESENTATION repeats the entrance. ORIGINAL SHEET and PLAY INTRO retain
the original references and existing films. The old movement tour, dummy and
executable move list are removed. This is a 2.5D art presentation, not ten new
fully modelled/rigged 3D characters.

V9 extends continuous animation to **49 whole attack clips** across all ten
fighters. Another 266 bidirectional fields align anticipation, chamber, extension,
contact and recovery, returning to idle around a planted support foot. Smooth
in-betweens render throughout the move, including the Fighters podium signature.
Walking uses 54 re-analyzed fields with steadier torso anchors, a longer two-step
stride and less body bounce. Gait follows actual displacement after arena and
opponent collision, so pushing against a blocked path stops the foot cycle.
Start, brake, pivot, jump/landing and guard transitions remain per character.

Combat now uses angular dark armor panels and animated energy gauges. A full
ultimate meter pulses gold along with the ULT touch button. Each fighter starts
with **200 HP**. Clean incoming damage grants **35% of the damage as meter,
rounded up**; guarding retains its existing four meter. Attack gains, costs,
damage, collision and 60-Hz physics retain their documented values. Meter caps at
100, supers spend 100, and the ready glow turns off when the meter is spent.

This animates existing artwork using derived motion fields; it does not add
independently hand-drawn frames. Limb occlusion/warping artifacts can remain.
Native resolution is retained and the render cap targets 60 FPS. Real-phone
frame pacing, performance and animation feel still need acceptance.

[Watch the scripted V9 combat animation preview (60-fps video)](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.9.0-android/releases/android-v0.9.0/InfernoDuel-CombatPreview-v0.9.0.mp4)

[Watch an intro preview](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.3.0/releases/v0.3.0/InfernoDuel-IntroPreview-v0.3.mp4)

Original sheets are preserved byte-for-byte. New sprites and intro key art are
reference-guided generated work. The intros use illustrated key poses, camera
motion and impact effects. See `docs/ART_PIPELINE.md` for provenance and limits.

## Controls — one shared keyboard

| Action | Player 1 | Player 2 |
| --- | --- | --- |
| Move | A / D | ← / → |
| Jump | W | ↑ |
| Block (hold) | S | ↓ |
| Light | F | I |
| Heavy | G | O |
| Special | H | P |
| Ultimate, 100 meter | J | L |
| Pause | Esc | Esc |

Character select: P1 WASD, F ready / G undo; P2 arrows, I ready / O undo.
With a mouse, select **EDIT P1/P2**, click a fighter, then use that player's
READY button. Both players may choose the same fighter.
Menus: W/S or arrows, F/I/Enter confirm, Esc back; mouse also supported.
F3 shows combat hitboxes. Focus loss automatically pauses the fight.

Rounds last 60 seconds with 200 HP. Win two rounds to win the match. Equal HP
at timeout or double KO replays the round. Light/heavy/special/ultimate deal
6/12/16/30 base damage; named variants have their own values in data/move_sets.json. Grounded guard facing the attacker reduces damage by 75%.
Taking clean damage also fills meter (35%, rounded up); blocking grants four.
Special cooldown is 1.5 seconds (Cheese Rat: 1.4); meter persists between rounds, not rematches.
Try light → light → heavy, or cancel a landed light's recovery into special.

PoisonBoy throws Toxic Splash and a larger Venom Cataclysm projectile. Chainveil's
Chain Lash and Iron Widow have extended reach and pull the opponent closer.
Cheese Rat throws Cheese Ball; hold **backward + special** to place Cheese Trap
instead. His ultimate is King of the Cheese. Traps expire after four seconds;
each fighter can have at most three active projectiles/traps.

Hold **forward, backward or guard** while pressing LIGHT, SPECIAL or ULT for
named variants. Forward/backward are relative to the opponent. GUARD is S for P1,
Down for P2, or the GUARD touch button. Hold a direction or BLOCK with an attack to choose these variants.
Lava Stone has armor and ground spikes; Crystal Fang has crystal rushdown,
shields and temporary power; Phoenix Reign has aerial fire moves and healing;
Nachtelf zones with ember/rift projectiles; Spinegrin fires capped spike volleys.
Armor reduces damage by 50%, power buffs add 20% damage, and invulnerability is
brief and visible. Rebirth costs 35 meter to escape hitstun and restore 8 HP;
Eternal Flame costs 100 meter to restore 25 HP. Neither revives a KO.

## Validate

```bash
./tools/test.sh
```

This verifies all eight artwork SHA-256 hashes, imports the project, checks for
engine/script errors, and runs 70 integration/combat, 494 artwork/animation,
45 earlier fighter-expansion and 287 full-roster/move checks (including all ten CPU matches). It also decodes all ten intro films with FFmpeg
(install `ffmpeg` for this validation step). For
rendered tests on a Linux desktop:

```bash
godot --path . --audio-driver Dummy tests/visual.tscn
godot --path . --audio-driver Dummy tests/expansion_visual.tscn
./tools/test_touch.sh
./tools/test_gallery.sh
TEST_NETWORK_RENDERED=1 ./tools/test_v9.sh
```

Rendered screenshots are written to `/tmp/inferno-visual/`, `/tmp/inferno-v03-visual/`,
`/tmp/inferno-touch/`, `/tmp/inferno-roster-visual/` and `/tmp/inferno-v6-visual/`.
The session/UI suite checks native framebuffer sizes, Android routes, session-code parsing
six-character LAN discovery, modern touch UI and real multi-process ENet gameplay. The V8 additions test all ten movement transitions, real GPU opacity and
persistent podiums. V9 adds all 49 attack clips, support-foot continuity, collision
gait stops, 200-HP balance and normal-input ultimate earning/spending checks.
./tools/benchmark_motion.sh measures actual monotonic frame
intervals against V7 at 720p and wide native resolution (requires the V7 tag).
The graphical network repeat is optional;
the default network run is headless. No public relay service is required or bundled.
Tests do not establish
physical keyboard rollover, audio-device quality, or real two-person playability.
See `docs/TEST_LOG.md` for exact results and the manual checklist.

## Native Linux package

```bash
./tools/build_linux.sh
./builds/linux/PLAY.sh
```

The script builds the game PCK. Set `GODOT_LINUX_TEMPLATE` to the official matching
`linux_release.x86_64` export template to bundle the smaller release engine; the
cloud default is `/workspace/.runtime/godot/linux_release.x86_64`. Versions must
match exactly. Without that file the script falls back to the installed editor
engine and records the choice in the package README. The published v0.3 bundle
uses the official Godot 4.6.3 Linux release template and adjacent PCK.

To rebuild the intro movies, install FFmpeg, use a graphical display and run
`./tools/render_intros.sh`. Movie Maker renders the deterministic cinematic
timeline at 30 FPS before Theora/Vorbis encoding. Optional authoring tool
`tools/index_intro_art.py` uses Pillow, NumPy and SciPy to index alpha meshes;
these Python packages are not needed to play or run the normal tests.

No external services or credentials are needed to play or test the game.
Every published update gets a new version, Android versionCode, APK path and Git
tag; published APKs/tags are retained instead of overwritten. This update is V9,
version 0.9.0 / Android code 900.
On restricted cloud hosts use writable XDG data/config/cache directories when
invoking Godot, e.g. `XDG_DATA_HOME=/workspace/.runtime/data` (and similarly
`XDG_CONFIG_HOME`, `XDG_CACHE_HOME`). A graphical desktop/OpenGL 3.3 is required
to play; headless mode is only for automated tests.
