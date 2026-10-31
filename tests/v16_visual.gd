extends Node
var game: Control
var output := "/tmp/inferno-v16"
var passed := 0
var failed := 0

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func capture(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	Progression.save_path = output+"/visual-wallet-"+Progression.match_id()+".cfg"
	Progression.load_progress()
	game = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	get_window().size = Vector2i(1600,900)
	await get_tree().process_frame
	game.show_select(true)
	game.screen.choose(0,10)
	game.screen.choose(1,11)
	await get_tree().create_timer(.4).timeout
	await capture("locked-fighter-select")
	check(game.screen.ready_buttons[0].text.contains("200") and game.screen.ready_buttons[1].text.contains("200"),"both paid fighters show their lock action and coin balance")
	game.show_gallery()
	for i in game.roster.size():
		game.screen.show_fighter(i)
		await get_tree().create_timer(.65).timeout
		var presentation: FighterIllustration = game.screen.presentation
		check(presentation.texture.get_width() >= 1000,game.roster[i].id+" gallery uses a high-resolution 2D illustration")
		for mode in ["body","portrait","signature"]:
			if mode == "portrait": presentation.set_portrait(true)
			elif mode == "signature": presentation.toggle_signature()
			else: presentation.set_portrait(false)
			await get_tree().process_frame
			var rect := Rect2(Vector2.ZERO,presentation.get_viewport().get_visible_rect().size)
			check(rect.encloses(presentation.framed_rect),game.roster[i].id+" complete "+mode+" illustration stays inside the preview")
		presentation.signature = false
		presentation.set_portrait(false)
		await get_tree().create_timer(.35).timeout
		check(is_equal_approx(presentation.figure.modulate.a,1),game.roster[i].id+" finishes the entrance at full brightness")
		if i in [0,5,10,11]: await capture(game.roster[i].id+"-gallery")
		if i in [10,11]:
			game.show_fighter_intro(i)
			await get_tree().create_timer(3.7).timeout
			check(game.screen.video.is_playing() and game.screen.video.get_stream_length() > 6,game.roster[i].id+" intro actually decodes and plays")
			await capture(game.roster[i].id+"-intro")
			game.show_gallery()
	# Authoring fixture: normal purchase API, isolated wallet; no shipping grant.
	Progression.coins = 400
	Progression.purchase("bamboo_blade")
	Progression.purchase("sawtina")
	game.selected.assign([10,11])
	game.arena_choice = "crystal_mine"
	game.solo = true
	game.start_match()
	var duel: DuelMatch = game.match_node
	duel.set_physics_process(false)
	duel.phase = "fight"
	duel.announcement.text = ""
	duel.fighters[0].position.x = 385
	duel.fighters[1].position.x = 895
	duel.update_hud()
	await get_tree().create_timer(.4).timeout
	await capture("new-fighters-combat")
	for side in 2:
		for fighter in duel.fighters: fighter.reset_at(385 if fighter.player == 0 else 895)
		var actor := duel.fighters[side]
		actor.meter = 100
		check(actor.begin_attack("ultimate"),actor.profile.id+" activates its own ultimate")
		actor.attack_time = actor.attack.startup+actor.attack.active*.5
		actor.visual._update_pose()
		duel._spawn_projectile(actor,actor.attack)
		duel.update_hud()
		var driver := NetworkMatchDriver.new()
		driver.duel = duel
		var snapshot := driver.capture()
		var compressed := var_to_bytes(snapshot).compress(FileAccess.COMPRESSION_DEFLATE)
		check(compressed.size() < 1200,"compressed projectile snapshot stays within a single Wi-Fi datagram")
		driver.apply_snapshot(snapshot)
		check(duel.projectiles.size() == 3,"all three ultimate projectiles survive snapshot reconstruction")
		driver.free()
		await capture(actor.profile.id+"-ultimate")
		for p in duel.projectiles: p.queue_free()
		duel.projectiles.clear()
	var scores: Array[int] = [2,0]
	game.show_result(scores)
	check(Progression.coins == 5,"rendered result shows the five-coin victory reward")
	await capture("coin-reward")
	game.show_online()
	game.screen.code_input.grab_focus()
	for symbol in "ab-23 cd":
		var event := InputEventKey.new()
		event.keycode = OS.find_keycode_from_string(symbol.to_upper())
		event.physical_keycode = event.keycode
		event.unicode = symbol.unicode_at(0)
		event.pressed = true
		get_viewport().push_input(event)
	await get_tree().process_frame
	check(game.screen.code_input.text == "AB23CD","pasted session code normalizes spaces and hyphens before length validation")
	await capture("session-connect")
	game.show_menu()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(.5).timeout
	print("V16 VISUAL RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
