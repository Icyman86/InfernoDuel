class_name FighterGallery
extends Control
signal back_requested
var roster: Array = []
var current := 0
var art: TextureRect
var details: Label

func _ready() -> void:
	theme = UI.theme()
	add_child(UI.place(UI.label("THE LEGENDS",36,UI.IVORY,true),40,35,1200,60))
	for i in 10:
		var index := i
		add_child(UI.place(UI.button(roster[i].display_name.to_upper(),func(): show_fighter(index)),40,117+i*48,245,42))
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UI.place(art,310,112,910,425)
	add_child(art)
	details = UI.label("",20,UI.GOLD)
	UI.place(details,310,553,910,85)
	add_child(details)
	add_child(UI.place(UI.label("ORIGINAL CONCEPT / MOVE SHEETS · Reference art, not gameplay animation frames.",18,UI.MUTED),300,650,940,30))
	add_child(UI.place(UI.button("BACK",func(): back_requested.emit()),40,644,245,46))
	show_fighter(0)
	get_child(1).grab_focus()

func show_fighter(index: int) -> void:
	current = index
	var f: Dictionary = roster[index]
	art.texture = load("res://"+f.reference_art_path)
	details.text = "%s · %s\nSpecial: %s\nUltimate: %s" % [f.display_name,f.archetype.replace("_"," "),f.special,f.ultimate]
