extends Node
const DT := 1.0/60.0
var game: Control
var duel: DuelMatch
var roster: Array
var passed := 0
var failed := 0

func check(value: bool, message: String) -> void:
	if value:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func index_of(id: String) -> int:
	for i in roster.size():
		if roster[i].id == id: return i
	return -1

func fresh(id: String, x := 200.0, target_x := 600.0) -> void:
	game.selected.assign([index_of(id),0])
	game.start_match()
	duel = game.match_node
	duel.set_physics_process(false)
	duel.phase = "fight"
	duel.fighters[0].position.x = x
	duel.fighters[1].position.x = target_x

func ticks(count: int, command: Dictionary = {}, block := false) -> void:
	for i in count:
		duel.advance_fight(DT,[command if i == 0 else {},{"block":block}])

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	roster = game.roster
	var available := 0
	for profile in roster:
		if profile.playable: available += 1
	check(available == 5,"exactly five complete fighters are available")
	for id in ["poisonboy","chainveil","cheese_rat"]:
		game.show_select(false)
		game.screen.choose(0,index_of(id))
		game.screen.confirm(0)
		check(game.screen.ready_players[0],id+" can ready in local selection")
		check(game.screen.hero_holders[0].get_child(0) is FighterVisual,id+" has animated selection art")
		fresh(id,560,650)
		ticks(8,{"light":true})
		check(duel.fighters[1].hp == 94,id+" has a functional six-damage light attack")
		fresh(id,560,650)
		ticks(17,{"heavy":true})
		check(duel.fighters[1].hp == 88,id+" has a functional twelve-damage heavy")
		fresh(id,560,650)
		ticks(17,{"heavy":true},true)
		check(duel.fighters[1].hp == 97,id+" heavy can be guarded for chip damage")
		fresh(id)
		check(not duel.fighters[0].begin_attack("ultimate"),id+" ultimate requires full meter")
		duel.fighters[0].meter = 100
		check(duel.fighters[0].begin_attack("ultimate") and duel.fighters[0].meter == 0,id+" ultimate spends full meter")
	fresh("poisonboy")
	ticks(100,{"special":true})
	check(duel.fighters[1].hp == 84,"Toxic Splash travels and hits once for sixteen")
	check(duel.fighters[0].position.x == 200,"PoisonBoy casts instead of using the generic dash")
	fresh("poisonboy")
	ticks(100,{"special":true},true)
	check(duel.fighters[1].hp == 96,"toxic projectile is directionally blockable")
	fresh("poisonboy")
	duel.fighters[0].meter = 100
	ticks(110,{"ultimate":true})
	check(duel.fighters[1].hp == 70,"Venom Cataclysm cloud delivers thirty damage once")
	fresh("chainveil",400,620)
	ticks(25,{"special":true})
	check(duel.fighters[1].hp == 84,"Chain Lash reaches beyond normal melee range")
	check(duel.fighters[1].position.x < 620,"Chain Lash pulls its target inward")
	fresh("chainveil",400,620)
	ticks(25,{"special":true},true)
	check(duel.fighters[1].hp == 96,"Chain Lash can be blocked")
	fresh("chainveil",400,655)
	duel.fighters[0].meter = 100
	ticks(35,{"ultimate":true})
	check(duel.fighters[1].hp == 70,"Iron Widow has extended reach and thirty damage")
	fresh("cheese_rat")
	ticks(90,{"special":true})
	check(duel.fighters[1].hp == 84,"Cheese Ball travels and strikes once")
	fresh("cheese_rat",450,950)
	ticks(12,{"special":true,"axis":-1})
	check(duel.projectiles.size() == 1 and duel.projectiles[0].kind == "cheese_trap" and duel.projectiles[0].speed == 0,"back plus special places a stationary Cheese Trap")
	var trap := duel.projectiles[0]
	check(trap.position.x < duel.fighters[0].position.x,"Cheese Trap is placed behind the retreating fighter")
	duel.fighters[1].position.x = trap.position.x
	ticks(3)
	check(duel.fighters[1].hp == 84 and duel.projectiles.is_empty(),"trap damages only the enemy and is consumed once")
	fresh("cheese_rat",200,1000)
	ticks(12,{"special":true,"axis":-1})
	var trap_x := duel.projectiles[0].position.x
	ticks(120)
	check(duel.projectiles.size() == 1 and duel.projectiles[0].position.x == trap_x,"trap remains stationary while waiting")
	ticks(130)
	check(duel.projectiles.is_empty(),"unused trap expires after its lifetime")
	fresh("cheese_rat")
	duel.fighters[0].meter = 100
	ticks(110,{"ultimate":true})
	check(duel.fighters[1].hp == 70,"King of the Cheese delivers thirty damage once")
	fresh("cheese_rat",200,1100)
	for i in 4:
		duel.fighters[0].attack_variant = "trap"
		duel._spawn_projectile(duel.fighters[0],duel.fighters[0].moves.special)
	check(duel.projectiles.size() == 3,"each fighter is limited to three active projectiles or traps")
	# Full normal-health CPU matches for every added profile.
	for id in ["poisonboy","chainveil","cheese_rat"]:
		game.solo = true
		game.selected.assign([0,index_of(id)])
		game.start_match()
		duel = game.match_node
		duel.set_physics_process(false)
		duel.ai.rng.seed = 1234
		for i in 24000:
			duel._physics_process(DT)
			if duel.phase == "complete": break
		check(duel.phase == "complete" and duel.wins[1] == 2,id+" CPU completes a full match at normal health")
	game.show_gallery()
	var sheets := {}
	for id in ["bullet","nachtelf","poisonboy"]:
		game.screen.show_fighter(index_of(id))
		var art: Texture2D = game.screen.art.texture
		check(art is AtlasTexture and art.resource_path.ends_with(id+"_sheet.tres"),id+" gallery uses its own named sheet resource")
		sheets[str(art.region)] = true
	check(sheets.size() == 3,"the three classic fighters have separate non-identical sheet regions")
	game.show_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	print("EXPANSION RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
