class_name DuelFighter
extends Node2D
signal projectile_requested(fighter: DuelFighter, attack: AttackData)
const MAX_HEALTH := 200
const RECEIVED_METER_RATIO := 0.35
const FLOOR := 590.0
const LEFT := 70.0
const RIGHT := 1210.0
const ATTACKS := {
	"light": preload("res://data/attacks/light.tres"),
	"heavy": preload("res://data/attacks/heavy.tres"),
	"special": preload("res://data/attacks/special.tres"),
	"ultimate": preload("res://data/attacks/ultimate.tres")}
var player := 0
var profile: Dictionary = {}
var tint := Color("49c4d7")
var hp := MAX_HEALTH
var meter := 0
var facing := 1
var velocity := Vector2.ZERO
var guarding := false
var stun := 0.0
var immunity := 0.0
var special_cooldown := 0.0
var attack: AttackData
var attack_time := 0.0
var hit_connected := false
var emitted := false
var buffered := ""
var buffer_time := 0.0
var combo := 0
var combo_time := 0.0
var received_chain := 0
var received_time := 0.0
var flash := 0.0
var anim_time := 0.0
var show_hitboxes := false
var visual: FighterVisual
var moves: Dictionary = {}
var attack_variant := ""
var armor_time := 0.0
var empower_time := 0.0
var jump_buffer := 0.0
var coyote_time := 0.0
var walk_distance := 0.0
var locomotion_speed := 0.0
var step_start_x := 0.0
var last_walk_delta := 0.0

func _ready() -> void:
	moves = MoveCatalog.build(profile, ATTACKS)
	visual = FighterVisual.new()
	visual.profile = profile
	visual.actor = self
	visual.accent = tint
	add_child(visual)

func reset_at(x: float, keep_meter := false) -> void:
	position = Vector2(x, FLOOR)
	velocity = Vector2.ZERO
	hp = MAX_HEALTH
	if not keep_meter: meter = 0
	facing = 1 if player == 0 else -1
	guarding = false
	stun = 0.0
	immunity = 0.0
	special_cooldown = 0.0
	attack = null
	buffered = ""
	buffer_time = 0.0
	combo = 0
	combo_time = 0.0
	received_chain = 0
	received_time = 0.0
	flash = 0.0
	attack_variant = ""
	armor_time = 0.0
	empower_time = 0.0
	jump_buffer = 0.0
	coyote_time = 0.0
	walk_distance = 0
	locomotion_speed = 0
	last_walk_delta = 0
	reset_physics_interpolation()
	if is_instance_valid(visual): visual.reset_motion()
	queue_redraw()

func grounded() -> bool:
	return position.y >= FLOOR - 0.1

func step(delta: float, input: Dictionary, opponent: DuelFighter) -> void:
	step_start_x = position.x
	last_walk_delta = 0
	locomotion_speed = 0
	anim_time += delta
	armor_time = maxf(0.0, armor_time - delta)
	empower_time = maxf(0.0, empower_time - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	coyote_time = 0.09 if grounded() else maxf(0.0, coyote_time - delta)
	if input.get("jump", false): jump_buffer = 0.12
	flash = maxf(0.0, flash - delta)
	stun = maxf(0.0, stun - delta)
	immunity = maxf(0.0, immunity - delta)
	special_cooldown = maxf(0.0, special_cooldown - delta)
	combo_time = maxf(0.0, combo_time - delta)
	received_time = maxf(0.0, received_time - delta)
	if combo_time == 0.0: combo = 0
	if received_time == 0.0: received_chain = 0
	buffer_time = maxf(0.0, buffer_time - delta)
	if buffer_time == 0.0: buffered = ""
	if not attack and stun == 0.0 and hp > 0:
		facing = 1 if opponent.position.x >= position.x else -1
	var requested := ""
	for id in ["light", "heavy", "special", "ultimate"]:
		if input.get(id, false): requested = MoveCatalog.resolve(moves, id, input, facing)
	guarding = input.get("block", false) and requested == "" and grounded() and not attack and stun == 0.0 and hp > 0
	if requested != "" and stun > 0 and moves[requested].escape_stun:
		begin_attack(requested)
	if attack:
		attack_time += delta
		if requested != "" and attack.duration() - attack_time <= 0.16:
			buffered = requested
			buffer_time = 0.16
		if not emitted and is_active():
			emitted = true
			if is_projectile_attack(attack.id): projectile_requested.emit(self, attack)
			armor_time = maxf(armor_time, attack.armor_time)
			empower_time = maxf(empower_time, attack.empower_time)
			if not attack.escape_stun: immunity = maxf(immunity, attack.invulnerable_time)
			hp = mini(MAX_HEALTH, hp + attack.heal)
		# A landed light can cancel its recovery into a follow-up; startup/active are never skipped.
		if attack.slot == "light" and hit_connected and attack_time >= attack.startup + attack.active and requested != "" and moves[requested].slot in ["light", "heavy", "special"]:
			attack = null
		if attack and attack_time >= attack.duration():
			attack = null
			if buffered != "" and buffer_time > 0:
				requested = buffered
				buffered = ""
	if not attack and stun == 0.0 and not guarding and hp > 0:
		if requested != "":
			begin_attack(requested)
		if not attack:
			var desired := float(input.get("axis", 0)) * float(profile.get("combat",{}).get("speed",285.0))
			var acceleration := (5200.0 if velocity.x * desired < 0 else 3600.0) if grounded() else 2600.0
			velocity.x = move_toward(velocity.x, desired, delta * acceleration)
			if jump_buffer > 0 and coyote_time > 0:
				velocity.y = -700.0
				jump_buffer = 0.0
				coyote_time = 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 1800)
	if attack and attack_kind(attack.id) == "dash" and is_active():
		velocity.x = facing * (attack.dash_speed if attack.dash_speed > 0 else float(profile.get("combat",{}).get("dash_speed",500.0)))
	if not grounded() or velocity.y < 0: velocity.y += 1800.0 * delta
	position += velocity * delta
	position.x = clampf(position.x, LEFT, RIGHT)
	if position.y >= FLOOR:
		position.y = FLOOR
		velocity.y = 0
	if not attack and stun <= 0 and not guarding and grounded():
		last_walk_delta = position.x-step_start_x
		walk_distance += last_walk_delta
		locomotion_speed = last_walk_delta/maxf(delta,.00001)
	queue_redraw()

