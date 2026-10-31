extends Node
const OUTPUT := "/tmp/inferno-v16-gallery"
var game: Control
var passed := 0
var failed := 0
var seen_images := {}

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func click(button: Button) -> void:
	button.grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = down
		get_viewport().push_input(event)
	await get_tree().process_frame

func capture(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+name+".png")


func check_framing(gallery: FighterGallery, label: String) -> void:
	var size := Vector2(gallery.demo_viewport.size)
	var bounds := gallery.presentation.framed_rect
	check(Rect2(Vector2.ZERO,size).encloses(bounds),label+" complete 2D silhouette fits with margin")
	check(bounds.size.y >= size.y*.85 or bounds.size.x >= size.x*.85,label+" illustration fills at least 85% of one preview dimension")

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	game.show_gallery()
	for index in game.roster.size():
		var gallery: FighterGallery = game.screen
		var id: String = game.roster[index].id
		await click(gallery.fighter_buttons[index])
		check(gallery.current == index,id+" selects through its actual roster card")
		await get_tree().create_timer(.65).timeout
		var stage: FighterIllustration = gallery.presentation
		check(stage.texture.get_width() >= 1000 and gallery.demo_viewport.disable_3d,id+" uses the detailed 2D artwork")
		check(stage.figure.get_child_count() > 0 and stage.figure.get_child(0) is Polygon2D,id+" renders the supplied illustration as complete textured geometry")
		check_framing(gallery,id+" full body")
		var stage_id := stage.get_instance_id()
		var scale_before := stage.figure.scale
		await get_tree().create_timer(.1).timeout
		check(stage.finished and stage.figure.scale == scale_before,id+" rests without stretching or changing anatomy")
		await capture("full-"+id)
		var hash := gallery.demo_viewport.get_texture().get_image().get_data().hex_encode().sha256_text()
		check(not seen_images.has(hash),id+" has a distinct illustrated character")
		seen_images[hash] = true
		await click(gallery.portrait_button)
		check(stage.portrait,id+" portrait button shows the high-resolution close-up")
		check_framing(gallery,id+" portrait")
		await capture("portrait-"+id)
		await click(gallery.portrait_button)
		check(not stage.portrait,id+" full-body button restores the entire character")
		await click(gallery.sheet_button)
		check(gallery.art.visible and not gallery.preview.visible and not stage.is_processing(),id+" original sheet stays accessible")
		await click(gallery.sheet_button)
		check(gallery.preview.visible and stage.get_instance_id() == stage_id,id+" returns to the same 2D presentation")
		await click(gallery.replay_button)
		check(not stage.finished and stage.get_instance_id() == stage_id,id+" replay restarts the entrance")
	for size in [Vector2i(960,540),Vector2i(1920,1080)]:
		get_window().size = size
		await get_tree().create_timer(.2).timeout
		var gallery: FighterGallery = game.screen
		var expected := Vector2i((gallery.preview.size*gallery.preview.get_global_transform().get_scale()).round())
		check(gallery.demo_viewport.size == expected,"2D gallery follows native pixel density at "+str(size))
		check_framing(gallery,str(size))
		await capture("gallery-"+str(size.x)+"x"+str(size.y))
	game.show_menu()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(.5).timeout
	print("GALLERY VISUAL RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
