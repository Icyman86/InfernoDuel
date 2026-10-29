class_name NetworkMatchDriver
extends Node
## Host simulates at 60 Hz. Guest sends its own input and renders authoritative
## 20 Hz snapshots with smoothed 60 Hz transforms; it never decides hits or wins.
var duel: DuelMatch
var tick := 0
var applied_sequence := -1
var state: Dictionary = {}
var last_phase := ""
var projectile_targets: Array = []

func _ready() -> void:
	duel = get_parent()
	if OnlineSession.local_slot == 0:
		duel.input_provider = host_inputs
		OnlineSession.state_provider = capture
		OnlineSession.input_gate = can_accept_remote_input
	else:
		duel.set_physics_process(false)
		duel.stopped = false

func host_inputs() -> Array[Dictionary]:
	var inputs: Array[Dictionary] = [InputRouter.sample(0), OnlineSession.consume_remote_input()]
	return inputs

func can_accept_remote_input() -> bool:
	return duel.phase == "fight" and not duel.stopped

func _physics_process(delta: float) -> void:
	if not OnlineSession.active(): return
	tick += 1
	if OnlineSession.local_slot == 0:
		if duel.phase != "fight" or duel.stopped:
			OnlineSession.consume_remote_input()
		if tick % 3 == 0: OnlineSession.send_snapshot(capture(), tick)
	else:
		var input := {}
		if OnlineSession.phase == "fight" and duel.phase == "fight" and not duel.stopped:
			input = InputRouter.sample(0)
		else:
			InputRouter.clear()
		OnlineSession.send_input(input)
		if applied_sequence != OnlineSession.snapshot_revision and not OnlineSession.latest_snapshot.is_empty():
			applied_sequence = OnlineSession.snapshot_revision
			apply_snapshot(OnlineSession.latest_snapshot)
		interpolate(delta)

func capture() -> Dictionary:
	var fighters: Array = []
	for f in duel.fighters:
		fighters.append({"p":[f.position.x,f.position.y],"v":[f.velocity.x,f.velocity.y],
			"travel":f.walk_distance,"locomotion":f.locomotion_speed,"hp":f.hp,"meter":f.meter,"facing":f.facing,"guard":f.guarding,"stun":f.stun,
			"immunity":f.immunity,"cooldown":f.special_cooldown,"armor":f.armor_time,
			"power":f.empower_time,"flash":f.flash,"combo":f.combo,"combo_time":f.combo_time,
			"attack":f.attack.id if f.attack else "","attack_time":f.attack_time})
	var objects: Array = []
	for p in duel.projectiles:
		objects.append({"source":p.source.player,"move":p.move.id,"kind":p.kind,
			"p":[p.position.x,p.position.y],"age":p.age,"direction":p.direction,
			"size":[p.size.x,p.size.y],"speed":p.speed,"lifetime":p.lifetime})
	return {"fighters":fighters,"projectiles":objects,"phase":duel.phase,
		"phase_time":duel.phase_time,"remaining":duel.remaining,"round":duel.round_number,
		"wins":duel.wins,"result":duel.result_text,"announcement":duel.announcement.text,
		"stopped":duel.stopped}

func apply_snapshot(snapshot: Dictionary) -> void:
	if snapshot.get("fighters",[]).size() != 2: return
	if OnlineSession.phase == "finished" and snapshot.get("phase") != "complete": return
	state = snapshot
	var teleport: bool = last_phase != state.phase and state.phase == "countdown"
	last_phase = state.phase
	duel.phase = state.phase
	duel.phase_time = state.phase_time
	duel.remaining = state.remaining
	duel.round_number = state.round
	duel.wins.assign(state.wins)
	duel.result_text = state.result
	duel.announcement.text = state.announcement
	# Pause/result RPCs own UI state; late unreliable packets cannot resume it.
	duel.stopped = true in OnlineSession.pause_flags or OnlineSession.phase == "finished"
	for i in 2:
		var f := duel.fighters[i]
		var data: Dictionary = state.fighters[i]
		var damage: bool = int(data.hp) < f.hp
		f.locomotion_speed = data.get("locomotion",0.0)
		f.hp = data.hp
		f.meter = data.meter
		f.facing = data.facing
		f.velocity = Vector2(data.v[0],data.v[1])
		f.guarding = data.guard
		f.stun = data.stun
		f.immunity = data.immunity
		f.special_cooldown = data.cooldown
		f.armor_time = data.armor
		f.empower_time = data.power
		f.flash = data.flash
		f.combo = data.combo
		f.combo_time = data.combo_time
		f.attack = f.moves.get(data.attack,null)
		f.attack_time = data.attack_time
		var target := Vector2(data.p[0],data.p[1])
		if teleport or f.position.distance_to(target) > 180:
			f.position = target
			f.walk_distance = data.get("travel",0.0)
			f.visual.reset_motion()
			f.reset_physics_interpolation()
		if damage:
			var burst := HitBurst.new()
			burst.position = target + Vector2(0,-170)
			burst.blocked = f.guarding
			duel.add_child(burst)
			Sound.play("block" if f.guarding else "hit")
	# Small capped projectile lists are reconstructed only on network snapshots.
	for p in duel.projectiles: p.queue_free()
	duel.projectiles.clear()
	projectile_targets = state.get("projectiles",[])
	for data in projectile_targets:
		var p := DuelProjectile.new()
		p.source = duel.fighters[data.source]
		p.move = p.source.moves[data.move]
		p.kind = data.kind
		p.position = Vector2(data.p[0],data.p[1])
		p.age = data.age
		p.direction = data.direction
		p.size = Vector2(data.size[0],data.size[1])
		p.speed = data.speed
		p.lifetime = data.lifetime
		duel.add_child(p)
		duel.projectiles.append(p)
	duel.update_hud()

func interpolate(delta: float) -> void:
	if state.is_empty() or duel.stopped: return
	var alpha := 1.0 - exp(-delta*25)
	for i in 2:
		var f := duel.fighters[i]
		var data: Dictionary = state.fighters[i]
		f.walk_distance = lerpf(f.walk_distance,float(data.get("travel",f.walk_distance)),alpha)
		f.position = f.position.lerp(Vector2(data.p[0],data.p[1]),alpha)
		if f.attack:
			f.attack_time = minf(f.attack_time+delta, f.attack.duration()-0.001)
	for p in duel.projectiles:
		p.position.x += p.direction*p.speed*delta
		p.age += delta
		p.queue_redraw()
