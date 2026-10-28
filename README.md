# INFERNO DUEL: LEGENDS

**Playable native Linux fighting-game prototype — Godot 4 / GDScript.**
Made by Rens de Gee en Ted Sondervan.

Based on the supplied v1.1 Word specification and Linux starter package.
The original design documents remain in `docs/`; the current implementation
and its limits are described here and in `docs/TEST_LOG.md`.

## Download Linux prototype

[Download Linux v0.1.0](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.1.0/releases/v0.1.0/InfernoDuel-Linux-v0.1.tar.gz)

Extract the archive and run `InfernoDuel-Linux/PLAY.sh`. Godot does not need to
be installed separately. This is the two-fighter geometric prototype described
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

SharkByte and Bullet are playable geometric prototypes. The other eight roster
slots are marked COMING SOON; all ten original designs are viewable in FIGHTERS.
The supplied sheets are not validated animation frames. Final fighter art and
animation are the next milestone, not part of this prototype's presentation.

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
Special cooldown is 1.5 seconds; meter persists between rounds, not rematches.
Try light → light → heavy, or cancel a landed light's recovery into special.

## Validate

```bash
./tools/test.sh
```

This verifies all eight artwork SHA-256 hashes, imports the project, checks for
engine/script errors, and runs the automated integration/combat suite. For
rendered tests on a Linux desktop:

```bash
godot --path . --audio-driver Dummy tests/visual.tscn
```

Rendered screenshots are written to `/tmp/inferno-visual/`. Tests do not establish
physical keyboard rollover, audio-device quality, or real two-person playability.
See `docs/TEST_LOG.md` for exact results and the manual checklist.

## Native Linux package

```bash
./tools/build_linux.sh
./builds/linux/PLAY.sh
```

The script builds the game PCK and bundles the installed Linux Godot executable,
so the resulting folder can run without Godot installed. This is a native Linux
package using the full editor engine, **not a stripped production export**.
With matching official export templates installed, the included `Linux` preset
also supports `godot --headless --path . --export-release Linux builds/InfernoDuel.x86_64`.
The template-export path has not been tested here because templates are absent.

No external services, credentials, or package-manager dependencies are needed.
On restricted cloud hosts use writable XDG data/config/cache directories when
invoking Godot, e.g. `XDG_DATA_HOME=/workspace/.runtime/data` (and similarly
`XDG_CONFIG_HOME`, `XDG_CACHE_HOME`). A graphical desktop/OpenGL 3.3 is required
to play; headless mode is only for automated tests.
