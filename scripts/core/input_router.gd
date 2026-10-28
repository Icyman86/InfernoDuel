extends Node
## Independent physical-key streams. Nothing is consumed by the other player.
var held: Array[Dictionary] = [{}, {}]
var pressed: Array[Dictionary] = [{}, {}]
var layouts: Array[Dictionary] = []
var keys: Array[Dictionary] = []

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
	var state := {"axis": int(held[player].get("move_right", false)) - int(held[player].get("move_left", false)),
		"block": held[player].get("block", false)}
	for action in ["jump", "light", "heavy", "special", "ultimate"]:
		state[action] = pressed[player].get(action, false)
	pressed[player].clear()
	return state

func clear() -> void:
	for i in 2:
		held[i].clear()
		pressed[i].clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear()
