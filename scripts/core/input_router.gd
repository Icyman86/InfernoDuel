extends Node
## Independent physical-key streams. Nothing is consumed by the other player.
var held: Array[Dictionary] = [{}, {}]
var pressed: Array[Dictionary] = [{}, {}]
var layouts: Array[Dictionary] = []
var keys: Array[Dictionary] = []
var touch_held: Array[Dictionary] = [{}, {}]
var touch_axis: Array[float] = [0.0, 0.0]
var generation := 0

func set_touch(player: int, action: String, down: bool) -> void:
	if down and not touch_held[player].get(action, false):
		pressed[player][action] = true
	touch_held[player][action] = down

func set_touch_axis(player: int, value: float) -> void:
	touch_axis[player] = clampf(value, -1.0, 1.0)

func is_held(player: int, action: String) -> bool:
	return held[player].get(action, false) or touch_held[player].get(action, false)

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/input_layouts.json"))
	for player in ["player_1", "player_2"]:
		layouts.append(data[player])
		var mapped := {}
		for action in data[player]:
			mapped[OS.find_keycode_from_string(data[player][action])] = action
		keys.append(mapped)

func _input(event: InputEvent) -> void:
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
	var state := {"axis": float(digital) if digital != 0 else touch_axis[player],
		"block": is_held(player, "block")}
	for action in ["jump", "light", "heavy", "special", "ultimate"]:
		state[action] = pressed[player].get(action, false)
	pressed[player].clear()
	return state

func clear() -> void:
	generation += 1
	for i in 2:
		touch_axis[i] = 0.0
		held[i].clear()
		pressed[i].clear()
		touch_held[i].clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear()
