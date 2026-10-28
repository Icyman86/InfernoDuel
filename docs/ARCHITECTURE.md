# Prototype architecture

Godot 4.6.3 standard / GDScript, Compatibility renderer, 60 Hz physics.
`scenes/main.tscn` is the F5 entry point. No network services or secrets are needed.

- `scripts/core/input_router.gd`: reads physical key events using `data/input_layouts.json`. Each player owns separate held and edge-triggered state. Focus loss, countdown, pause, rounds, and scene changes clear input.
- `scripts/ui/game.gd`: screen transitions, confirmation dialogs, focus-loss pause, shared 1280×720 stage. Separate character select, gallery, options, UI theme, and procedural arena scripts keep each responsibility contained.
- `scenes/combat/fighter.tscn` and `fighter_controller.gd`: shared deterministic movement, facing, attack lifecycle, block, hitstun, cooldown, meter, and temporary mannequin rendering. Two profiles use different dash speeds. Real character animations remain unimplemented.
- `data/attacks/*.tres`: reusable `AttackData` resources define startup, active, recovery, damage, reach, knockback, hitstun, meter, and cooldown. A 120 ms late-recovery input buffer supports chaining. A successful light may cancel recovery into light/heavy/special. Three consecutive hits grant brief defender escape immunity.
- `scenes/combat/match.tscn` and `match_controller.gd`: countdown, 60-second rounds, first-to-two wins, timeout/draw retry, HUD, CPU routing, and projectile lifecycle. Meter persists between rounds; rematch resets everything.
- `ai_controller.gd`: Easy CPU generates the same input dictionary consumed by a human-controlled fighter. No direct HP manipulation or unlimited meter.
- `projectile.gd`: Bullet's ultimate travels as a ground shock; SharkByte's ultimate uses a close-range hitbox. Specials are Fin Dash and Bull Charge. These are starting interpretations for the two prototype movesets, not complete final movesets.
- `settings.gd`: volume buses and fullscreen/window configuration stored in `user://settings.cfg`.
- `sound.gd`: original synthesized placeholder SFX; no music recording is bundled. Music bus/slider is prepared and labeled accordingly.

## Collision model

This small two-fighter prototype uses explicit world-space Rect2 hurtboxes,
attack boxes, and projectile boxes instead of physics collision-layer nodes.
Bodies resolve overlap separately. Arena decorations have no collision.
Each physics tick first moves both fighters, then collects all eligible hit events,
then applies them. This preserves same-tick trades, including double KO.
One melee hit per activation and one hit per projectile prevent repeated damage.
F3 toggles visible hurtboxes and active melee hitboxes for tuning.

## Assets

All eight original sheets remain byte-identical and appear only as complete
reference sheets in the gallery. Combat geometry is deliberately labeled as a
prototype. No automatic cropping, synthesized character sprites, or final animation
claims. JSON retains all ten fighters; only indices 0/1 are enabled in v0.1.
DejaVu fonts are bundled with their license. Godot's MIT license accompanies
the optional native package. See `ASSET_REPORT.md` for the next art tasks.

## Scope still ahead

Validated transparent animation frames, all ten unique movesets, final arena art,
recorded audio/music, balance and physical-keyboard acceptance testing, and a
small release-template Linux export. Story, rebinding, and Android remain later work.
