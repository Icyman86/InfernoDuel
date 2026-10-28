extends Control
const SelectScreen = preload("res://scripts/ui/character_select.gd")
const Options = preload("res://scripts/ui/options.gd")
const Gallery = preload("res://scripts/ui/gallery.gd")
const MatchScene = preload("res://scenes/combat/match.tscn")
var stage: Control
var screen: Control
var overlay: Control
var backdrop: Node2D
var match_node: DuelMatch
var roster: Array = []
var selected: Array[int] = [0,1]
var solo := false
var route := "menu"
var option_origin := "menu"
var modal: ConfirmationDialog

func _ready() -> void:
	roster = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json")).fighters
	stage = Control.new()
	stage.theme = UI.theme()
	stage.size = Vector2(1280,720)
	add_child(stage)
	backdrop = preload("res://scenes/arenas/infernal_citadel.tscn").instantiate()
	stage.add_child(backdrop)
	resized.connect(_resize_stage)
	_resize_stage()
	show_menu()

func _resize_stage() -> void:
	if not stage: return
	var factor := minf(size.x/1280.0,size.y/720.0)
	stage.scale = Vector2.ONE * factor
	stage.position = (size-Vector2(1280,720)*factor)*0.5

func clear_screen() -> void:
	InputRouter.clear()
	if screen:
		stage.remove_child(screen)
		screen.queue_free()
		screen = null
	clear_overlay()

func clear_overlay() -> void:
	if overlay:
		stage.remove_child(overlay)
		overlay.queue_free()
		overlay = null

func new_screen() -> Control:
	clear_screen()
	screen = Control.new()
	screen.size = Vector2(1280,720)
	stage.add_child(screen)
	return screen

func end_match() -> void:
	if is_instance_valid(match_node):
		stage.remove_child(match_node)
		match_node.queue_free()
	match_node = null

func show_menu() -> void:
	end_match()
	route = "menu"
	new_screen()
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.01,0.03,0.3)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(UI.place(shade,0,0,1280,720))
	screen.add_child(UI.place(UI.label("I N F E R N O",66,UI.IVORY,true),80,74,1120,92))
	screen.add_child(UI.place(UI.label("DUEL : LEGENDS",36,UI.GOLD,true),80,164,1120,54))
	screen.add_child(UI.place(UI.label("E N T E R   T H E   A R E N A",18,UI.MUTED),80,230,1120,30))
	var buttons := VBoxContainer.new()
	UI.place(buttons,440,293,400,340)
	screen.add_child(buttons)
	buttons.add_child(UI.button("LOCAL VERSUS",func(): show_select(false),true))
	buttons.add_child(UI.button("SOLO VS CPU",func(): show_select(true)))
	buttons.add_child(UI.button("STORY MODE",show_story))
	buttons.add_child(UI.button("FIGHTERS",show_gallery))
	buttons.add_child(UI.button("OPTIONS",func(): show_options("menu")))
	buttons.add_child(UI.button("QUIT",func(): confirm_action("Quit Inferno Duel: Legends?",func(): get_tree().quit())))
	buttons.get_child(0).grab_focus()
	screen.add_child(UI.place(UI.label("Made by Rens de Gee en Ted Sondervan",18,UI.IVORY),40,669,770,30))
	screen.add_child(UI.place(UI.label("LINUX PROTOTYPE v0.1",18,UI.MUTED),890,669,350,30))

func show_select(cpu: bool) -> void:
	end_match()
	clear_screen()
	route = "select"
	solo = cpu
	var picker := SelectScreen.new()
	picker.roster = roster
	picker.solo = solo
	picker.selected = selected.duplicate()
	picker.accepted.connect(func(indices: Array[int]):
		selected = indices
		show_arena())
	picker.back_requested.connect(show_menu)
	screen = picker
	stage.add_child(screen)

func show_arena() -> void:
	route = "arena"
	new_screen()
	screen.add_child(UI.place(UI.label("CHOOSE ARENA",40,UI.IVORY,true),40,65,1200,70))
	var panel := UI.panel()
	UI.place(panel,340,230,600,220)
	screen.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(UI.label("01 / INFERNAL CITADEL",30,UI.GOLD,true))
	box.add_child(UI.label("Broken stone. Molten depths. No escape.",20,UI.IVORY))
	box.add_child(UI.label("60 SECONDS · FIRST TO TWO ROUNDS",18,UI.MUTED))
	box.add_child(UI.label("%s   VS   %s" % [roster[selected[0]].display_name,roster[selected[1]].display_name],22,UI.CYAN))
	var start := UI.button("ENTER THE ARENA",start_match,true)
	screen.add_child(UI.place(start,440,510,400,56))
	start.grab_focus()
	screen.add_child(UI.place(UI.button("BACK",func(): show_select(solo)),440,586,400,46))
	screen.add_child(UI.place(UI.label("ENTER / F  fight     ·     ESC  back",18,UI.MUTED),300,659,680,30))

func start_match() -> void:
	clear_screen()
	end_match()
	route = "fight"
	match_node = MatchScene.instantiate()
	match_node.profiles = [roster[selected[0]],roster[selected[1]]]
	match_node.solo = solo
	match_node.completed.connect(show_result)
	stage.add_child(match_node)
	InputRouter.clear()

