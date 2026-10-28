class_name DuelFighter
extends Node2D
signal projectile_requested(fighter: DuelFighter, attack: AttackData)
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
var hp := 100
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

func reset_at(x: float, keep_meter := false) -> void:
	position = Vector2(x, FLOOR)
	velocity = Vector2.ZERO
	hp = 100
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
	queue_redraw()

func grounded() -> bool:
	return position.y >= FLOOR - 0.1

func step(delta: float, input: Dictionary, opponent: DuelFighter) -> void:
	anim_time += delta
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
	guarding = input.get("block", false) and grounded() and not attack and stun == 0.0 and hp > 0
	var requested := ""
	for id in ["light", "heavy", "special", "ultimate"]:
		if input.get(id, false): requested = id
	if attack:
		attack_time += delta
		if requested != "" and attack.duration() - attack_time <= 0.12:
			buffered = requested
			buffer_time = 0.12
		if not emitted and attack.id == "ultimate" and profile.get("id") == "bullet" and is_active():
			emitted = true
			projectile_requested.emit(self, attack)
		# A landed light can cancel its recovery into a follow-up; startup/active are never skipped.
		if attack.id == "light" and hit_connected and attack_time >= attack.startup + attack.active and requested in ["light", "heavy", "special"]:
			attack = null
		if attack and attack_time >= attack.duration():
			attack = null
			if buffered != "" and buffer_time > 0:
				requested = buffered
				buffered = ""
	if not attack and stun == 0.0 and not guarding and hp > 0:
		if requested != "": begin_attack(requested)
		if not attack:
			velocity.x = float(input.get("axis", 0)) * (330.0 if profile.get("id") == "sharkbyte" else 285.0)
			if input.get("jump", false) and grounded(): velocity.y = -700.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 1100)
	if attack and attack.id == "special" and is_active():
		velocity.x = facing * (620.0 if profile.get("id") == "sharkbyte" else 500.0)
	if not grounded() or velocity.y < 0: velocity.y += 1800.0 * delta
	position += velocity * delta
	position.x = clampf(position.x, LEFT, RIGHT)
	if position.y >= FLOOR:
		position.y = FLOOR
		velocity.y = 0
	queue_redraw()

func begin_attack(id: String) -> bool:
	if not ATTACKS.has(id) or attack or stun > 0 or guarding or hp <= 0: return false
	var move: AttackData = ATTACKS[id]
	if id == "special" and special_cooldown > 0: return false
	if meter < move.meter_cost: return false
	meter -= move.meter_cost
	if id == "special": special_cooldown = move.cooldown
	attack = move
	attack_time = 0.0
	hit_connected = false
	emitted = false
	if id == "ultimate": Sound.play("ultimate")
	return true

func is_active() -> bool:
	return attack != null and attack_time >= attack.startup and attack_time < attack.startup + attack.active

func hurtbox() -> Rect2:
	return Rect2(position + Vector2(-29, -145), Vector2(58, 145))

func hitbox() -> Rect2:
	if not attack: return Rect2()
	return Rect2(position + Vector2(18 if facing == 1 else -18 - attack.reach, -126), Vector2(attack.reach, 93))

func pending_hit(target: DuelFighter) -> bool:
	if not is_active() or hit_connected: return false
	# Bullet's ultimate is a traveling ground shock, never also a melee hit.
	if attack.id == "ultimate" and profile.get("id") == "bullet": return false
	return hitbox().intersects(target.hurtbox()) and target.immunity <= 0.0 and target.hp > 0

func receive_hit(move: AttackData, attacker_x: float) -> bool:
	if immunity > 0.0 or hp <= 0: return false
	var toward := 1 if attacker_x >= position.x else -1
	var blocked := guarding and grounded() and toward == facing
	var damage := maxi(1, int(ceil(move.damage * 0.25))) if blocked else move.damage
	hp = maxi(0, hp - damage)
	flash = 0.12
	if blocked:
		meter = mini(100, meter + 4)
		velocity.x = -toward * move.knockback * 0.25
		Sound.play("block")
	else:
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
	var color := Color.WHITE if flash > 0 else tint
	draw_set_transform(Vector2.ZERO)
	draw_ellipse_shadow()
	var bob := sin(anim_time * 5.0) * 3.0 if grounded() and not attack else 0.0
	draw_set_transform(Vector2(0, bob), 0, Vector2(facing, 1))
	# Deliberately geometric training mannequins, not fabricated character sprites.
	var stance := sin(anim_time * 12) * 10 if absf(velocity.x) > 20 else 0.0
	draw_line(Vector2(-12, -60), Vector2(-23 - stance, -9), Color("d4ccd0"), 18, true)
	draw_line(Vector2(12, -60), Vector2(24 + stance, -9), Color("d4ccd0"), 18, true)
	draw_line(Vector2(-28 - stance, -6), Vector2(-7 - stance, -6), Color("14151f"), 12, true)
	draw_line(Vector2(17 + stance, -6), Vector2(43 + stance, -6), Color("14151f"), 12, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-29,-125),Vector2(25,-125),Vector2(22,-58),Vector2(-21,-58)]), Color("181d2b"))
	draw_polyline(PackedVector2Array([Vector2(-29,-125),Vector2(25,-125),Vector2(22,-58),Vector2(-21,-58),Vector2(-29,-125)]), color, 2, true)
	draw_circle(Vector2(0, -148), 24, color.darkened(0.4))
	if profile.get("id") == "sharkbyte":
		draw_colored_polygon(PackedVector2Array([Vector2(-20,-165),Vector2(-16,-195),Vector2(10,-167)]), color)
		draw_colored_polygon(PackedVector2Array([Vector2(15,-159),Vector2(40,-144),Vector2(14,-137)]), color)
	else:
		for side in [-1,1]:
			draw_polyline(PackedVector2Array([Vector2(side*16,-163),Vector2(side*35,-183),Vector2(side*33,-153)]), color, 7, true)
	draw_line(Vector2(8,-153), Vector2(19,-153), Color("f6e7d9"), 3, true)
	var hand := Vector2(42, -100)
	if guarding: hand = Vector2(27, -148)
	elif is_active(): hand = Vector2(attack.reach, -106)
	draw_line(Vector2(17,-116), hand, color.darkened(0.2), 15, true)
	draw_circle(hand, 10, color)
	draw_line(Vector2(-23,-117), Vector2(-33,-82), color.darkened(0.4), 12, true)
	if guarding:
		draw_arc(Vector2(0,-95), 74, -1.3, 1.3, 20, Color(tint, 0.7), 4, true)
	if is_active():
		draw_arc(Vector2(25,-100), attack.reach - 12, -0.7, 0.7, 16, Color(tint, 0.65), 5, true)
	draw_set_transform(Vector2.ZERO)
	if show_hitboxes:
		draw_rect(Rect2(Vector2(-29,-145),Vector2(58,145)),Color(0,1,0,0.25))
		if is_active(): draw_rect(Rect2(hitbox().position-position,hitbox().size),Color(1,0,0,0.3))

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, FLOOR - position.y + 4), 0, Vector2(1,0.18))
	draw_circle(Vector2.ZERO, 55, Color(0,0,0,0.5))
	draw_set_transform(Vector2.ZERO)
