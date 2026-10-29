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
		check(gallery.current == index,game.roster[index].id+" is selectable through its actual roster card")
		await get_tree().create_timer(.95).timeout
		check(gallery.presentation.face.mesh != null and gallery.presentation.edge.mesh != null and gallery.demo_viewport.find_world_3d() != null,game.roster[index].id+" has a textured extruded silhouette in a real perspective 3D world")
		check(gallery.presentation.visual.preview_pose == "heavy" and gallery.preview.visible,game.roster[index].id+" performs one signature move on entry")
		var framed := true
		var bounds := gallery.presentation.face.mesh.get_aabb()
		for corner in 8:
			var world := gallery.presentation.face.global_transform*bounds.get_endpoint(corner)
			framed = framed and Rect2(Vector2.ZERO,Vector2(gallery.demo_viewport.size)).has_point(gallery.presentation.camera.unproject_position(world))
		check(framed,game.roster[index].id+" full signature silhouette remains inside the camera frame")
		var stage_id := gallery.presentation.get_instance_id()
		var ring_id := gallery.presentation.rings[0].get_instance_id()
		var world_id := gallery.demo_viewport.find_world_3d().get_instance_id()
		await capture("presentation-"+game.roster[index].id)
		await get_tree().create_timer(2.0).timeout
		check(gallery.preview.visible and gallery.presentation.finished and gallery.presentation.is_processing() and gallery.presentation.get_instance_id() == stage_id and gallery.presentation.rings[0].get_instance_id() == ring_id and gallery.demo_viewport.find_world_3d().get_instance_id() == world_id,game.roster[index].id+" keeps the same live 3D world, character and rings after the signature move")
		var foot := gallery.presentation.rig.position
		var scale_before := gallery.presentation.rig.scale.y
		await get_tree().create_timer(.16).timeout
		check(gallery.presentation.rig.position == foot and gallery.presentation.rig.scale.y != scale_before,game.roster[index].id+" breathes on the existing ring without moving its feet")
		await capture("idle-"+game.roster[index].id)
		await click(gallery.sheet_button)
		check(gallery.art.visible and not gallery.preview.visible and not gallery.presentation.is_processing(),game.roster[index].id+" original reference sheet remains separately accessible")
		await click(gallery.sheet_button)
		check(gallery.preview.visible and not gallery.art.visible and gallery.presentation.rings[0].get_instance_id() == ring_id,game.roster[index].id+" returns from the sheet to the same persistent podium")
		await click(gallery.replay_button)
		check(gallery.preview.visible and not gallery.presentation.finished and gallery.presentation.rings[0].get_instance_id() == ring_id,game.roster[index].id+" presentation replay restarts the entrance")
	var gallery: FighterGallery = game.screen
	check(gallery.get("move_buttons") == null and gallery.get("showcase") == null,"old automatic movement tour and executable move list are removed from Fighters")
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
