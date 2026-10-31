# Current roster assets — v0.5, 29 October 2026

All ten fighters have playable animated combat sets and animated selection/move-lab
previews. Five new 24-key base atlases and four eight-key supplemental atlases were
generated from the supplied designs; alpha/meshes/poses are validated. These are
new reference-guided derivatives, not original hand-drawn animation. All eight
original sheets remain byte-identical. See ART_PIPELINE and the provenance manifest
for exact paths and hashes. Original sheets and all ten intro movies remain
available. More in-betweens, artist polish, music, Story and on-device balance/feel
remain separate work; no fighter slot is left marked COMING SOON.

The report below is historical and describes the earlier five-fighter build.

# Asset import report

Status: source files are **never modified**.

| Name | Status | Destination |
|---|---|---|
| SharkByte Fighting Game Character Sheet.png | BUNDLED_VERIFIED_ORIGINAL | assets/originals/character_sheets_2026-10-27/SharkByte Fighting Game Character Sheet.png |
| Spinegrin_ Inferno Duel Character Sheet.png | BUNDLED_VERIFIED_ORIGINAL | assets/originals/character_sheets_2026-10-27/Spinegrin_ Inferno Duel Character Sheet.png |
| Chainveil_ Inferno Duel Character Sheet.png | BUNDLED_VERIFIED_ORIGINAL | assets/originals/character_sheets_2026-10-27/Chainveil_ Inferno Duel Character Sheet.png |
| Dark Fantasy Fighting Game Character Sheet.png | BUNDLED_VERIFIED_ORIGINAL | assets/originals/character_sheets_2026-10-27/Dark Fantasy Fighting Game Character Sheet.png |
| WhatsApp Image 2026-10-25 at 18.59.15.jpeg | BUNDLED_VERIFIED_ORIGINAL | assets/originals/character_sheets_2026-10-27/WhatsApp Image 2026-10-25 at 18.59.15.jpeg |
| WhatsApp Image 2026-10-25 at 19.53.45.jpeg | BUNDLED_VERIFIED_ORIGINAL | assets/originals/character_sheets_2026-10-27/WhatsApp Image 2026-10-25 at 19.53.45.jpeg |
| WhatsApp Image 2026-10-27 at 20.17.30.jpeg | BUNDLED_VERIFIED_ORIGINAL | assets/originals/character_sheets_2026-10-27/WhatsApp Image 2026-10-27 at 20.17.30.jpeg |
| WhatsApp Image 2026-10-27 at 20.18.10.jpeg | BUNDLED_VERIFIED_ORIGINAL | assets/originals/character_sheets_2026-10-27/WhatsApp Image 2026-10-27 at 20.18.10.jpeg |
| Spinegrin: Inferno Duel Character Sheet.png | OPTIONAL_NOT_PROVIDED |  |
| Chainveil: Inferno Duel Character Sheet.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_FighterArt_Bullet.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_FighterArt_Nachtelf.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_FighterArt_Poisonboy.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_Bullet_Sprite_Vergelijking.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_Nachtelf_Sprite_Vergelijking.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_PoisonBoy_Sprite_Vergelijking.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_Bullet_Sprite_Vergelijking(1).png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_Nachtelf_Sprite_Vergelijking(1).png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_PoisonBoy_Sprite_Vergelijking(1).png | OPTIONAL_NOT_PROVIDED |  |
| Dark Fantasy Fighting Game Character Sheet(1).png | OPTIONAL_NOT_PROVIDED |  |
| Dark Fantasy Fighting Game Character Sheet(2).png | OPTIONAL_NOT_PROVIDED |  |
| Dark Fantasy Fighter Roster Sheet.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno Fighters Character Sheet.png | OPTIONAL_NOT_PROVIDED |  |
| Infernal Fighters: Bullet, Nachtelf, PoisonBoy.png | OPTIONAL_NOT_PROVIDED |  |
| Dark Fantasy Fighting Game Character Showcase.png | OPTIONAL_NOT_PROVIDED |  |
| Infernal Fighting Game Character Showcase.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno Duel: Legends Game UI Showcase.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno Duel Legends: Clash of Champions.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno Duel: Neon Legends Showcase.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno Duel: Legends Promotional Game Poster.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_Legends_Gameplay.png | OPTIONAL_NOT_PROVIDED |  |
| Inferno_Legends_Gameplay(1).png | OPTIONAL_NOT_PROVIDED |  |
| Neon Demon in the Infernal Citadel.png | OPTIONAL_NOT_PROVIDED |  |
| Neon Warden of the Infernal Citadel.png | OPTIONAL_NOT_PROVIDED |  |
| Infernal Green-Haired Character Showcase.png | OPTIONAL_NOT_PROVIDED |  |
| Neon Skull Streetwear Character Sheet.png | OPTIONAL_NOT_PROVIDED |  |
| inferno_duel_fight.png | OPTIONAL_NOT_PROVIDED |  |
| Dark Elf Warlock Before the Infernal Titan.png | OPTIONAL_NOT_PROVIDED |  |