func make_overlay() -> VBoxContainer:
	clear_overlay()
	overlay = Control.new()
	overlay.size = Vector2(1280,720)
	stage.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.025,0.015,0.035,0.92)
	overlay.add_child(UI.place(shade,0,0,1280,720))
	var panel := UI.panel()
	overlay.add_child(UI.place(panel,390,150,500,460))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	return box

func show_pause() -> void:
	if not is_instance_valid(match_node): return
	match_node.set_stopped(true)
	route = "pause"
	var box := make_overlay()
	box.add_child(UI.label("PAUSED",40,UI.GOLD,true))
	box.add_child(UI.label("The citadel can wait.",18,UI.MUTED))
	box.add_child(UI.button("RESUME",resume_match,true))
	box.add_child(UI.button("RESTART MATCH",func(): confirm_action("Restart this match? The current score will be lost.",start_match)))
	box.add_child(UI.button("OPTIONS",func(): show_options("pause")))
	box.add_child(UI.button("MAIN MENU",func(): confirm_action("Leave the match? The current score will be lost.",show_menu)))
	box.get_child(2).grab_focus()

func resume_match() -> void:
	clear_overlay()
	InputRouter.clear()
	route = "fight"
	match_node.set_stopped(false)

func show_result(score: Array[int]) -> void:
	match_node.set_stopped(true)
	route = "result"
	var box := make_overlay()
	var winner := 0 if score[0] > score[1] else 1
	box.add_child(UI.label("P%d WINS" % (winner+1),44,UI.GOLD,true))
	box.add_child(UI.label(roster[selected[winner]].display_name.to_upper(),26,UI.IVORY))
	box.add_child(UI.label("%d : %d" % [score[0],score[1]],40,UI.IVORY,true))
	box.add_child(UI.button("REMATCH",start_match,true))
	box.add_child(UI.button("CHARACTER SELECT",func(): show_select(solo)))
	box.add_child(UI.button("MAIN MENU",show_menu))
	box.get_child(3).grab_focus()

func show_options(origin: String) -> void:
	option_origin = origin
	route = "options"
	if origin == "pause":
		make_overlay()
		for child in overlay.get_children(): child.queue_free()
		var shade := ColorRect.new()
		shade.color = Color("0b0911")
		overlay.add_child(UI.place(shade,0,0,1280,720))
		var options := Options.new()
		options.back_requested.connect(show_pause)
		overlay.add_child(options)
	else:
		clear_screen()
		var options := Options.new()
		options.back_requested.connect(show_menu)
		screen = options
		stage.add_child(screen)

func show_gallery() -> void:
	end_match()
	clear_screen()
	route = "gallery"
	var gallery := Gallery.new()
	gallery.roster = roster
	gallery.back_requested.connect(show_menu)
	screen = gallery
	stage.add_child(screen)

func show_story() -> void:
	end_match()
	route = "story"
	new_screen()
	screen.add_child(UI.place(UI.label("THE ABYSS IS CALLING",40,UI.GOLD,true),90,150,1100,70))
	screen.add_child(UI.place(UI.label("STORY MODE · COMING IN A LATER MILESTONE",22,UI.MUTED),90,245,1100,40))
	screen.add_child(UI.place(UI.label("SharkByte's campaign is still in development.\nFor now, enter the citadel in Local Versus or Solo vs CPU.",22,UI.IVORY),150,330,980,110))
	var back := UI.button("BACK TO MAIN MENU",show_menu,true)
	screen.add_child(UI.place(back,440,520,400,50))
	back.grab_focus()

func confirm_action(message: String, action: Callable) -> void:
	if is_instance_valid(modal) and modal.visible: return
	InputRouter.clear()
	var dialog := ConfirmationDialog.new()
	modal = dialog
	dialog.title = "INFERNO DUEL: LEGENDS"
	dialog.dialog_text = message
	dialog.confirmed.connect(func():
		dialog.hide()
		dialog.queue_free()
		action.call())
	dialog.canceled.connect(func():
		dialog.hide()
		dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(550,180))

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if is_instance_valid(modal) and modal.visible: return
	var key: int = event.physical_keycode if event.physical_keycode else event.keycode
	if key == KEY_ESCAPE:
		match route:
			"fight": show_pause()
			"pause": resume_match()
			"options":
				if option_origin == "pause": show_pause()
				else: show_menu()
			"select", "story", "gallery": show_menu()
			"arena": show_select(solo)
		get_viewport().set_input_as_handled()
	elif route == "select":
		screen.handle_key(key)
		get_viewport().set_input_as_handled()
	elif route == "arena" and (key == KEY_F or key == KEY_ENTER):
		start_match()
		get_viewport().set_input_as_handled()
	elif route == "fight" and key == KEY_F3:
		match_node.toggle_hitboxes()
	elif route != "fight":
		# Native keyboard focus plus W/S and either fighter's confirm key.
		if key in [KEY_W,KEY_S]:
			var focused := get_viewport().gui_get_focus_owner()
			if focused:
				var next := focused.find_prev_valid_focus() if key == KEY_W else focused.find_next_valid_focus()
				if next: next.grab_focus()
			get_viewport().set_input_as_handled()
		elif key in [KEY_F,KEY_I]:
			var focused := get_viewport().gui_get_focus_owner()
			if focused is Button: focused.pressed.emit()
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and route == "fight":
		show_pause()
