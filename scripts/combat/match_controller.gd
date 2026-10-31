class_name DuelMatch
extends Node2D
signal completed(wins: Array[int])
const FighterScene = preload("res://scenes/combat/fighter.tscn")
var fighters: Array[DuelFighter] = []
var projectiles: Array[DuelProjectile] = []
var profiles: Array[Dictionary] = []
var modern_rules := false
var arena_rules := ArenaRules.new()
var arena_3d: GladiatorArena3D
var hitstop := 0.0
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
var meters: Array[UltimateGauge] = []
var names: Array[Label] = []
var combos: Array[Label] = []
var diagnostics: Label
var debug_boxes := false
var meter_labels: Array[Label] = []
var round_tokens: Array[Label] = []
var input_provider: Callable
var local_network_slot := -1
var chrome: CombatChrome
var portraits: Array[Control] = []
var timer_panel: PanelContainer
var ultimate_banners: Array[UltimateBanner] = []
var footer: Control

func _ready() -> void:
	for i in 2:
		var fighter: DuelFighter = FighterScene.instantiate()
		fighter.modern_rules = modern_rules
		fighter.player = i
		fighter.profile = profiles[i]
		fighter.tint = UI.CYAN if i == 0 else UI.ORANGE
		fighter.projectile_requested.connect(_spawn_projectile)
		fighters.append(fighter)
		add_child(fighter)
	if modern_rules:
		arena_3d = GladiatorArena3D.new()
		arena_3d.duel = self
		add_child(arena_3d)
		move_child(arena_3d,0)
	_make_hud()
	start_round(false)

func _make_hud() -> void:
	hud = Control.new()
	hud.theme = UI.theme()
	add_child(hud)
	chrome = CombatChrome.new()
	hud.add_child(chrome)
	for i in 2:
		var x := 134.0 if i == 0 else 748.0
		var c := UI.CYAN if i == 0 else UI.ORANGE
		var portrait_frame := UI.panel()
		var portrait_style := UI.style(Color("101b2b"),c,2)
		portrait_style.set_corner_radius_all(14)
		portrait_frame.add_theme_stylebox_override("panel",portrait_style)
		hud.add_child(UI.place(portrait_frame,34 if i == 0 else 1162,34,84,88))
		portraits.append(portrait_frame)
		var portrait := FighterPortrait.new()
		portrait.setup(profiles[i])
		portrait_frame.add_child(portrait)
		var name_label := UI.label("",21,UI.IVORY)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		hud.add_child(UI.place(name_label,x,30,398,30))
		names.append(name_label)
		var hp_bar := UI.bar(c)
		hp_bar.max_value = DuelFighter.MAX_HEALTH
		for layer in ["background","fill"]:
			var health_style := hp_bar.get_theme_stylebox(layer).duplicate()
			health_style.set_corner_radius_all(10)
			health_style.set_border_width_all(0)
			health_style.bg_color = Color("172839") if layer == "background" else c
			hp_bar.add_theme_stylebox_override(layer,health_style)
		hud.add_child(UI.place(hp_bar,x,65,398,24))
		if i == 1: hp_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		health.append(hp_bar)
		var meter_bar := UltimateGauge.new()
		meter_bar.accent = c
		meter_bar.reversed = i == 1
		meter_bar.duel = self
		hud.add_child(UI.place(meter_bar,x-4,93,406,25))
		meters.append(meter_bar)
		var meter_text := UI.label("",14,UI.MUTED)
		meter_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		hud.add_child(UI.place(meter_text,x,118,398,23))
		meter_labels.append(meter_text)
		var tokens := UI.label("○ ○",22,c)
		hud.add_child(UI.place(tokens,421 if i == 0 else 749,23,112,40))
		round_tokens.append(tokens)
		var combo_label := UI.label("",22,c)
		hud.add_child(UI.place(combo_label,95 if i == 0 else 780,163,405,75))
		combos.append(combo_label)
		var ultimate_banner := UltimateBanner.new()
		ultimate_banner.actor = fighters[i]
		hud.add_child(UI.place(ultimate_banner,95 if i == 0 else 780,158,405,100))
		ultimate_banners.append(ultimate_banner)
	timer_panel = UI.panel()
	var timer_style := UI.style(Color("0d1726"),Color("334a62"),1)
	timer_style.set_corner_radius_all(18)
	timer_panel.add_theme_stylebox_override("panel",timer_style)
	hud.add_child(UI.place(timer_panel,577,22,126,93))
	timer_label = UI.label("60",47,UI.IVORY)
	hud.add_child(UI.place(timer_label,575,28,130,64))
	round_label = UI.label("ROUND 1",14,UI.MUTED)
	hud.add_child(UI.place(round_label,568,95,144,25))
	announcement = UI.label("3",64,UI.IVORY)
	announcement.add_theme_constant_override("outline_size",8)
	announcement.add_theme_color_override("font_outline_color",Color("130b15"))
	hud.add_child(UI.place(announcement,100,230,1080,145))
	if GamePlatform.touch_enabled(): return
	var footer_bg := ColorRect.new()
	footer = footer_bg
	footer_bg.color = Color(0.02,0.015,0.03,0.84)
	footer_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(UI.place(footer_bg,0,675,1280,45))
	if local_network_slot >= 0:
		hud.add_child(UI.place(UI.label("YOUR CONTROLS  A D · W · S · F G H J     /     ESC PAUSE · CONNECTED SESSION",16,UI.IVORY),35,684,1210,28))
		return
	hud.add_child(UI.place(UI.label("P1 AD/W/S · FGHJ · R GRAB · T ESCAPE",16,UI.CYAN),35,684,420,28))
	hud.add_child(UI.place(UI.label("ESC  PAUSE   /   F3  HITBOXES",14,UI.MUTED),455,684,370,28))
	hud.add_child(UI.place(UI.label("P2 ARROWS · IOPL · U GRAB · K ESCAPE",16,UI.ORANGE),825,684,420,28))

