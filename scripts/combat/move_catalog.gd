class_name MoveCatalog
extends RefCounted
## One catalogue drives combat, AI and the interactive gallery.
static var cache: Dictionary = {}

static func definitions(profile: Dictionary) -> Array:
	if cache.is_empty():
		cache = JSON.parse_string(FileAccess.get_file_as_string("res://data/move_sets.json"))
	return cache.get(profile.get("id", ""), [])

static func build(profile: Dictionary, bases: Dictionary) -> Dictionary:
	var result := {}
	var overrides: Dictionary = profile.get("combat", {}).get("overrides", {})
	for id in bases:
		var move: AttackData = bases[id].duplicate()
		move.slot = id
		move.animation = id
		move.display_name = {"light": "Light", "heavy": "Heavy", "special": profile.get("special", "Special"), "ultimate": profile.get("ultimate", "Ultimate")}[id]
		move.kind = profile.get("combat", {}).get(id + "_kind", "melee")
		for field in overrides.get(id, {}): move.set(field, overrides[id][field])
		result[id] = move
	for definition in definitions(profile):
		var move: AttackData = result[definition.get("base", definition.slot)].duplicate()
		for field in definition:
			if field != "base": move.set(field, definition[field])
		result[move.id] = move
	return result

static func resolve(moves: Dictionary, slot: String, input: Dictionary, facing: int) -> String:
	var direction := int(signf(float(input.get("axis", 0))) * facing)
	var command := "down" if input.get("block", false) else ("forward" if direction > 0 else ("back" if direction < 0 else "neutral"))
	for id in moves:
		if moves[id].slot == slot and moves[id].command == command: return id
	return slot

static func input_for(move: AttackData, facing := 1) -> Dictionary:
	var result := {move.slot: true}
	if move.command == "forward": result.axis = facing
	elif move.command == "back": result.axis = -facing
	elif move.command == "down": result.block = true
	return result

static func binding(move: AttackData) -> String:
	var prefix: String = {"neutral": "", "forward": "FORWARD + ", "back": "BACK + ", "down": "GUARD + "}.get(move.command, "")
	return prefix + move.slot.to_upper()
