extends Node
var game: Control
var pad: TouchControls
var passed := 0
var failed := 0

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ", message)
	else:
		failed += 1
		push_error(message)

func contact(id: int, action: String, down := true, player := 0, canceled := false) -> void:
	var point := Vector2.ZERO
	for b in pad.buttons:
		if b.player == player and b.action == action: point = b.rect.get_center()
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = pad.get_global_transform_with_canvas() * point
	event.pressed = down
	event.canceled = canceled
	get_viewport().push_input(event)

func click(button: Button) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = down
		get_viewport().push_input(event)

func find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found := find_button(child, text)
		if found: return found
	return null

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	pad = game.touch_controls
	await get_tree().process_frame
	check(not pad.visible, "combat touchpad stays hidden in menus")
	check(not get_tree().quit_on_go_back, "Android back is routed through game navigation instead of quitting")
	click(find_button(game.screen, "PLAY · TOUCH VS CPU"))
	await get_tree().process_frame
	check(game.route == "select" and game.solo, "phone play button opens solo selection")
	click(game.screen.cards[0])
	click(game.screen.ready_buttons[0])
	click(game.screen.ready_buttons[1])
	await get_tree().process_frame
	check(game.route == "arena", "touch-friendly ready buttons confirm both fighters")
	click(find_button(game.screen, "ENTER THE ARENA"))
	await get_tree().process_frame
	check(game.route == "fight" and pad.visible, "arena button starts fight with touchpad")
	game.match_node.set_physics_process(false)
	game.match_node.phase = "fight"
	InputRouter.clear()
	contact(0, "move_right")
	contact(1, "light")
	var state: Dictionary = InputRouter.sample(0)
	check(state.axis == 1 and state.light, "two fingers move and attack simultaneously")
	check(not InputRouter.sample(0).light, "held attack produces a single press edge")
	var before: float = game.match_node.fighters[0].position.x
	# A light attack intentionally plants the fighter's feet; test walking alone.
	var inputs: Array[Dictionary] = [InputRouter.sample(0), {}]
	game.match_node.advance_fight(1.0 / 60.0, inputs)
	check(game.match_node.fighters[0].position.x > before, "touch input moves the actual fighter")
	game.match_node.fighters[0].position.x = 560
	game.match_node.fighters[1].position.x = 650
	contact(1, "light", false)
	contact(1, "light")
	for tick in 25:
		inputs = [InputRouter.sample(0), {}]
		game.match_node.advance_fight(1.0 / 60.0, inputs)
	check(game.match_node.fighters[1].hp == 94, "touch light attack damages the opponent exactly once")
	contact(2, "move_right")
	contact(0, "move_right", false)
	check(InputRouter.sample(0).axis == 1, "releasing one of two fingers on a button keeps it held")
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = Vector2(640, 350)
	get_viewport().push_input(drag)
	check(InputRouter.sample(0).axis == 0, "dragging outside releases movement")
	contact(3, "move_left")
	contact(3, "move_left", false, 0, true)
	check(InputRouter.sample(0).axis == 0, "Android canceled touches release movement")
	contact(4, "block")
	contact(5, "special")
	state = InputRouter.sample(0)
	check(state.block and state.special, "guard and special support independent contacts")
	contact(6, "jump")
	contact(7, "heavy")
	contact(8, "ultimate")
	state = InputRouter.sample(0)
	check(state.jump and state.heavy and state.ultimate, "jump, heavy and ultimate are routed")
	InputRouter.held[0].move_left = true
	pad.release_all()
	check(InputRouter.sample(0).axis == -1, "touch release does not clear a held keyboard key")
	InputRouter.clear()
	contact(0, "move_right")
	contact(1, "pause")
	await get_tree().process_frame
	check(game.route == "pause" and not pad.visible, "touch pause opens a usable pause menu")
	check(InputRouter.sample(0).axis == 0, "pausing clears held touch input")
	click(find_button(game.overlay, "OPTIONS"))
	await get_tree().process_frame
	check(game.route == "options" and not find_button(game.overlay, "NATIVE WINDOW · FIT SCREEN"), "mobile options replace desktop-only window buttons")
	click(find_button(game.overlay, "BACK"))
	await get_tree().process_frame
	check(game.route == "pause", "mobile options return to pause")
	click(find_button(game.overlay, "RESUME"))
	await get_tree().process_frame
	check(game.route == "fight" and pad.visible and InputRouter.sample(0).axis == 0, "resume does not leave a stuck movement key")
	game.match_node.set_physics_process(false)
	contact(0, "move_right")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await get_tree().process_frame
	check(game.route == "pause" and InputRouter.sample(0).axis == 0, "backgrounding pauses and clears touches")
	game.go_back()
	await get_tree().process_frame
	game.match_node.set_physics_process(false)
	InputRouter.clear()
	await get_tree().process_frame
	check(pad.fingers.is_empty(), "round/reset generation invalidates stale contacts")
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(1024, 768), Vector2i(1600, 720)]:
		# Real sized viewports avoid the desktop window manager clamping a phone
		# or tablet test to the virtual monitor's 1280x720 resolution.
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		var host := Control.new()
		host.size = Vector2(dimensions)
		viewport.add_child(host)
		var layout := TouchControls.new()
		host.add_child(layout)
		for solo in [true, false]:
			layout.solo = solo
			layout.rebuild()
			var valid := true
			var safe := TouchControls.safe_rect(viewport)
			for i in layout.buttons.size():
				valid = valid and safe.encloses(layout.buttons[i].rect)
				for j in range(i):
					valid = valid and not layout.buttons[i].rect.intersects(layout.buttons[j].rect)
			check(valid, "%s %s layout has no overlapping or clipped touch targets" % [dimensions, "solo" if solo else "shared"])
		viewport.queue_free()
	pad.solo = false
	pad.rebuild()
	pad.set_active(true)
	InputRouter.clear()
	contact(0, "move_right", true, 0)
	contact(1, "move_left", true, 1)
	contact(2, "light", true, 0)
	contact(3, "heavy", true, 1)
	var p1: Dictionary = InputRouter.sample(0)
	var p2: Dictionary = InputRouter.sample(1)
	check(p1.axis == 1 and p1.light and p2.axis == -1 and p2.heavy, "desktop two-player touch-controller inputs remain independent")
	DirAccess.make_dir_recursive_absolute("/tmp/inferno-touch")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/inferno-touch/shared-tablet.png")
	pad.release_all()
	game.solo = true
	game.selected.assign([7, 8])
	game.start_match()
	await get_tree().process_frame
	game.match_node.set_physics_process(false)
	game.match_node.phase = "fight"
	game.match_node.fighters[0].meter = 100
	game.match_node.fighters[1].meter = 100
	contact(0, "block")
	contact(1, "special")
	var commands: Array[Dictionary] = [InputRouter.sample(0), InputRouter.sample(1)]
	game.match_node.advance_fight(1.0/60.0, commands)
	check(game.match_node.fighters[0].attack.id == "metal_armor" and game.match_node.fighters[0].meter == 65, "GUARD plus SPECIAL performs Lava Stone's actual armor move through touch")
	game.selected.assign([8, 0])
	game.start_match()
	await get_tree().process_frame
	game.match_node.set_physics_process(false)
	game.match_node.phase = "fight"
	game.match_node.fighters[0].meter = 100
	game.match_node.fighters[0].position.x = 900
	game.match_node.fighters[1].position.x = 400
	contact(2, "move_right")
	contact(3, "special")
	commands = [InputRouter.sample(0), {}]
	game.match_node.advance_fight(1.0/60.0, commands)
	check(game.match_node.fighters[0].attack.id == "shatter_shield" and game.match_node.fighters[0].meter == 80, "back plus SPECIAL uses facing-relative touch binding after sides switch")
	game.show_menu()
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	print("TOUCH RESULT: %d passed, %d failed" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)