func layout_hud(safe: Rect2) -> void:
	if not hud: return
	hud.position = safe.position
	hud.size = safe.size
	var width := safe.size.x
	var side_width := width*.5-82
	var bar_width := side_width-160
	chrome.logical_width = width
	chrome.queue_redraw()
	for i in 2:
		var x := 134.0 if i == 0 else width*.5+108
		portraits[i].position.x = 34 if i == 0 else width-118
		for item in [names[i],health[i],meter_labels[i]]:
			item.position.x = x
			item.size.x = bar_width
		meters[i].position.x = x-4
		meters[i].size.x = bar_width+8
		round_tokens[i].position.x = side_width-137 if i == 0 else width*.5+109
		combos[i].position.x = 95 if i == 0 else width-500
		ultimate_banners[i].position.x = combos[i].position.x
	timer_panel.position.x = width*.5-63
	timer_label.position.x = width*.5-65
	round_label.position.x = width*.5-72
	announcement.position = Vector2(100,safe.size.y*.32)
	announcement.size.x = width-200
	if footer:
		footer.position.y = safe.size.y-45
		footer.size.x = width


func start_round(keep_meter := true) -> void:
	arena_rules.reset()
	hitstop = 0
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
	if modern_rules and hitstop > 0:
		hitstop = maxf(0,hitstop-delta)
		return
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
	if modern_rules: arena_rules.step(delta,fighters,inputs)
	_resolve_bodies()
	# Correct visual travel after push-box resolution. Feet do not cycle while
	# pushing into another fighter or an arena boundary.
	for f in fighters:
		if f.last_walk_delta != 0:
			var actual := f.position.x-f.step_start_x
			if actual*f.last_walk_delta < 0: actual = 0
			f.walk_distance += actual-f.last_walk_delta
			f.last_walk_delta = actual
			f.locomotion_speed = actual/maxf(delta,.00001)
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
		if modern_rules and clean_hit and move.slot in ["heavy","ultimate"]: hitstop = .05
		var burst := HitBurst.new()
		burst.position = target.position + Vector2((1 if event.x > target.position.x else -1)*23,-175)
		burst.color = UI.CYAN if was_blocking and not clean_hit else UI.GOLD
		burst.blocked = was_blocking and not clean_hit
		burst.seed_angle = remaining
		if modern_rules:
			arena_3d.impact_at(target,was_blocking and not clean_hit)
			burst.free()
		else:
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
		# Preserve separation when half of the correction was clipped at a wall.
		if modern_rules:
			var left := fighters[0] if direction > 0 else fighters[1]
			var right := fighters[1] if direction > 0 else fighters[0]
			if right.position.x-left.position.x < 86:
				if left.position.x <= DuelFighter.LEFT: right.position.x = left.position.x+86
				elif right.position.x >= DuelFighter.RIGHT: left.position.x = right.position.x-86

func finish_round() -> void:
	if phase != "fight": return
	phase = "round_over"
	for fighter in fighters:
		fighter.ultimate_time = 0
		fighter.ultimate_move = ""
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
	var count := 3 if fighter.attack_kind(move.id) in ["spike_volley", "spineburst", "cheese_storm", "crystal_storm", "fruit_storm", "bullet_volley", "saw_cyclone"] else 1
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
		round_tokens[i].text = "● ".repeat(wins[i])+"○ ".repeat(2-wins[i])
		meter_labels[i].text = "%d / %d HP   ·   %s" % [fighters[i].hp,DuelFighter.MAX_HEALTH,"ULTIMATE READY" if fighters[i].meter >= 100 else "ULT %d%%" % fighters[i].meter]
		meter_labels[i].add_theme_color_override("font_color",UI.GOLD if fighters[i].meter >= 100 else UI.MUTED)
		if fighters[i].armor_time > 0: meter_labels[i].text += "  ARMOR %.1fs" % fighters[i].armor_time
		if fighters[i].empower_time > 0: meter_labels[i].text += "  POWER %.1fs" % fighters[i].empower_time
		var info := ""
		if modern_rules and fighters[i].command_notice != "": info = fighters[i].command_notice+"\n"
		if fighters[i].combo >= 2: info += "%d HIT COMBO\n" % fighters[i].combo
		if fighters[i].meter >= 100: info += "ULTIMATE READY"
		elif fighters[i].special_cooldown > 0: info += "SPECIAL %.1fs" % fighters[i].special_cooldown
		combos[i].text = info
		var active := phase == "fight" and fighters[i].ultimate_time > 0
		ultimate_banners[i].visible = active
		combos[i].position.y = 266 if active else 163
		ultimate_banners[i].refresh()

func set_stopped(value: bool) -> void:
	stopped = value
	InputRouter.clear()

func toggle_hitboxes() -> void:
	debug_boxes = not debug_boxes
	for fighter in fighters:
		fighter.show_hitboxes = debug_boxes
		fighter.queue_redraw()
