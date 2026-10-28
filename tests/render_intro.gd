extends Node
## Author each OGV from a deterministic 6.4-second cinematic timeline.
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass the fighter id after --")
		get_tree().quit(1)
		return
	var roster: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json")).fighters
	for profile in roster:
		if profile.id == args[0]:
			var cinematic := IntroCinematic.new()
			cinematic.profile = profile
			cinematic.finished.connect(func(): get_tree().quit())
			add_child(cinematic)
			return
	push_error("Unknown intro fighter: "+args[0])
	get_tree().quit(1)
