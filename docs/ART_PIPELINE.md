# V10 discrete drawings and half-body portraits — 29 October 2026

The live renderer no longer uses the V8/V9 flow fields described historically
below. It displays intact artwork without UV/vertex warping or crossfade ghosts.
New reference-guided ImageGen sheets provide 240 indexed drawings: twelve walk
and twelve heavy poses per fighter. Other attacks retain their existing drawn
keys. Heavy contact is held through the actual active interval. These are newly
generated drawings; no human frame-by-frame authorship, motion capture or sixty
unique drawings per second is claimed. Costume/volume consistency still benefits
from artist review.

assets/sprites/<id>/v10_motion.png contains a 4×6 sheet. PoisonBoy uses only its
first twelve walk cells and a separate 4×3 v10_heavy.png; clipped rejected cells
are never indexed. data/drawn_animation_sources.json records the selected cells.
The PNGs are copied byte-for-byte from ImageGen output. No existing PNG is edited.
All eight original user sheets and earlier generated sheets remain unchanged.

Two generated 1536×1024 portrait sheets, assets/portraits/v10_classic.png and
v10_legends.png, supply ten 512×512 half-body paintings. data/select_busts.json
maps the cells. FighterBust uses an AtlasTexture crop, gentle rigid movement and
an entrance fade. HUD/source-reference portraits remain separately accessible.

The optional tools/index_drawn_poses.py reads alpha connected components, indexes
complete bodies even when a foot overhangs a nominal grid cell, and writes JSON
rectangles, support pivots, atlas scale and convex envelope polygons. Convex
envelopes prevent self-touching hair/chains from breaking 3D triangulation; alpha
preserves the visible painted contour. It never writes artwork pixels. Reproduce
with Pillow, NumPy, SciPy and opencv-python-headless 4.11.0.86. Runtime needs only
the committed metadata. data/visual_asset_provenance.json records SHA-256 and
identifies all new artwork as generated derivatives, not original user uploads.

V10 preview captures select portraits, all ten walking/heavy demonstrations and
the charged-ultimate UI at 1280×582 and 60 video FPS. Attacks are slowed for pose
inspection; charged meter is a UI fixture. Separate quality tests earn/spend the
ultimate through ordinary input. Offline capture does not measure phone FPS.

---

# V9 continuous whole attacks — 29 October 2026

All ten fighters now use 49 full attack timelines: idle → anticipation → chamber
→ extension/contact → recovery → idle. tools/build_action_fields.py analyzes
masked existing atlas poses and chooses a rear support-foot pivot. It writes 266
bidirectional RGBA8 vector fields, zlib/base64 compressed, plus timestamps/pivots
and root offsets to data/action_motion_fields.json. At render time the one-pass
shader aligns adjacent poses with eased interpolation; contact is held through
the actual active interval. It adds continuous derived in-betweens rather than
independently drawn raster frames. Existing PNGs and all original art remain
byte-for-byte unchanged. Limb occlusions can still warp or reveal pose changes.

Both action and walk authoring use tools/pose_field_utils.py: OpenCV DIS optical
flow, a normalized 640×448 analysis canvas and 96×72 vector grids. Python/Pillow,
NumPy and opencv-python-headless 4.11.0.86 are authoring-only dependencies. Run
python3 tools/build_action_fields.py and python3 tools/build_walk_fields.py to
regenerate metadata. The game and normal builds use committed JSON directly.
Walk fields were re-analyzed with stable torso/ground anchors; gait strides now
span two steps, grounded offsets are removed and extra bounce is reduced.

The Fighters podium uses the same motion field in a spatial shader. Its fixed
support position and full-signature camera envelope retain the same world, lit
character and rings throughout the entrance and idle. The V9 preview records all
ten fighters' heavy moves in scripted slow motion plus the ultimate-ready HUD
fixture at 60 video frames/sec. It does not establish real-device performance.
The separate balance tests earn and spend meter through normal combat input.

