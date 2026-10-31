extends SceneTree
## Runs OUTSIDE the APK pack. All game scripts, artwork and metadata come from
## the exported Android assets; editor resources cannot satisfy missing files.
var passed := 0
var failed := 0
var output := "/tmp/inferno-v17"
var game

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func count_buttons(node: Node, text: String) -> int:
	var count := 1 if node is Button and node.text == text else 0
	for child in node.get_children(): count += count_buttons(child,text)
	return count

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/apk-"+name+".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	var progression = root.get_node("Progression")
	progression.save_path = output+"/apk-wallet-"+str(Time.get_ticks_usec())+".cfg"
	progression.load_progress()
	var scene = load("res://scenes/main.tscn")
	game = scene.instantiate()
	game.touch_mode = true
	root.add_child(game)
	root.size = Vector2i(1280,800)
	await create_timer(.7).timeout
	check(game.menu_previews.size() == 2 and game.menu_pair[0] != game.menu_pair[1],"APK menu uses two different fighters")
	for hero in game.menu_previews:
		check(hero.texture != null and not hero.fallback_used,"APK menu loads its real high-resolution texture")
	await capture("random-menu")
	game.show_gallery()
	for index in game.roster.size():
		game.screen.show_fighter(index)
		await create_timer(.7).timeout
		var illustration = game.screen.presentation
		var identity: String = game.roster[index].id
		check(illustration.texture != null and not illustration.fallback_used,identity+" gallery texture loads from exported APK")
		var artwork = illustration.metadata
		check(ResourceLoader.exists("res://"+str(artwork.path)),identity+" illustration resource exists in exported pack")
		var rendered: Image = game.screen.demo_viewport.get_texture().get_image()
		var palette := {}
		for y in range(0,rendered.get_height(),7):
			for x in range(0,rendered.get_width(),7):
				var pixel := rendered.get_pixel(x,y)
				var key := (int(pixel.r*31)<<10)+(int(pixel.g*31)<<5)+int(pixel.b*31)
				palette[key] = true
		check(palette.size() > 80,identity+" APK render has detailed colored artwork instead of a white silhouette")
		if identity in ["cheese_rat","sharkbyte","sawtina"]: await capture("gallery-"+identity)
	game.show_story()
	check(game.screen.cards.size() == 4,"APK contains all four story levels")
	game.screen.cards[0].pressed.emit()
	await create_timer(.7).timeout
	await capture("story-briefing")
	game.start_story_level(0)
	check(game.match_node.profiles[0].id == "sharkbyte" and game.match_node.profiles[1].id == "bullet","APK starts SharkByte versus Bullet in the first story level")
	var duel = game.match_node
	duel.set_physics_process(false)
	for round_index in 2:
		duel.phase = "fight"
		duel.fighters[1].hp = 0
		duel.finish_round()
		duel._physics_process(2.1)
	check(progression.story_completed == 1 and progression.coins == 5,"APK story victory saves its checkpoint and five coins")
	check(count_buttons(game.overlay,"MAIN MENU") == 1,"APK story result has a single main-menu action")
	game.show_menu()
	game.queue_free()
	await process_frame
	await create_timer(.5).timeout
	print("APK UI RESULT: %d passed, %d failed" % [passed,failed])
	quit(0 if failed == 0 else 1)
