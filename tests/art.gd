extends Node
var passed := 0
var failed := 0

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var roster: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json")).fighters
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sprite_atlases.json"))
	var unique_portraits := {}
	for profile in roster:
		var portrait := FighterPortrait.new()
		portrait.setup(profile)
		var region: Rect2 = portrait.texture.region
		var atlas_size: Vector2 = portrait.texture.atlas.get_size()
		check(region.size.x > 100 and Rect2(Vector2.ZERO,atlas_size).encloses(region),profile.id+" portrait is a valid crop of its original sheet")
		unique_portraits[profile.reference_art_path+str(region)] = true
		portrait.free()
	check(unique_portraits.size() == 10,"all ten roster avatars are distinct")
	for id in data:
		var fighter_data: Dictionary = data[id]
		var count := 0
		for atlas_id in ["core","actions","walk"]:
			var texture: Texture2D = load("res://"+fighter_data[atlas_id].path)
			var image := texture.get_image()
			check(image.get_format() == Image.FORMAT_RGBA8 and image.detect_alpha() != Image.ALPHA_NONE,id+" "+atlas_id+" has genuine alpha transparency")
			for frame in fighter_data[atlas_id].frames:
				var r: Array = frame.rect
				check(Rect2(Vector2.ZERO,texture.get_size()).encloses(Rect2(r[0],r[1],r[2],r[3])) and frame.polygon.size() >= 3,id+" "+atlas_id+" frame %d has a bounded textured mesh" % count)
				count += 1
		check(count == 30,id+" has thirty indexed pose keys")
		var profile: Dictionary
		for candidate in roster:
			if candidate.id == id: profile = candidate
		var view := FighterVisual.new()
		view.profile = profile
		add_child(view)
		for animation in fighter_data.animations:
			view.preview_pose = animation
			view.preview_progress = 0.5
			view._update_pose()
			check(view.sprite.texture != null and view.sprite.polygon.size() >= 3 and view.state == animation,id+" renders "+animation)
		view.queue_free()
	var game: Control = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	game.start_match()
	var duel: DuelMatch = game.match_node
	duel.set_physics_process(false)
	var actor := duel.fighters[0]
	actor.begin_attack("heavy")
	actor.attack_time = actor.attack.startup+actor.attack.active*0.65
	actor.visual._update_pose()
	check(actor.visual.state == "heavy" and actor.visual.frame_number == 2,"heavy full-extension artwork coincides with active hitbox")
	actor.attack = null
	actor.guarding = true
	actor.visual._update_pose()
	check(actor.visual.state == "guard","guard input selects authored block pose")
	actor.guarding = false
	actor.hp = 0
	actor.visual._update_pose()
	check(actor.visual.state == "ko","KO selects authored defeated pose")
	duel.set_stopped(true)
	var clock := actor.visual.clock
	actor.visual._process(0.5)
	check(actor.visual.clock == clock,"pause freezes sprite animation clock")
	game.show_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	print("ART RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
