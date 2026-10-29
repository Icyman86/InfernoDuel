class_name CharacterSelect
extends Control
signal accepted(indices: Array[int])
signal back_requested
var roster: Array = []
var solo := false
var touch_mode := false
var selected: Array[int] = [0,1]
var ready_players: Array[bool] = [false,false]
var mouse_player := 0
var cards: Array[Button] = []
var previews: Array[Label] = []
var ready_buttons: Array[Button] = []
var cursor_buttons: Array[Button] = []
var hero_holders: Array[Control] = []
var hero_names: Array[Label] = []
var hero_ids: Array[String] = ["",""]
var badges: Array[Label] = []
var hint: Label

func _ready() -> void:
	theme = UI.theme()
	var shade := ColorRect.new()
	shade.color = Color(0.015,0.012,0.026,0.83)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.place(shade,0,0,1280,720))
	add_child(UI.place(UI.label("THE CITADEL AWAITS",16,UI.GOLD),300,32,680,28))
	add_child(UI.place(UI.label("CHOOSE YOUR FIGHTER",33,UI.IVORY,true),290,66,700,50))
	add_child(UI.place(UI.label("SOLO  /  CPU EASY" if solo else ("LOCAL VERSUS  /  SHARED TOUCHSCREEN" if touch_mode else "LOCAL VERSUS  /  ONE KEYBOARD"),16,UI.MUTED),300,122,680,25))
	for i in 10:
		var index := i
		var f: Dictionary = roster[i]
		var b := UI.button("",func(): choose(mouse_player,index))
		UI.place(b,300+(i%5)*138,174+(i/5)*185,130,173)
		b.clip_contents = true
		add_child(b)
		var portrait := FighterPortrait.new()
		portrait.setup(f)
		b.add_child(UI.place(portrait,3,3,124,128))
		if not f.get("playable",false): portrait.modulate = Color(0.68,0.62,0.66)
		var stripe := ColorRect.new()
		stripe.color = Color(f.accent)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(UI.place(stripe,3,126,124,2))
		var name_label := UI.label(f.display_name.to_upper().replace(" ","\n"),16,UI.IVORY)
		if not " " in f.display_name: name_label.text = f.display_name.to_upper()
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b.add_child(UI.place(name_label,2,131,126,40))
		var badge := UI.label("",14,UI.GOLD)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(UI.place(badge,4,7,122,21))
		badges.append(badge)
		cards.append(b)
	add_child(UI.place(UI.label("SELECT YOUR LEGEND",16,UI.MUTED),300,556,680,28))
	add_child(UI.place(UI.label("ALL TEN FIGHTERS READY · TRY THEIR MOVES IN FIGHTERS",16,UI.MUTED),260,588,760,26))
	for i in 2:
		var p := i
		var x := 34+i*1004
		var c := UI.CYAN if i == 0 else UI.ORANGE
		var panel := UI.panel()
		panel.add_theme_stylebox_override("panel",UI.style(Color(0.035,0.03,0.055,0.8),Color(c,0.3)))
		add_child(UI.place(panel,x,165,208,389))
		var player_label := UI.label("PLAYER ONE" if i == 0 else ("CPU OPPONENT" if solo else "PLAYER TWO"),16,c)
		add_child(UI.place(player_label,x-10,120,228,30))
		var name_label := UI.label("",23,c,true)
		add_child(UI.place(name_label,x-15,170,238,44))
		hero_names.append(name_label)
		var holder := Control.new()
		UI.place(holder,x,222,208,255)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(holder)
		hero_holders.append(holder)
		var preview := UI.label("",16,UI.IVORY)
		preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(UI.place(preview,x+4,480,200,65))
		previews.append(preview)
		var cursor := UI.button("EDIT P%d%s" % [p+1," / CPU" if solo and p == 1 else ""],func():
			mouse_player=p
			refresh())
		cursor.add_theme_font_size_override("font_size",16)
		add_child(UI.place(cursor,x,565,208,40))
		cursor_buttons.append(cursor)
		var ready_button := UI.button("READY",func(): confirm(p),true)
		add_child(UI.place(ready_button,x,613,148,43))
		ready_buttons.append(ready_button)
		var undo := UI.button("↶",func():
			ready_players[p]=false
			refresh())
		undo.tooltip_text = "Undo ready: G / O"
		add_child(UI.place(undo,x+156,613,52,43))
	hint = UI.label("P1  W A S D · F ready · G undo       /       P2  Arrows · I ready · O undo",17,UI.MUTED)
	if touch_mode:
		hint.text = "TAP A FIGHTER · EDIT P2 / CPU TO PICK OPPONENT · READY BOTH SIDES"
	add_child(UI.place(hint,220,675,1000,28))
	add_child(UI.place(UI.button("BACK",func(): back_requested.emit()),34,675,150,38))
	refresh()

