# Prototype architecture — V6 / v0.6.0

Godot 4.6.3 standard / GDScript, Compatibility renderer, 60 Hz physics.
`scenes/main.tscn` is the F5 entry point. No network services or secrets are needed.

- `scripts/core/input_router.gd` reads physical keys from `data/input_layouts.json`.
  Each player owns held and edge-triggered state. Focus loss, countdown, pause,
  rounds and transitions clear inputs.
- `scripts/ui/game.gd` routes menu, connection, character select, arena, gallery,
  intro, options, pause and results on a logical 1280×720 stage. The root viewport
  renders at native surface pixels with Godot stretch disabled. The stage fits
  the safe rectangle without changing arena coordinates. Gallery index survives intro playback.
- `fighter_controller.gd` owns deterministic movement, facing, attack lifecycle,
  blocking, hitstun, cooldowns and meter. Each fighter duplicates base `AttackData`
  resources before applying data-driven overrides, avoiding shared-state mutations.
- `data/attacks/*.tres` defines startup, active, recovery, damage, reach, knockback,
  hitstun, meter and cooldown. A 160 ms recovery buffer supports chaining; landing jumps have a 120 ms buffer. A landed
  light can cancel recovery; three consecutive hits grant brief escape immunity.
- `data/fighters.json` marks all ten fighters playable and stores movement speeds,
  special/ultimate kinds and overrides. Playability is not inferred from roster index.
- `match_controller.gd` handles countdown, 60-second rounds, first-to-two wins,
  timeout/draw retry, HUD, CPU routing and projectiles. Meter persists between
  rounds; rematch resets it. At most three active projectiles/traps per owner.
- `ai_controller.gd` emits the same input dictionary as human input. No direct
  damage manipulation or unlimited meter is used.
- `projectile.gd` implements Bullet ground shock, PoisonBoy toxic orb/venom cloud,
  and Cheese Rat cheese ball/trap/king. Backward + special chooses Cheese Trap.
  Traps last four seconds and hit the enemy once. Chainveil uses extended melee
  ranges and negative knockback to pull targets. SharkByte retains his dash/melee.
- `settings.gd` stores volume/fullscreen preferences in `user://settings.cfg`.
  `sound.gd` synthesizes bounded short SFX. Recorded music and voices are absent.

## Collision and presentation

World-space Rect2 hurtboxes, melee boxes and projectile boxes define combat.
Bodies resolve overlap separately. Each physics tick moves both fighters, collects
eligible hits, then applies them to preserve same-tick trades and double KOs.
Each melee activation/projectile hits once. F3 displays tuning boxes.

`FighterVisual` reads controller state and selects textured UV meshes and pivots
from `data/sprite_atlases.json`. It does not own damage or movement. `FighterPortrait`
creates views of immutable source sheets; the gallery uses separate AtlasTexture
views for Bullet, Nachtelf and PoisonBoy. `HitBurst` supplies transient impact FX.

`FighterIntroPlayer` plays a bundled OGV using VideoStreamPlayer and the SFX bus.
REPLAY restarts it; BACK/Esc returns to the same gallery fighter. `IntroCinematic`
is an authoring-only deterministic camera/key-art timeline used by Movie Maker.
See `ART_PIPELINE.md` for artwork provenance and the film generation commands.

## Packaging and remaining scope

`tools/build_linux.sh` exports a PCK and pairs it with an exactly matching official
Linux release template, or falls back to the editor engine if none is supplied.
The published v0.3 uses the official 4.6.3 Linux release template. The executable
and PCK share the InfernoDuel basename, allowing standard adjacent-pack discovery.
The wrapper changes to its own folder before launching. Authoring intro PNGs,
tests, tools, docs and release archives are excluded from the pack.

All eight original sheets remain unchanged. DejaVu fonts, Godot's MIT license and
third-party notices accompany the native package. Final balance, music/voices,
physical-keyboard acceptance, Story, rebinding and physical Android acceptance
remain follow-up work. All ten combat sets and the Android APK are implemented.

## Full roster and move lab

`data/move_sets.json` defines 69 attacks/abilities. `MoveCatalog` builds independent
AttackData resources, applies profile overrides, resolves facing-relative directional
commands and supplies bindings for UI and AI. Meter costs, shared special cooldowns,
buffs, healing limits and KO restrictions are enforced in DuelFighter. Rebirth
explicitly permits hitstun escape; ordinary attacks cannot bypass stun. Volleys
split their total damage across three single-hit projectiles, preserving the
three-object cap. Low variants have genuine low hitboxes.

Ground locomotion accelerates at 3600 units/s², reverses at 5200 and uses lighter
air control. Physics interpolation and reset handling smooth world motion without
changing the 60 Hz deterministic simulation. Sprite keys blend separately over
55 ms and track authored active/recovery phases.

`MoveShowcase` subclasses DuelMatch in a 2D-only SubViewport. It replaces the HUD
with a training dummy/readout, scripts commands through the same move catalogue,
refills meter between demonstrations and has no link to match progression.
`FighterGallery` offers autoplay, manual scrollable move buttons, original-sheet
view and existing intro navigation. Changing fighter destroys the previous preview;
viewing the original sheet stops both its simulation and viewport rendering.
The move lab and offline modes need no service or account.

## Direct sessions

`OnlineSession` owns an ENet peer and the host-authoritative lobby. `SessionCode`
encodes the IPv4 endpoint, random room nonce, protocol and typo checksum; there
is no directory or NAT traversal. A reliable handshake checks the nonce and
exact application version. Each peer can edit only its own fighter/ready state.
Android exposes session-code play and offline CPU, with no local-versus route.

`NetworkMatchDriver` supplies the host's DuelMatch with local and bounded guest
inputs. The host alone simulates collisions, damage, rounds and wins at 60 Hz.
Guest input edges use a sequenced reliable channel; held controls expire after
350 ms without fresh input. Countdown, pause and round transitions gate inputs.
The guest renders 20 Hz authoritative snapshots with transform smoothing and
visual-only projectiles. It does not decide damage, and has no rollback or
client-side movement prediction. This targets low-latency LAN play.

Reliable pause snapshots keep both timers frozen; either peer may pause, and
all pause votes must be released before resuming. Results are reliable; rematch
requires both votes and increments an epoch to reject prior-match packets.
An eight-second gameplay heartbeat timeout stops lost sessions. Disconnects
close the ENet peer on a deferred call, outside SceneMultiplayer's packet poll.
See NETWORK.md for endpoint reachability and testing limits.
