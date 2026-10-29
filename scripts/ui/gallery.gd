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
var demo_viewport: SubViewport
var preview: SubViewportContainer
var presentation: FighterPresentation
var sheet_button: Button
var replay_button: Button
var sheet_open := false
var name_label: Label
var number_label: Label
var role_label: Label
var move_label: Label
var move_details: Label
var status_label: Label

func _ready() -> void:
	theme = UI.theme()
	var shade := ColorRect.new()
	shade.color = Color("090d17")
	add_child(UI.place(shade,0,0,1280,720))
	add_child(UI.place(UI.label("THE ROSTER",15,UI.CYAN),40,27,330,28))
	add_child(UI.place(UI.label("FIGHTERS",35,UI.IVORY),35,57,400,52))
	add_child(UI.place(UI.button("BACK",func(): back_requested.emit()),1082,35,160,44))
	var panel := UI.panel()
	panel.add_theme_stylebox_override("panel",UI.style(Color("0b101b"),Color("202d42"),1))
	add_child(UI.place(panel,360,108,550,422))
	preview = SubViewportContainer.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.stretch = true
	add_child(UI.place(preview,362,110,546,418))
	demo_viewport = SubViewport.new()
	demo_viewport.size = Vector2i(820,628)
	demo_viewport.own_world_3d = true
	demo_viewport.handle_input_locally = false
	preview.add_child(demo_viewport)
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.place(art,366,113,538,412))
	art.visible = false
	number_label = UI.label("",19,UI.CYAN)
	add_child(UI.place(number_label,42,145,300,32))
	name_label = UI.label("",35,UI.IVORY)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(name_label,35,193,315,116))
	role_label = UI.label("",17,UI.GOLD)
	role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(role_label,43,322,290,55))
	details = UI.label("",17,UI.MUTED)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(details,43,395,285,98))
	add_child(UI.place(UI.label("SIGNATURE MOVE",15,UI.CYAN),938,144,300,30))
	move_label = UI.label("",23,UI.IVORY)
	move_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(move_label,933,194,300,88))
	move_details = UI.label("",17,UI.MUTED)
	move_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(move_details,938,298,292,88))
	replay_button = UI.button("REPLAY PRESENTATION",replay_presentation)
	replay_button.add_theme_font_size_override("font_size",15)
	add_child(UI.place(replay_button,938,410,295,45))
	sheet_button = UI.button("ORIGINAL SHEET",toggle_sheet)
	sheet_button.add_theme_font_size_override("font_size",15)
	add_child(UI.place(sheet_button,938,468,295,45))
	intro_button = UI.button("PLAY INTRO",func(): intro_requested.emit(current))
	intro_button.add_theme_font_size_override("font_size",15)
	add_child(UI.place(intro_button,43,500,285,40))
	status_label = UI.label("",13,UI.MUTED)
	add_child(UI.place(status_label,370,532,530,26))
	add_child(UI.place(UI.label("CHOOSE YOUR FIGHTER",14,UI.CYAN),38,567,1200,26))
	for i in roster.size():
		var index := i
		var button := UI.button(roster[i].display_name.to_upper(),func(): show_fighter(index))
		button.add_theme_font_size_override("font_size",11)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var normal := UI.style(Color("121b29"),Color("2e3a4e"),1)
		normal.content_margin_top = 60
		button.add_theme_stylebox_override("normal",normal)
		var hover := normal.duplicate()
		hover.border_color = UI.CYAN
		button.add_theme_stylebox_override("hover",hover)
		button.add_theme_stylebox_override("pressed",hover)
		add_child(UI.place(button,37+i*121,604,116,86))
		fighter_buttons.append(button)
		var portrait := FighterPortrait.new()
		portrait.setup(roster[i])
		button.add_child(UI.place(portrait,30,6,56,54))
	show_fighter(current)
	fighter_buttons[current].grab_focus()

func show_fighter(index: int) -> void:
	current = index
	if presentation:
		demo_viewport.remove_child(presentation)
		presentation.queue_free()
	var f: Dictionary = roster[index]
	var color := Color(f.get("accent","55d9ef"))
	presentation = FighterPresentation.new()
	presentation.profile = f
	presentation.completed.connect(show_idle)
	demo_viewport.add_child(presentation)
	art.texture = load("res://"+f.get("gallery_art_path",f.reference_art_path))
	name_label.text = f.display_name.to_upper()
	number_label.text = "LEGEND / %02d" % (index+1)
	number_label.modulate = color
	role_label.text = f.archetype.to_upper().replace("_"," ")
	var moves := MoveCatalog.build(f,{"light":load("res://data/attacks/light.tres"),"heavy":load("res://data/attacks/heavy.tres"),"special":load("res://data/attacks/special.tres"),"ultimate":load("res://data/attacks/ultimate.tres")})
	var move: AttackData = moves.heavy
	move_label.text = move.display_name.to_upper()
	move_details.text = "A signature strike.\n%d damage · %s" % [move.damage,MoveCatalog.binding(move)]
	details.text = "%d ATTACKS & ABILITIES\n\nChoose your legend.
Ready for the citadel." % moves.size()
	for i in fighter_buttons.size():
		var style := UI.style(Color("223345") if i == current else Color("121b29"),color if i == current else Color("2e3a4e"),2 if i == current else 1)
		style.content_margin_top = 60
		fighter_buttons[i].add_theme_stylebox_override("normal",style)
	set_sheet(false)
	replay_presentation()

func show_idle() -> void:
	if sheet_open: return
	preview.visible = true
	demo_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	status_label.text = "READY FOR THE CITADEL"

func replay_presentation() -> void:
	set_sheet(false)
	preview.visible = true
	presentation.replay()
	demo_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	status_label.text = "LEGEND PRESENTATION"

func toggle_sheet() -> void:
	set_sheet(not sheet_open)

func set_sheet(value: bool) -> void:
	sheet_open = value
	art.visible = value
	preview.visible = not value
	presentation.set_process(not value)
	demo_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if preview.visible else SubViewport.UPDATE_DISABLED
	sheet_button.text = "BACK TO FIGHTER" if value else "ORIGINAL SHEET"
	status_label.text = "ORIGINAL REFERENCE" if value else ("READY FOR THE CITADEL" if presentation.finished else "LEGEND PRESENTATION")
