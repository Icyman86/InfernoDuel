extends Node
var passed := 0
var failed := 0

func check(ok: bool, text: String) -> void:
	if ok:
		passed += 1
		print("PASS ",text)
	else:
		failed += 1
		push_error(text)

func button(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found := button(child,text)
		if found: return found
	return null

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var seen := {}
	for i in 32:
		var code := SessionCode.generate()
		check(code.length() == 6 and SessionCode.valid(code) and not seen.has(code),"generated room code has exactly six human-readable random symbols")
		seen[code] = true
	check(SessionCode.normalize(" ab-23cd ") == "AB23CD","codes normalize case, copied spacing and separators")
	for invalid in ["", "12345", "1234567", "https://example.com", "ABC.23", "IO0O1L"]:
		check(not SessionCode.valid(invalid),"bad length, ambiguous symbols and addresses cannot be room codes")
	var input: Dictionary = OnlineSession.sanitize_input({"axis":200,"light":true,"hp":10000})
	check(input.axis == 1 and input.light and not input.has("hp"),"remote input is clamped and cannot carry health changes")
	check(is_equal_approx(OnlineSession.sanitize_input({"axis":0.45}).axis,0.45),"network input preserves partial thumbstick movement")
	check(OnlineSession.sanitize_input({"axis":"bad"}).is_empty(),"non-numeric remote movement is rejected")
	check(OnlineSession.sanitize_input({"axis":NAN}).is_empty(),"non-finite remote movement is rejected")
	check(not OnlineSession.sanitize_input({"axis":0,"light":"true"}).light,"string input cannot masquerade as an attack button")
	var game: Control = preload("res://scenes/main.tscn").instantiate()
	game.touch_mode = true
	add_child(game)
	check(button(game.screen,"CONNECT · SESSION CODE") != null,"Android menu has session-code connection")
	check(button(game.screen,"LOCAL VERSUS") == null and button(game.screen,"2 PLAYERS · SHARED TABLET") == null,"Android menu has no local-versus or shared-tablet option")
	check(button(game.screen,"PLAY · TOUCH VS CPU") != null,"offline CPU play remains available")
	game.show_select(false)
	check(game.route == "online","Android cannot enter local versus through the selection API")
	var lobby: OnlineLobby = game.screen
	check(lobby.code_input.max_length == 6 and not lobby.get("address_picker"),"connection UI accepts only six symbols and has no address picker")
	lobby.code_input.grab_focus()
	for letter in ["f","s","i"]:
		var event := InputEventKey.new()
		event.keycode = OS.find_keycode_from_string(letter.to_upper())
		event.physical_keycode = event.keycode
		event.unicode = letter.unicode_at(0)
		event.pressed = true
		get_viewport().push_input(event)
	check(lobby.code_input.text.to_lower() == "fsi","session text entry does not lose F/S/I to menu shortcuts")
	lobby.join_session()
	check(OnlineSession.phase == "idle" and lobby.message.text.contains("Invalid"),"bad code shows a usable error instead of starting a fake match")
	check(get_window().content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED and get_window().content_scale_size == Vector2i.ZERO,"rendering uses the actual surface size with no fixed-resolution target")
	var picker := CharacterSelect.new()
	picker.roster = game.roster
	picker.online_slot = 1
	add_child(picker)
	var requests: Array[int] = []
	picker.network_choice.connect(func(index: int): requests.append(index))
	picker.choose(0,7)
	picker.choose(1,8)
	check(requests == [8] and picker.ready_buttons[0].disabled,"guest cannot choose or ready the opponent's fighter")
	picker.queue_free()
	game.show_menu()
	await get_tree().process_frame
	game.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(.6).timeout
	print("SESSION RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
