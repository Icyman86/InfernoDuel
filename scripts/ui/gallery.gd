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
var preview: TextureRect
var presentation: FighterPresentation
var sheet_button: Button
var replay_button: Button
var sheet_open := false
var name_label: Label
var number_label: Label
var role_label: Label
var move_label: Label
var portrait_button: Button
var turn_buttons: Array[Button] = []
var dragging := false
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
	add_child(UI.place(panel,282,83,752,507))
	preview = TextureRect.new()
	preview.mouse_filter = Control.MOUSE_FILTER_STOP
	preview.gui_input.connect(_preview_input)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(UI.place(preview,284,85,748,503))
	demo_viewport = SubViewport.new()
	demo_viewport.size = Vector2i(1122,754)
	demo_viewport.msaa_3d = Viewport.MSAA_2X
	demo_viewport.own_world_3d = true
	demo_viewport.handle_input_locally = false
	preview.add_child(demo_viewport)
	preview.texture = demo_viewport.get_texture()
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.place(art,288,89,740,495))
	art.visible = false
	number_label = UI.label("",19,UI.CYAN)
	add_child(UI.place(number_label,38,137,230,30))
	name_label = UI.label("",32,UI.IVORY)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(name_label,30,183,245,110))
	role_label = UI.label("",17,UI.GOLD)
	role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(role_label,35,306,235,50))
	details = UI.label("",17,UI.MUTED)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(details,35,379,235,98))
	add_child(UI.place(UI.label("SIGNATURE",14,UI.CYAN),1048,134,200,30))
	move_label = UI.label("",20,UI.IVORY)
	move_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(move_label,1040,174,208,82))
	move_details = UI.label("",15,UI.MUTED)
	move_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(move_details,1048,259,200,72))
	replay_button = UI.button("REPLAY ENTRANCE",replay_presentation)
	replay_button.add_theme_font_size_override("font_size",15)
	add_child(UI.place(replay_button,1050,431,194,42))
	sheet_button = UI.button("ORIGINAL SHEET",toggle_sheet)
	sheet_button.add_theme_font_size_override("font_size",15)
	add_child(UI.place(sheet_button,1050,488,194,42))
	intro_button = UI.button("PLAY INTRO",func(): intro_requested.emit(current))
	intro_button.add_theme_font_size_override("font_size",15)
	add_child(UI.place(intro_button,35,498,235,40))
	for side in [-1,1]:
		var amount: float = side*PI/6
		var turn_button := UI.button("↶ TURN" if side < 0 else "TURN ↷",func(): presentation.turn(amount))
		turn_button.add_theme_font_size_override("font_size",13)
		add_child(UI.place(turn_button,1050 if side < 0 else 1152,332,92,38))
		turn_buttons.append(turn_button)
	portrait_button = UI.button("PORTRAIT VIEW",func():
		presentation.set_portrait(not presentation.portrait)
		portrait_button.text = "FULL BODY" if presentation.portrait else "PORTRAIT VIEW")
	portrait_button.add_theme_font_size_override("font_size",14)
	add_child(UI.place(portrait_button,1050,382,194,38))
	status_label = UI.label("",13,UI.MUTED)
	add_child(UI.place(status_label,340,561,635,24))
	add_child(UI.place(UI.label("CHOOSE YOUR FIGHTER",14,UI.CYAN),38,572,240,26))
	for i in roster.size():
		var index := i
		var button := UI.button(roster[i].display_name.to_upper().replace(" ","\n"),func(): show_fighter(index))
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
	dragging = false
	if portrait_button: portrait_button.text = "PORTRAIT VIEW"
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
	details.text = "%d ATTACKS & ABILITIES\n\n%s" % [moves.size(),_identity(f.id)]
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
	status_label.text = "DRAG TO ROTATE  ·  PORTRAIT / FULL BODY"

func replay_presentation() -> void:
	set_sheet(false)
	preview.visible = true
	presentation.replay()
	demo_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	status_label.text = "ENTER THE SPOTLIGHT"

func toggle_sheet() -> void:
	set_sheet(not sheet_open)

func set_sheet(value: bool) -> void:
	sheet_open = value
	art.visible = value
	preview.visible = not value
	presentation.set_process(not value)
	if presentation.animator: presentation.animator.active = not value
	demo_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if preview.visible else SubViewport.UPDATE_DISABLED
	sheet_button.text = "BACK TO FIGHTER" if value else "ORIGINAL SHEET"
	status_label.text = "ORIGINAL REFERENCE" if value else ("READY FOR THE CITADEL" if presentation.finished else "LEGEND PRESENTATION")

func _preview_input(event: InputEvent) -> void:
	if sheet_open: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		presentation.turn(-event.relative.x*.008)

func _process(_delta: float) -> void:
	if not preview or not preview.visible: return
	var pixels := Vector2i((preview.size*preview.get_global_transform().get_scale().abs()).round())
	if pixels.x > 0 and pixels.y > 0 and demo_viewport.size != pixels:
		demo_viewport.size = pixels

func _identity(id: String) -> String:
	return {"sharkbyte":"Ocean predator.\nLeather, fins and steel.","bullet":"The human bruiser.\nScarred fists. Red leather.","nachtelf":"The voidbringer.\nElven steel and crimson.","poisonboy":"The toxic shadow.\nStreetwear and venom.","spinegrin":"The living arsenal.\nScales, spines and instinct.","chainveil":"The iron widow.\nBlack lace and cold chains.","cheese_rat":"The big dreams.\nYellow shirt. Razor wit.","lava_stone":"Steel soul. Rock heart.\nBasalt and molten veins.","crystal_fang":"Part wolf. Part diamond.\nObsidian and amethyst.","phoenix_reign":"Born from the ashes.\nFeathers, fire and resolve."}.get(id,"")
