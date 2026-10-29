extends Control
const SelectScreen = preload("res://scripts/ui/character_select.gd")
const Options = preload("res://scripts/ui/options.gd")
const Gallery = preload("res://scripts/ui/gallery.gd")
const MatchScene = preload("res://scenes/combat/match.tscn")
const ConnectionScreen = preload("res://scripts/ui/online_lobby.gd")
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
var gallery_index := 0
var touch_controls: TouchControls
var touch_mode := OS.has_feature("android") or "--touch" in OS.get_cmdline_user_args()
var networked := false
var network_driver: NetworkMatchDriver

func _ready() -> void:
	get_tree().quit_on_go_back = false
	OnlineSession.lobby_changed.connect(_network_lobby_changed)
	OnlineSession.match_started.connect(_network_match_started)
	OnlineSession.match_finished.connect(show_result)
	OnlineSession.pause_changed.connect(_network_pause_changed)
	OnlineSession.disconnected.connect(_network_disconnected)
	roster = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json")).fighters
	stage = Control.new()
	stage.theme = UI.theme()
	stage.size = Vector2(1280,720)
	add_child(stage)
	backdrop = preload("res://scenes/arenas/infernal_citadel.tscn").instantiate()
	stage.add_child(backdrop)
	resized.connect(_resize_stage)
	_resize_stage()
	if touch_mode:
		touch_controls = TouchControls.new()
		add_child(touch_controls)
		touch_controls.pause_requested.connect(show_pause)
	show_menu()

func _resize_stage() -> void:
	if not stage: return
	var safe := TouchControls.safe_rect(get_viewport())
	var factor := minf(safe.size.x/1280.0,safe.size.y/720.0)
	stage.scale = Vector2.ONE * factor
	stage.position = safe.position + (safe.size-Vector2(1280,720)*factor)*0.5

func _process(_delta: float) -> void:
	if touch_controls:
		touch_controls.set_active(route == "fight")

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
	network_driver = null

