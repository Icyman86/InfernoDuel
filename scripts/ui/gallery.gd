class_name FighterGallery
extends Control
signal back_requested
signal intro_requested(index: int)
var roster: Array = []
var current := 0
var art: TextureRect
var details: Label
var intro_button: Button
var fighter_buttons: Array[Button] = []
var move_buttons: Dictionary = {}
var showcase: MoveShowcase
var demo_viewport: SubViewport
var preview: SubViewportContainer
var moves_box: VBoxContainer
var move_title: Label
var readout: Label
var auto_button: Button
var sheet_button: Button
var sheet_open := false

func _ready() -> void:
	theme = UI.theme()
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.01,0.03,0.91)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.place(shade,0,0,1280,720))
	add_child(UI.place(UI.label("FIGHTERS · MOVE LAB",34,UI.IVORY,true),40,30,1200,55))
	for i in roster.size():
		var index := i
		var button := UI.button(roster[i].display_name.to_upper(),func(): show_fighter(index))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size",16)
		for state in ["normal", "hover", "pressed"]:
			var style := UI.style(Color("19131e"), UI.GOLD if state != "normal" else Color("59424a"))
			style.content_margin_left = 48
			button.add_theme_stylebox_override(state, style)
		add_child(UI.place(button,28,111+i*48,242,42))
		fighter_buttons.append(button)
		var portrait := FighterPortrait.new()
		portrait.setup(roster[i])
		button.add_child(UI.place(portrait,3,3,36,36))
	var panel := UI.panel()
	add_child(UI.place(panel,290,108,610,445))
	preview = SubViewportContainer.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.stretch = true
	add_child(UI.place(preview,296,114,598,432))
	demo_viewport = SubViewport.new()
	demo_viewport.size = Vector2i(1000,680)
	demo_viewport.handle_input_locally = false
	demo_viewport.disable_3d = true
	demo_viewport.transparent_bg = true
	preview.add_child(demo_viewport)
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.place(art,300,116,590,425))
	art.visible = false
	move_title = UI.label("IDLE",23,UI.GOLD,true)
	add_child(UI.place(move_title,302,121,585,34))
	readout = UI.label("",14,UI.MUTED)
	add_child(UI.place(readout,300,525,590,22))
	add_child(UI.place(UI.label("TAP A MOVE TO PERFORM IT",16,UI.GOLD),918,107,333,32))
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(UI.place(scroll,918,150,336,430))
	moves_box = VBoxContainer.new()
	moves_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(moves_box)
	details = UI.label("",15,UI.MUTED)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(details,300,557,590,78))
	add_child(UI.place(UI.button("BACK",func(): back_requested.emit()),28,644,242,46))
	auto_button = UI.button("AUTO · ON",toggle_autoplay,true)
	add_child(UI.place(auto_button,300,644,185,46))
	sheet_button = UI.button("ORIGINAL SHEET",toggle_sheet)
	sheet_button.add_theme_font_size_override("font_size",16)
	add_child(UI.place(sheet_button,496,644,215,46))
	intro_button = UI.button("PLAY INTRO",func(): intro_requested.emit(current))
	intro_button.add_theme_font_size_override("font_size",16)
	add_child(UI.place(intro_button,724,644,530,46))
	add_child(UI.place(UI.label("Moves use the same combat rules as a match · Preview refills meter for each demonstration.",14,UI.MUTED),284,696,980,22))
	show_fighter(current)
	fighter_buttons[current].grab_focus()

func show_fighter(index: int) -> void:
	current = index
	if showcase:
		demo_viewport.remove_child(showcase)
		showcase.queue_free()
	move_buttons.clear()
	for child in moves_box.get_children():
		moves_box.remove_child(child)
		child.queue_free()
	for i in fighter_buttons.size():
		var style := UI.style(Color("35202a") if i == current else Color("19131e"),UI.GOLD if i == current else Color("59424a"))
		style.content_margin_left = 48
		fighter_buttons[i].add_theme_stylebox_override("normal",style)
		fighter_buttons[i].add_theme_color_override("font_color",UI.GOLD if i == current else UI.IVORY)
	var f: Dictionary = roster[index]
	art.texture = load("res://"+f.get("gallery_art_path",f.reference_art_path))
	showcase = MoveShowcase.new()
	showcase.profiles.assign([f, f])
	showcase.move_changed.connect(_move_changed)
	showcase.readout_changed.connect(func(text: String): readout.text = text)
	demo_viewport.add_child(showcase)
	for id in showcase.sequence:
		var move_id := id
		var text: String = {"idle": "IDLE", "walk": "WALK", "jump": "JUMP", "guard": "GUARD"}.get(id, "")
		if showcase.fighters[0].moves.has(id):
			var move: AttackData = showcase.fighters[0].moves[id]
			text = move.display_name + "\n" + MoveCatalog.binding(move)
		var button := UI.button(text,func(): perform_move(move_id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size",15)
		button.custom_minimum_size = Vector2(310,56)
		moves_box.add_child(button)
		move_buttons[id] = button
	intro_button.text = "PLAY "+f.display_name.to_upper()+" INTRO"
	auto_button.text = "AUTO · ON"
	set_sheet(false)
	_move_changed("idle")

func perform_move(id: String) -> void:
	set_sheet(false)
	showcase.play_move(id)
	auto_button.text = "AUTO · OFF"

func _move_changed(id: String) -> void:
	move_title.text = id.to_upper().replace("_", " ")
	details.text = roster[current].display_name + " · " + roster[current].archetype.replace("_", " ")
	if showcase and showcase.fighters.size() > 0 and showcase.fighters[0].moves.has(id):
		var move: AttackData = showcase.fighters[0].moves[id]
		move_title.text = move.display_name.to_upper()
		details.text = "%s · %d damage · %d meter · %.2fs recovery" % [MoveCatalog.binding(move),move.damage,move.meter_cost,move.recovery]
		if move.description != "": details.text += "\n"+move.description
	else:
		details.text += "\nAutomatic move tour, or tap any move to take control."
	for key in move_buttons:
		move_buttons[key].add_theme_stylebox_override("normal",UI.style(Color("493022") if key == id else Color("19131e"),UI.GOLD if key == id else Color("59424a")))

func toggle_autoplay() -> void:
	set_sheet(false)
	showcase.autoplay = not showcase.autoplay
	auto_button.text = "AUTO · ON" if showcase.autoplay else "AUTO · OFF"
	if showcase.autoplay: showcase.play_move(showcase.current_move, false)

func toggle_sheet() -> void:
	set_sheet(not sheet_open)

func set_sheet(value: bool) -> void:
	sheet_open = value
	art.visible = value
	preview.visible = not value
	move_title.visible = not value
	readout.visible = not value
	showcase.stopped = value
	demo_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if value else SubViewport.UPDATE_ALWAYS
	sheet_button.text = "MOVE PREVIEW" if value else "ORIGINAL SHEET"
	if value:
		details.text = roster[current].display_name + " · Original reference sheet\nReference-guided animation keys are shown in the move preview. Original artwork is unchanged."
	else:
		_move_changed(showcase.current_move)
