class_name MoveShowcase
extends DuelMatch
## A bounded training match: the same controllers, hitboxes and projectiles as play.
signal move_changed(id: String)
signal readout_changed(text: String)
var autoplay := true
var current_move := "idle"
var sequence: Array[String] = []
var elapsed := 0.0
var demo_duration := 1.8
var step_count := 0
var damage_done := 0
var finished := false

func _make_hud() -> void:
	pass

func _ready() -> void:
	super._ready()
	sequence.assign(["idle", "walk", "jump", "guard"])
	sequence.append_array(fighters[0].moves.keys())
	fighters[1].visual.visible = false
	var camera := Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = Vector2(595, 405)
	camera.zoom = Vector2.ONE
	add_child(camera)
	play_move("idle", false)

func play_move(id: String, manual := true) -> void:
	if id not in sequence: return
	if manual: autoplay = false
	current_move = id
	elapsed = 0.0
	step_count = 0
	damage_done = 0
	finished = false
	remaining = 60.0
	phase = "fight"
	for projectile in projectiles: projectile.queue_free()
	projectiles.clear()
	for i in 2:
		fighters[i].reset_at(560 if i == 0 else 650)
		fighters[i].meter = 100
	fighters[0].hp = 70
	if fighters[0].moves.has(id):
		var move: AttackData = fighters[0].moves[id]
		demo_duration = maxf(1.7, move.duration() + 0.8)
		if fighters[0].is_projectile_attack(id):
			fighters[0].position.x = 440
			fighters[1].position.x = 760
			demo_duration = maxf(demo_duration, 2.6)
	else:
		demo_duration = 1.8
		fighters[0].position.x = 420
		fighters[1].position.x = 800
	for fighter in fighters: fighter.reset_physics_interpolation()
	move_changed.emit(id)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if stopped: return
	elapsed += delta
	if elapsed > demo_duration:
		if autoplay:
			play_move(sequence[(sequence.find(current_move) + 1) % sequence.size()], false)
		else:
			finished = true
	var command := {}
	if current_move == "walk" and not finished:
		command.axis = 1 if elapsed < 0.9 else -1
	elif current_move == "jump" and step_count == 0:
		command.jump = true
	elif current_move == "guard" and not finished:
		command.block = true
	elif step_count == 0 and fighters[0].moves.has(current_move):
		command = MoveCatalog.input_for(fighters[0].moves[current_move])
	var inputs: Array[Dictionary] = [command, {}]
	advance_fight(delta, inputs)
	step_count += 1
	damage_done = 100 - fighters[1].hp
	var label := "%d DAMAGE  ·  %d / 100 METER  ·  %d HP" % [damage_done, fighters[0].meter, fighters[0].hp]
	if fighters[0].armor_time > 0: label += "  ·  ARMOR"
	if fighters[0].empower_time > 0: label += "  ·  POWER UP"
	if fighters[0].immunity > 0: label += "  ·  INVULNERABLE"
	readout_changed.emit(label)
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(100, 594), Vector2(1150, 594), Color("84604f"), 3, true)
	if fighters.size() < 2: return
	var target := fighters[1]
	var color := Color("bb9b76").lerp(Color("ffe3ad"), minf(1, target.flash/0.12))
	draw_line(target.position + Vector2(0,-155),target.position,Color("5d4a42"),9,true)
	draw_circle(target.position + Vector2(0,-202),24,color)
	draw_style_box(UI.style(Color("382e34"),color,2),Rect2(target.position+Vector2(-29,-172),Vector2(58,115)))
	draw_line(target.position+Vector2(-45,-140), target.position+Vector2(45,-140),color,8,true)
	draw_arc(target.position+Vector2(0,-117),18,0,TAU,24,color,2,true)
