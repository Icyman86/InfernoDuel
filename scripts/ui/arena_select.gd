class_name ArenaSelect
extends Control
signal chosen(id: String)
signal back_requested
var can_choose := true
var selection := "citadel"
var cards: Array[Button] = []
var hint: Label
var start_button: Button
var random_button: Button
func _ready() -> void:
	theme = UI.theme()
	var shade := ColorRect.new()
	shade.color = Color("090e19")
	add_child(UI.place(shade,0,0,1280,720))
	add_child(UI.place(UI.label("CHOOSE YOUR ARENA",36,UI.IVORY,true),60,55,1160,65))
	add_child(UI.place(UI.label("PICK A MAP OR LET RANDOM CHOOSE" if can_choose else "THE HOST IS CHOOSING THE ARENA",19,UI.GOLD),80,135,1120,36))
	var entries := ArenaCatalog.entries()
	for i in entries.size():
		var arena: Dictionary = entries[i]
		var id: String = arena.id
		var card := UI.button("",func(): select(id))
		card.disabled = not can_choose
		add_child(UI.place(card,40+i*408,208,384,260))
		cards.append(card)
		var art := TextureRect.new()
		art.texture = load("res://"+arena.path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(UI.place(art,6,6,372,204))
		var label := UI.label(str(arena.name).to_upper(),18,UI.IVORY,true)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(UI.place(label,6,216,372,34))
	hint = UI.label("",18,UI.MUTED)
	add_child(UI.place(hint,60,486,1160,45))
	random_button = UI.button("RANDOM",func(): select("random"))
	random_button.disabled = not can_choose
	add_child(UI.place(random_button,90,560,275,56))
	start_button = UI.button("ENTER THE ARENA",confirm,true)
	start_button.disabled = not can_choose
	add_child(UI.place(start_button,400,560,480,56))
	add_child(UI.place(UI.button("BACK",func(): back_requested.emit()),915,560,275,56))
	select(selection)
	if can_choose: start_button.grab_focus()
func select(id: String) -> void:
	if id != "random" and not ArenaCatalog.valid(id): return
	selection = id
	var entries := ArenaCatalog.entries()
	for i in cards.size():
		cards[i].add_theme_stylebox_override("normal",UI.style(Color("101a2a"),UI.GOLD if entries[i].id == id else Color("344158"),3 if entries[i].id == id else 1))
	random_button.add_theme_stylebox_override("normal",UI.style(Color("152033"),UI.GOLD if id == "random" else Color("344158"),3 if id == "random" else 1))
	hint.text = "RANDOM · one arena is drawn when the host starts" if id == "random" else ArenaCatalog.get_arena(id).description
	if not can_choose: hint.text = "Both devices will load the same map selected by the host."
func confirm() -> void:
	if can_choose: chosen.emit(ArenaCatalog.resolve(selection))
