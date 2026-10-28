class_name CharacterSelect
extends Control
signal accepted(indices: Array[int])
signal back_requested
var roster: Array = []
var solo := false
var selected: Array[int] = [0,1]
var ready_players: Array[bool] = [false,false]
var mouse_player := 0
var cards: Array[Button] = []
var previews: Array[Label] = []
var ready_buttons: Array[Button] = []
var hint: Label
var cursor_buttons: Array[Button] = []

func _ready() -> void:
	theme = UI.theme()
	add_child(UI.place(UI.label("CHOOSE YOUR FIGHTER",36,UI.IVORY,true),40,40,1200,54))
	add_child(UI.place(UI.label("TEN LEGENDS. TWO READY FOR THE ARENA.",18,UI.MUTED),40,101,1200,28))
	for i in 10:
		var f: Dictionary = roster[i]
		var text: String = "%s\n%s\n%s" % [f.display_name.to_upper(),f.archetype.replace("_"," "),"PLAYABLE PROTOTYPE" if i < 2 else "COMING SOON"]
		var b := UI.button(text,func(): choose(mouse_player,i))
		UI.place(b,60+(i%5)*234,155+(i/5)*116,224,106)
		b.add_theme_font_size_override("font_size",18)
		add_child(b)
		cards.append(b)
	for i in 2:
		var p := i
		var x := 60+i*600
		var c := UI.CYAN if i == 0 else UI.ORANGE
		var cursor := UI.button("MOUSE EDITS P%d%s" % [i+1," / CPU" if solo and i == 1 else ""],func():
			mouse_player=p
			refresh())
		UI.place(cursor,x,403,560,42)
		add_child(cursor)
		cursor_buttons.append(cursor)
		var preview := UI.label("",20,c)
		UI.place(preview,x,458,560,96)
		add_child(preview)
		previews.append(preview)
		var ready_button := UI.button("READY",func(): confirm(p),true)
		UI.place(ready_button,x,561,420,44)
		add_child(ready_button)
		ready_buttons.append(ready_button)
		add_child(UI.place(UI.button("UNDO",func():
			ready_players[p]=false
			refresh()),x+432,561,128,44))
	hint = UI.label("P1  W A S D · F ready · G undo     |     P2  Arrows · I ready · O undo",18,UI.MUTED)
	UI.place(hint,50,623,1180,30)
	add_child(hint)
	add_child(UI.place(UI.button("BACK",func(): back_requested.emit()),60,666,160,40))
	refresh()

func choose(player: int, index: int) -> void:
	if ready_players[player]: return
	selected[player] = index
	refresh()

func confirm(player: int) -> void:
	if selected[player] >= 2:
		hint.text = "COMING SOON · Choose SharkByte or Bullet for this prototype."
		return
	ready_players[player] = true
	Sound.play("confirm")
	refresh()
	if ready_players[0] and ready_players[1]: accepted.emit(selected.duplicate())

func refresh() -> void:
	for i in 10:
		var color := Color("59424a")
		if selected[0] == i: color = UI.CYAN
		if selected[1] == i: color = UI.ORANGE
		if selected[0] == i and selected[1] == i: color = UI.GOLD
		cards[i].add_theme_stylebox_override("normal",UI.style(Color("19131e"),color,2))
	for p in 2:
		var f: Dictionary = roster[selected[p]]
		previews[p].text = "%s%s\n%s  /  %s\n%s" % [f.display_name," · CPU EASY" if solo and p == 1 else "",f.special,f.ultimate,"GEOMETRIC PROTOTYPE" if selected[p] < 2 else "PROFILE IN DEVELOPMENT"]
		ready_buttons[p].text = "READY ✓" if ready_players[p] else "P%d READY" % (p+1)
		cursor_buttons[p].modulate = UI.GOLD if mouse_player == p else Color.WHITE

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