func show_menu() -> void:
	if OnlineSession.active(): OnlineSession.close()
	networked = false
	end_match()
	route = "menu"
	new_screen()
	var shade := ColorRect.new()
	shade.color = Color(0.012,0.008,0.023,0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(UI.place(shade,0,0,1280,720))
	var side := ColorRect.new()
	side.color = Color(0.018,0.012,0.032,0.6)
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(UI.place(side,0,0,610,720))
	screen.add_child(UI.place(UI.label("O N E   A R E N A .   T E N   L E G E N D S .",16,UI.GOLD),65,50,550,32))
	var title := UI.label("INFERNO",69,UI.IVORY,true)
	title.add_theme_constant_override("outline_size",5)
	title.add_theme_color_override("font_outline_color",Color("241420"))
	screen.add_child(UI.place(title,45,95,600,100))
	screen.add_child(UI.place(UI.label("D U E L : L E G E N D S",29,UI.GOLD,true),45,189,600,53))
	screen.add_child(UI.place(UI.label("ENTER THE CITADEL",16,UI.MUTED),65,258,550,25))
	for i in [1,0]:
		var hero := FighterVisual.new()
		hero.profile = roster[i]
		hero.accent = UI.CYAN if i == 0 else UI.ORANGE
		hero.target_height = 420 if i == 0 else 370
		hero.preview_pose = "guard" if i == 0 else "idle"
		hero.position = Vector2(832 if i == 0 else 1089,648 if i == 0 else 610)
		hero.scale.x = -1 if i == 1 else 1
		screen.add_child(hero)
	var buttons := VBoxContainer.new()
	UI.place(buttons,140,311 if touch_mode else 288,390,370)
	screen.add_child(buttons)
	if touch_mode:
		buttons.add_child(UI.button("CONNECT · SESSION CODE",show_online,true))
		buttons.add_child(UI.button("PLAY · TOUCH VS CPU",func(): show_select(true)))
	else:
		buttons.add_child(UI.button("LOCAL VERSUS",func(): show_select(false),true))
		buttons.add_child(UI.button("SOLO VS CPU",func(): show_select(true)))
		buttons.add_child(UI.button("CONNECT · SESSION CODE",show_online))
	buttons.add_child(UI.button("STORY MODE",show_story))
	buttons.add_child(UI.button("FIGHTERS",show_gallery))
	buttons.add_child(UI.button("OPTIONS",func(): show_options("menu")))
	buttons.add_child(UI.button("QUIT",func(): confirm_action("Quit Inferno Duel: Legends?",func(): get_tree().quit())))
	buttons.get_child(0).grab_focus()
	screen.add_child(UI.place(UI.label("Made by Rens de Gee en Ted Sondervan",16,UI.IVORY),35,677,630,28))
	screen.add_child(UI.place(UI.label("INFERNAL CITADEL  /  V7",14,UI.MUTED),920,677,320,28))

func show_select(cpu: bool) -> void:
	if touch_mode and not cpu:
		show_online()
		return
	networked = false
	end_match()
	clear_screen()
	route = "select"
	solo = cpu
	var picker := SelectScreen.new()
	picker.roster = roster
	picker.solo = solo
	picker.touch_mode = touch_mode
	picker.selected = selected.duplicate()
	picker.accepted.connect(func(indices: Array[int]):
		selected = indices
		show_arena())
	picker.back_requested.connect(show_menu)
	screen = picker
	stage.add_child(screen)

func show_online() -> void:
	end_match()
	clear_screen()
	route = "online"
	var connection := ConnectionScreen.new()
	connection.back_requested.connect(show_menu)
	screen = connection
	stage.add_child(connection)

func _network_lobby_changed() -> void:
	if route == "online" and OnlineSession.phase == "lobby":
		networked = true
		clear_screen()
		route = "network_select"
		var picker := SelectScreen.new()
		picker.roster = roster
		picker.touch_mode = touch_mode
		picker.online_slot = OnlineSession.local_slot
		picker.selected.assign(OnlineSession.selected)
		picker.ready_players.assign(OnlineSession.ready_players)
		picker.network_choice.connect(OnlineSession.choose)
		picker.network_ready.connect(OnlineSession.ready_up)
		picker.back_requested.connect(show_menu)
		screen = picker
		stage.add_child(picker)
	elif route == "network_select":
		screen.apply_network_state(OnlineSession.selected, OnlineSession.ready_players)
	elif route == "online":
		screen.refresh()

func _network_match_started(indices: Array[int], _generation: int) -> void:
	networked = true
	solo = false
	selected.assign(indices)
	start_match()

func _network_disconnected(_reason: String) -> void:
	if route in ["online","network_select","fight","pause","options","result"]:
		networked = false
		show_online()

func show_arena() -> void:
	route = "arena"
	new_screen()
	screen.add_child(UI.place(UI.label("CHOOSE ARENA",40,UI.IVORY,true),40,65,1200,70))
	for i in 2:
		var portrait := FighterPortrait.new()
		portrait.setup(roster[selected[i]])
		screen.add_child(UI.place(portrait,110 if i == 0 else 980,230,190,220))
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
	screen.add_child(UI.place(UI.label("TAP ENTER THE ARENA TO FIGHT" if touch_mode else "ENTER / F  fight     ·     ESC  back",18,UI.MUTED),300,659,680,30))

func start_match() -> void:
	if touch_mode and not solo and not networked:
		show_online()
		return
	clear_screen()
	end_match()
	route = "fight"
	if touch_controls:
		touch_controls.solo = true if networked else solo
		touch_controls.local_team = OnlineSession.local_slot if networked else 0
		touch_controls.rebuild()
	match_node = MatchScene.instantiate()
	match_node.profiles = [roster[selected[0]],roster[selected[1]]]
	match_node.solo = solo
	match_node.local_network_slot = OnlineSession.local_slot if networked else -1
	if networked:
		if OnlineSession.local_slot == 0: match_node.completed.connect(OnlineSession.complete_match)
	else:
		match_node.completed.connect(show_result)
	stage.add_child(match_node)
	if touch_controls: touch_controls.match_state = match_node
	if networked:
		network_driver = NetworkMatchDriver.new()
		match_node.add_child(network_driver)
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
	if networked:
		OnlineSession.request_pause(true)
		return
	_render_pause()

func _render_pause() -> void:
	if not is_instance_valid(match_node): return
	match_node.set_stopped(true)
	route = "pause"
	var box := make_overlay()
	box.add_child(UI.label("PAUSED",40,UI.GOLD,true))
	box.add_child(UI.label("Both players must resume to continue." if networked else "The citadel can wait.",18,UI.MUTED))
	box.add_child(UI.button("RESUME",resume_match,true))
	if not networked: box.add_child(UI.button("RESTART MATCH",func(): confirm_action("Restart this match? The current score will be lost.",start_match)))
	box.add_child(UI.button("OPTIONS",func(): show_options("pause")))
	box.add_child(UI.button("MAIN MENU",func(): confirm_action("Leave the match? The current score will be lost.",show_menu)))
	box.get_child(2).grab_focus()

func resume_match() -> void:
	if networked:
		OnlineSession.request_pause(false)
		return
	_resume_local()

func _resume_local() -> void:
	clear_overlay()
	InputRouter.clear()
	route = "fight"
	match_node.set_stopped(false)

func _network_pause_changed(paused: bool) -> void:
	if not networked or not is_instance_valid(match_node): return
	if OnlineSession.local_slot == 1 and is_instance_valid(network_driver) and not OnlineSession.latest_snapshot.is_empty():
		network_driver.apply_snapshot(OnlineSession.latest_snapshot)
		network_driver.applied_sequence = OnlineSession.snapshot_revision
	match_node.set_stopped(paused)
	if paused and route in ["fight", "pause"]: _render_pause()
	elif not paused and route in ["fight","pause","options"]: _resume_local()

func show_result(score: Array[int]) -> void:
	if not is_instance_valid(match_node): return
	match_node.wins.assign(score)
	match_node.phase = "complete"
	match_node.set_stopped(true)
	route = "result"
	var box := make_overlay()
	var winner := 0 if score[0] > score[1] else 1
	var hero := FighterVisual.new()
	hero.profile = roster[selected[winner]]
	hero.target_height = 330
	hero.position = Vector2(198,590)
	hero.accent = UI.CYAN if winner == 0 else UI.ORANGE
	overlay.add_child(hero)
	box.add_child(UI.label("P%d WINS" % (winner+1),44,UI.GOLD,true))
	box.add_child(UI.label(roster[selected[winner]].display_name.to_upper(),26,UI.IVORY))
	box.add_child(UI.label("%d : %d" % [score[0],score[1]],40,UI.IVORY,true))
	if networked:
		var rematch := UI.button("REMATCH",func():
			OnlineSession.request_rematch()
			if is_instance_valid(overlay):
				var button: Button = box.get_child(3)
				button.text = "WAITING FOR OPPONENT…"
				button.disabled = true,true)
		box.add_child(rematch)
	else:
		box.add_child(UI.button("REMATCH",start_match,true))
		box.add_child(UI.button("CHARACTER SELECT",func(): show_select(solo)))
	box.add_child(UI.button("MAIN MENU",show_menu))
	box.get_child(3).grab_focus()

func show_options(origin: String) -> void:
	option_origin = origin
	route = "options"
	if origin == "pause":
		if networked: OnlineSession.request_pause(true)
		make_overlay()
		for child in overlay.get_children(): child.queue_free()
		var shade := ColorRect.new()
		shade.color = Color("0b0911")
		overlay.add_child(UI.place(shade,0,0,1280,720))
		var options := Options.new()
		options.touch_mode = touch_mode
		options.back_requested.connect(_render_pause)
		overlay.add_child(options)
	else:
		clear_screen()
		var options := Options.new()
		options.touch_mode = touch_mode
		options.back_requested.connect(show_menu)
		screen = options
		stage.add_child(screen)

func show_gallery() -> void:
	end_match()
	clear_screen()
	route = "gallery"
	var gallery := Gallery.new()
	gallery.roster = roster
	gallery.current = gallery_index
	gallery.intro_requested.connect(show_fighter_intro)
	gallery.back_requested.connect(show_menu)
	screen = gallery
	stage.add_child(screen)

func show_fighter_intro(index: int) -> void:
	gallery_index = index
	clear_screen()
	route = "intro"
	var player := FighterIntroPlayer.new()
	player.profile = roster[index]
	player.back_requested.connect(show_gallery)
	screen = player
	stage.add_child(screen)

func show_story() -> void:
	end_match()
	route = "story"
	new_screen()
	screen.add_child(UI.place(UI.label("THE ABYSS IS CALLING",40,UI.GOLD,true),90,150,1100,70))
	screen.add_child(UI.place(UI.label("STORY MODE · COMING IN A LATER MILESTONE",22,UI.MUTED),90,245,1100,40))
	screen.add_child(UI.place(UI.label("SharkByte's campaign is still in development.\nFor now, play Solo vs CPU or connect with a session code." if touch_mode else "SharkByte's campaign is still in development.\nFor now, enter the citadel in Local Versus or Solo vs CPU.",22,UI.IVORY),150,330,980,110))
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
	var typing := get_viewport().gui_get_focus_owner()
	if typing is LineEdit and key not in [KEY_ESCAPE,KEY_BACK]: return
	if key == KEY_ESCAPE or key == KEY_BACK:
		go_back()
		get_viewport().set_input_as_handled()
	elif route in ["select","network_select"]:
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

func go_back() -> void:
	if is_instance_valid(modal) and modal.visible:
		modal.hide()
		modal.queue_free()
		return
	match route:
		"fight": show_pause()
		"pause": resume_match()
		"options":
			if option_origin == "pause": show_pause()
			else: show_menu()
		"select", "story", "gallery", "online", "network_select": show_menu()
		"intro": show_gallery()
		"arena": show_select(solo)
		"menu": confirm_action("Quit Inferno Duel: Legends?",func(): get_tree().quit())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and route == "fight":
		show_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()
