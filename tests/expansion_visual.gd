extends Node
var game: Control
var passed := 0
var failed := 0
const OUTPUT := "/tmp/inferno-v03-visual"

func check(value: bool, message: String) -> void:
	if value:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func index_of(id: String) -> int:
	for i in game.roster.size():
		if game.roster[i].id == id: return i
	return -1

func capture(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+name+".png")

func press(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	get_viewport().push_input(event)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	game.show_gallery()
	for id in ["bullet","nachtelf","poisonboy"]:
		game.screen.show_fighter(index_of(id))
		await capture("sheet-"+id)
		check(game.screen.art.texture.resource_path.ends_with(id+"_sheet.tres"),id+" own sheet rendered in gallery")
	# Exercise the real contextual intro button, video decoder, replay and Escape.
	for i in game.roster.size():
		var id: String = game.roster[i].id
		game.screen.show_fighter(i)
		game.screen.intro_button.pressed.emit()
		await get_tree().create_timer(0.4).timeout
		var player: FighterIntroPlayer = game.screen
		var texture := player.video.get_video_texture()
		check(game.route == "intro" and player.video.is_playing() and texture != null and texture.get_size() == Vector2(1280,720),id+" intro button decodes a real 720p video")
		await capture("intro-"+id)
		if i == 0:
			var position := player.video.stream_position
			player.replay()
			await get_tree().create_timer(0.1).timeout
			check(player.video.stream_position < position,"replay restarts the intro from its beginning")
			await get_tree().create_timer(3.45).timeout
			await capture("intro-camera-kick")
			await get_tree().create_timer(3).timeout
			check(player.status.text.contains("INTRO COMPLETE"),"intro reaches its finished end state")
		press(KEY_ESCAPE)
		await get_tree().process_frame
		check(game.route == "gallery" and game.screen.current == i,id+" Escape returns to the same selected fighter")
	game.show_select(false)
	game.screen.choose(0,index_of("poisonboy"))
	game.screen.choose(1,index_of("chainveil"))
	await capture("five-fighter-select")
	for id in ["poisonboy","chainveil","cheese_rat"]:
		game.show_select(false)
		game.screen.choose(0,index_of(id))
		game.screen.confirm(0)
		game.screen.confirm(1)
		check(game.route == "arena",id+" reaches arena through ready buttons")
		game.start_match()
		await get_tree().create_timer(3.15).timeout
		var duel: DuelMatch = game.match_node
		duel.fighters[0].position.x = 430
		duel.fighters[1].position.x = 650 if id == "chainveil" else 880
		press(KEY_H)
		await get_tree().create_timer(0.23).timeout
		check(duel.fighters[0].visual.sprite.texture != null,id+" combat sprite renders during special")
		await capture("combat-"+id)
	game.show_menu()
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	print("EXPANSION VISUAL RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
