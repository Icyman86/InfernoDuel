class_name DuelMatch
extends Node2D
signal completed(wins: Array[int])
const FighterScene = preload("res://scenes/combat/fighter.tscn")
var fighters: Array[DuelFighter] = []
var projectiles: Array[DuelProjectile] = []
var profiles: Array[Dictionary] = []
var solo := false
var ai := DuelAI.new()
var wins: Array[int] = [0,0]
var round_number := 1
var remaining := 60.0
var phase := "countdown"
var phase_time := 3.0
var stopped := false
var result_text := ""
var hud: Control
var announcement: Label
var timer_label: Label
var round_label: Label
var health: Array[ProgressBar] = []
var meters: Array[ProgressBar] = []
var names: Array[Label] = []
var combos: Array[Label] = []
var diagnostics: Label
var debug_boxes := false

func _ready() -> void:
	for i in 2:
		var fighter: DuelFighter = FighterScene.instantiate()
		fighter.player = i
		fighter.profile = profiles[i]
		fighter.tint = UI.CYAN if i == 0 else UI.ORANGE
		fighter.projectile_requested.connect(_spawn_projectile)
		fighters.append(fighter)
		add_child(fighter)
	_make_hud()
	start_round(false)

func _make_hud() -> void:
	hud = Control.new()
	hud.theme = UI.theme()
	add_child(hud)
	for i in 2:
		var x := 48.0 if i == 0 else 770.0
		var c := UI.CYAN if i == 0 else UI.ORANGE
		var name_label := UI.label("",22,c)
		UI.place(name_label,x,30,462,34)
		hud.add_child(name_label)
		names.append(name_label)
		var hp_bar := UI.bar(c)
		UI.place(hp_bar,x,70,462,27)
		if i == 1: hp_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		hud.add_child(hp_bar)
		health.append(hp_bar)
		var meter_bar := UI.bar(UI.GOLD,0)
		UI.place(meter_bar,x,106,462,9)
		hud.add_child(meter_bar)
		meters.append(meter_bar)
		var combo_label := UI.label("",28,c,true)
		UI.place(combo_label,x,165,462,80)
		hud.add_child(combo_label)
		combos.append(combo_label)
	timer_label = UI.label("60",48,UI.GOLD,true)
	UI.place(timer_label,548,24,184,65)
	hud.add_child(timer_label)
	round_label = UI.label("ROUND 1",18,UI.MUTED)
	UI.place(round_label,535,98,210,28)
	hud.add_child(round_label)
	announcement = UI.label("3",64,UI.GOLD,true)
	UI.place(announcement,140,258,1000,140)
	hud.add_child(announcement)
	var footer := UI.label("P1  A D · W · S · F G H J          ESC  PAUSE          P2  ← → · ↑ · ↓ · I O P L",18,UI.IVORY)
	UI.place(footer,30,651,1220,28)
	hud.add_child(footer)
	diagnostics = UI.label("GEOMETRIC PROTOTYPES · ANIMATIEFRAMES NOG NIET BESCHIKBAAR · F3 hitboxes",18,UI.MUTED)
	UI.place(diagnostics,30,686,1220,26)
	hud.add_child(diagnostics)

func start_round(keep_meter := true) -> void:
	for projectile in projectiles: projectile.queue_free()
	projectiles.clear()
	for i in 2: fighters[i].reset_at(390.0 if i == 0 else 890.0,keep_meter)
	remaining = 60.0
	phase = "countdown"
	phase_time = 3.0
	InputRouter.clear()
	Sound.play("round")
	update_hud()

func _physics_process(delta: float) -> void:
	if stopped: return
	if phase == "countdown":
		InputRouter.clear()
		phase_time -= delta
		announcement.text = str(maxi(1,int(ceil(phase_time))))
		if phase_time <= 0:
			phase = "fight"
			announcement.text = "FIGHT"
			phase_time = 0.65
	elif phase == "fight":
		var inputs: Array[Dictionary] = [InputRouter.sample(0),ai.sample(delta,fighters[1],fighters[0]) if solo else InputRouter.sample(1)]
		advance_fight(delta,inputs)
		phase_time -= delta
		if phase_time <= 0: announcement.text = ""
	elif phase == "round_over":
		InputRouter.clear()
		phase_time -= delta
		if phase_time <= 0:
			if wins[0] >= 2 or wins[1] >= 2:
				phase = "complete"
				completed.emit(wins)
			else:
				if not result_text.begins_with("DRAW"): round_number += 1
				start_round()
	update_hud()

