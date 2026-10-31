extends Node
## Independent physical-key streams. Nothing is consumed by the other player.
var held: Array[Dictionary] = [{}, {}]
var pressed: Array[Dictionary] = [{}, {}]
var layouts: Array[Dictionary] = []
var keys: Array[Dictionary] = []
var touch_held: Array[Dictionary] = [{}, {}]
var touch_axis: Array[float] = [0.0, 0.0]
signal controller_action(player: int, action: String)
signal controller_removed(player: int)
const DEADZONE := 0.24
const PAD_BUTTONS := {JOY_BUTTON_A:"jump", JOY_BUTTON_X:"light", JOY_BUTTON_Y:"heavy", JOY_BUTTON_B:"special", JOY_BUTTON_LEFT_SHOULDER:"grab", JOY_BUTTON_RIGHT_SHOULDER:"escape", JOY_BUTTON_DPAD_LEFT:"move_left", JOY_BUTTON_DPAD_RIGHT:"move_right", JOY_BUTTON_DPAD_DOWN:"block"}
var devices: Array[int] = [-1,-1]
var pad_held: Array[Dictionary] = [{},{}]
var pad_axis: Array[float] = [0.0,0.0]
var stick_direction: Array[int] = [0,0]
var trigger_block: Array[bool] = [false,false]
var vertical_direction: Array[int] = [0,0]
var generation := 0

func assign_device(device: int, connected: bool) -> void:
	if connected:
		if device in devices: return
		var slot := devices.find(-1)
		if slot >= 0: devices[slot] = device
	else:
		var slot := devices.find(device)
		if slot < 0: return
		devices[slot] = -1
		pad_held[slot].clear()
		pad_axis[slot] = 0
		pressed[slot].clear()
		stick_direction[slot] = 0
		trigger_block[slot] = false
		vertical_direction[slot] = 0
		controller_removed.emit(slot)

func _pad_button(player: int, action: String, down: bool) -> void:
	if down and not pad_held[player].get(action,false):
		pressed[player][action] = true
	pad_held[player][action] = down

func set_touch(player: int, action: String, down: bool) -> void:
	if down and not touch_held[player].get(action, false):
		pressed[player][action] = true
	touch_held[player][action] = down

func set_touch_axis(player: int, value: float) -> void:
	touch_axis[player] = clampf(value, -1.0, 1.0)

func is_held(player: int, action: String) -> bool:
	return held[player].get(action, false) or touch_held[player].get(action, false) or pad_held[player].get(action, false) or (action == "block" and trigger_block[player])

func _ready() -> void:
	Input.joy_connection_changed.connect(assign_device)
	for device in Input.get_connected_joypads(): assign_device(device,true)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/input_layouts.json"))
	for player in ["player_1", "player_2"]:
		layouts.append(data[player])
		var mapped := {}
		for action in data[player]:
			mapped[OS.find_keycode_from_string(data[player][action])] = action
		keys.append(mapped)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		var player := devices.find(event.device)
		if player < 0: return
		if event is InputEventJoypadButton:
			if PAD_BUTTONS.has(event.button_index): _pad_button(player,PAD_BUTTONS[event.button_index],event.pressed)
			if event.pressed:
				var navigation := {JOY_BUTTON_A:"accept",JOY_BUTTON_B:"back",JOY_BUTTON_X:"ready",JOY_BUTTON_Y:"undo",JOY_BUTTON_START:"pause",JOY_BUTTON_DPAD_LEFT:"left",JOY_BUTTON_DPAD_RIGHT:"right",JOY_BUTTON_DPAD_UP:"up",JOY_BUTTON_DPAD_DOWN:"down"}
				if navigation.has(event.button_index): controller_action.emit(player,navigation[event.button_index])
		else:
			if event.axis == JOY_AXIS_LEFT_X:
				var value: float = event.axis_value
				pad_axis[player] = signf(value)*maxf(0,(absf(value)-DEADZONE)/(1-DEADZONE))
				var direction := int(signf(value)) if absf(value) > .6 else 0
				if direction != 0 and direction != stick_direction[player]: controller_action.emit(player,"right" if direction > 0 else "left")
				stick_direction[player] = direction
			elif event.axis == JOY_AXIS_LEFT_Y:
				var direction := int(signf(event.axis_value)) if absf(event.axis_value) > .6 else 0
				if direction != 0 and direction != vertical_direction[player]: controller_action.emit(player,"down" if direction > 0 else "up")
				vertical_direction[player] = direction
			elif event.axis == JOY_AXIS_TRIGGER_LEFT:
				trigger_block[player] = event.axis_value > .45
			elif event.axis == JOY_AXIS_TRIGGER_RIGHT:
				_pad_button(player,"ultimate",event.axis_value > .55)
		# Our route handler owns navigation; avoid native ui_accept also
		# activating the focused button on the newly opened screen.
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode else event.keycode
		for i in 2:
			if keys[i].has(code):
				var action: String = keys[i][code]
				held[i][action] = event.pressed
				if event.pressed:
					pressed[i][action] = true

func sample(player: int) -> Dictionary:
	var digital := int(is_held(player, "move_right")) - int(is_held(player, "move_left"))
	var state := {"axis": float(digital) if digital != 0 else (pad_axis[player] if absf(pad_axis[player]) > 0 else touch_axis[player]),
		"block": is_held(player, "block")}
	for action in ["jump", "light", "heavy", "special", "ultimate", "grab", "escape"]:
		state[action] = pressed[player].get(action, false)
	pressed[player].clear()
	return state

func network_sample(player: int) -> Dictionary:
	# V12 grabs/escapes are local Linux rules. Keep the existing LAN packet
	# shape within its strict size bound instead of silently dropping all input.
	var state := sample(player)
	state.erase("grab")
	state.erase("escape")
	return state

func clear() -> void:
	generation += 1
	for i in 2:
		touch_axis[i] = 0.0
		pad_axis[i] = 0.0
		pad_held[i].clear()
		stick_direction[i] = 0
		vertical_direction[i] = 0
		trigger_block[i] = false
		held[i].clear()
		pressed[i].clear()
		touch_held[i].clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear()
