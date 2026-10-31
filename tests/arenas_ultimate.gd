extends Node
var passed := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS " if ok else "FAIL ",message)
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/inferno-v15/"+name+".png")
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/inferno-v15")
	var game := preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	game.show_select(true)
	game.screen.confirm(0)
	game.screen.confirm(1)
	check(game.route == "arena" and game.screen is ArenaSelect,"Android readied character selection goes to map picker")
	check(game.screen.cards.size() == 4 and game.screen.random_button != null,"picker contains all four available maps and RANDOM")
	check(ArenaCatalog.get_arena("crystal_mine").name == "Crystal Fang zijn mijn","mine preserves the user-requested name exactly")
	for card in game.screen.cards:
		check(Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(Rect2(card.position,card.size)),"every map card fits fully inside the Android layout")
	await get_tree().process_frame
	await get_tree().process_frame
	var mine_card: Button = game.screen.cards[3]
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = mine_card.get_global_rect().get_center()
		event.pressed = down
		get_viewport().push_input(event)
	check(game.screen.selection == "crystal_mine","the fourth map is selectable through its actual on-screen card")
	await capture("arena-picker")
	seed(1500)
	var seen := {}
	for i in 128:
		var id := ArenaCatalog.resolve("random")
		check(ArenaCatalog.valid(id),"random returns an available arena")
		seen[id] = true
	check(seen.size() == 4,"random can select each of the four available maps")
	check(not ArenaCatalog.valid("../../other") and not ArenaCatalog.valid("random"),"only resolved known arena IDs are accepted for networking")
	for entry in ArenaCatalog.entries():
		game.show_arena()
		game.screen.select(entry.id)
		game.screen.confirm()
		check(game.route == "fight" and game.backdrop.arena_id == entry.id,"actual map picker loads "+entry.id)
		check(game.backdrop.plate.get_width() >= 1280,"map has high-resolution artwork: "+entry.id)
		var duel: DuelMatch = game.match_node
		duel.set_physics_process(false)
		duel.phase = "fight"
		duel.announcement.text = ""
		duel.fighters[0].meter = 100
		check(duel.fighters[0].begin_attack("ultimate"),"ultimate starts with full meter on "+entry.id)
		duel.update_hud()
		await get_tree().process_frame
		check(duel.ultimate_banners[0].visible and duel.ultimate_banners[0].title.text == "ULTIMATE!","activation displays a large ultimate banner")
		check(duel.fighters[0].get_child(0).visible,"character aura is visible above the arena background")
		await capture("ultimate-"+entry.id)
		var a := duel.fighters[0]
		var b := duel.fighters[1]
		var initial_damage := a.attack.damage
		check(initial_damage == a.moves.ultimate.damage,"initial ultimate keeps its catalog damage")
		a.attack = null
		check(a.begin_attack("heavy") and a.attack.damage == 15,"subsequent heavy is boosted 20% with rounding")
		a.attack = null
		a.empower_time = 2
		a.begin_attack("heavy")
		check(a.attack.damage == 15,"existing empowerment does not stack multiplicatively with ultimate power")
		var before := a.ultimate_time
		duel.set_stopped(true)
		duel._physics_process(.5)
		check(a.ultimate_time == before,"pause freezes the boost and its visual timer")
		duel.set_stopped(false)
		a.attack = null
		a.empower_time = 0
		for i in 181: a.step(1.0/60,{},b)
		check(a.ultimate_time == 0,"ultimate aura and power expire after three seconds of simulation")
		a.begin_attack("heavy")
		check(a.attack.damage == 12,"normal damage returns after expiry")
		a.reset_at(400)
		check(not a.begin_attack("ultimate") and a.ultimate_time == 0,"failed ultimate attempt neither glows nor grants power")
		a.meter = 100
		a.begin_attack("ultimate")
		duel.finish_round()
		check(a.ultimate_time == 0,"round end clears ultimate effects")
		a.reset_at(400)
		check(a.ultimate_time == 0 and a.ultimate_move == "","round reset removes stale power and announcements")
	# Snapshot transport preserves actual active aura on the guest.
	var duel: DuelMatch = game.match_node
	var driver := NetworkMatchDriver.new()
	driver.duel = duel
	duel.fighters[0].ultimate_time = 2.3
	duel.fighters[0].ultimate_move = "Abyssal Frenzy"
	var snapshot := driver.capture()
	duel.fighters[0].ultimate_time = 0
	driver.apply_snapshot(snapshot)
	check(is_equal_approx(duel.fighters[0].ultimate_time,2.3) and duel.fighters[0].ultimate_move == "Abyssal Frenzy","guest snapshot restores ultimate aura time and announcement")
	driver.free()
	OnlineSession.local_slot = 1
	OnlineSession.phase = "arena"
	var epoch := OnlineSession.epoch
	OnlineSession.start_arena("living_ship")
	check(OnlineSession.epoch == epoch,"guest cannot force a match or pick a different arena")
	OnlineSession.close()
	game.show_menu()
	await get_tree().process_frame
	await get_tree().create_timer(.8).timeout
	print("ARENAS ULTIMATE RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(1 if failed else 0)
