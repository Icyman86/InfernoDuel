# INFERNO DUEL: LEGENDS

**Native fighting game for Linux and Android — Godot 4 / GDScript.**
Made by Rens de Gee en Ted Sondervan.

Based on the supplied v1.1 Word specification and Linux starter package.
The original design documents remain in `docs/`; the current implementation
and its limits are described here and in `docs/TEST_LOG.md`.

## Android V15 — Crystal Fang zijn mijn

[Download V15-preview](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.15.0-android-preview/releases/android-v0.15.0/InfernoDuel-Android-v0.15.0-preview.apk).
Werkt de bestaande V14-preview bij.

De gekozen C1-arena staat nu in de game als **Crystal Fang zijn mijn**: een grote
ondergrondse mijn vol gloeiende roze diamanten. Kies hem na character select,
of laat RANDOM kiezen uit alle vier arena's. De mapkeuze toont alle vier kaarten
volledig in beeld. [Ingame-beelden en controles](releases/android-v0.15.0/README.md).

## Android V14 — nieuwe arena's en ultimate power

[Download de aparte V14-preview-app](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.14.0-android-preview/releases/android-v0.14.0/InfernoDuel-Android-v0.14.0-preview.apk).
Installeert **naast V11**, onder de naam Inferno Duel V14 Preview.

Na character select: kies Infernal Citadel, **Nachtelvenbos — Hart van het Bos**,
**Spinegrins ruimteschip — Levende Brug**, of **RANDOM**. De host kiest in een sessie.
Een ultimate toont nu een grote melding en drie seconden aura/ACTIVE-status,
met +20% schade op vervolgaanvallen. [Beelden en details](releases/android-v0.14.0/README.md).

## Linux V13 — 3D Fighter Gallery

[Download Linux V13](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.13.0-linux-gallery/releases/linux-v0.13.0/InfernoDuel-Linux-v0.13.0.tar.xz).
Pak uit en start `InfernoDuel-Linux/PLAY.sh`.

**FIGHTERS** toont tien nieuwe Blender-volumemodellen met echte skeletons,
skin-gewichten, idle-animatie, ogen/vingers, kleding- en characterdetails en
normal maps. Het grotere 3D-vlak houdt iedere fighter inclusief voeten, haar,
staarten en vleugels in beeld. Sleep om te draaien of kies **PORTRAIT VIEW** /
**FULL BODY**. Studiobelichting en schaduwen laten de materialen en vormen zien.
De modellen zijn gestileerde interpretaties; de combat-modellen uit V12 blijven
behouden. [Alle tien bekijken](releases/linux-v0.13.0/README.md) ·
[Bediening en modelpipeline](docs/V13_GALLERY.md).

## Linux V12 — 0.12.0 preview

[Download de Linux V12-preview](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.12.0-linux-preview/releases/linux-v0.12.0/InfernoDuel-Linux-v0.12.0-preview.tar.xz).
Pak uit en start `InfernoDuel-Linux/PLAY.sh`.

