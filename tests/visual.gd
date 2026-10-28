extends Node
var game: Control
var problems: Array[String] = []
var screenshots := "/tmp/inferno-visual"

func capture(label: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(screenshots+"/"+label+".png")
	print("CAPTURE ",label)

func check(value: bool, message: String) -> void:
	if value: print("PASS ",message)
	else:
		problems.append(message)
		push_error(message)

func press(code: int, down := true) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	get_viewport().push_input(event)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(screenshots)
	game = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	await capture("01-menu")
	press(KEY_F)
	await capture("02-select")
	check(game.route == "select","keyboard opens local versus")
	press(KEY_F,false)
	press(KEY_F)
	press(KEY_I)
	await capture("03-arena")
	check(game.route == "arena","native input flow confirms both players")
	press(KEY_ENTER)
	await get_tree().create_timer(3.2).timeout
	var duel: DuelMatch = game.match_node
	press(KEY_D)
	press(KEY_LEFT)
	await get_tree().create_timer(0.65).timeout
	press(KEY_D,false)
	press(KEY_LEFT,false)
	check(duel.fighters[0].position.x > 500 and duel.fighters[1].position.x < 780,"both input streams move fighters in rendered match")
	press(KEY_F,false)
	press(KEY_I,false)
	press(KEY_F)
	press(KEY_I)
	await get_tree().create_timer(0.2).timeout
	await capture("04-fight")
	check(duel.fighters[0].hp < 100 and duel.fighters[1].hp < 100,"simultaneous attacks trade in real physics loop")
	press(KEY_ESCAPE)
	await capture("05-pause")
	var t := duel.remaining
	await get_tree().create_timer(0.15).timeout
	check(duel.remaining == t,"rendered pause holds timer")
	game.show_options("pause")
	await capture("06-options")
	check(get_viewport().gui_get_focus_owner() != null,"options has keyboard focus")
	Settings.fullscreen = true
	Settings.apply()
	await get_tree().create_timer(0.15).timeout
	check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,"fullscreen applies")
	Settings.fullscreen = false
	Settings.apply()
	game.show_gallery()
	await capture("07-gallery")
	check(get_viewport().gui_get_focus_owner() != null,"gallery has keyboard focus")
	game.show_menu()
	DisplayServer.window_set_size(Vector2i(960,540))
	await get_tree().create_timer(0.15).timeout
	await capture("08-resized")
	check(DisplayServer.window_get_size() == Vector2i(960,540) and game.size == Vector2(1280,720),"resize retains 16:9 logical interface at smaller window size")
	DisplayServer.window_set_size(Vector2i(1280,720))
	Settings.reset()
	print("VISUAL RESULT: ",problems.size()," failed")
	get_tree().quit(0 if problems.is_empty() else 1)
