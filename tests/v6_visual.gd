extends Node
const OUTPUT := "/tmp/inferno-v6-visual"
var passed := 0
var failed := 0
var game: Control

func check(ok: bool, text: String) -> void:
	if ok:
		passed += 1
		print("PASS ",text)
	else:
		failed += 1
		push_error(text)

func capture(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+name+".png")

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1280,800),Vector2i(1024,768),Vector2i(2400,1080)]:
		get_window().size = size
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		print("RESOLUTION OBSERVED requested=",size," framebuffer=",image.get_size()," viewport=",get_viewport().get_visible_rect().size," root=",game.size," window=",get_window().size," scale=",get_window().content_scale_size," mode=",get_window().content_scale_mode)
		check(image.get_size() == size and get_viewport().get_visible_rect().size == Vector2(size) and game.size == Vector2(size),"actual framebuffer, viewport and UI root follow %s native pixels" % size)
		var bounds := Rect2(game.stage.position,Vector2(1280,720)*game.stage.scale)
		check(TouchControls.safe_rect(get_viewport()).encloses(bounds),"logical arena stays correctly proportioned inside %s" % size)
		if size == Vector2i(2400,1080): image.save_png(OUTPUT+"/wide-phone-native.png")
	get_window().size = Vector2i(1280,720)
	await get_tree().process_frame
	game.show_online()
	await capture("session-code-screen")
	check(game.screen is OnlineLobby,"Android session-code screen renders")
	game.show_options("menu")
	await capture("native-resolution-options")
	check(game.screen.resolution_label.text.contains("1280 × 720"),"options display real surface dimensions")
	get_window().size = Vector2i(1440,900)
	await get_tree().process_frame
	await get_tree().process_frame
	check(game.screen.resolution_label.text.contains("1440 × 900"),"resolution readout refreshes after device/window size changes")
	game.show_select(false)
	check(game.route == "online","Android local-versus route is replaced by session connect")
	game.show_select(true)
	check(game.route == "select" and game.solo,"Android solo remains playable independently of networking")
	game.screen.confirm(0)
	game.screen.confirm(1)
	game.start_match()
	await get_tree().create_timer(.2).timeout
	check(game.touch_controls.solo and game.touch_controls.buttons.size() == 7 and game.touch_controls.sticks.size() == 1,"Android fight renders one thumbstick and seven circular buttons instead of shared controls")
	await capture("single-pad-native-fight")
	game.show_menu()
	get_window().size = Vector2i(1280,720)
	await get_tree().process_frame
	game.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(.7).timeout
	print("V6 VISUAL RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
