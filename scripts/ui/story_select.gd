class_name StorySelect
extends Control
signal level_chosen(index: int)
signal back_requested
var roster: Array = []
var cards: Array[Button] = []

func _ready() -> void:
	theme = UI.theme()
	var shade := ColorRect.new()
	shade.color = Color(.02,.025,.04,.92)
	add_child(UI.place(shade,0,0,1280,720))
	add_child(UI.place(UI.label("SHARKBYTE · CHAPTER ONE",18,UI.CYAN),40,34,1200,34))
	add_child(UI.place(UI.label(StoryCatalog.campaign().title,38,UI.IVORY,true),40,78,1200,60))
	add_child(UI.place(UI.label("%d / 4 LEVELS COMPLETE · %d COINS" % [Progression.story_completed,Progression.coins],18,UI.GOLD),40,140,1200,30))
	var arenas := ArenaCatalog.entries()
	for i in StoryCatalog.levels().size():
		var index := i
		var level: Dictionary = StoryCatalog.levels()[i]
		var profile: Dictionary = roster[StoryCatalog.fighter_index(roster,level.opponent)]
		var card := UI.button("",func(): level_chosen.emit(index))
		card.disabled = not Progression.story_available(i)
		add_child(UI.place(card,40+i*310,195,280,345))
		cards.append(card)
		var number := UI.label("LEVEL %d" % (i+1),16,UI.CYAN)
		card.add_child(UI.place(number,8,9,264,26))
		var portrait := FighterPortrait.new()
		portrait.setup(profile)
		card.add_child(UI.place(portrait,105,42,70,92))
		card.add_child(UI.place(UI.label(profile.display_name.to_upper(),22,UI.IVORY),8,139,264,32))
		for arena in arenas:
			if arena.id != level.arena: continue
			var art := TextureRect.new()
			art.texture = load("res://"+str(arena.path))
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			card.add_child(UI.place(art,10,184,260,115))
		var status := "COMPLETE · REPLAY" if i < Progression.story_completed else ("PLAY LEVEL" if Progression.story_available(i) else "WIN PREVIOUS LEVEL")
		card.add_child(UI.place(UI.label(status,15,UI.GOLD if Progression.story_available(i) else UI.MUTED),8,307,264,28))
		for child in card.get_children():
			if child is Control: child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.place(UI.label("Play as SharkByte · Win two rounds to advance · Win +5 coins / Lose +1",18,UI.MUTED),70,570,1140,50))
	add_child(UI.place(UI.button("BACK TO MAIN MENU",func(): back_requested.emit()),440,648,400,46))
	cards[mini(Progression.story_completed,cards.size()-1)].grab_focus()