func begin_attack(id: String) -> bool:
	if not moves.has(id) or attack or guarding or hp <= 0: return false
	var move: AttackData = moves[id]
	if stun > 0 and not move.escape_stun: return false
	if move.slot == "special" and special_cooldown > 0: return false
	if meter < move.meter_cost: return false
	meter -= move.meter_cost
	if move.slot == "special": special_cooldown = move.cooldown
	attack = move.duplicate()
	if empower_time > 0 and attack.damage > 0: attack.damage = int(ceil(attack.damage * 1.2))
	attack_time = 0.0
	hit_connected = false
	emitted = false
	attack_variant = "trap" if attack.kind == "cheese_trap" else ""
	if move.escape_stun:
		stun = 0.0
		buffered = ""
		immunity = maxf(immunity, move.invulnerable_time)
	if attack.launch < 0 and grounded(): velocity.y = attack.launch
	if move.slot == "ultimate": Sound.play("ultimate")
	return true

func is_active() -> bool:
	return attack != null and attack_time >= attack.startup and attack_time < attack.startup + attack.active

func hurtbox() -> Rect2:
	return Rect2(position + Vector2(-33, -225), Vector2(66, 225))

func hitbox() -> Rect2:
	if not attack: return Rect2()
	if attack.kind == "area":
		return Rect2(position + Vector2(-attack.reach, -270), Vector2(attack.reach * 2, 300))
	if attack.command == "down" and attack.slot == "light":
		return Rect2(position + Vector2(18 if facing == 1 else -18 - attack.reach, -95), Vector2(attack.reach, 95))
	return Rect2(position + Vector2(18 if facing == 1 else -18 - attack.reach, -205), Vector2(attack.reach, 115))

func pending_hit(target: DuelFighter) -> bool:
	if not is_active() or hit_connected or attack.damage <= 0: return false
	# Projectile attacks apply their hit once through their projectile, never twice.
	if is_projectile_attack(attack.id): return false
	return hitbox().intersects(target.hurtbox()) and target.immunity <= 0.0 and target.hp > 0

func attack_kind(id: String) -> String:
	if moves.has(id): return moves[id].kind
	return profile.get("combat",{}).get(id+"_kind","melee")

func is_projectile_attack(id: String) -> bool:
	return attack_kind(id) in ["ground_shock", "toxic_orb", "venom_cloud", "cheese_ball", "cheese_king", "cheese_trap", "cheese_storm", "ember_bolt", "infernal_rift", "spike_volley", "spineburst", "stone_spikes", "earthquake", "crystal_spikes", "crystal_storm", "heat_wave", "fire_tornado", "solar_flare"]

func receive_hit(move: AttackData, attacker_x: float) -> bool:
	if immunity > 0.0 or hp <= 0: return false
	var toward := 1 if attacker_x >= position.x else -1
	var blocked := guarding and grounded() and toward == facing
	var damage := maxi(1, int(ceil(move.damage * 0.25))) if blocked else move.damage
	if armor_time > 0: damage = maxi(1, int(ceil(damage * 0.5)))
	hp = maxi(0, hp - damage)
	flash = 0.12
	if blocked:
		meter = mini(100, meter + 4)
		velocity.x = -toward * move.knockback * 0.25
		Sound.play("block")
	else:
		meter = mini(100,meter+maxi(1,int(ceil(damage*RECEIVED_METER_RATIO))))
		stun = move.hitstun
		velocity.x = -toward * move.knockback
		attack = null
		buffered = ""
		guarding = false
		received_chain += 1
		received_time = 1.2
		if received_chain >= 3:
			immunity = move.hitstun + 0.18
			received_chain = 0
		Sound.play("hit")
	return not blocked

func _draw() -> void:
	draw_set_transform(Vector2(0,FLOOR-position.y+3),0,Vector2(1,0.19))
	draw_circle(Vector2.ZERO,68,Color(0,0,0,0.32))
	draw_circle(Vector2.ZERO,43,Color(0,0,0,0.25))
	draw_set_transform(Vector2.ZERO)
	if show_hitboxes:
		draw_rect(Rect2(Vector2(-33,-225),Vector2(66,225)),Color(0,1,0,0.25))
		if is_active(): draw_rect(Rect2(hitbox().position-position,hitbox().size),Color(1,0,0,0.3))
