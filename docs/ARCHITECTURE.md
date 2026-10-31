# Prototype architecture — V10 / v0.10.0

Godot 4.6.3 standard / GDScript, Compatibility renderer, 60 Hz physics.
`scenes/main.tscn` is the F5 entry point. No network services or secrets are needed.

- `scripts/core/input_router.gd` reads physical keys from `data/input_layouts.json`.
  Each player owns held and edge-triggered state. Focus loss, countdown, pause,
  rounds and transitions clear inputs.
- `scripts/ui/game.gd` routes menu, connection, character select, arena, gallery,
  intro, options, pause and results on a logical 1280×720 stage. The root viewport
  renders at native surface pixels with Godot stretch disabled. The stage fits
  the safe rectangle without changing arena coordinates. Citadel draws over the
  full native viewport via view_rect, splitting at the fixed combat floor; HUD
  uses layout_hud with that same safe area. Gallery index survives intro playback.
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
The wrapper changes to its own folder before launching. The cinematic PNGs are runtime gallery/menu assets in V17 and are included.
Tests, tools, docs and release archives remain excluded.

All eight original sheets remain unchanged. DejaVu fonts, Godot's MIT license and
third-party notices accompany the native package. Final balance, music/voices,
physical-keyboard acceptance, later story chapters, rebinding and physical Android acceptance
remain follow-up work. All ten combat sets and the Android APK are implemented.

## Full roster and character presentation

`data/move_sets.json` defines 69 attacks/abilities. `MoveCatalog` builds independent
AttackData resources, applies profile overrides, resolves facing-relative directional
commands and supplies bindings for UI and AI. Meter costs, shared special cooldowns,
buffs, healing limits and KO restrictions are enforced in DuelFighter. Rebirth
explicitly permits hitstun escape; ordinary attacks cannot bypass stun. Volleys
split their total damage across three single-hit projectiles, preserving the
three-object cap. Low variants have genuine low hitboxes.

Ground locomotion accelerates at 3600 units/s², reverses at 5200 and uses lighter
air control. Physics interpolation and reset handling smooth world motion without
changing the 60 Hz deterministic simulation. FighterMotion samples movement curves at render cadence, with separate per-character
stride/bounce/lean profiles. Gait advances by traveled distance and reverses for
backsteps. Start, brake, pivot, rise/apex/fall/land and guard transitions are visual
only. Facing flips directly without squeezing the image, resets on round start
and freezes with pause. World movement remains physics-interpolated.

FighterVisual caches atlas polygons/UVs and only uploads changed geometry. Walking
uses a cached union mesh for adjacent poses and one GPU pass. WalkPoseFields loads
54 bidirectional vector fields derived by OpenCV from existing masked pose pixels.
The shader aligns both source poses before blending, with nearer-silhouette choice
at occlusions. A fallback subdivided mesh supports profiles without derived fields;
all ten current fighters have fields. Idle/attack transitions preserve opacity
through corrected over-compositing. Foot pivots anchor stretch/lean. Shared cached
motion textures are primed during match creation, before the countdown ends.

`FighterGallery` now loads one of ten real skinned Blender GLB characters through
`FighterPresentation`. `data/character_models.json` records each asset, immutable
shipped hash and full volume bounds. A Skeleton3D/AnimationPlayer drives the idle;
feet and model scale stay fixed. Standard physical materials carry embedded normal
maps and skin vertex colors. A TextureRect displays a dedicated SubViewport at
actual stage pixel density. Full-body perspective fitting projects every AABB
corner onto camera right/up axes with depth and framing margins, recalculating for
orbit and aspect changes. Portrait mode intentionally uses the upper envelope;
FULL BODY restores the complete character. Real mouse dragging and turn buttons
orbit the camera. Original sheet mode pauses both the presentation and animator.
See V13_GALLERY.md for the Blender recipe and validation. The old illustrated
presentation shader is retained for historical assets; it is not the new model.

`TouchControls` owns fixed analog thumbsticks separately from circular contacts.
A thumb owns its stick until release/cancel, with clamped travel and a deadzone.
InputRouter combines fractional touch axis with existing keyboard input and
clears both on transitions. Other fingers press the large basic attack, surrounding
heavy/special/ultimate/jump and nearby block. Readiness rings use actual actor
cooldowns/meter, including authoritative guest state.

## Direct sessions

`OnlineSession` owns an ENet peer and host-authoritative lobby. SessionCode makes
six random unambiguous characters. SessionDiscovery uses local UDP broadcast and
challenge-echoed unicast replies to resolve that code, keeping endpoints internal.
The UI has no address picker/input. There is no public directory, relay or NAT
traversal; the host device advertises only while waiting on the same Wi-Fi.
The reliable ENet handshake checks a separate room nonce, protocol and exact app
version. Each peer edits only its own selection/ready state. Android offers only
session-code versus or offline CPU. See NETWORK.md for port/reachability limits.

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

## V10 intact drawings and responsive display

FighterVisual caches immutable polygons, UVs, pivots and uniform atlas scales.
cel.gdshader samples the unmodified texture plus the hit flash; it has no vertex
or UV displacement. The previous-frame layer remains hidden. Walk and heavy each
select twelve new poses per fighter; other moves use their existing discrete
keys. Heavy times map semantic startup/active/recovery and hold extension during
contact. The old motion-field data/tools remain for historical reproduction but
are not loaded by the live sprite or podium renderer.

FighterPresentation uses the same discrete signature frames, an alpha-cutout
spatial material and an extruded mesh. A fixed envelope fits all signature poses;
its world, camera and rings persist after the entrance. New generated pose
polygons use convex alpha envelopes so thin hair/chains cannot self-intersect
and break Godot triangulation. Transparent pixels preserve the painted contour.
FighterBust crops separately painted 512×512 half-body artwork from two sheets.
It animates entrance alpha and rigid image position, without deforming anatomy.

The controller records walk_distance only for grounded free locomotion; the match
corrects it after push-box resolution. FighterMotion advances gait from that
ledger, rather than commanded speed. Network snapshots include the ledger and
locomotion speed; guests smooth travel with position. Strides span two steps,
torso anchors reduce lateral snapping, grounded offsets are zero and extra body
bounce/deformation is reduced. No movement data determines collision or damage.

DuelFighter.MAX_HEALTH is 200 (reset, healing cap and health HUD). Clean hits grant
the defender ceil(actual_damage*.35) meter; blocking retains four and all paths
cap at 100. CombatChrome draws bounded angular HUD plates. UltimateGauge uses a
small canvas shader with a gold pulse/streak at 100; TouchControls adds a matching
ULT halo. Gauge/touch clocks pause with combat. The ready state follows actual
meter, so spending or a new round updates it without separate readiness flags.


## V17 menu and story state

StoryCatalog reads four ordered levels from data/story_campaign.json. StorySelect
uses PlayerProgression.story_completed to gate cards. game.gd presents a briefing,
starts the normal DuelMatch with SharkByte and the specified CPU/map, and routes
results to retry, next-level or chapter-complete actions. Completed best-of-three
results still pay the ordinary wallet once; checkpoint persistence preserves the
V16 save fields and supplies zero story progress when the new field is absent.

FighterIllustration can frame into an explicit menu/briefing rectangle and face
either direction. Two distinct random profiles occupy separate menu rectangles.
Its main gallery path stays at native viewport density. The APK verifier follows
every illustration's import remap, and test_apk_ui.py runs only exported Android
assets in a temporary resourcepack. This detects missing textures that editor-only
renders cannot detect.