func advance_fight(delta: float, inputs: Array[Dictionary]) -> void:
	for i in 2: fighters[i].step(delta,inputs[i],fighters[1-i])
	_resolve_bodies()
	# Collect all hit events BEFORE applying damage, preserving same-tick trades.
	var events: Array[Dictionary] = []
	for i in 2:
		var a := fighters[i]
		if a.pending_hit(fighters[1-i]):
			events.append({"source": a,"target": fighters[1-i],"move": a.attack,"x": a.position.x})
			a.hit_connected = true
	for projectile in projectiles:
		projectile.step(delta)
		var target := fighters[1-projectile.source.player]
		if not projectile.spent and target.immunity <= 0 and projectile.hitbox().intersects(target.hurtbox()):
			events.append({"source":projectile.source,"target":target,"move":projectile.move,"x":projectile.position.x - projectile.direction*50})
			projectile.spent = true
	for event in events:
		var source: DuelFighter = event.source
		var target: DuelFighter = event.target
		var move: AttackData = event.move
		var clean_hit := target.receive_hit(move,event.x)
		source.meter = mini(100,source.meter+move.meter_gain)
		if clean_hit:
			source.combo += 1
			source.combo_time = 1.2
	for i in range(projectiles.size()-1,-1,-1):
		if projectiles[i].spent:
			projectiles[i].queue_free()
			projectiles.remove_at(i)
	remaining = maxf(0,remaining-delta)
	if fighters[0].hp <= 0 or fighters[1].hp <= 0 or remaining <= 0: finish_round()

func _resolve_bodies() -> void:
	if absf(fighters[0].position.y-fighters[1].position.y) > 130: return
	var distance := fighters[1].position.x - fighters[0].position.x
	if absf(distance) < 60:
		var correction := (60.0-absf(distance))*0.5
		var direction := 1.0 if distance >= 0 else -1.0
		fighters[0].position.x = clampf(fighters[0].position.x - correction*direction,DuelFighter.LEFT,DuelFighter.RIGHT)
		fighters[1].position.x = clampf(fighters[1].position.x + correction*direction,DuelFighter.LEFT,DuelFighter.RIGHT)

func finish_round() -> void:
	if phase != "fight": return
	phase = "round_over"
	phase_time = 2.0
	InputRouter.clear()
	var a := fighters[0].hp
	var b := fighters[1].hp
	if a == b:
		result_text = "DRAW · ROUND REPLAY"
	else:
		var winner := 0 if a > b else 1
		wins[winner] += 1
		result_text = ("KO · " if mini(a,b) == 0 else "TIME · ") + "P%d WINS" % (winner+1)
	announcement.text = result_text
	Sound.play("round")

func _spawn_projectile(fighter: DuelFighter, move: AttackData) -> void:
	var projectile := DuelProjectile.new()
	projectile.setup(fighter,move)
	add_child(projectile)
	move_child(projectile,0)
	projectiles.append(projectile)

func update_hud() -> void:
	if not hud: return
	timer_label.text = "%02d" % int(ceil(remaining))
	round_label.text = "ROUND %d" % round_number
	for i in 2:
		health[i].value = fighters[i].hp
		meters[i].value = fighters[i].meter
		names[i].text = "%s · %s   %s   %d HP" % ["CPU" if solo and i == 1 else "P%d" % (i+1),profiles[i].display_name.to_upper(),"◆".repeat(wins[i])+"◇".repeat(2-wins[i]),fighters[i].hp]
		var info := ""
		if fighters[i].combo >= 2: info = "%d HIT COMBO\n" % fighters[i].combo
		if fighters[i].meter >= 100: info += "ULTIMATE READY"
		elif fighters[i].special_cooldown > 0: info += "SPECIAL %.1fs" % fighters[i].special_cooldown
		combos[i].text = info

func set_stopped(value: bool) -> void:
	stopped = value
	InputRouter.clear()

func toggle_hitboxes() -> void:
	debug_boxes = not debug_boxes
	for fighter in fighters:
		fighter.show_hitboxes = debug_boxes
		fighter.queue_redraw()
