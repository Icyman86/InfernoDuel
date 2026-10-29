extends Node
var passed := 0
var failed := 0
var game: Control
const OUTPUT := "/tmp/inferno-v7-ui"

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func click(button: Button) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = button.get_global_rect().get_center()
		get_viewport().push_input(event)
	await get_tree().process_frame

func text_content(node: Node) -> String:
	var result := ""
	if (node is Label or node is LineEdit or node is Button) and node.is_visible_in_tree(): result += node.text+"\n"
	for child in node.get_children(): result += text_content(child)
	return result

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
	get_window().size = Vector2i(1280,720)
	await get_tree().process_frame
	game.show_online()
	var lobby: OnlineLobby = game.screen
	await click(lobby.host_button)
	check(OnlineSession.phase == "hosting" and SessionCode.valid(lobby.invitation.text),"CREATE SESSION displays an actual six-character hosted invitation")
	var address_pattern := RegEx.new()
	address_pattern.compile("[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}")
	check(address_pattern.search(text_content(lobby)) == null,"no visible label, button or input exposes a network address")
	# Do not retain the live invitation in public validation screenshots.
	await click(lobby.cancel_button)
	check(not OnlineSession.active() and lobby.invitation.text == "— — — — — —" and not lobby.host_button.disabled,"CANCEL removes the live room and permits another session")
	await capture("session-code")
	game.show_select(true)
	game.selected.assign([0,1])
	game.start_match()
	await get_tree().process_frame
	game.match_node.set_physics_process(false)
	game.match_node.phase = "fight"
	game.match_node.announcement.text = ""
	game.match_node.fighters[0].meter = 65
	game.match_node.fighters[0].special_cooldown = .8
	game.match_node.update_hud()
	for dimensions in [Vector2i(1280,720),Vector2i(2400,1080),Vector2i(1024,768)]:
		get_window().size = dimensions
		await get_tree().process_frame
		await get_tree().process_frame
		var pad: TouchControls = game.touch_controls
		check(pad.sticks.size() == 1 and pad.buttons.size() == 7,"one thumbstick, block, basic attack, four surrounding skills and pause fit %s" % dimensions)
		var safe := TouchControls.safe_rect(get_viewport())
		var enclosed := true
		for b in pad.buttons: enclosed = enclosed and safe.encloses(b.rect)
		check(enclosed,"all circular combat targets remain inside the native safe area at %s" % dimensions)
		await capture("combat-%dx%d" % [dimensions.x,dimensions.y])
	var ui: TouchControls = game.touch_controls
	var found_special := false
	var found_ultimate := false
	for b in ui.buttons:
		if b.action == "special": found_special = ui.cooldown(b) > 0
		if b.action == "ultimate": found_ultimate = is_equal_approx(ui.cooldown(b),.35)
	check(found_special and found_ultimate,"skill readiness rings track actual cooldown and meter state")
	game.show_menu()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(.7).timeout
	print("V7 UI RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
