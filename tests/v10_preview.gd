extends Node
## Offline Movie Maker fixture, not a phone performance benchmark.
const OUTPUT := "/tmp/inferno-v10-preview"
var game: Control
var duel: DuelMatch
var elapsed := 0.0
var segment := -1
var marks := {}
var running := true

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	get_window().size = Vector2i(1280,582)
	game = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+name+".png")

func begin_segment(index: int) -> void:
	segment = index
	marks.clear()
	game.show_select(true)
	if index < 2:
		game.screen.choose(0,5 if index == 0 else 9)
		game.screen.choose(1,0 if index == 0 else 3)
		return
	var pair := index-2
	game.selected.assign([pair*2,pair*2+1])
	game.start_match()
	duel = game.match_node
	duel.set_physics_process(false)
	duel.phase = "fight"
	duel.announcement.text = ""
	duel.fighters[0].reset_at(400)
	duel.fighters[1].reset_at(880)
	var caption := UI.label("V10  /  DRAWN WALK + HEAVY POSES",16,UI.GOLD)
	duel.hud.add_child(UI.place(caption,140,190,600,30))

func _process(delta: float) -> void:
	if not running or not game: return
	elapsed += delta
	var index := int(elapsed/2) if elapsed < 4 else 2+mini(4,int((elapsed-4)/5.2))
	if segment != index: begin_segment(index)
	var phase := fmod(elapsed,2) if index < 2 else fmod(elapsed-4,5.2)
	if index < 2:
		if phase > .5 and not marks.has("portrait"):
			marks.portrait = true
			capture("select-%d" % index)
		return
	if phase < 1.5:
		var direction := 1 if phase < .75 else -1
		duel.advance_fight(delta,[{"axis":direction},{"axis":-direction}])
	else:
		if not marks.has("heavy"):
			marks.heavy = true
			# Keep both demonstrations apart so hitstun cannot truncate a pose.
			duel.fighters[0].reset_at(400)
			duel.fighters[1].reset_at(880)
			for hero in duel.fighters: hero.begin_attack("heavy")
		# Slow the real attack timeline only for visible pose inspection.
		duel.advance_fight(delta*.28,[{},{}])
	if phase > 2.05 and not marks.has("contact"):
		marks.contact = true
		capture("pair-%d-heavy" % (index-1))
	if phase > 4.2:
		# HUD fixture; quality.gd separately earns/spends through real input.
		for hero in duel.fighters: hero.meter = 100
	if phase > 4.6 and not marks.has("ready"):
		marks.ready = true
		capture("pair-%d-ready" % (index-1))
	duel.update_hud()
	if elapsed >= 29.9:
		running = false
		game.show_menu()
		game.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().create_timer(.3).timeout
		print("V10 PREVIEW: ten fighters, half-body select, native wide layout, drawn walk/heavy, ready HUD; offline 60-fps capture")
		get_tree().quit()