Local Versus en Solo hebben nu een echte 3D-gladiatorenarena en tien nieuwe,
eenvoudige gelede volumemodellen, controllerondersteuning, directionele commando's,
grabs/throws met throw-tech, stunontsnapping en aangekondigde klemvallen.
**Dit is een technisch 3D-prototype; het gevraagde moderne character- en
animatiekwaliteitsniveau is nog niet bereikt.** Gedetailleerde productiemodellen,
skinning, texturen en professionele animatiepolish ontbreken nog.
[Bediening, concrete regels, testcommando's en beperkingen](docs/V12_LINUX.md).
LAN en Android houden hun bestaande 2D-routes; er is geen nieuwe mobiele build.

## Android APK — phones and tablets

V11 replaces character-select portraits with ten newly painted frontal half-body
shots looking directly at the player. Both selection slots retain that frontal
orientation. Combat artwork is unchanged from V10.

[Download Android V11 (0.11.0) APK](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.11.0-android/releases/android-v0.11.0/InfernoDuel-Android-v0.11.0.apk)

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
The painted arena fills the entire surface, including wide phone screens and
taller tablets. Fighters keep their proportions; HUD and touch controls share the
usable safe display area. Combat coordinates remain stable across aspect ratios. Lift and touch again after countdown, rounds or
pause. Physical-device ergonomics, cutouts and performance still need acceptance.

The APK is stored in Git LFS because it includes both native engines and all ten
intro movies. A source checkout needs `git lfs pull` to fetch it; the download
link above serves the APK directly. Linux play and keyboard controls remain supported.

## iPhone 0.9 — zonder App Store

Voor iPhone/iPad is een iOS 15+ exportprofiel toegevoegd met Metal-rendering,
native resolutie, touchbediening en dezelfde V9-content. De aparte
[iPhone-buildworkflow](https://github.com/Icyman86/InfernoDuel/actions/workflows/ios.yml)
bouwt op een macOS/Xcode-runner een echte ARM64-app en unsigned IPA.
Na een geslaagde tagbuild staat het bestand bij de
[iOS 0.9 release](https://github.com/Icyman86/InfernoDuel/releases/tag/v0.9.0-ios).
Een Xcode-export of broncode-zip is geen installeerbare IPA.
Het [complete Mac/Xcode-bouwpakket](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.9.0-ios-project/releases/ios-v0.9.0/InfernoDuel-Xcode-v0.9.0.zip) is apart beschikbaar.
Vanuit deze Linux-cloudomgeving startte geen Mac-build: de Actions-API geeft
Forbidden. De eigenaar kan in de workflow Run workflow kiezen vanaf main met
release_tag v0.9.0-ios; pas na succes verschijnt de installeerbare IPA.

Installeer met AltStore Classic + AltServer op Windows of Mac en je eigen Apple
Account. Een gratis account vraagt normaal elke zeven dagen om vernieuwen.
Geen jailbreak of betaald account vereist; alleen het IPA-bestand in Safari
openen werkt niet. Volg de [Nederlandse installatiehandleiding](docs/IPHONE_INSTALLATIE.md).

iPhone gebruikt voor sessiecodes beperkte unicast-discovery op maximaal twee
nabije private /24-netwerken, zonder een betaald multicast-entitlement. Gebruik
Android als host bij de bestaande Android V9-APK. Native iPhone-installatie,
Metal-rendering, echte safe areas, wifi en prestaties zijn nog niet gevalideerd.
De bestaande Android APK/tag worden voor deze port niet overschreven.

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

**FIGHTERS** presents ten new skinned Blender characters on a persistent lit
3D stage. Each has a real skeleton, an idle animation, character-specific mesh
details and normal-mapped materials. Drag to rotate or choose TURN and PORTRAIT
VIEW / FULL BODY. Automatic framing retains the entire silhouette; the 3D target
tracks native pixel density. Original-sheet view and the existing intro films
remain available. This V13 gallery replaces the earlier extruded illustration
presentation; the V12 arena combat models remain unchanged.

V10 replaces flow-warped animation with intact illustrated poses. Each of the ten
fighters gets **12 walk drawings and 12 heavy-attack drawings**: 240 new indexed
poses. Heavy anticipation, chamber, extension and recovery follow the existing
hitbox timing, with contact held through the active window. Other attacks retain
their earlier illustrated keys; they also render without UV/mesh deformation.
Walking follows actual traveled distance and stops at walls/opponents. Character
select now uses **ten high-resolution half-body portraits** with a small entrance
fade and gentle whole-image movement. The Fighters podium retains its rings.

Combat now uses angular dark armor panels and animated energy gauges. A full
ultimate meter pulses gold along with the ULT touch button. Each fighter starts
with **200 HP**. Clean incoming damage grants **35% of the damage as meter,
rounded up**; guarding retains its existing four meter. Attack gains, costs,
damage, collision and 60-Hz physics retain their documented values. Meter caps at
100, supers spend 100, and the ready glow turns off when the meter is spent.

Native resolution is retained and rendering targets 60 FPS. Twelve drawings per
cycle do not mean sixty independently drawn frames per second. Real-phone frame
pacing, performance and animation feel still need acceptance.

[Watch the scripted V10 wide-screen preview (60-fps video)](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.10.0-android/releases/android-v0.10.0/InfernoDuel-Preview-v0.10.0.mp4)

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
engine/script errors, and runs 70 integration/combat, 745 artwork/animation,
45 earlier fighter-expansion and 287 full-roster/move checks (including all ten CPU matches). It also decodes all ten intro films with FFmpeg
(install `ffmpeg` for this validation step). For
rendered tests on a Linux desktop:

```bash
godot --path . --audio-driver Dummy tests/visual.tscn
godot --path . --audio-driver Dummy tests/expansion_visual.tscn
./tools/test_touch.sh
./tools/test_gallery.sh
TEST_NETWORK_RENDERED=1 ./tools/test_v10.sh
```

Rendered screenshots are written to `/tmp/inferno-visual/`, `/tmp/inferno-v03-visual/`,
`/tmp/inferno-touch/`, `/tmp/inferno-roster-visual/`, `/tmp/inferno-v6-visual/`
and `/tmp/inferno-v10-visual/`.
The session/UI suite checks native framebuffer sizes, Android routes, session-code parsing
six-character LAN discovery, modern touch UI and real multi-process ENet gameplay. The movement tests cover all ten fighters and persistent podiums. Quality tests
cover 49 attack clips with immutable drawing geometry, collision gait stops,
200-HP balance and normal-input ultimate earning/spending. V10 renders six screen
sizes (including 2780×1264), checks full-surface scenery, shared safe-area HUD and
controls, all ten half-body portraits and all 240 triangulatable pose meshes.
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
tag; published APKs/tags are retained instead of overwritten. This update is V11,
version 0.11.0 / Android code 1100.
On restricted cloud hosts use writable XDG data/config/cache directories when
invoking Godot, e.g. `XDG_DATA_HOME=/workspace/.runtime/data` (and similarly
`XDG_CONFIG_HOME`, `XDG_CACHE_HOME`). A graphical desktop/OpenGL 3.3 is required
to play; headless mode is only for automated tests.
