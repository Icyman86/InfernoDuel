extends Node
const OUTPUT := "/tmp/inferno-v13-gallery"
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

func meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: output.append(node)
	for child in node.get_children(): meshes(child,output)

func projected_bounds(presentation: FighterPresentation, size: Vector2) -> Rect2:
	var rect := Rect2()
	for i in 8:
		var point := presentation.rig.global_transform*presentation.model_bounds.get_endpoint(i)
		var pixel := presentation.camera.unproject_position(point)
		if i == 0: rect = Rect2(pixel,Vector2.ZERO)
		else: rect = rect.expand(pixel)
	return rect

func check_framing(gallery: FighterGallery, label: String) -> void:
	var size := Vector2(gallery.demo_viewport.size)
	var bounds := projected_bounds(gallery.presentation,size)
	var safe := Rect2(size*.025,size*.95)
	check(safe.encloses(bounds),label+" full mesh envelope including feet, hair, wings and tail fits with margin")
	check(bounds.size.y >= size.y*.72,label+" character occupies at least 72% of viewport height")

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
		check(gallery.current == index,id+" selects through its real roster card")
		await get_tree().create_timer(.3).timeout
		var stage := gallery.presentation
		var model_meshes: Array[MeshInstance3D] = []
		meshes(stage.model,model_meshes)
		var actual_triangles := 0
		var surfaces := 0
		var normal_maps := 0
		var skinned := true
		for node in model_meshes:
			skinned = skinned and node.skin != null
			for surface in node.mesh.get_surface_count():
				surfaces += 1
				actual_triangles += node.mesh.surface_get_array_index_len(surface)/3
				var material := node.get_active_material(surface) as StandardMaterial3D
				if material and material.normal_enabled and material.normal_texture: normal_maps += 1
		check(actual_triangles >= 30000 and skinned,id+" has an actual detailed, skinned volume mesh ("+str(actual_triangles)+" triangles)")
		check(stage.skeleton != null and stage.skeleton.get_bone_count() >= 16,id+" has a real imported skeleton")
		check(surfaces >= 8 and normal_maps >= 3,id+" renders separate physical materials and normal maps")
		check_framing(gallery,id+" entrance")
		var stage_id := stage.get_instance_id()
		var ring_id := stage.rings[0].get_instance_id()
		await get_tree().create_timer(1.2).timeout
		check(stage.finished and gallery.preview.visible and stage.get_instance_id() == stage_id,id+" retains the same live 3D model after entrance")
		var spine := stage.skeleton.find_bone("spine")
		var pose := stage.skeleton.get_bone_pose_rotation(spine)
		var foot := stage.rig.position
		await get_tree().create_timer(.23).timeout
		check(stage.skeleton.get_bone_pose_rotation(spine) != pose and stage.rig.position == foot and stage.rig.scale == Vector3.ONE,id+" breathes through the skeleton without stretching the model or sliding feet")
		check_framing(gallery,id+" idle")
		await capture("full-"+id)
		var image := gallery.demo_viewport.get_texture().get_image()
		var hash := image.get_data().hex_encode().sha256_text()
		check(not seen_images.has(hash),id+" has a distinct rendered 3D character")
		seen_images[hash] = true
		# Test quarter, side and rear views against the same adaptive camera.
		for angle in [PI*.5,PI]:
			stage.yaw = angle
			stage.frame_camera()
			check_framing(gallery,id+" rotated "+str(int(rad_to_deg(angle))))
		stage.yaw = .4
		stage.frame_camera()
		await click(gallery.turn_buttons[1])
		check(stage.yaw > .8,id+" TURN RIGHT rotates the actual model view")
		await click(gallery.turn_buttons[0])
		check(is_equal_approx(stage.yaw,.4),id+" TURN LEFT returns to the original angle")
		var center := gallery.preview.get_global_rect().get_center()
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = center
		get_viewport().push_input(press)
		var motion := InputEventMouseMotion.new()
		motion.position = center+Vector2(40,0)
		motion.relative = Vector2(40,0)
		get_viewport().push_input(motion)
		press.pressed = false
		get_viewport().push_input(press)
		check(stage.yaw < .3,id+" dragging inside the viewport rotates the character")
		stage.yaw = .4
		stage.frame_camera()
		await click(gallery.portrait_button)
		check(stage.portrait and stage.camera.position.distance_to(stage.target) < stage.camera_distance+0.01,id+" portrait button switches to the actual 3D close view")
		await capture("portrait-"+id)
		await click(gallery.portrait_button)
		check(not stage.portrait,id+" full-body button restores complete framing")
		check_framing(gallery,id+" restored")
		await click(gallery.sheet_button)
		check(gallery.art.visible and not gallery.preview.visible and not stage.is_processing() and not stage.animator.active,id+" original sheet remains accessible and pauses the 3D animation")
		await click(gallery.sheet_button)
		check(gallery.preview.visible and stage.animator.active and stage.rings[0].get_instance_id() == ring_id,id+" returns to the same live model and podium")
		await click(gallery.replay_button)
		check(not stage.finished and stage.get_instance_id() == stage_id,id+" replay restarts the real model presentation")
	# Native stage scaling keeps the character sharp and large at smaller windows.
	get_window().size = Vector2i(960,540)
	await get_tree().create_timer(.2).timeout
	var gallery: FighterGallery = game.screen
	var expected := Vector2i((gallery.preview.size*gallery.preview.get_global_transform().get_scale()).round())
	check(gallery.demo_viewport.size == expected,"gallery renders at actual native pixel density after resize")
	check_framing(gallery,"960x540")
	await capture("gallery-960x540")
	get_window().size = Vector2i(1920,1080)
	await get_tree().create_timer(.2).timeout
	expected = Vector2i((gallery.preview.size*gallery.preview.get_global_transform().get_scale()).round())
	check(gallery.demo_viewport.size == expected,"gallery increases its 3D framebuffer for a larger native window")
	check_framing(gallery,"1920x1080")
	await capture("gallery-1920x1080")
	get_window().size = Vector2i(1280,720)
	game.show_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(.8).timeout
	print("GALLERY VISUAL RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(1 if failed else 0)