## Historical v0.1 runtime implementation — 27 October 2026

- All eight original source images pass `tools/verify_assets.py` (8/8). No original was edited, cropped, recompressed, or replaced.
- All ten gallery entries display their corresponding complete original reference sheet. Bullet, Nachtelf, and PoisonBoy intentionally share one sheet.
- SharkByte and Bullet use explicitly labeled geometric training mannequins in combat. These are functional placeholders, not extracted or final character animation.
- Other eight fighters have visible COMING SOON cards and an explanatory response when selected. Their reference art and move data are retained.
- The citadel is currently procedural geometry with drifting smoke/embers and lava lines. Final environment art remains a TODO.
- Original synthesized short SFX are implemented; music/voice recordings are absent. The Music slider is labeled as prepared with no music asset yet.
- DejaVu Sans and DejaVu Serif Bold are bundled under `assets/fonts/` with license. Godot's license and third-party notices are included under `docs/` and copied into the native package.

### Next art tasks

1. `assets/sprites/sharkbyte/`: create and validate separate transparent idle, walk, jump, light, heavy, special, ultimate, hit, block, KO, victory frames from the approved design.
2. `assets/sprites/bullet/`: same frame/pivot/silhouette validation; original shared sheet remains untouched.
3. `scenes/combat/fighter.tscn`: add AnimatedSprite2D once frames have been reviewed; keep the combat/hitbox controller independent of rendering.
4. Add final Infernal Citadel artwork, licensed/owned music and voices, then expand the remaining eight combat profiles.

## Visual update v0.2 — 28 October 2026

The runtime placeholder status above describes v0.1. In v0.2, SharkByte and Bullet
have illustrated reference-derived sprite atlases, thirty indexed keys each, with
state/timing-driven playback. These are new generated derivatives, not original
animation frames found in the ZIP. All ten fighters have distinct original-sheet
portrait crops, with animated previews for the two playable fighters. Original
files remain unchanged. New citadel artwork, menu heroes, HUD portraits, impact
FX and result art are integrated. See `ART_PIPELINE.md` and the provenance manifest.

## Current fighter expansion v0.3 — 28 October 2026

This section supersedes the historical placeholder and two-fighter status above.
PoisonBoy, Chainveil and Cheese Rat now join SharkByte and Bullet as playable
illustrated fighters. New sets have 24 unique pose keys each; the first two retain
30 each. All five have animated previews and all ten have individual portraits.

Bullet, Nachtelf and PoisonBoy each have a dedicated AtlasTexture gallery view of
their own source column. All ten roster entries have a real 720p, 30 FPS intro film
with footwear close-up and front kick toward camera. Crystal Fang/Phoenix Reign
retain original claw feet. Generated key art and cinematic derivatives are labeled
in `data/visual_asset_provenance.json`; no supplied image was modified.

The published Linux bundle uses the official Godot 4.6.3 Linux release template.
Source integrity remains 8/8 SHA-256 matches. See `ART_PIPELINE.md` for the authoring
pipeline and `TEST_LOG.md` for validation. The remaining five combat characters,
extra move variants, animation in-betweens, final music/voices and balance remain
future work; the old v0.1 Next art tasks list is historical.

## V16 — twee nieuwe fighters en 2D-gallery

Bamboo Blade en Sawtina gebruiken hun twee ongewijzigde JPEG-uploads als bron.
Elke fighter heeft een afzonderlijk gegenereerde transparante 24-key combat-atlas,
twee extra ultimate-poses, vier cinematic views en een daadwerkelijk gerenderde
6,43s Theora-intro. Het zijn afgeleide game-assets; ze worden niet als originele
uploadframes voorgesteld. De authoringtools `index_v16_art.py`,
`index_intro_art.py` en `render_intros.sh` maken dit herhaalbaar.

De gebruiker wees de 3D-gallery af vanwege de kwaliteit en lichaamsverhoudingen.
FIGHTERS toont daarom voor alle twaalf fighters de hoge-resolutie 2D-illustraties,
met volledig lichaam, portret en signature-pose. Er worden geen PNG-pixels bewerkt
of anatomieën vervormd; Polygon2D gebruikt de bestaande transparante silhouette-
metadata. De volledige illustratie past met marge in de native preview.
De afgewezen nieuwe 3D-iteraties staan alleen in de genegeerde lokale buildsmap.
Oudere V13-bestanden en downloads blijven behouden.

## V17 — packaged gallery artwork

The original user artwork and generated PNG pixels are unchanged. V16's export
filter excluded the cinematic PNGs now used by FIGHTERS, leaving white Polygon2D
shapes in the shipped app. V17 removes the exclusion and checks the remap and
imported texture for each of twelve fighters. A separate renderer reads only the
built APK assets and confirms real colored characters, including Cheese Rat.
The same illustrations now supply distinct, non-overlapping random menu rivals
and story briefings. No new character artwork was invented for the story levels.
