class_name ArenaCatalog
extends RefCounted
static func entries() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas.json")).arenas
static func valid(id: String) -> bool:
	for arena in entries():
		if arena.id == id: return true
	return false
static func get_arena(id: String) -> Dictionary:
	for arena in entries():
		if arena.id == id: return arena
	return entries()[0]
static func resolve(id: String) -> String:
	if id == "random":
		var choices := entries()
		return choices[randi_range(0,choices.size()-1)].id
	return id if valid(id) else "citadel"
