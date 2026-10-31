extends Node
const DT := 1.0 / 60.0
var passed := 0
var failed := 0
var game: Control

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ", message)
	else:
		failed += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	var all_moves := 0
	for index in game.roster.size():
		var profile: Dictionary = game.roster[index]
		game.show_select(false)
		game.screen.choose(0, index)
		game.screen.confirm(0)
		game.screen.confirm(1)
		check(game.route == "arena", profile.id + " can ready and enter versus")
		game.start_match()
		var duel: DuelMatch = game.match_node
		duel.set_physics_process(false)
		var hero := duel.fighters[0]
		var target := duel.fighters[1]
		check(hero.visual.sprite != null and not hero.visual.metadata.is_empty(), profile.id + " has an animated combat sprite")
		for id in hero.moves:
			# This suite verifies the original 69 single-input bindings on both
			# renderers. The twenty motion commands need history; tests/v12.gd
			# exercises their actual input sequences and damage for all fighters.
			if id.begins_with("v12_"): continue
			all_moves += 1
			duel.start_round(false)
			duel.phase = "fight"
			hero.position.x = 560
			target.position.x = 650
			hero.hp = 60
			hero.meter = 100
			var move: AttackData = hero.moves[id]
			var command := MoveCatalog.input_for(move)
			check(MoveCatalog.resolve(hero.moves, move.slot, command, 1) == id, profile.id + "/" + id + " has an unambiguous keyboard/touch binding")
			var armor_seen := false
			var power_seen := false
			var immunity_seen := false
			var trap_placed := false
			for tick in 150:
				var inputs: Array[Dictionary] = [command if tick == 0 else {}, {}]
				duel.advance_fight(DT, inputs)
				armor_seen = armor_seen or hero.armor_time > 0
				power_seen = power_seen or hero.empower_time > 0
				immunity_seen = immunity_seen or hero.immunity > 0
				if move.kind == "cheese_trap" and not trap_placed and not duel.projectiles.is_empty():
					target.position.x = duel.projectiles[0].position.x
					trap_placed = true
			check(target.hp == DuelFighter.MAX_HEALTH - move.damage, profile.id + "/" + id + " applies its exact damage once (including volleys)")
			check(hero.meter <= 100 - move.meter_cost + move.meter_gain * 3, profile.id + "/" + id + " respects its meter cost")
			if move.armor_time > 0: check(armor_seen, profile.id + "/" + id + " activates temporary armor")
			if move.empower_time > 0: check(power_seen, profile.id + "/" + id + " activates empowered attacks")
			if move.invulnerable_time > 0: check(immunity_seen, profile.id + "/" + id + " activates temporary invulnerability")
			if move.heal > 0: check(hero.hp == 60 + move.heal, profile.id + "/" + id + " restores its documented HP")
			if move.meter_cost > 0:
				hero.reset_at(560)
				check(not hero.begin_attack(id), profile.id + "/" + id + " refuses insufficient meter")
			await get_tree().process_frame
		# Every character's CPU has to finish a real normal-health match.
		game.show_select(true)
		game.selected.assign([0, index])
		game.solo = true
		game.start_match()
		duel = game.match_node
		duel.set_physics_process(false)
		duel.ai.rng.seed = 9281 + index
		for tick in 24000:
			duel._physics_process(DT)
			if duel.phase == "complete": break
		check(duel.phase == "complete" and duel.wins[1] == 2, profile.id + " CPU wins a full normal-health match against a passive player")
		await get_tree().process_frame
	check(all_moves == 69, "all 69 defined attacks and abilities were exercised")
	# Test defensive semantics separately from catalogue activation.
	game.selected.assign([7, 0])
	game.start_match()
	var duel: DuelMatch = game.match_node
	duel.set_physics_process(false)
	var hero := duel.fighters[0]
	hero.armor_time = 2.0
	hero.receive_hit(DuelFighter.ATTACKS.heavy, 900)
	check(hero.hp == DuelFighter.MAX_HEALTH - 6, "Lava Stone armor halves an incoming 12-damage heavy")
	hero.reset_at(400)
	hero.immunity = 1.0
	hero.receive_hit(DuelFighter.ATTACKS.ultimate, 900)
	check(hero.hp == DuelFighter.MAX_HEALTH, "temporary invulnerability prevents damage")
	hero.immunity = 0
	hero.empower_time = 2.0
	hero.begin_attack("light")
	check(hero.attack.damage == 8 and hero.moves.light.damage == 6, "empower modifies this attack without mutating base resources")
	# A jump pressed just before landing is buffered; an ordinary second jump is not.
	hero.reset_at(400)
	hero.position.y = DuelFighter.FLOOR - 8
	hero.velocity.y = 300
	hero.step(DT, {"jump": true}, duel.fighters[1])
	hero.step(DT, {}, duel.fighters[1])
	hero.step(DT, {}, duel.fighters[1])
	check(hero.velocity.y < 0, "landing buffer executes a jump pressed just before touchdown")
	hero.reset_at(400)
	hero.step(DT, {"axis": 1}, duel.fighters[1])
	var first_speed := hero.velocity.x
	for tick in 8: hero.step(DT, {"axis": 1}, duel.fighters[1])
	check(first_speed > 0 and first_speed < hero.velocity.x, "locomotion responds immediately and accelerates smoothly")
	game.selected.assign([6, 0])
	game.start_match()
	duel = game.match_node
	duel.set_physics_process(false)
	duel.phase = "fight"
	duel.fighters[0].position.x = 560
	duel.fighters[1].position = Vector2(650, DuelFighter.FLOOR-170)
	for tick in 15:
		var inputs: Array[Dictionary] = [{"light": true, "block": true} if tick == 0 else {}, {}]
		duel.advance_fight(DT, inputs)
	check(duel.fighters[1].hp == DuelFighter.MAX_HEALTH, "jumping over Low Cheese Swipe evades its genuine low hitbox")
	game.selected.assign([9, 0])
	game.start_match()
	duel = game.match_node
	duel.set_physics_process(false)
	hero = duel.fighters[0]
	hero.hp = DuelFighter.MAX_HEALTH - 2
	hero.meter = 100
	hero.begin_attack("rebirth")
	for tick in 25: hero.step(DT, {}, duel.fighters[1])
	check(hero.hp == DuelFighter.MAX_HEALTH and hero.meter == 65, "Rebirth caps healing at maximum health and spends 35 meter")
	hero.reset_at(400)
	hero.stun = .4
	hero.meter = 100
	hero.step(DT, {"axis": -1, "special": true}, duel.fighters[1])
	check(hero.attack != null and hero.attack.id == "rebirth" and hero.stun == 0 and hero.immunity > 0 and hero.meter == 65, "Rebirth genuinely escapes hitstun through the normal back-special input")
	hero.reset_at(400)
	hero.hp = 0
	hero.meter = 100
	check(not hero.begin_attack("eternal_flame"), "Eternal Flame cannot revive an already defeated fighter")
	game.show_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	print("ROSTER RESULT: %d passed, %d failed" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)
