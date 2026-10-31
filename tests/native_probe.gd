extends SceneTree
## Read-only observer for the packaged game. tools/test_native.py supplies real
## X11 input; this script never writes fighter HP, input, routes or phase.
var game: Control
var elapsed := 0.0
var frames := 0
func _initialize() -> void:
	call_deferred("start")
func start() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
func _process(delta: float) -> bool:
	if not is_instance_valid(game): return false
	elapsed += delta
	frames += 1
	if frames%3 == 0:
		var state := {"dialog":is_instance_valid(game.modal) and game.modal.visible,"route":game.route,"version":ProjectSettings.get_setting("application/config/version"),"elapsed":elapsed}
		if game.route == "select": state.ready = game.screen.ready_players
		if game.route == "gallery":
			state.current = game.screen.current
			state.bones = game.screen.presentation.skeleton.get_bone_count()
			state.triangles = game.screen.presentation.model_triangles
		if is_instance_valid(game.match_node):
			var duel = game.match_node
			state.phase = duel.phase
			state.remaining = duel.remaining
			state.modern = duel.modern_rules
			state.fighters = []
			for f in duel.fighters: state.fighters.append({"x":f.position.x,"hp":f.hp,"stun":f.stun})
		var file := FileAccess.open("/tmp/inferno-v12-native.json.tmp",FileAccess.WRITE)
		file.store_string(JSON.stringify(state))
		file.close()
		DirAccess.rename_absolute("/tmp/inferno-v12-native.json.tmp","/tmp/inferno-v12-native.json")
	if elapsed > 45: quit(2)
	return false
