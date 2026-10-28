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

func _ready() -> void:
	theme = UI.theme()
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.01,0.03,0.87)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.place(shade,0,0,1280,720))
	add_child(UI.place(UI.label("THE LEGENDS",36,UI.IVORY,true),40,35,1200,60))
	for i in 10:
		var index := i
		var button := UI.button("    "+roster[i].display_name.to_upper(),func(): show_fighter(index))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size",16)
		add_child(UI.place(button,40,117+i*48,245,42))
		fighter_buttons.append(button)
		var portrait := FighterPortrait.new()
		portrait.setup(roster[i])
		button.add_child(UI.place(portrait,3,3,36,36))
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UI.place(art,310,112,910,425)
	add_child(art)
	details = UI.label("",20,UI.GOLD)
	UI.place(details,310,553,910,85)
	add_child(details)
	add_child(UI.place(UI.label("CHARACTER SHEETS · Original artwork preserved.",16,UI.MUTED),300,684,940,26))
	add_child(UI.place(UI.button("BACK",func(): back_requested.emit()),40,644,245,46))
	intro_button = UI.button("PLAY INTRO",func(): intro_requested.emit(current),true)
	add_child(UI.place(intro_button,640,641,450,42))
	show_fighter(current)
	fighter_buttons[current].grab_focus()

func show_fighter(index: int) -> void:
	current = index
	for i in fighter_buttons.size():
		fighter_buttons[i].add_theme_stylebox_override("normal",UI.style(Color("35202a") if i == current else Color("19131e"),UI.GOLD if i == current else Color("59424a")))
		fighter_buttons[i].add_theme_color_override("font_color",UI.GOLD if i == current else UI.IVORY)
	var f: Dictionary = roster[index]
	art.texture = load("res://"+f.get("gallery_art_path",f.reference_art_path))
	var individual_sheet: bool = f.id in ["bullet","nachtelf","poisonboy"]
	UI.place(art,328 if individual_sheet else 310,108 if individual_sheet else 112,548 if individual_sheet else 910,548 if individual_sheet else 425)
	UI.place(details,890 if individual_sheet else 310,200 if individual_sheet else 553,340 if individual_sheet else 910,250 if individual_sheet else 85)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(intro_button,880 if individual_sheet else 640,565 if individual_sheet else 641,350 if individual_sheet else 450,42)
	intro_button.text = "PLAY "+f.display_name.to_upper()+" INTRO"
	details.text = "%s · %s\nSpecial: %s\nUltimate: %s" % [f.display_name,f.archetype.replace("_"," "),f.special,f.ultimate]
