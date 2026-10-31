extends Node
var passed := 0
var failed := 0
var duel: DuelMatch
var roster: Array
func check(ok: bool, description: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS " if ok else "FAIL ",description)

func reset_pair(x := 530.0, y := 630.0) -> void:
	duel.start_round(false)
	duel.phase = "fight"
	duel.fighters[0].reset_at(x)
	duel.fighters[1].reset_at(y)
	duel.fighters[0].facing = 1
	duel.fighters[1].facing = -1

func tick(a: Dictionary = {}, b: Dictionary = {}, frames := 1) -> void:
	for i in frames: duel.advance_fight(1.0/60,[a if i == 0 else {},b if i == 0 else {}])

func button(device: int, code: int, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = device
	e.button_index = code
	e.pressed = down
	InputRouter._input(e)

func _ready() -> void:
	await get_tree().process_frame
	roster = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json")).fighters
	duel = DuelMatch.new()
	duel.modern_rules = true
	duel.profiles = [roster[0],roster[1]]
	add_child(duel)
	duel.set_physics_process(false)
	var a := duel.fighters[0]
	var b := duel.fighters[1]
	reset_pair()
	# Actual router events, isolated ownership, edge semantics, hotplug.
	InputRouter.assign_device(40,true)
	InputRouter.assign_device(41,true)
	button(40,JOY_BUTTON_X,true)
	check(InputRouter.sample(0).light and not InputRouter.sample(1).light,"pad one cannot attack for player two")
	check(not InputRouter.sample(0).light,"held attack does not repeat")
	button(41,JOY_BUTTON_Y,true)
	check(InputRouter.sample(1).heavy,"pad two owns its independent attack")
	var axis := InputEventJoypadMotion.new()
	axis.device = 40
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = .1
	InputRouter._input(axis)
	check(InputRouter.sample(0).axis == 0,"stick deadzone rejects drift")
	axis.axis_value = .8
	InputRouter._input(axis)
	check(InputRouter.sample(0).axis > .7,"analog movement survives deadzone scaling")
	InputRouter.assign_device(40,false)
	check(InputRouter.sample(0).axis == 0 and InputRouter.pad_held[0].is_empty(),"unplug clears owned movement and held buttons")
	InputRouter.assign_device(42,true)
	check(InputRouter.devices == [42,41],"replacement fills vacant slot without stealing player two")
	button(43,JOY_BUTTON_X,true)
	check(not InputRouter.sample(0).light,"unassigned controller cannot act")
	InputRouter.assign_device(42,false)
	InputRouter.assign_device(41,false)
	check(not OnlineSession.sanitize_input(InputRouter.network_sample(0)).is_empty(),"LAN sample remains within the existing packet schema")
	InputRouter.clear()
	# Commands are relative to facing and expire with simulation time.
	for facing in [-1,1]:
		var cmd := MotionCommands.new()
		cmd.sample(.016,{"block":true},facing)
		cmd.sample(.016,{"block":true,"axis":facing},facing)
		check(cmd.sample(.016,{"axis":facing,"special":true},facing) == "rising","quarter circle recognizes facing %d" % facing)
		check(cmd.sample(.016,{"axis":facing,"special":true},facing) == "","motion consumed once")
	var cmd := MotionCommands.new()
	cmd.sample(.016,{"block":true},1)
	cmd.sample(.016,{"block":true,"axis":1},1)
	check(cmd.sample(.5,{"axis":1,"special":true},1) == "","stale command rejected")
	reset_pair()
	tick({"block":true})
	tick({"block":true,"axis":1})
	tick({"axis":1,"special":true})
	check(a.attack != null and a.attack.id == "v12_rising" and a.velocity.y < 0,"quarter circle enters real launching attack")
	reset_pair()
	tick({"axis":1})
	tick({})
	tick({"axis":1,"heavy":true})
	check(a.attack != null and a.attack.id == "v12_rush","double forward heavy selects momentum strike")
	# Throws: range, guard bypass, tech, reverse direction, immunity.
	reset_pair(300,600)
	tick({"grab":true})
	check(duel.arena_rules.grabs.is_empty() and b.hp == 200,"out of range grab cannot acquire a fighter")
	reset_pair()
	tick({"grab":true},{"block":true})
	check(duel.arena_rules.grabs.size() == 1,"close grab acquires a guarding fighter")
	tick({}, {},18)
	check(b.hp == 182 and b.velocity.y < 0,"throw bypasses guard and launches for 18 damage")
	check(b.throw_protection > 0,"throw grants regrab protection")
	reset_pair()
	tick({"grab":true},{"grab":true})
	check(a.hp == 200 and b.hp == 200 and duel.arena_rules.grabs.is_empty(),"simultaneous grabs tech symmetrically")
	reset_pair()
	tick({"grab":true})
	tick({}, {},5)
	tick({}, {"grab":true})
	check(b.hp == 200 and duel.arena_rules.grabs.is_empty() and b.command_notice == "THROW TECH","defender can tech during the 220ms window")
	reset_pair()
	tick({"grab":true})
	tick({}, {},14)
	tick({}, {"grab":true})
	check(b.hp == 182,"late throw tech cannot undo committed damage")
	reset_pair()
	tick({"grab":true,"axis":-1})
	tick({}, {},16)
	check(b.position.x < a.position.x,"backward grab reverses throw direction")
	reset_pair()
	b.stun = .8
	b.meter = 34
	tick({}, {"escape":true})
	check(b.stun > 0 and b.meter == 34,"escape cannot spend unavailable meter")
	b.meter = 35
	tick({}, {"escape":true})
	check(b.stun == 0 and b.meter == 0 and b.immunity > 0,"35 meter break-free cancels stun with bounded immunity")
	# Traps: visible warning first, jump avoidance, no HP drain, cooldown.
	reset_pair(460,1000)
	duel.arena_rules.elapsed = 5.5
	check(duel.arena_rules.trap_phase(0) == "warning","clamp warns before activation")
	tick()
	check(a.stun == 0,"warning never stuns")
	duel.arena_rules.elapsed = 6.19
	tick()
	check(a.stun > .7 and a.hp == 200 and a.attack == null,"active clamp stuns grounded fighter without hidden damage")
	tick({}, {},50)
	check(a.stun == 0,"trap stun expires naturally")
	reset_pair(460,1000)
	a.position.y -= 70
	duel.arena_rules.elapsed = 6.2
	tick()
	check(a.stun == 0,"airborne fighter clears the clamp")
	reset_pair(460,1000)
	a.meter = 35
	duel.arena_rules.elapsed = 6.2
	tick()
	tick({"escape":true})
	check(a.stun == 0 and not a.trapped and a.meter == 0,"universal escape breaks a clamp without immediate retrigger")
	duel.stopped = true
	var before := duel.arena_rules.elapsed
	var time_before := duel.remaining
	await get_tree().create_timer(.15).timeout
	check(duel.arena_rules.elapsed == before and duel.remaining == time_before,"pause freezes authoritative traps and combat clock")
	duel.stopped = false
	reset_pair()
	check(duel.arena_rules.elapsed == 0 and duel.arena_rules.grabs.is_empty(),"round reset clears traps and held grabs")
	reset_pair(70,100)
	duel._resolve_bodies()
	check(absf(b.position.x-a.position.x) >= 85.99,"wall collision preserves full body separation")
	reset_pair()
	tick({"grab":true})
	a.trapped = true
	tick()
	check(duel.arena_rules.grabs.is_empty() and b.hp == 200,"trap interrupts a pending throw")
	# All twenty new motion moves must really hit, not merely select a name.
	for profile in roster:
		a.profile = profile
		a.moves = MoveCatalog.build(profile,DuelFighter.ATTACKS)
		# Rebuild the model-independent motion variants using a fresh fighter.
		var fresh := DuelFighter.new()
		fresh.profile = profile
		fresh.modern_rules = true
		add_child(fresh)
		a.moves = fresh.moves
		fresh.free()
		for motion in ["rising","rush"]:
			reset_pair(560,650)
			if motion == "rising":
				tick({"block":true})
				tick({"block":true,"axis":1})
				tick({"axis":1,"special":true})
			else:
				tick({"axis":1})
				tick({})
				tick({"axis":1,"heavy":true})
			tick({}, {},60)
			check(b.hp == 200-(22 if motion == "rising" else 18),profile.id+" "+motion+" deals exact damage through real directional input")
	# Build real volume models for every profile, not just two silhouettes.
	for profile in roster:
		var f := DuelFighter.new()
		f.profile = profile
		add_child(f)
		var model := FighterModel3D.new()
		model.actor = f
		duel.arena_3d.world.add_child(model)
		check(model.mesh_count >= 25 and model.arms.size() == 2 and model.legs.size() == 2,"articulated volume model built for "+profile.id)
		model.free()
		f.free()
	if "--rendered" in OS.get_cmdline_user_args():
		reset_pair(440,840)
		duel.layout_hud(Rect2(0,0,1280,720))
		duel.announcement.text = ""
		for i in 12: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("/tmp/inferno-v12")
		var image := get_viewport().get_texture().get_image()
		image.save_png("/tmp/inferno-v12/arena.png")
		check(image.get_width() >= 1280,"rendered arena screenshot captured from native viewport")
		var world_image := duel.arena_3d.viewport.get_texture().get_image()
		check(world_image.get_pixel(640,500).a > .9,"3D viewport renders an opaque arena surface")
		duel.scale = Vector2.ONE*.75
		await get_tree().process_frame
		await get_tree().process_frame
		check(duel.arena_3d.viewport.size == Vector2i(960,540),"3D framebuffer follows actual stage pixel density")
		duel.scale = Vector2.ONE
		await get_tree().process_frame
		await get_tree().process_frame
		check(duel.arena_3d.viewport.size == Vector2i(1280,720),"3D framebuffer restores after resizing")
	duel.queue_free()
	await get_tree().process_frame
	# Full controller navigation must not double-activate Godot ui_accept.
	var game := preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	InputRouter.assign_device(40,true)
	InputRouter.assign_device(41,true)
	var pad := InputEventJoypadButton.new()
	pad.device = 40
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	get_viewport().push_input(pad)
	check(game.route == "select" and not game.screen.ready_players[0],"one controller accept opens selection without double activation")
	pad.pressed = false
	get_viewport().push_input(pad)
	pad.pressed = true
	get_viewport().push_input(pad)
	check(game.screen.ready_players[0] and not game.screen.ready_players[1],"pad one readies only its owned slot")
	pad.device = 41
	get_viewport().push_input(pad)
	check(game.route == "arena","two controller confirmations reach arena selection")
	pad.pressed = false
	get_viewport().push_input(pad)
	pad.pressed = true
	get_viewport().push_input(pad)
	check(game.route == "fight" and game.match_node.modern_rules,"controller starts actual local 3D rules")
	InputRouter.assign_device(41,false)
	check(game.route == "pause" and game.match_node.stopped,"controller unplug pauses the running match")
	game.show_menu()
	game.show_select(true)
	game._controller_action(0,"pause")
	check(game.route == "arena","one controller can ready both human and CPU in solo")
	InputRouter.assign_device(40,false)
	game.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(.8).timeout
	print("V12 RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(1 if failed else 0)
