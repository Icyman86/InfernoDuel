class_name OptionsScreen
extends Control
signal back_requested
var touch_mode := OS.has_feature("android") or "--touch" in OS.get_cmdline_user_args()

func _ready() -> void:
	theme = UI.theme()
	add_child(UI.place(UI.label("OPTIONS",36,UI.IVORY,true),60,45,1160,55))
	add_child(UI.place(UI.label("VIDEO",24,UI.GOLD),80,133,490,40))
	if touch_mode:
		add_child(UI.place(UI.label("LANDSCAPE · AUTOMATIC SCREEN FIT",20,UI.IVORY),80,195,510,48))
		add_child(UI.place(UI.label("Phone: play against CPU\nTablet: solo or shared touchscreen",20,UI.MUTED),80,258,510,76))
	else:
		add_child(UI.place(UI.button("FULLSCREEN: %s" % ("ON" if Settings.fullscreen else "OFF"),func():
			Settings.fullscreen = not Settings.fullscreen
			Settings.save()
			rebuild()),90,195,470,48))
		add_child(UI.place(UI.button("WINDOW · 1280 × 720",func():
			Settings.fullscreen = false
			Settings.save()
			if DisplayServer.get_name() != "headless": DisplayServer.window_set_size(Vector2i(1280,720))
			rebuild()),90,258,470,48))
	add_child(UI.place(UI.label("AUDIO · SYNTHESIZED PLACEHOLDER SFX",22,UI.GOLD),635,133,570,40))
	for i in 3:
		var key: String = ["master","music","sfx"][i]
		var text := UI.label(key.to_upper()+"%s" % (" · no music asset yet" if key == "music" else ""),18,UI.MUTED)
		UI.place(text,650,185+i*62,500,28)
		add_child(text)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.01
		slider.value = Settings.get(key)
		UI.place(slider,660,216+i*62,480,24)
		slider.value_changed.connect(func(value: float):
			Settings.set(key,value)
			Settings.save())
		add_child(slider)
	add_child(UI.place(UI.label("MULTITOUCH · MOVE AND ATTACK TOGETHER" if touch_mode else "ONE KEYBOARD · TWO INDEPENDENT PLAYERS",24,UI.GOLD),60,410,1160,44))
	add_child(UI.place(UI.label("LEFT: ◀ / ▶ move · JUMP · GUARD\nHold GUARD while facing your opponent" if touch_mode else "P1  A / D move · W jump · S block\nF light · G heavy · H special · J ultimate",20,UI.CYAN),60,475,570,80))
	add_child(UI.place(UI.label("RIGHT: LIGHT · HEAVY · SPECIAL · ULT\nULT requires 100% meter" if touch_mode else "P2  ← / → move · ↑ jump · ↓ block\nI light · O heavy · P special · L ultimate",20,UI.ORANGE),650,475,570,80))
	add_child(UI.place(UI.label("Ⅱ pauses · Android Back navigates back · Cyan = P1 / Orange = P2" if touch_mode else "ESC pause · Physical keyboard ghosting requires a two-person hardware test.",18,UI.MUTED),60,579,1160,32))
	add_child(UI.place(UI.label("MOVE VARIANTS: hold FORWARD / BACK / GUARD + LIGHT, SPECIAL or ULT · Full move list in FIGHTERS",15,UI.GOLD),60,611,1160,26))
	add_child(UI.place(UI.button("RESET DEFAULTS",func():
		Settings.reset()
		rebuild()),340,644,290,46))
	add_child(UI.place(UI.button("BACK",func(): back_requested.emit(),true),650,644,290,46))

	get_child(get_child_count()-1).grab_focus()

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_ready()
