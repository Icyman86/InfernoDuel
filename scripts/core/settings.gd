extends Node
var master := 0.7
var music := 0.35
var sfx := 0.7
var fullscreen := false

func _ready() -> void:
	# Render at the actual window/surface pixel dimensions. The logical arena
	# and menus scale separately; they never force a 1280x720 render target.
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().content_scale_size = Vector2i.ZERO
	get_window().content_scale_factor = 1.0
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
	fit_device_resolution()

func apply() -> void:
	for entry in [["Master", master], ["Music", music], ["SFX", sfx]]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(entry[0]), linear_to_db(maxf(0.0001, entry[1])))
	if DisplayServer.get_name() != "headless" and not OS.has_feature("android"):
		get_window().mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED

func fit_device_resolution() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("android") or fullscreen: return
	var usable := DisplayServer.screen_get_usable_rect()
	if usable.has_area():
		get_window().size = usable.size
		get_window().position = usable.position

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