# V8 persistent podiums and continuous movement — 29 October 2026

Fighters now retains the same 3D character, lighting, pedestal and luminous rings
after the entrance. There is no replacement by a separate 2D sprite. The camera
settles after 2.8 seconds, while small idle breathing/sway continues. Reference
sheet view pauses the world; returning and replay retain the same podium nodes.
The hidden FighterVisual advances only once, driven by the presentation timeline.

All ten fighters gain render-time start, brake, backstep, pivot, rise, apex, fall,
landing and guard-in/out clips, with individual stride, weight, breathing and
lean profiles in data/movement_animations.json. They change presentation only.
Gait follows traveled distance, including fractional thumbstick motion. Scaling
and leaning use the foot pivot. Round/reset and pause invalidate old motion phases.

Walking uses existing authored poses plus derived in-betweens. The optional
OpenCV authoring script tools/build_walk_fields.py reads masked RGBA pose regions
and computes forward/backward motion fields for 54 adjacent walk-pose pairs.
It writes only quantized vector data to data/walk_motion_fields.json; it never
writes source or derivative artwork pixels. Runtime reconstructs small GPU data
textures and aligns both poses in a single shader pass over a cached union mesh.
Occlusions prefer the time-nearest silhouette; some limb warping remains possible.
This is motion-interpolated illustrated animation, not 60 independently drawn
frames or a new fully rigged 3D model. Original art hashes and unique image counts
remain unchanged. The other movement phases use authored curves and pose art.

To regenerate analysis data, use Python with Pillow, NumPy and
opencv-python-headless==4.11.0.86, then python3 tools/build_walk_fields.py from the
repository. These packages are authoring-only: normal tests, APK builds and the
game use the committed data and do not require OpenCV. The cloud installation
used /workspace/.runtime/motion-python, outside the checkout. All eight original
reference sheets and existing sprite PNGs remain byte-for-byte unchanged.

The scripted movement video is recorded at 60 frames per second with Godot Movie
Maker. It shows persistent rings and all ten characters' transitions using a test
fixture controlling both fighters. It is an offline animation review, not proof
of live phone performance. Separate uncapped-wall-clock measurements retain a
60-FPS engine cap and report actual monotonic frame intervals on Linux llvmpipe.
Physical phone/tablet frame pacing and final human animation review remain open.

# V7 character presentations — 29 October 2026

Fighters no longer runs the animated move lab or movement tour. Each character
opens with one signature heavy in a short 3D podium shot, then switches to a
stationary FighterVisual idle with breathing, matching the menu's presentation.
REPLAY PRESENTATION repeats it; original sheets and existing films remain.

FighterPresentation uses real Godot Node3D, a perspective Camera3D, a lit cylinder
podium, illuminated rings and MeshInstance3D faces/sidewalls. Front faces retain
the existing indexed atlas texture/UVs; sidewalls extrude the validated silhouette
by 0.15 world units. Meshes cache per authored pose. Camera movement, a small
rotation and attack lunge add depth. The hidden FighterVisual supplies authored
pose timing; no original pixels or generated derivatives are edited. This is a
2.5D extruded-art presentation, not a new fully modelled/rigged 3D character or
motion capture. It deliberately does not show invented back/side anatomy.

After 2.8 seconds the 3D viewport stops rendering and a stationary idle sprite
breathes in place. Original-sheet view pauses presentation; switching characters
disposes the previous world/visual. All ten presentations, move-to-idle transitions,
replay and original sheets are covered by rendered tests. Physical Android GPU
performance remains unverified. All eight original source hashes remain unchanged.

# Full roster animation update v0.5 — 29 October 2026

All ten fighters now have reference-guided runtime sprites. The five new combat
atlases belong to Nachtelf (the center dark elf/Warlock on the shared sheet),
Spinegrin, Lava Stone, Crystal Fang and Phoenix Reign. Their original source
images remain unchanged; all eight SHA-256 hashes pass. These new atlases are
generated derivatives, **not original animation extracted from the uploads**.
Crystal Fang retains furry wolf claw feet; Phoenix Reign retains bird talons.
Sneakers have no copied brand marks.

