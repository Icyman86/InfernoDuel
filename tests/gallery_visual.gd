extends Node
const OUTPUT := "/tmp/inferno-roster-visual"
var game: Control
var passed := 0
var failed := 0

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ", message)
	else:
		failed += 1
		push_error(message)

func click(button: Button) -> void:
	button.grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = down
		get_viewport().push_input(event)
	await get_tree().process_frame

func capture(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT + "/" + name + ".png")

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	game.show_gallery()
	for index in game.roster.size():
		var gallery: FighterGallery = game.screen
		await click(gallery.fighter_buttons[index])
		check(gallery.current == index, game.roster[index].id + " is selectable through its actual gallery button")
		var hero := gallery.showcase.fighters[0]
		check(hero.visual.sprite.texture != null and gallery.preview.visible, game.roster[index].id + " has a rendered animated preview")
		check(gallery.move_buttons.size() == hero.moves.size()+4, game.roster[index].id + " lists every attack and movement")
		await click(gallery.move_buttons.heavy)
		await get_tree().create_timer(0.23).timeout
		check(gallery.showcase.current_move == "heavy" and not gallery.showcase.autoplay, game.roster[index].id + " actual move button performs heavy and takes manual control")
		await capture("gallery-" + game.roster[index].id)
		# Ultimate is below the fold: native focus scrolling must make it clickable.
		await click(gallery.move_buttons.ultimate)
		await get_tree().create_timer(0.4).timeout
		check(gallery.showcase.current_move == "ultimate" and gallery.showcase.fighters[0].meter == 0, game.roster[index].id + " scrolled ultimate button executes the real meter-consuming move")
		await capture("ultimate-" + game.roster[index].id)
		await click(gallery.auto_button)
		check(gallery.showcase.autoplay, game.roster[index].id + " auto tour can resume after manual moves")
		await click(gallery.sheet_button)
		check(gallery.art.visible and not gallery.preview.visible and gallery.showcase.stopped, game.roster[index].id + " original sheet remains available and pauses preview")
		await click(gallery.sheet_button)
		check(gallery.preview.visible and not gallery.showcase.stopped, game.roster[index].id + " returns from original sheet to live moves")
	# Verify the auto tour actually advances; a toggled label is not enough.
	var gallery: FighterGallery = game.screen
	gallery.showcase.play_move("idle", false)
	gallery.showcase.elapsed = gallery.showcase.demo_duration
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(gallery.showcase.current_move == "walk", "automatic demonstration advances to the next move")
	gallery.perform_move("walk")
	await get_tree().create_timer(.22).timeout
	var view := gallery.showcase.fighters[0].visual
	var key := view.frame_number
	await get_tree().create_timer(.15).timeout
	check(view.frame_number != key, "walking preview advances authored gait frames")
	check(view.material_fx.get_shader_parameter("pose_alpha") > 0, "pose blending leaves the current sprite visible")
	# Mobile/touch UI stays usable after the roster/gallery expansion.
	game.touch_mode = true
	game.show_select(true)
	game.screen.choose(0,8)
	game.screen.confirm(0)
	game.screen.confirm(1)
	game.start_match()
	await get_tree().create_timer(.2).timeout
	game.match_node.phase = "fight"
	game.match_node.phase_time = 0.0
	await capture("crystal-fang-match")
	check(game.match_node.fighters[0].visual.sprite.texture != null, "new roster fighter also renders in actual combat")
	game.show_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(.8).timeout
	print("GALLERY VISUAL RESULT: %d passed, %d failed" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)
