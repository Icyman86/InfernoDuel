extends Node
var passed := 0
var failed := 0
var root_path := "/tmp/inferno-v16"

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(root_path)
	Progression.save_path = root_path+"/wallet-"+Progression.match_id()+".cfg"
	Progression.load_progress()
	check(Progression.coins == 0 and not Progression.available("bamboo_blade") and not Progression.available("sawtina"),"fresh installation has zero coins and both new fighters locked")
	check(Progression.owned_indices() == [0,1,2,3,4,5,6,7,8,9],"existing ten fighters stay available")
	check(Progression.award_match("unfinished",[1,0],0) == 0 and Progression.award_match("draw",[2,2],0) == 0,"incomplete matches and draws give no coins")
	for i in 39: check(Progression.award_match("win-"+str(i),[2,1],0) == 5,"completed win earns exactly five coins")
	for i in 4: check(Progression.award_match("loss-"+str(i),[0,2],0) == 1,"completed loss earns exactly one coin")
	check(Progression.coins == 199 and not Progression.purchase("bamboo_blade") and Progression.coins == 199,"199 coins cannot buy a 200-coin fighter and balance is unchanged")
	check(Progression.award_match("last-loss",[1,2],0) == 1 and Progression.purchase("bamboo_blade"),"exactly 200 coins unlock Bamboo Blade")
	check(Progression.coins == 0 and Progression.available("bamboo_blade") and not Progression.available("sawtina"),"each fighter costs 200 independently")
	check(not Progression.purchase("bamboo_blade") and Progression.coins == 0,"buying an owned fighter cannot charge twice")
	Progression.load_progress()
	check(Progression.coins == 0 and Progression.available("bamboo_blade"),"wallet and unlock survive reload from disk")
	check(Progression.award_match("win-0",[2,1],0) == 0 and Progression.coins == 0,"duplicate match remains unpaid after reload")
	for i in 40: Progression.award_match("second-"+str(i),[0,2],1)
	check(Progression.coins == 200,"remote P2 winner earns five per match on their own device")
	var game: Control = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	game.show_select(true)
	var picker: CharacterSelect = game.screen
	check(picker.cards.size() == 12,"all twelve fighters are visible in the picker")
	for card in picker.cards:
		check(Rect2(0,0,1280,720).encloses(Rect2(card.position,card.size)),"fighter card fits the logical phone menu")
	picker.choose(0,11)
	check(picker.ready_buttons[0].text.contains("200"),"locked selection shows its 200 coin unlock action")
	picker.ready_buttons[0].pressed.emit()
	check(Progression.available("sawtina") and Progression.coins == 0 and not picker.ready_players[0],"real unlock button spends 200 and waits for ready")
	picker.confirm(0)
	picker.confirm(1)
	check(game.route == "arena","purchased fighter can enter arena selection")
	game.start_match()
	game.match_node.set_physics_process(false)
	check(game.match_node.fighters[0].profile.id == "sawtina","unlocked Sawtina enters actual combat")
	var final_score: Array[int] = [2,0]
	game.show_result(final_score)
	game.show_result(final_score)
	check(Progression.coins == 5 and game.reward_amount == 5,"result refresh cannot pay twice")
	game.start_match()
	game.show_menu()
	check(Progression.coins == 5,"abandoning or restarting a fight gives no coins")
	game.show_gallery()
	game.screen.show_fighter(10)
	check(game.screen.buy_button.disabled and game.screen.buy_button.text.contains("UNLOCKED"),"gallery shows persisted ownership")
	game.screen.show_fighter(11)
	check(game.screen.presentation is FighterIllustration and game.screen.presentation.texture.get_width() >= 1000,"Sawtina gallery uses high-resolution 2D character art")
	for index in [10,11]:
		var profile: Dictionary = game.roster[index]
		var visual := FighterVisual.new()
		visual.profile = profile
		add_child(visual)
		var keys := {}
		for state in visual.metadata.animations:
			visual.preview_pose = state
			for progress in [0.0,.35,.5,.9]:
				visual.preview_progress = progress
				visual._update_pose()
				check(visual.sprite.texture != null and Geometry2D.triangulate_polygon(visual.sprite.polygon).size() > 0,profile.id+" renders intact "+state+" animation")
				keys[visual.last_key] = true
		check(keys.size() >= 18,profile.id+" uses distinct actual drawings across motion and attacks")
		visual.queue_free()
	for index in [10,11]:
		game.selected.assign([index,0])
		game.start_match()
		var duel: DuelMatch = game.match_node
		duel.set_physics_process(false)
		for facing in [1,-1]:
			duel.start_round(false)
			duel.phase = "fight"
			duel.fighters[0].position.x = 450 if facing == 1 else 536
			duel.fighters[1].position.x = 536 if facing == 1 else 450
			for tick in 150:
				duel.advance_fight(1.0/60.0,[{"special":true} if tick == 0 else {},{}])
			check(duel.fighters[1].hp == DuelFighter.MAX_HEALTH-16,game.roster[index].id+" full projectile damage connects at point-blank range in either direction")
	var addresses := SessionDiscovery.wifi_destinations(PackedStringArray(["192.168.4.17"]))
	check("192.168.4.1" in addresses and "192.168.4.254" in addresses and "192.168.4.17" not in addresses,"unicast room search reaches both ends of a Wi-Fi subnet")
	Progression.load_progress()
	check(Progression.available("bamboo_blade") and Progression.available("sawtina") and Progression.coins == 5,"both paid unlocks and final balance survive a fresh load")
	# Interrupted final rename recovers the retained previous committed save.
	var active := ProjectSettings.globalize_path(Progression.save_path)
	DirAccess.rename_absolute(active,active+".bak")
	Progression.load_progress()
	check(Progression.coins == 5 and Progression.available("sawtina"),"save recovery works if the app stopped between atomic file renames")
	game.show_menu()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(.5).timeout
	print("V16 PROGRESSION RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