Each new base atlas contains 24 poses: idle, six-key gait, light, heavy, guard,
jump, special, ultimate, recoil and KO. Four supplementary eight-key atlases add
actual fully extended kicks (Lava Stone, Spinegrin, Phoenix Reign), a wolf bite
(Crystal Fang), ground slams, wing sweeps and buff poses. Nachtelf has 24 unique
keys; the other four have 32 each. Some poses are shared between abilities;
69 abilities do not mean 69 independently drawn animation sequences.

`tools/index_roster_art.py` reads RGBA silhouettes and emits atlas rectangles,
foot pivots, scale factors and textured meshes. It never writes image pixels or
original reference sheets. Supplemental kick meshes include full extended feet,
even where they cross nominal grid boundaries. Metadata separates two touching
Spinegrin sole contacts. Artwork paths, references and SHA-256 hashes are in
`data/visual_asset_provenance.json`.

`FighterVisual` caches atlas metadata, blends adjacent keys over 55 ms, drives gait
phase from speed, and adds small breathing/lean motions. Heavy extension keys
coincide with active hitboxes; new slam, bite, wing and buff keys distinguish the
named abilities. Color-coded projectiles, chains, tail sweeps and temporary auras
are runtime effects. This improves transitions but remains illustrated key-pose
animation rather than complete hand-drawn in-betweens or skeletal animation.

The move lab uses a bounded training match and the same controllers, effects,
resources and directional input resolution as combat. It shows real damage,
meter and buff state. Source sheets and intro movies remain accessible separately.
The final artwork suite checks 494 properties, including all ten identities,
real alpha, mesh bounds and every registered animation. Rendered move-lab and
native Linux checks are recorded in TEST_LOG. Physical-device performance,
keyboard/digitizer feel, final art polish and balance still need human review.

# Historical illustrated fighter expansion v0.3 — 28 October 2026


## Source integrity and provenance

All eight supplied character/move sheets remain byte-identical under
`assets/originals/character_sheets_2026-10-27/`. `tools/verify_assets.py` checks
all eight original SHA-256 hashes. The ZIP provided composed reference sheets,
not transparent animation frames. Runtime sprites and intro key art are new
reference-guided generated derivatives, not original animation extracted from
the upload. `data/visual_asset_provenance.json` records paths, references and hashes.

The original SharkByte and Bullet sprites from v0.2 are retained. New PoisonBoy,
Chainveil and Cheese Rat sets follow the supplied green/black streetwear, gothic
black/red outfit with platform boots, and black rat/yellow cheese shirt designs.
Cheese Rat's red shoes have plain uppers and black laces/soles, without brand logos.
The Infernal Citadel plate is newly generated artwork matching the design brief.

## Selection and individual gallery sheets

All ten fighters use distinct original-sheet portrait regions in selection, HUD
and gallery navigation. The five playable fighters have animated selection previews.
Bullet, Nachtelf and PoisonBoy now have separate `AtlasTexture` resources under
`assets/reference/`, each displaying only their own column of the shared source
sheet. This changes the gallery view without editing or duplicating source pixels.

## Combat animation

SharkByte and Bullet each have 30 indexed pose keys across `core.png`, `walk.png`
and `actions.png`. Their dedicated six-key walk replaces the retained four old
walk keys. PoisonBoy, Chainveil and Cheese Rat each have 24 unique indexed keys:
16 core poses (idle, four-step walk, light and heavy) plus eight action poses
(block, jump, dash/special, ultimate, hit and KO). Their walk metadata aliases the
four core walk frames; those aliases are not counted as extra artwork.

`data/sprite_atlases.json` stores source rectangles, ground pivots, texture scale
and convex silhouette meshes. Meshes isolate adjacent atlas figures. Indexing
reads source alpha and produces metadata without repainting images. Incorrectly
overlapping Chainveil poses were replaced with a spaced atlas before indexing.

