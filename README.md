# INFERNO DUEL: LEGENDS

**Playable native Linux fighting-game prototype — Godot 4 / GDScript.**
Made by Rens de Gee en Ted Sondervan.

Based on the supplied v1.1 Word specification and Linux starter package.
The original design documents remain in `docs/`; the current implementation
and its limits are described here and in `docs/TEST_LOG.md`.

## Android APK — phones and tablets

[Download Android v0.4.0 APK](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.4.0-android/releases/android-v0.4.0/InfernoDuel-Android-v0.4.0.apk)

Android 7.0+ with a **64-bit ARM or x86_64 Android OS**, OpenGL ES 3.0 and
multitouch. Install the APK from your browser/downloads; allow installation from
that source when Android asks. This is a sideloadable preview signed with a local
development key, not a Play Store release. See [Android build and validation](docs/ANDROID.md).

Play in landscape. **PLAY · TOUCH VS CPU** is the phone default; **2 PLAYERS ·
SHARED TABLET** gives both players separate cyan/orange controls on one screen.
Tap a fighter, ready both sides, and enter the arena. EDIT P2 / CPU changes the
opponent. Left controls move, jump and guard; right controls light, heavy, special
and ultimate. Hold guard while facing the opponent; ultimate needs 100% meter.
Moving and attacking support multiple fingers. Tap **Ⅱ** to pause; Android Back
returns or pauses, and switching apps pauses the fight. Layouts fit phone and
tablet aspect ratios and keep controls inside Android's safe display area.

The APK is stored in Git LFS because it includes both native engines and all ten
intro movies. A source checkout needs `git lfs pull` to fetch it; the download
link above serves the APK directly. Linux play and keyboard controls remain supported.

## Download Linux prototype

[Download Linux v0.3.0](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.3.0/releases/v0.3.0/InfernoDuel-Linux-v0.3.tar.xz)

Extract the archive and run `InfernoDuel-Linux/PLAY.sh`. Godot does not need to
be installed separately. This is the five-fighter illustrated build described
below; Linux x86_64 and OpenGL 3.3 are required.

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

SharkByte, Bullet, **PoisonBoy, Chainveil and Cheese Rat** are playable, with
illustrated sprite animation and animated selection previews. All ten fighters
have their own portrait avatars. The other five slots are marked COMING SOON.

In **FIGHTERS**, Bullet, Nachtelf and PoisonBoy each display their own column of
the supplied shared sheet. Every fighter has a **PLAY INTRO** button: a short
720p film opens on their footwear and ends with a kick toward camera. Crystal
Fang and Phoenix Reign retain their original claw feet. BACK/Esc returns to the
same fighter; REPLAY starts the film again.

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
With a mouse, select **MOUSE EDITS P1/P2**, click a fighter, then use that player's
READY button. Both players may choose the same fighter.
Menus: W/S or arrows, F/I/Enter confirm, Esc back; mouse also supported.
F3 shows combat hitboxes. Focus loss automatically pauses the fight.

Rounds last 60 seconds with 100 HP. Win two rounds to win the match. Equal HP
at timeout or double KO replays the round. Light/heavy/special/ultimate deal
6/12/16/30 damage. Grounded guard facing the attacker reduces damage by 75%.
Special cooldown is 1.5 seconds (Cheese Rat: 1.4); meter persists between rounds, not rematches.
Try light → light → heavy, or cancel a landed light's recovery into special.

PoisonBoy throws Toxic Splash and a larger Venom Cataclysm projectile. Chainveil's
Chain Lash and Iron Widow have extended reach and pull the opponent closer.
Cheese Rat throws Cheese Ball; hold **backward + special** to place Cheese Trap
instead. His ultimate is King of the Cheese. Traps expire after four seconds;
each fighter can have at most three active projectiles/traps.

## Validate

```bash
./tools/test.sh
```

This verifies all eight artwork SHA-256 hashes, imports the project, checks for
engine/script errors, and runs 70 integration/combat, 229 artwork/animation and
45 fighter-expansion checks. It also decodes all ten intro films with FFmpeg
(install `ffmpeg` for this validation step). For
rendered tests on a Linux desktop:

```bash
godot --path . --audio-driver Dummy tests/visual.tscn
godot --path . --audio-driver Dummy tests/expansion_visual.tscn
```

Rendered screenshots are written to `/tmp/inferno-visual/` and `/tmp/inferno-v03-visual/`.
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
On restricted cloud hosts use writable XDG data/config/cache directories when
invoking Godot, e.g. `XDG_DATA_HOME=/workspace/.runtime/data` (and similarly
`XDG_CONFIG_HOME`, `XDG_CACHE_HOME`). A graphical desktop/OpenGL 3.3 is required
to play; headless mode is only for automated tests.
