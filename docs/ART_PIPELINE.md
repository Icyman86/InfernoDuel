# Illustrated fighter expansion v0.3 — 28 October 2026

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
