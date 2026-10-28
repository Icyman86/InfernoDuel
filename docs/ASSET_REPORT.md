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

## Runtime implementation — 27 October 2026

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
