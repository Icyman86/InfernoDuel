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
var arena_choice := "citadel"
var solo := false
var route := "menu"
var option_origin := "menu"
var modal: ConfirmationDialog
var gallery_index := 0
var touch_controls: TouchControls
var touch_mode := GamePlatform.touch_enabled()
var networked := false
var network_driver: NetworkMatchDriver
var reward_id := ""
var reward_amount := 0
var story_mode := false
var story_index := 0
var menu_pair: Array[int] = []
var menu_previews: Array[FighterIllustration] = []

func _ready() -> void:
	get_tree().quit_on_go_back = false
	InputRouter.controller_action.connect(_controller_action)
	InputRouter.controller_removed.connect(func(_player: int):
		if route == "fight": show_pause())
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
		touch_controls.safe_area_changed.connect(_resize_stage)
	show_menu()

func _resize_stage() -> void:
	if not stage: return
	var safe := TouchControls.safe_rect(get_viewport())
	var factor := minf(safe.size.x/1280.0,safe.size.y/720.0)
	stage.scale = Vector2.ONE * factor
	stage.position = safe.position + (safe.size-Vector2(1280,720)*factor)*0.5
	if is_instance_valid(backdrop):
		backdrop.view_rect = Rect2(-stage.position/factor,get_viewport().get_visible_rect().size/factor)
		backdrop.queue_redraw()
	if is_instance_valid(match_node):
		match_node.layout_hud(Rect2((safe.position-stage.position)/factor,safe.size/factor))

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
	story_mode = false
	if OnlineSession.active(): OnlineSession.close()
	networked = false
	end_match()
	route = "menu"
	if is_instance_valid(backdrop): backdrop.choose_arena("citadel")
	new_screen()
	var shade := ColorRect.new()
	shade.color = Color(0.012,0.008,0.023,0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(UI.place(shade,0,0,1280,720))
	var side := ColorRect.new()
	side.color = Color(0.018,0.012,0.032,0.6)
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(UI.place(side,0,0,610,720))
	screen.add_child(UI.place(UI.label("F O U R   A R E N A S .   T W E L V E   L E G E N D S .",16,UI.GOLD),65,50,550,32))
	var title := UI.label("INFERNO",69,UI.IVORY,true)
	title.add_theme_constant_override("outline_size",5)
	title.add_theme_color_override("font_outline_color",Color("241420"))
	screen.add_child(UI.place(title,45,95,600,100))
	screen.add_child(UI.place(UI.label("D U E L : L E G E N D S",29,UI.GOLD,true),45,189,600,53))
	screen.add_child(UI.place(UI.label("ENTER THE CITADEL",16,UI.MUTED),65,258,550,25))
	var pair: Array[int] = [randi_range(0,roster.size()-1),0]
	pair[1] = posmod(pair[0]+randi_range(1,roster.size()-1),roster.size())
	if pair == menu_pair: pair.reverse()
	menu_pair.assign(pair)
	menu_previews.clear()
	for side_index in 2:
		var hero := FighterIllustration.new()
		hero.profile = roster[menu_pair[side_index]]
		hero.custom_size = Vector2(285,430)
		hero.show_background = false
		hero.facing = 1 if side_index == 0 else -1
		hero.position = Vector2(650+side_index*320,210)
		screen.add_child(hero)
		menu_previews.append(hero)
		var color := UI.CYAN if side_index == 0 else UI.ORANGE
		screen.add_child(UI.place(UI.label(hero.profile.display_name.to_upper(),18,color),650+side_index*320,646,285,28))
	screen.add_child(UI.place(UI.label("VS",24,UI.GOLD,true),934,396,40,40))
	screen.add_child(UI.place(UI.label("%d COINS · WIN +5 / LOSE +1" % Progression.coins,16,UI.GOLD),680,55,550,30))
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
	if not OS.has_feature("ios"):
		buttons.add_child(UI.button("QUIT",func(): confirm_action("Quit Inferno Duel: Legends?",func(): get_tree().quit())))
	buttons.get_child(0).grab_focus()
	screen.add_child(UI.place(UI.label("Made by Rens de Gee en Ted Sondervan",16,UI.IVORY),35,677,630,28))
	screen.add_child(UI.place(UI.label("V17 · SHARKBYTE STORY",14,UI.MUTED),920,677,320,28))

func show_select(cpu: bool) -> void:
	story_mode = false
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
	story_mode = false
	end_match()
	clear_screen()
	route = "online"
	var connection := ConnectionScreen.new()
	connection.back_requested.connect(show_menu)
	screen = connection
	stage.add_child(connection)

func _network_lobby_changed() -> void:
	if OnlineSession.phase == "arena":
		networked = true
		show_arena()
		return
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
	arena_choice = OnlineSession.selected_arena
	start_match()

func _network_disconnected(_reason: String) -> void:
	if route in ["online","network_select","arena","fight","pause","options","result"]:
		networked = false
		show_online()

func show_arena() -> void:
	route = "arena"
	clear_screen()
	var picker := ArenaSelect.new()
	picker.selection = arena_choice
	picker.can_choose = not networked or OnlineSession.local_slot == 0
	picker.chosen.connect(func(id: String):
		if networked: OnlineSession.start_arena(id)
		else:
			arena_choice = id
			start_match())
	picker.back_requested.connect(func():
		if networked: show_menu()
		else: show_select(solo))
	screen = picker
	stage.add_child(screen)

func start_match() -> void:
	reward_id = Progression.match_id()
	reward_amount = 0
	if touch_mode and not solo and not networked:
		show_online()
		return
	clear_screen()
	end_match()
	route = "fight"
	backdrop.choose_arena(arena_choice)
	if touch_controls:
		touch_controls.solo = true if networked else solo
		touch_controls.local_team = OnlineSession.local_slot if networked else 0
		touch_controls.rebuild()
	match_node = MatchScene.instantiate()
	match_node.profiles = [roster[selected[0]],roster[selected[1]]]
	match_node.solo = solo
	match_node.modern_rules = not touch_mode and not networked and not story_mode and arena_choice == "citadel"
	match_node.local_network_slot = OnlineSession.local_slot if networked else -1
	if networked:
		if OnlineSession.local_slot == 0: match_node.completed.connect(OnlineSession.complete_match)
	else:
		match_node.completed.connect(show_result)
	stage.add_child(match_node)
	_resize_stage()
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
	var local_player := OnlineSession.local_slot if networked else 0
	var earned := Progression.award_match(reward_id,score,local_player)
	if earned > 0: reward_amount = earned
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
	var reward_label := UI.label("+%d COINS · BALANCE %d" % [reward_amount,Progression.coins],20,UI.GOLD)
	if reward_amount == 0 and not Progression.last_error.is_empty(): reward_label.text = Progression.last_error
	box.add_child(reward_label)
	if story_mode:
		story_result(box,score)
	elif networked:
		var rematch := UI.button("REMATCH",func():
			OnlineSession.request_rematch()
			if is_instance_valid(overlay):
				var button: Button = box.get_child(4)
				button.text = "WAITING FOR OPPONENT…"
				button.disabled = true,true)
		box.add_child(rematch)
	else:
		box.add_child(UI.button("REMATCH",start_match,true))
		box.add_child(UI.button("CHARACTER SELECT",func(): show_select(solo)))
	box.add_child(UI.button("MAIN MENU",show_menu))
	box.get_child(4).grab_focus()

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
	story_mode = false
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
	story_mode = false
	if OnlineSession.active(): OnlineSession.close()
	networked = false
	end_match()
	clear_screen()
	route = "story"
	backdrop.choose_arena("citadel")
	var picker := StorySelect.new()
	picker.roster = roster
	picker.level_chosen.connect(show_story_briefing)
	picker.back_requested.connect(show_menu)
	screen = picker
	stage.add_child(screen)

func show_story_briefing(index: int) -> void:
	if not Progression.story_available(index): return
	story_index = index
	story_mode = false
	end_match()
	route = "story_briefing"
	new_screen()
	var level: Dictionary = StoryCatalog.levels()[index]
	backdrop.choose_arena(level.arena)
	var shade := ColorRect.new()
	shade.color = Color(.01,.015,.025,.82)
	screen.add_child(UI.place(shade,0,0,1280,720))
	screen.add_child(UI.place(UI.label("CHAPTER ONE · LEVEL %d / 4" % (index+1),19,UI.CYAN),40,38,1200,36))
	screen.add_child(UI.place(UI.label(level.title,35,UI.IVORY,true),40,88,1200,58))
	var player_index := StoryCatalog.fighter_index(roster,StoryCatalog.campaign().player)
	var opponent_index := StoryCatalog.fighter_index(roster,level.opponent)
	for side_index in 2:
		var hero := FighterIllustration.new()
		hero.profile = roster[player_index if side_index == 0 else opponent_index]
		hero.custom_size = Vector2(300,390)
		hero.show_background = false
		hero.facing = 1 if side_index == 0 else -1
		hero.position = Vector2(50+side_index*880,200)
		screen.add_child(hero)
		screen.add_child(UI.place(UI.label(hero.profile.display_name.to_upper(),23,UI.CYAN if side_index == 0 else UI.ORANGE),50+side_index*880,590,300,38))
	var text := UI.label(level.briefing,22,UI.IVORY)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	screen.add_child(UI.place(text,400,190,480,248))
	screen.add_child(UI.place(UI.label(ArenaCatalog.get_arena(level.arena).name,18,UI.GOLD),370,454,540,40))
	var play := UI.button("BEGIN DUEL",func(): start_story_level(index),true)
	screen.add_child(UI.place(play,450,515,380,56))
	screen.add_child(UI.place(UI.button("LEVEL SELECT",show_story),450,590,380,44))
	play.grab_focus()

func start_story_level(index: int) -> void:
	if not Progression.story_available(index): return
	if OnlineSession.active(): OnlineSession.close()
	story_index = index
	story_mode = true
	networked = false
	solo = true
	var level: Dictionary = StoryCatalog.levels()[index]
	selected.assign([StoryCatalog.fighter_index(roster,StoryCatalog.campaign().player),StoryCatalog.fighter_index(roster,level.opponent)])
	arena_choice = level.arena
	start_match()

func story_result(box: VBoxContainer, score: Array[int]) -> void:
	var won := score[0] == 2
	var last := story_index == StoryCatalog.levels().size()-1
	var saved := Progression.complete_story_level(story_index) if won else true
	var heading: Label = box.get_child(0)
	heading.text = ("CHAPTER COMPLETE" if last else "LEVEL COMPLETE") if won else "TRY AGAIN"
	heading.add_theme_font_size_override("font_size",32)
	var level: Dictionary = StoryCatalog.levels()[story_index]
	var text := UI.label(level.victory if won else "SharkByte's journey continues. Try this duel again.",19,UI.IVORY)
	if not saved: text.text = Progression.last_error
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay.add_child(UI.place(text,930,230,300,230))
	if won and not last:
		var next := UI.button("NEXT LEVEL",func(): show_story_briefing(story_index+1),true)
		next.disabled = not saved
		box.add_child(next)
	elif won:
		box.add_child(UI.button("LEVEL SELECT",show_story,true))
	else:
		box.add_child(UI.button("RETRY LEVEL",func(): start_story_level(story_index),true))
	if won: box.add_child(UI.button("REPLAY LEVEL",func(): start_story_level(story_index)))
	if not won or not last: box.add_child(UI.button("LEVEL SELECT",show_story))

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
		screen.confirm()
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
		"story_briefing": show_story()
		"result":
			if story_mode: show_story()
			else: show_menu()
		"arena":
			if networked: show_menu()
			else: show_select(solo)
		"menu": confirm_action("Quit Inferno Duel: Legends?",func(): get_tree().quit())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and route == "fight":
		show_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()

func _controller_action(player: int, action: String) -> void:
	if is_instance_valid(modal) and modal.visible:
		if action == "accept": modal.confirmed.emit()
		elif action == "back": modal.canceled.emit()
		return
	if route == "select" and solo and action == "pause":
		screen.confirm(0)
		screen.confirm(1)
		return
	if action in ["pause","back"]:
		if route == "fight" and action == "back": return
		go_back()
		return
	if route in ["select","network_select"]:
		var p := player
		if networked: p = OnlineSession.local_slot
		var codes := {"left":KEY_A if p == 0 else KEY_LEFT,"right":KEY_D if p == 0 else KEY_RIGHT,"up":KEY_W if p == 0 else KEY_UP,"down":KEY_S if p == 0 else KEY_DOWN,"accept":KEY_F if p == 0 else KEY_I,"ready":KEY_F if p == 0 else KEY_I,"undo":KEY_G if p == 0 else KEY_O}
		if codes.has(action): screen.handle_key(codes[action])
	elif route == "arena" and action == "accept": screen.confirm()
	elif route != "fight":
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Slider and action in ["left","right"]:
			focused.value += .05 if action == "right" else -.05
			return
		if action in ["down","right","up","left"] and focused:
			var next := focused.find_next_valid_focus() if action in ["down","right"] else focused.find_prev_valid_focus()
			if next: next.grab_focus()
		elif action == "accept" and focused is Button: focused.pressed.emit()
