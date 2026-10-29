extends Node
const OUTPUT := "/tmp/inferno-v10-visual"
var game: Control
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error(label)

func capture(name: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(OUTPUT+"/"+name+".png")
	return image

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	for size in [Vector2i(1280,582),Vector2i(2400,1080),Vector2i(2780,1264),Vector2i(2532,1170),Vector2i(1024,768),Vector2i(1280,720)]:
		get_window().size = size
		game.show_select(true)
		game.selected.assign([5,9])
		game.start_match()
		var duel: DuelMatch = game.match_node
		duel.set_physics_process(false)
		duel.phase = "fight"
		duel.announcement.text = ""
		for frame in 3: await get_tree().process_frame
		game._resize_stage()
		var safe := TouchControls.safe_rect(get_viewport())
		var backdrop_rect := Rect2(game.stage.position+game.backdrop.view_rect.position*game.stage.scale,game.backdrop.view_rect.size*game.stage.scale)
		check(backdrop_rect.position.distance_to(Vector2.ZERO) < .1 and backdrop_rect.size.distance_to(Vector2(size)) < .1,"%s arena covers the full native surface without a 16:9 frame" % size)
		check(duel.hud.get_global_rect().position.distance_to(safe.position) < .1 and duel.hud.get_global_rect().size.distance_to(safe.size) < .1,"%s HUD follows the same usable screen rectangle as touch controls" % size)
		for bar in duel.health:
			check(safe.encloses(bar.get_global_rect()),"%s health bar remains inside the screen" % size)
		var targets_fit := true
		for button in game.touch_controls.buttons: targets_fit = targets_fit and safe.encloses(button.rect)
		check(targets_fit,"%s all combat buttons are visible and reachable within the safe area" % size)
		var image := await capture("fight-%dx%d" % [size.x,size.y])
		check(image.get_size() == size,"%s uses actual device/window pixels" % size)
		# Former black wings have essentially constant pixels. Painted scenery varies.
		var scenery := true
		for x in [int(size.x*.025),int(size.x*.975)]:
			var colors := {}
			for sample in 30:
				var pixel := image.get_pixel(x,int(size.y*(.3+sample*.017)))
				colors[pixel.to_rgba32()] = true
			scenery = scenery and colors.size() > 15
		check(scenery,"%s former side wings contain live arena artwork" % size)
		check(is_equal_approx(duel.fighters[0].visual.sprite.scale.x,duel.fighters[0].visual.sprite.scale.y),"%s fighter proportions remain uniform while the background fills the screen" % size)
	get_window().size = Vector2i(1280,720)
	var illustrated := 0
	var triangulates := true
	for index in game.roster.size():
		game.show_select(true)
		game.screen.choose(0,index)
		for frame in 3: await get_tree().process_frame
		var bust: FighterBust = game.screen.hero_holders[0].get_child(0)
		check(bust.clip_contents and bust.figure.texture is AtlasTexture and not bust.figure.is_processing(),game.roster[index].id+" has an intact waist-up drawing instead of a tiny animated full-body sprite")
		check(bust.figure.material == null and bust.figure.texture.region.size.x >= 500,game.roster[index].id+" select portrait has no flow deformation or ghost layer")
		var data: Dictionary = FighterVisual.art_cache[game.roster[index].id]
		illustrated += data.drawn.frames.size()
		if data.has("drawn_heavy"): illustrated += data.drawn_heavy.frames.size()
		for source in ["drawn","drawn_heavy"]:
			if not data.has(source): continue
			for frame in data[source].frames:
				var points := PackedVector2Array()
				for point in frame.polygon: points.append(Vector2(point[0],point[1]))
				triangulates = triangulates and Geometry2D.triangulate_polygon(points).size() >= 3
		check(data.animations.walk.frames.size() == 12 and data.animations.heavy.frames.size() == 12,game.roster[index].id+" has twelve real walk and heavy drawings")
		if index in [0,5,9]:
			await get_tree().create_timer(.3).timeout
			await capture("select-"+game.roster[index].id)
	check(illustrated == 240,"all 240 new complete drawings are indexed; rejected/cropped poses are excluded")
	check(triangulates,"every new pose triangulates for both combat and the persistent 3D podium")
	game.show_menu()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(.6).timeout
	print("V10 VISUAL RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
