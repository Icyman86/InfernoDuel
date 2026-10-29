extends Node
var master := 0.7
var music := 0.35
var sfx := 0.7
var fullscreen := false

func _ready() -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		master = config.get_value("audio", "master", 0.7)
		music = config.get_value("audio", "music", 0.35)
		sfx = config.get_value("audio", "sfx", 0.7)
		fullscreen = config.get_value("video", "fullscreen", false)
	apply()

func apply() -> void:
	for entry in [["Master", master], ["Music", music], ["SFX", sfx]]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(entry[0]), linear_to_db(maxf(0.0001, entry[1])))
	if DisplayServer.get_name() != "headless" and not OS.has_feature("android"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func save() -> void:
	apply()
	var config := ConfigFile.new()
	for key in ["master", "music", "sfx"]:
		config.set_value("audio", key, get(key))
	config.set_value("video", "fullscreen", fullscreen)
	config.save("user://settings.cfg")

func reset() -> void:
	master = 0.7
	music = 0.35
	sfx = 0.7
	fullscreen = false
	save()
