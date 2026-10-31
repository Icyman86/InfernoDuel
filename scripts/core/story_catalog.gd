class_name StoryCatalog
extends RefCounted
static var cache: Dictionary = {}

static func campaign() -> Dictionary:
	if cache.is_empty(): cache = JSON.parse_string(FileAccess.get_file_as_string("res://data/story_campaign.json"))
	return cache

static func levels() -> Array:
	return campaign().levels

static func valid(index: int) -> bool:
	return index >= 0 and index < levels().size()

static func fighter_index(roster: Array, id: String) -> int:
	for i in roster.size():
		if roster[i].id == id: return i
	return -1
