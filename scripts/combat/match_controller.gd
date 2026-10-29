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
var meter_labels: Array[Label] = []
var round_tokens: Array[Label] = []
var input_provider: Callable
var local_network_slot := -1

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
	var top := ColorRect.new()
	top.color = Color(0.018,0.014,0.03,0.82)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(UI.place(top,0,0,1280,140))
	for i in 2:
		var x := 134.0 if i == 0 else 748.0
		var c := UI.CYAN if i == 0 else UI.ORANGE
		var portrait_frame := UI.panel()
		portrait_frame.add_theme_stylebox_override("panel",UI.style(Color("17131b"),c,2))
		hud.add_child(UI.place(portrait_frame,34 if i == 0 else 1162,34,84,88))
		var portrait := FighterPortrait.new()
		portrait.setup(profiles[i])
		portrait_frame.add_child(portrait)
		var name_label := UI.label("",21,UI.IVORY)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		hud.add_child(UI.place(name_label,x,30,398,30))
		names.append(name_label)
		var hp_bar := UI.bar(c)
		hud.add_child(UI.place(hp_bar,x,65,398,24))
		if i == 1: hp_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		health.append(hp_bar)
		var meter_bar := UI.bar(UI.GOLD,0)
		hud.add_child(UI.place(meter_bar,x,96,398,7))
		if i == 1: meter_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		meters.append(meter_bar)
		var meter_text := UI.label("",14,UI.MUTED)
		meter_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		hud.add_child(UI.place(meter_text,x,109,398,23))
		meter_labels.append(meter_text)
		var tokens := UI.label("◇ ◇",22,c)
		hud.add_child(UI.place(tokens,421 if i == 0 else 749,23,112,40))
		round_tokens.append(tokens)
		var combo_label := UI.label("",28,c,true)
		hud.add_child(UI.place(combo_label,95 if i == 0 else 780,163,405,75))
		combos.append(combo_label)
	var timer_panel := UI.panel()
	timer_panel.add_theme_stylebox_override("panel",UI.style(Color("17111c"),Color("806044"),2))
	hud.add_child(UI.place(timer_panel,577,22,126,93))
	timer_label = UI.label("60",47,UI.GOLD,true)
	hud.add_child(UI.place(timer_label,575,28,130,64))
	round_label = UI.label("ROUND 1",14,UI.MUTED)
	hud.add_child(UI.place(round_label,568,95,144,25))
	announcement = UI.label("3",64,UI.GOLD,true)
	announcement.add_theme_constant_override("outline_size",8)
	announcement.add_theme_color_override("font_outline_color",Color("130b15"))
	hud.add_child(UI.place(announcement,100,230,1080,145))
	if OS.has_feature("android") or "--touch" in OS.get_cmdline_user_args(): return
	var footer_bg := ColorRect.new()
	footer_bg.color = Color(0.02,0.015,0.03,0.84)
	footer_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(UI.place(footer_bg,0,675,1280,45))
	if local_network_slot >= 0:
		hud.add_child(UI.place(UI.label("YOUR CONTROLS  A D · W · S · F G H J     /     ESC PAUSE · CONNECTED SESSION",16,UI.IVORY),35,684,1210,28))
		return
	hud.add_child(UI.place(UI.label("P1  A D · W · S · F G H J",16,UI.CYAN),35,684,420,28))
	hud.add_child(UI.place(UI.label("ESC  PAUSE   /   F3  HITBOXES",14,UI.MUTED),455,684,370,28))
	hud.add_child(UI.place(UI.label("P2  ← → · ↑ · ↓ · I O P L",16,UI.ORANGE),825,684,420,28))


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
		var inputs: Array[Dictionary] = []
		if input_provider.is_valid():
			inputs = input_provider.call()
		else:
			inputs = [InputRouter.sample(0),ai.sample(delta,fighters[1],fighters[0]) if solo else InputRouter.sample(1)]
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
		var was_blocking := target.guarding
		var clean_hit := target.receive_hit(move,event.x)
		var burst := HitBurst.new()
		burst.position = target.position + Vector2((1 if event.x > target.position.x else -1)*23,-175)
		burst.color = UI.CYAN if was_blocking and not clean_hit else UI.GOLD
		burst.blocked = was_blocking and not clean_hit
		burst.seed_angle = remaining
		add_child(burst)
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
	if absf(distance) < 86:
		var correction := (86.0-absf(distance))*0.5
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
	var count := 3 if fighter.attack_kind(move.id) in ["spike_volley", "spineburst", "cheese_storm", "crystal_storm"] else 1
	for i in count:
		var owned: Array[DuelProjectile] = []
		for existing in projectiles:
			if existing.source == fighter: owned.append(existing)
		if owned.size() >= 3:
			projectiles.erase(owned[0])
			owned[0].queue_free()
		var projectile := DuelProjectile.new()
		projectile.spawn_index = i
		var projectile_move: AttackData = move.duplicate()
		projectile_move.damage = move.damage / count + (1 if i < move.damage % count else 0)
		projectile.setup(fighter,projectile_move)
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
		var owner := "YOU" if local_network_slot == i else ("CPU" if solo and i == 1 else "P%d" % (i+1))
		names[i].text = "%s  /  %s" % [owner,profiles[i].display_name.to_upper()]
		round_tokens[i].text = "◆ ".repeat(wins[i])+"◇ ".repeat(2-wins[i])
		meter_labels[i].text = "%d HP    /    SUPER %d%%" % [fighters[i].hp,fighters[i].meter]
		if fighters[i].armor_time > 0: meter_labels[i].text += "  ARMOR %.1fs" % fighters[i].armor_time
		if fighters[i].empower_time > 0: meter_labels[i].text += "  POWER %.1fs" % fighters[i].empower_time
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
