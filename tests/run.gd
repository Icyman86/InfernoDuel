extends Node
var passed := 0
var failures: Array[String] = []
var game: Control
var match_node: DuelMatch
const DT := 1.0/60.0

func check(value: bool, description: String) -> void:
	if value:
		passed += 1
		print("PASS ",description)
	else:
		failures.append(description)
		push_error("FAIL "+description)

func key(code: int, down := true) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	get_viewport().push_input(event)

func fresh() -> void:
	match_node.start_round(false)
	match_node.phase = "fight"
	match_node.fighters[0].position.x = 560
	match_node.fighters[1].position.x = 650

func ticks(count: int, a: Dictionary = {}, b: Dictionary = {}) -> void:
	for i in count:
		match_node.advance_fight(DT,[a if i == 0 else {},b if i == 0 else {}])

func find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var result := find_button(child,text)
		if result: return result
	return null

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	await get_tree().process_frame
	game = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	check(game.route == "menu","main scene boots to menu")
	check(game.roster.size() == 12,"twelve data-driven roster profiles")
	game.show_select(false)
	var picker: CharacterSelect = game.screen
	picker.handle_key(KEY_D)
	picker.handle_key(KEY_LEFT)
	check(picker.selected == [1,0],"both select cursors navigate independently")
	picker.choose(0,8)
	picker.confirm(0)
	check(picker.ready_players[0],"Crystal Fang is fully selectable and can ready")
	picker.ready_players[0] = false
	picker.choose(0,0)
	picker.choose(1,1)
	picker.confirm(0)
	picker.confirm(1)
	check(game.route == "arena","both confirmations open arena selection")
	game.start_match()
	match_node = game.match_node
	match_node.set_physics_process(false)
	check(match_node.phase == "countdown","round begins with locked countdown")
	key(KEY_D)
	match_node._physics_process(DT)
	check(InputRouter.sample(0).axis == 0,"countdown clears held input")
	fresh()
	var a := match_node.fighters[0]
	var b := match_node.fighters[1]
	key(KEY_A)
	key(KEY_RIGHT)
	key(KEY_F)
	key(KEY_I)
	var p1: Dictionary = InputRouter.sample(0)
	var p2: Dictionary = InputRouter.sample(1)
	check(p1.axis == -1 and p2.axis == 1 and p1.light and p2.light,"physical events route simultaneous movement and attacks")
	check(not InputRouter.sample(0).light,"held attack does not retrigger")
	InputRouter.clear()
	check(InputRouter.sample(0).axis == 0 and InputRouter.sample(1).axis == 0,"clearing releases both players")
	for player in 2:
		for code in InputRouter.keys[player]:
			key(code)
			var action: String = InputRouter.keys[player][code]
			var sample: Dictionary = InputRouter.sample(player)
			var registered: bool = sample.get(action,false) == true
			if action == "move_left": registered = sample.axis == -1
			if action == "move_right": registered = sample.axis == 1
			check(registered,"P%d maps %s" % [player+1,action])
			InputRouter.clear()
	fresh()
	var x := a.position.x
	match_node.advance_fight(DT,[{"axis":-1},{"axis":1}])
	check(a.position.x < x and b.position.x > 650,"fighters move simultaneously")
	fresh()
	ticks(8,{"light":true},{"light":true})
	check(a.hp == DuelFighter.MAX_HEALTH - 6 and b.hp == DuelFighter.MAX_HEALTH - 6,"same-tick light attacks trade for six damage each")
	check(a.meter == 10 and b.meter == 10,"hit meter accrues independently")
	ticks(8)
	check(a.hp == DuelFighter.MAX_HEALTH - 6 and b.hp == DuelFighter.MAX_HEALTH - 6,"one hit per attack activation")
	fresh()
	for i in 16: match_node.advance_fight(DT,[{"heavy":i==0},{"block":true}])
	check(b.hp == DuelFighter.MAX_HEALTH - 3 and b.meter == 4,"ground guard reduces heavy damage by 75 percent")
	fresh()
	b.guarding = true
	b.facing = 1
	b.receive_hit(DuelFighter.ATTACKS.light,a.position.x)
	check(b.hp == DuelFighter.MAX_HEALTH - 6,"guard does not protect the fighter's back")
	fresh()
	a.position.x = 200
	ticks(20,{"heavy":true})
	check(b.hp == DuelFighter.MAX_HEALTH,"out-of-range hitboxes miss")
	fresh()
	a.begin_attack("special")
	check(a.special_cooldown == 1.5,"special starts independent cooldown")
	ticks(55)
	check(not a.begin_attack("special"),"special cannot repeat before cooldown")
	ticks(40)
	check(a.begin_attack("special"),"special becomes available after cooldown")
	fresh()
	a.begin_attack("heavy")
	for i in 27: a.step(DT,{},b)
	a.step(DT,{"light":true},b)
	for i in 9: a.step(DT,{},b)
	check(a.attack != null and a.attack.id == "light","late recovery input buffers a follow-up attack")
	fresh()
	ticks(10,{"light":true})
	ticks(1,{"special":true})
	check(a.attack != null and a.attack.id == "special","landed light cancels recovery into special")
	fresh()
	check(not a.begin_attack("ultimate"),"ultimate requires full meter")
	a.meter = 100
	ticks(25,{"ultimate":true})
	check(a.meter == 0 and b.hp == DuelFighter.MAX_HEALTH - 30,"ultimate consumes meter and deals thirty damage")
	fresh()
	b.meter = 100
	ticks(70,{}, {"ultimate":true})
	check(a.hp == DuelFighter.MAX_HEALTH - 30 and b.meter == 0,"Bullet ultimate projectile collides exactly once")
	fresh()
	a.position.x = 560
	b.position.x = 625
	ticks(18,{"light":true})
	ticks(18,{"light":true})
	ticks(20,{"heavy":true})
	check(b.hp == DuelFighter.MAX_HEALTH - 24 and a.combo == 3,"light-light-heavy connects as three-hit combo")
	check(b.immunity > 0,"third hit grants escape immunity against infinite stun")
	fresh()
	ticks(1,{"jump":true})
	var vy := a.velocity.y
	ticks(1,{"jump":true})
	check(a.position.y < DuelFighter.FLOOR and a.velocity.y > vy,"jump works without a double jump")
	ticks(70)
	check(a.grounded(),"gravity returns fighter to arena floor")
	a.position.x = 71
	for i in 60: match_node.advance_fight(DT,[{"axis":-1},{}])
	check(a.position.x >= DuelFighter.LEFT,"arena boundary contains fighter")
	fresh()
	var before := match_node.remaining
	game.show_pause()
	match_node._physics_process(1)
	check(match_node.remaining == before and match_node.stopped,"pause freezes timer and simulation")
	key(KEY_D)
	game.resume_match()
	check(InputRouter.sample(0).axis == 0 and not match_node.stopped,"resume releases stale held keys")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.route == "pause" and match_node.stopped,"focus loss automatically pauses")
	game.show_options("pause")
	check(game.route == "options" and match_node.stopped,"pause options keep combat stopped")
	game.show_pause()
	game.resume_match()
	fresh()
	a.meter = 42
	b.hp = 70
	match_node.remaining = DT/2
	ticks(1)
	check(match_node.phase == "round_over" and match_node.wins[0] == 1,"timeout awards healthier fighter")
	match_node.start_round()
	check(a.meter == 42 and a.hp == DuelFighter.MAX_HEALTH,"meter persists but health resets between rounds")
	match_node.phase = "fight"
	match_node.remaining = 0
	match_node.finish_round()
	check(match_node.wins == [1,0] and match_node.result_text.begins_with("DRAW"),"equal timeout replays round without awarding score")
	match_node._physics_process(2.1)
	check(match_node.round_number == 1,"draw retry keeps round number")
	fresh()
	a.hp = 6
	b.hp = 6
	ticks(8,{"light":true},{"light":true})
	check(a.hp == 0 and b.hp == 0 and match_node.wins == [1,0],"double KO trades without awarding a round")
	# Complete a full 2-1 match through actual attacks and round transitions.
	match_node.wins = [0,0]
	match_node.round_number = 1
	for winner in [0,1,0]:
		fresh()
		var loser: DuelFighter = match_node.fighters[1-winner]
		loser.hp = 6
		match_node.advance_fight(DT,[{"light":winner==0},{"light":winner==1}])
		ticks(8)
		check(match_node.phase == "round_over","KO locks round %d" % match_node.round_number)
		match_node._physics_process(2.1)
	check(game.route == "result" and match_node.wins == [2,1],"complete best-of-three match reaches 2-1 result")
	game.start_match()
	match_node = game.match_node
	match_node.set_physics_process(false)
	check(match_node.wins == [0,0] and match_node.fighters[0].hp == DuelFighter.MAX_HEALTH and match_node.fighters[0].meter == 0,"rematch resets score health and meter")
	match_node.wins[0] = 1
	game.show_pause()
	find_button(game.overlay,"RESTART MATCH").pressed.emit()
	check(is_instance_valid(game.modal) and game.modal.visible,"restart requires a visible confirmation")
	game.modal.canceled.emit()
	check(game.match_node.wins[0] == 1,"cancel restart preserves score")
	find_button(game.overlay,"RESTART MATCH").pressed.emit()
	game.modal.confirmed.emit()
	match_node = game.match_node
	match_node.set_physics_process(false)
	check(match_node.wins == [0,0] and game.route == "fight","confirmed restart creates fresh match")
	game.show_gallery()
	check(game.screen.art.texture != null,"gallery loads original reference art")
	for i in game.roster.size(): game.screen.show_fighter(i)
	check(game.screen.current == 11,"all twelve gallery entries load")
	game.show_story()
	check(game.route == "story","story has a working preview screen")
	game.show_menu()
	game.show_select(true)
	game.selected.assign([0,1])
	game.start_match()
	match_node = game.match_node
	match_node.set_physics_process(false)
	fresh()
	match_node.ai.rng.seed = 1234
	var cpu_attacked := false
	var cpu_moved := false
	match_node.fighters[1].position.x = 1000
	for i in 600:
		var cpu: Dictionary = match_node.ai.sample(DT,match_node.fighters[1],match_node.fighters[0])
		if cpu.get("axis",0) != 0: cpu_moved = true
		if cpu.get("light",false) or cpu.get("heavy",false) or cpu.get("special",false): cpu_attacked = true
		match_node.advance_fight(DT,[{},cpu])
	check(cpu_moved and cpu_attacked and match_node.fighters[0].hp < DuelFighter.MAX_HEALTH,"easy CPU approaches and damages player")
	# CPU completes a full match with normal HP and timers against a passive player.
	match_node.start_round(false)
	match_node.wins.assign([0,0])
	match_node.round_number = 1
	for i in 30000:
		match_node._physics_process(DT)
		if match_node.phase == "complete": break
	check(game.route == "result" and match_node.wins[1] == 2,"CPU completes an unmodified full match against passive player")
	game.selected.assign([0,0])
	game.start_match()
	match_node = game.match_node
	match_node.set_physics_process(false)
	fresh()
	match_node.fighters[0].meter = 35
	ticks(8,{"light":true},{"light":true})
	check(match_node.fighters[0].hp == DuelFighter.MAX_HEALTH - 6 and match_node.fighters[1].hp == DuelFighter.MAX_HEALTH - 6 and match_node.fighters[1].meter == 10,"mirror match keeps each instance's combat state separate")
	Settings.sfx = 0.42
	Settings.save()
	var config := ConfigFile.new()
	check(config.load("user://settings.cfg") == OK and is_equal_approx(config.get_value("audio","sfx"),0.42),"options persist to user settings")
	Settings.reset()
	game.show_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	print("\nRESULT: %d passed, %d failed" % [passed,failures.size()])
	for failure in failures: print("FAILED: ",failure)
	get_tree().quit(0 if failures.is_empty() else 1)
