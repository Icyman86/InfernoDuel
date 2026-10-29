extends Node
const DT := 1.0/60.0
const OUTPUT := "/tmp/inferno-v8-motion"
var game: Control
var duel: DuelMatch
var elapsed := 0.0
var pair := -1
var observed: Array[Dictionary] = [{},{}]
var marks := {}
var passed := 0
var failed := 0
var running := false

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+name+".png")

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	# Exercise actual GPU compositing: a half-blend of opaque poses stays opaque.
	var vp := SubViewport.new()
	vp.size = Vector2i(32,32)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	add_child(vp)
	var pixels := Image.create_empty(32,32,false,Image.FORMAT_RGBA8)
	pixels.fill(Color.WHITE)
	var white := ImageTexture.create_from_image(pixels)
	for overlay in [false,true]:
		var quad := Polygon2D.new()
		quad.polygon = PackedVector2Array([Vector2(0,0),Vector2(32,0),Vector2(32,32),Vector2(0,32)])
		quad.uv = quad.polygon
		quad.texture = white
		var fx := ShaderMaterial.new()
		fx.shader = preload("res://assets/shaders/fighter.gdshader")
		fx.set_shader_parameter("pose_alpha",.5)
		fx.set_shader_parameter("blend_base",not overlay)
		fx.set_shader_parameter("overlay_weight",.5)
		fx.set_shader_parameter("overlay_texture",white)
		quad.material = fx
		vp.add_child(quad)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	print("POSE BLEND GPU PIXEL ",vp.get_texture().get_image().get_pixel(16,16))
	check(vp.get_texture().get_image().get_pixel(16,16).a > .98,"GPU pose compositing stays opaque halfway through a movement blend")
	vp.queue_free()
	if "--alpha-only" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		print("COMPOSITING RESULT: %d passed, %d failed" % [passed,failed])
		get_tree().quit(0 if failed == 0 else 1)
		return
	game = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	get_window().size = Vector2i(1280,720)
	game.show_gallery()
	running = true

func setup_pair(index: int) -> void:
	pair = index
	observed = [{},{}]
	marks.clear()
	game.show_select(true)
	game.selected.assign([pair*2,pair*2+1])
	game.start_match()
	duel = game.match_node
	duel.set_physics_process(false)
	duel.phase = "fight"
	duel.announcement.text = ""

func finish_pair() -> void:
	for i in 2:
		var id: String = duel.fighters[i].profile.id
		check(observed[i].has("start") and observed[i].has("brake") and observed[i].has("pivot"),id+" renders start, reverse and brake through its actual controller")
		check(observed[i].has("rise") and observed[i].has("apex") and observed[i].has("fall") and observed[i].has("land"),id+" renders the full jump and landing sequence")
		check(duel.fighters[i].hp == 100 and duel.fighters[i].position.y == DuelFighter.FLOOR,id+" returns to the floor without changing health")

func _process(delta: float) -> void:
	if not running: return
	elapsed += delta
	if elapsed < 4:
		if elapsed > 3.3 and not marks.has("ring"):
			marks.ring = true
			check(game.screen.presentation.finished and game.screen.preview.visible and game.screen.presentation.rings.size() == 2,"rings and the same lit character remain live after the entrance")
			capture("persistent-rings")
		return
	var index := mini(4,int((elapsed-4)/3.2))
	if pair != index:
		if pair >= 0: finish_pair()
		setup_pair(index)
	var phase := fmod(elapsed-4,3.2)
	var axis := 1 if phase >= .1 and phase < .65 else (-1 if phase >= .65 and phase < 1.1 else 0)
	var jump := phase >= 1.35 and not marks.has("jump")
	if jump: marks.jump = true
	var commands: Array[Dictionary] = [{"axis":axis,"jump":jump},{"axis":axis,"jump":jump}]
	duel.advance_fight(delta,commands)
	for i in 2: observed[i][duel.fighters[i].visual.motion_state] = true
	if phase > .5 and not marks.has("walk"):
		marks.walk = true
		check(duel.fighters[0].visual.motion.blend_speed > .5 and duel.fighters[1].visual.motion.blend_speed > .5,"pair %d has active continuous gait deformation" % (pair+1))
		capture("pair-%d-walk" % (pair+1))
	if phase > 1.65 and not marks.has("air"):
		marks.air = true
		capture("pair-%d-jump" % (pair+1))
	if elapsed >= 19.9:
		finish_pair()
		running = false
		game.show_menu()
		game.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().create_timer(.6).timeout
		print("MOVEMENT VISUAL RESULT: %d passed, %d failed" % [passed,failed])
		get_tree().quit(0 if failed == 0 else 1)
