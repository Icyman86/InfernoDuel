# Visual update v0.2 — 28 October 2026

## What changed

The geometric fighter renderer has been replaced by illustrated alpha-textured
animation sets for SharkByte and Bullet. Bullet now follows the actual supplied
human design: tattooed man, long reddish hair, red skull tank and black trousers.
He is not rendered as a horned bull. SharkByte retains his navy shark body, blue
fins/tail, leather jacket, white trousers and dark shoes.

All ten roster entries have individual portraits extracted at runtime via
`AtlasTexture` coordinates into their original sheets. No original image has been
edited. The two playable fighters have animated selection previews. Portraits also
appear in the HUD, arena selection and gallery navigation; results show the winner.

The Infernal Citadel uses a new detailed illustrated arena plate with animated
embers and subtle living lava light. Menu and selection overlays preserve contrast.
Impact bursts, special afterimages, hit flash, team rim accents and a ground shock
replace the most conspicuous geometric effect placeholders.

## Provenance and source integrity

New files in `assets/sprites/` are **reference-guided generated derivatives**, made
with the image-generation tool using the actual user-supplied SharkByte and classic
trio sheets. They are not pre-existing animation files from the user's ZIP. The
arena plate is newly generated to match the Infernal Citadel brief.

The ZIP contained composed character/move sheets, not separate transparent runtime
frames. Original files under `assets/originals/character_sheets_2026-10-27/` remain
byte-identical; `python3 tools/verify_assets.py` still verifies all eight SHA-256s.
`data/visual_asset_provenance.json` records derived-asset hashes and references.

## Sprite animation and rendering

Each fighter has three alpha PNG atlases:

- `core.png`: four idle keys, four retained legacy walk keys, four punch keys and
  four heavy-kick keys. The old four-step walk is retained as source material but
  replaced in playback by the dedicated six-frame cycle.
- `walk.png`: six contact/down/passing keys for locomotion.
- `actions.png`: block, jump, two dash poses, two ultimate poses, hit reaction and KO.

There are 30 indexed pose keys per fighter, 60 total. A pose key is not a promise
of 30 separate fully hand-drawn in-between frames for every action. Idle and walk
loop; attacks use authored anticipation/extension/recovery keys. Grounding, hit
reaction, secondary breathing and the world movement supply additional motion.

`data/sprite_atlases.json` records per-frame source rectangles, ground pivots,
texture scale and convex silhouette meshes. Meshes isolate neighbouring characters
when their rectangular bounding boxes overlap. Opaque-pixel component analysis
confirmed that no other character lies within each frame mesh. This indexing reads
images and produces metadata; it does not repaint or rewrite the art.

`FighterVisual` selects poses from the controller's state. Attack art progresses
through startup, active and recovery phases, so the full-extension heavy frame
coincides with an active hitbox. KO, guard, jump and stun have dedicated silhouettes.
Pause freezes the visual clock. Team colors affect a subtle rim, preserving outfits.
Hurtbox height, strike height and body spacing were adjusted for the taller artwork.

## Checks and remaining art review

`tests/art.tscn` adds 103 checks covering all ten portrait regions, distinct crops,
alpha transparency, bounded frame meshes, all animation states, attack-frame timing,
KO/guard selection and pause. Existing 70 combat/flow tests and nine rendered
integration checks remain required. The deterministic `tests/showcase.tscn` can be
recorded with Godot Movie Maker to review every state in motion.

These are first integrated illustrated animation sets. Artist review of likeness,
frame-to-frame volume, foot sliding, facial consistency and extra in-betweens is
still useful; this is not a claim of final studio animation quality. The other eight
fighters have avatars and reference art, but are not yet complete combat characters.
Physical two-player keyboard and actual audio tests remain outstanding.
