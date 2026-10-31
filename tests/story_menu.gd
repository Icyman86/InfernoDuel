extends Node
const OUTPUT := "/tmp/inferno-v17"
var game: Control
var passed := 0
var failed := 0

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func button(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found := button(child,text)
		if found: return found
	return null

func count_buttons(node: Node, text: String) -> int:
	var count := 1 if node is Button and node.text == text else 0
	for child in node.get_children(): count += count_buttons(child,text)
	return count

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+name+".png")

func finish_match(winner: int) -> void:
	var duel: DuelMatch = game.match_node
	duel.set_physics_process(false)
	for round_index in 2:
		duel.phase = "fight"
		duel.fighters[1-winner].hp = 0
		duel.finish_round()
		duel._physics_process(2.1)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	Progression.save_path = OUTPUT+"/migration-"+Progression.match_id()+".cfg"
	var legacy := ConfigFile.new()
	legacy.set_value("progress","version",1)
	legacy.set_value("progress","coins",137)
	legacy.set_value("progress","unlocked",["bamboo_blade"])
	legacy.set_value("progress","rewarded",["old-paid-match"])
	legacy.save(Progression.save_path)
	Progression.load_progress()
	check(Progression.coins == 137 and Progression.available("bamboo_blade") and Progression.story_completed == 0,"V16 save migrates without losing coins or purchased fighters")
	check(not Progression.complete_story_level(3),"unbeaten story levels cannot be skipped through progression API")
	game = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	seed(1741)
	var pairs := {}
	var fighters := {}
	for i in 24:
		var previous: Array = game.menu_pair.duplicate()
		game.show_menu()
		check(game.menu_pair[0] != game.menu_pair[1] and game.menu_pair != previous,"menu draws two different random fighters and changes its last pairing")
		var bounds: Array[Rect2] = []
		for side in 2:
			var hero: FighterIllustration = game.menu_previews[side]
			check(hero.texture != null and not hero.fallback_used and hero.facing == (1 if side == 0 else -1),"menu uses complete textured artwork facing the opposite fighter")
			bounds.append(Rect2(hero.position+hero.framed_rect.position,hero.framed_rect.size))
			fighters[hero.profile.id] = true
		check(not bounds[0].intersects(bounds[1]) and bounds[0].position.x > 610 and Rect2(0,0,1280,720).encloses(bounds[1]),"menu fighters do not overlap each other or the buttons")
		pairs[str(game.menu_pair)] = true
		await get_tree().process_frame
	check(pairs.size() > 12 and fighters.size() > 8,"menu randomizes across the roster")
	await get_tree().create_timer(.7).timeout
	await capture("random-menu")
	button(game.screen,"STORY MODE").pressed.emit()
	check(game.route == "story" and game.screen.cards.size() == 4,"story menu opens four level cards")
	check(not game.screen.cards[0].disabled and game.screen.cards[1].disabled and game.screen.cards[3].disabled,"new campaign starts with Bullet and locks later levels")
	game.screen.cards[3].pressed.emit()
	check(game.route == "story","locked card cannot bypass story gating")
	await capture("story-level-select")
	game.screen.cards[0].pressed.emit()
	check(game.route == "story_briefing" and game.story_index == 0,"first card opens Bullet's story briefing")
	await get_tree().create_timer(.7).timeout
	await capture("story-briefing-1")
	button(game.screen,"BEGIN DUEL").pressed.emit()
	check(game.story_mode and game.match_node.solo and not game.match_node.modern_rules,"story starts a native solo duel with touch support")
	finish_match(1)
	check(game.route == "result" and Progression.story_completed == 0 and Progression.coins == 138,"losing grants one coin and does not unlock the next level")
	check(count_buttons(game.overlay,"MAIN MENU") == 1,"story defeat has one main-menu action")
	button(game.overlay,"RETRY LEVEL").pressed.emit()
	check(game.story_index == 0 and game.match_node.wins == [0,0],"retry restarts the same level with fresh rounds")
	game.match_node.set_physics_process(false)
	game.show_pause()
	check(game.route == "pause" and game.story_mode,"story supports the real pause flow")
	game.resume_match()
	game.match_node.set_physics_process(false)
	var enemies := ["bullet","nachtelf","spinegrin","crystal_fang"]
	var arenas := ["citadel","nightelf_forest","living_ship","crystal_mine"]
	for index in 4:
		var duel: DuelMatch = game.match_node
		duel.set_physics_process(false)
		check(duel.profiles[0].id == "sharkbyte" and duel.profiles[1].id == enemies[index],"level %d uses SharkByte against the requested opponent" % (index+1))
		check(game.arena_choice == arenas[index] and game.backdrop.arena_id == arenas[index],"level %d loads its requested arena" % (index+1))
		duel.phase = "fight"
		duel.announcement.text = ""
		duel.update_hud()
		await capture("story-level-"+str(index+1))
		var before := Progression.coins
		finish_match(0)
		check(Progression.story_completed == index+1 and Progression.coins == before+5,"winning level %d saves progress and grants five coins" % (index+1))
		check(count_buttons(game.overlay,"MAIN MENU") == 1,"story victory has one main-menu action")
		var score: Array[int] = [2,0]
		game.show_result(score)
		check(Progression.coins == before+5 and Progression.story_completed == index+1,"reopening results cannot duplicate coins or skip another level")
		Progression.load_progress()
		check(Progression.story_completed == index+1 and Progression.available("bamboo_blade"),"story checkpoint and previous purchase survive reload")
		await capture("story-result-"+str(index+1))
		if index < 3:
			button(game.overlay,"NEXT LEVEL").pressed.emit()
			check(game.route == "story_briefing" and game.story_index == index+1,"next level presents its own story briefing")
			button(game.screen,"BEGIN DUEL").pressed.emit()
	check(button(game.overlay,"NEXT LEVEL") == null and button(game.overlay,"LEVEL SELECT") != null,"fourth victory finishes the chapter without a nonexistent fifth level")
	button(game.overlay,"LEVEL SELECT").pressed.emit()
	check(game.route == "story" and game.screen.cards.all(func(card): return not card.disabled),"completed campaign permits replaying all four levels")
	await capture("story-chapter-complete")
	game.screen.cards[0].pressed.emit()
	button(game.screen,"BEGIN DUEL").pressed.emit()
	finish_match(0)
	check(Progression.story_completed == 4,"replaying an earlier level cannot reduce completed progress")
	game.show_menu()
	check(not game.story_mode and Progression.coins == 163,"returning to menu exits story cleanly and preserves earned coins")
	game.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(.5).timeout
	print("V17 STORY MENU RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