func choose(player: int, index: int) -> void:
	if ready_players[player]: return
	selected[player] = index
	Sound.play("confirm")
	refresh()

func confirm(player: int) -> void:
	if not roster[selected[player]].get("playable",false):
		hint.text = "IN DEVELOPMENT · Choose a highlighted playable fighter."
		return
	ready_players[player] = true
	Sound.play("confirm")
	refresh()
	if ready_players[0] and ready_players[1]: accepted.emit(selected.duplicate())

func refresh() -> void:
	for i in 10:
		var color := Color("473944")
		var badge := ""
		if selected[0] == i:
			color = UI.CYAN
			badge = "P1"
		if selected[1] == i:
			color = UI.ORANGE
			badge += "   CPU" if solo else "   P2"
		if selected[0] == i and selected[1] == i: color = UI.GOLD
		cards[i].add_theme_stylebox_override("normal",UI.style(Color("15111a"),color,2))
		badges[i].text = badge.strip_edges() if badge != "" else ("COMING SOON" if not roster[i].get("playable",false) else "")
		badges[i].add_theme_color_override("font_color",color if badge != "" else UI.MUTED)
	for p in 2:
		var f: Dictionary = roster[selected[p]]
		hero_names[p].text = f.display_name.to_upper().replace(" ","\n")
		previews[p].text = "%s\n%s" % [f.special,f.ultimate]
		ready_buttons[p].text = "READY ✓" if ready_players[p] else "READY"
		cursor_buttons[p].modulate = (UI.CYAN if p == 0 else UI.ORANGE) if mouse_player == p else Color.WHITE
		if hero_ids[p] != f.id:
			for child in hero_holders[p].get_children():
				hero_holders[p].remove_child(child)
				child.queue_free()
			hero_ids[p] = f.id
			if f.get("playable",false):
				var figure := FighterVisual.new()
				figure.profile = f
				figure.accent = UI.CYAN if p == 0 else UI.ORANGE
				figure.target_height = 240
				figure.position = Vector2(104,250)
				figure.scale.x = 1 if p == 0 else -1
				hero_holders[p].add_child(figure)
			else:
				var portrait := FighterPortrait.new()
				portrait.setup(f)
				hero_holders[p].add_child(UI.place(portrait,9,10,190,228))

func handle_key(code: int) -> void:
	for p in 2:
		var left := KEY_A if p == 0 else KEY_LEFT
		var right := KEY_D if p == 0 else KEY_RIGHT
		var up := KEY_W if p == 0 else KEY_UP
		var down := KEY_S if p == 0 else KEY_DOWN
		var accept := KEY_F if p == 0 else KEY_I
		var undo := KEY_G if p == 0 else KEY_O
		if code == undo:
			ready_players[p] = false
			refresh()
		elif code == accept: confirm(p)
		elif not ready_players[p]:
			var offset := 0
			if code == left: offset = -1
			elif code == right: offset = 1
			elif code == up or code == down: offset = 5
			if offset != 0: choose(p,posmod(selected[p]+offset,10))