`FighterVisual` reads the controller's state. Anticipation, extension and recovery
keys follow attack timing; the heavy extension coincides with the active hitbox.
Idle and walk loop; block, airborne, stun and KO have dedicated silhouettes.
World movement, breathing, impact flash and chain/projectile effects add motion.
Pause freezes animation. Team colors use a subtle rim to retain outfit colors.

These are keyed illustrated animations. Twenty-four or thirty pose keys do not
mean that each action has that many separately drawn in-between frames. Extra
in-betweens, consistent face/volume review and foot-slide polish remain useful.
Five roster fighters still have avatars, sheets and intros rather than combat sets.

## Ten intro films

Every fighter has an individual `assets/intros/<id>.ogv`: 193 frames at 30 FPS,
1280×720, about 6.43 seconds, Theora video and Vorbis synthesized SFX. Each film
opens with a footwear close-up, cuts to the fighter, raises the knee and drives
a foreshortened front kick toward camera with the sole prominently framed.
Crystal Fang and Phoenix Reign retain their original claw feet, as explicitly
chosen by the user. Their close-ups and camera kicks show claws and foot pads.

Each `<id>_poses.png` contains four reference-guided key-art views. The deterministic
`intro_cinematic.gd` timeline supplies shot changes, camera moves, impact zoom,
flash, citadel backdrop, typography and sound. These are motion-comic cinematics
with moving key art, not fully drawn frame-by-frame character animation.

`tools/index_intro_art.py` writes UV metadata to `data/intro_atlases.json` from the
alpha silhouettes. `tools/render_intros.sh` runs the Godot Movie Maker test scene
and encodes its AVI/WAV output using FFmpeg. Authoring PNGs, test scenes and tools
are excluded from the shipped PCK; the actual OGV movies are bundled for native
`VideoStreamPlayer` playback. REPLAY resets decoding; leaving the screen stops it.

## Validation and next art review

`tests/art.tscn` checks all ten portraits, atlas alpha, mesh bounds and pose/state
selection (229 checks). `tests/expansion_visual.tscn` renders the three individual
gallery sheets, decodes all ten films through their actual buttons, checks replay,
completion and returning to the same fighter, and renders the three new combat
sprites. `tools/verify_intros.py` fully decodes frame counts and compares footwear
and kick frames across all ten movies. See `TEST_LOG.md` for results and limits.

Original reference likeness, costume consistency, silhouette isolation and camera
framing were reviewed from rendered screenshots. Physical two-player keyboard,
real speaker output, balance and final artist review remain outstanding.


## Linux V12-prototype — echte procedurele volumes

`scripts/v12/fighter_model.gd` maakt tien nieuwe 3D-volumemodellen met een
hiërarchie van torso-, hoofd-, schouder-, elleboog-, heup- en kniegewrichten.
MeshInstances met StandardMaterial3D worden verlicht en werpen schaduwen in de
arena. Geometrie is nieuw procedureel werk, geen uitgesneden, geëxtrudeerde of
gebillboarde characterillustratie. Vinnen/hoorns/staarten, rattenoren en geel shirt,
rugspikes, roze kristallen, kettingen en vleugels volgen de aangeleverde
identiteitskenmerken. Crystal Fang en Phoenix behouden klauwvoeten. Geen logo's
of oorspronkelijke artworkbestanden zijn gewijzigd.

Dit is een eenvoudige gestileerde basis met gedeelde animatiepatronen, geen
productiesculpt, gewogen SkeletalMesh, mocap of uitgewerkte PBR-characterasset.
Lijkenis, anatomie, gezicht en character-specifieke animaties vereisen verdere
artistieke productie. De oude V11-portretten, sprites, galerij en films blijven
bewaard en worden op de bestaande mobiele/LAN-routes gebruikt. Blender 4.3.2 is
beschikbaar maar niet nodig voor deze procedurele modellen of de build.
