extends Node
const OUTPUT := "/tmp/inferno-v9-combat"
var game: Control
var duel: DuelMatch
var elapsed := 0.0
var pair := -1
var marks := {}
var passed := 0
var failed := 0
var running := false
var hashes: Array[Dictionary] = [{},{}]

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
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	get_window().size = Vector2i(1280,720)
	running = true

func setup_pair(index: int) -> void:
	pair = index
	marks.clear()
	hashes = [{},{}]
	game.show_select(true)
	game.selected.assign([pair*2,pair*2+1])
	game.start_match()
	duel = game.match_node
	duel.set_physics_process(false)
	duel.phase = "fight"
	duel.announcement.text = ""
	# Separated demonstration: full recovery, no hitstun cutting off the kick.
	duel.fighters[0].reset_at(400)
	duel.fighters[1].reset_at(880)
	var caption := UI.label("V9  /  CONTINUOUS ATTACKS",16,UI.GOLD)
	duel.hud.add_child(UI.place(caption,140,215,410,30))
	for hero in duel.fighters: hero.begin_attack("heavy")

func finish_pair() -> void:
	for i in 2:
		check(hashes[i].size() >= 12,duel.fighters[i].profile.id+" heavy draws at least twelve distinct visible intermediate images")

func observe() -> void:
	await RenderingServer.frame_post_draw
	if not is_instance_valid(duel): return
	var image := get_viewport().get_texture().get_image()
	for i in 2:
		var cropped := image.get_region(Rect2i(190 if i == 0 else 670,305,420,290))
		hashes[i][hash(cropped.get_data())] = true

func verify_glow() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var color := image.get_pixel(330,105)
	check(color.r > .6 and color.g > .3 and color.r > color.b*1.5,"pair %d actual GPU pixels show a bright golden ultimate gauge" % (pair+1))

func _process(delta: float) -> void:
	if not running: return
	elapsed += delta
	var index := mini(4,int(elapsed/3.6))
	if pair != index:
		if pair >= 0: finish_pair()
		setup_pair(index)
	var phase := fmod(elapsed,3.6)
	# Real attack timing sampled in slow motion for this preview only.
	duel.advance_fight(delta*.24,[{},{}])
	duel.update_hud()
	if phase < 2.35: observe()
	if phase > .85 and not marks.has("kick"):
		marks.kick = true
		capture("pair-%d-kick" % (pair+1))
	if phase > 2.4 and not marks.has("ready"):
		marks.ready = true
		# UI fixture; real zero-meter earning/spending is covered by quality.gd.
		for hero in duel.fighters: hero.meter = 100
		duel.update_hud()
		check(duel.meters[0].glowing and duel.meters[1].glowing,"pair %d shows both charged ultimate bars" % (pair+1))
	if phase > 2.8 and not marks.has("glow"):
		marks.glow = true
		verify_glow()
		capture("pair-%d-ultimate-ready" % (pair+1))
	if elapsed >= 17.9:
		finish_pair()
		running = false
		game.show_menu()
		game.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().create_timer(.6).timeout
		print("QUALITY VISUAL RESULT: %d passed, %d failed" % [passed,failed])
		get_tree().quit(0 if failed == 0 else 1)
