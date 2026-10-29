class_name TouchControls
extends Control
## Fixed thumbsticks retain finger ownership while attack contacts slide/release.
signal pause_requested
var solo := true
var active := false
var buttons: Array[Dictionary] = []
var sticks: Array[Dictionary] = []
var fingers: Dictionary = {}
var stick_fingers: Dictionary = {}
var input_generation := -1
var local_team := 0
var match_state: DuelMatch
const DEADZONE := .17

static func safe_rect(viewport: Viewport) -> Rect2:
	var rect := viewport.get_visible_rect()
	if OS.has_feature("android"):
		var safe := Rect2(DisplayServer.get_display_safe_area())
		if safe.has_area():
			var inverse := viewport.get_screen_transform().affine_inverse()
			rect = Rect2(inverse * safe.position, safe.size * inverse.get_scale()).intersection(rect)
	return rect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(rebuild)
	rebuild()
	set_active(false)

func set_active(value: bool) -> void:
	if active != value: release_all()
	active = value
	visible = value

func circle_button(player: int, action: String, label: String, center: Vector2, radius: float) -> void:
	buttons.append({"player":player,"action":action,"label":label,"center":center,
		"radius":radius,"rect":Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2)})

func rebuild() -> void:
	release_all()
	buttons.clear()
	sticks.clear()
	var safe := safe_rect(get_viewport()).grow(-18)
	var unit := minf(safe.size.x/1244.0,safe.size.y/684.0) * (1.0 if solo else .62)
	for p in (1 if solo else 2):
		var region := safe
		if not solo:
			region.size.x = safe.size.x*.5-10*unit
			region.position.x += p*(safe.size.x*.5+10*unit)
		var left := Vector2(region.position.x+118*unit,region.end.y-120*unit)
		sticks.append({"center":left,"radius":87*unit,"offset":Vector2.ZERO})
		circle_button(p,"block","BLOCK",left+Vector2(144,-45)*unit,39*unit)
		var right := Vector2(region.end.x-102*unit,region.end.y-104*unit)
		circle_button(p,"light","ATTACK",right,64*unit)
		circle_button(p,"heavy","HEAVY",right+Vector2(-115,-62)*unit,39*unit)
		circle_button(p,"special","SPECIAL",right+Vector2(-57,-151)*unit,39*unit)
		circle_button(p,"ultimate","ULT",right+Vector2(39,-143)*unit,39*unit)
		circle_button(p,"jump","JUMP",right+Vector2(-128,43)*unit,39*unit)
	var pause_radius := 25*unit
	circle_button(0,"pause","Ⅱ",Vector2(safe.get_center().x,safe.position.y+162*unit),pause_radius)
	queue_redraw()

func release_all() -> void:
	for p in 2:
		InputRouter.set_touch_axis(p,0.0)
		for action in ["move_left","move_right","jump","block","light","heavy","special","ultimate"]:
			InputRouter.set_touch(p,action,false)
	fingers.clear()
	stick_fingers.clear()
	for stick in sticks: stick.offset = Vector2.ZERO
	input_generation = InputRouter.generation
	queue_redraw()

func _process(_delta: float) -> void:
	if input_generation != InputRouter.generation: release_all()
	if visible: queue_redraw()

func _input(event: InputEvent) -> void:
	if not active: return
	if input_generation != InputRouter.generation: release_all()
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			move_finger(event.index,event.position,true)
		else:
			if stick_fingers.has(event.index):
				var p: int = stick_fingers[event.index]
				sticks[p].offset = Vector2.ZERO
				InputRouter.set_touch_axis(p,0.0)
				stick_fingers.erase(event.index)
			fingers.erase(event.index)
			sync_actions()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		move_finger(event.index,event.position,false)
		get_viewport().set_input_as_handled()

func move_finger(index: int, point: Vector2, initial := true) -> void:
	var local := get_global_transform_with_canvas().affine_inverse()*point
	if initial and not stick_fingers.has(index):
		for p in sticks.size():
			if not p in stick_fingers.values() and local.distance_to(sticks[p].center) <= sticks[p].radius+1.0:
				stick_fingers[index] = p
				break
	if stick_fingers.has(index):
		var p: int = stick_fingers[index]
		var stick: Dictionary = sticks[p]
		stick.offset = (local-stick.center).limit_length(stick.radius)
		var normalized: float = stick.offset.x/stick.radius
		var amount := (absf(normalized)-DEADZONE)/(1.0-DEADZONE)
		InputRouter.set_touch_axis(p,signf(normalized)*maxf(0.0,amount))
		queue_redraw()
		return
	var hit := -1
	for i in buttons.size():
		if local.distance_to(buttons[i].center) <= buttons[i].radius:
			hit = i
			break
	var previous: int = fingers.get(index,-1)
	fingers[index] = hit
	if hit >= 0 and buttons[hit].action == "pause" and previous != hit:
		pause_requested.emit()
		return
	sync_actions()

func sync_actions() -> void:
	for p in 2:
		for action in ["jump","block","light","heavy","special","ultimate"]:
			var down := false
			for index in fingers.values():
				if index >= 0 and buttons[index].player == p and buttons[index].action == action: down = true
			InputRouter.set_touch(p,action,down)
	queue_redraw()

func fighter_for(player: int) -> DuelFighter:
	if not is_instance_valid(match_state): return null
	var index := local_team if solo else player
	return match_state.fighters[index] if match_state.fighters.size() > index else null

func cooldown(button: Dictionary) -> float:
	var actor := fighter_for(button.player)
	if not actor: return 0.0
	if button.action == "special": return clampf(actor.special_cooldown/1.5,0.0,1.0)
	if button.action == "ultimate": return 1.0-clampf(actor.meter/100.0,0.0,1.0)
	return 0.0

func _draw() -> void:
	for p in sticks.size():
		var s: Dictionary = sticks[p]
		var color := UI.CYAN if (p+local_team)%2 == 0 else UI.ORANGE
		draw_circle(s.center,s.radius+7,Color(0.01,.02,.04,.36))
		draw_circle(s.center,s.radius,Color(.06,.10,.16,.55))
		draw_arc(s.center,s.radius,0,TAU,64,Color(color,.5),2,true)
		draw_arc(s.center,s.radius*.53,0,TAU,48,Color(color,.12),1,true)
		draw_line(s.center-Vector2(24,0),s.center+Vector2(24,0),Color(color,.25),1,true)
		var knob: Vector2 = s.center+s.offset*.68
		draw_circle(knob,s.radius*.42,Color("233b50"))
		draw_circle(knob,s.radius*.35,Color(color,.25))
		draw_arc(knob,s.radius*.42,0,TAU,40,Color(color,.9),2,true)
	for i in buttons.size():
		var b: Dictionary = buttons[i]
		var down: bool = i in fingers.values()
		var color := UI.CYAN if (b.player+local_team)%2 == 0 else UI.ORANGE
		if b.action == "ultimate": color = UI.GOLD
		var lock := cooldown(b)
		draw_circle(b.center,b.radius+5,Color(.01,.02,.04,.3))
		draw_circle(b.center,b.radius,Color(color,.6) if down else Color(.035,.065,.10,.85))
		draw_arc(b.center,b.radius,0,TAU,64,Color(color,.85 if lock == 0 else .28),2,true)
		if lock > 0:
			draw_arc(b.center,b.radius-5,-PI/2,-PI/2+TAU*(1-lock),48,color,3,true)
		var text: String = b.label
		if b.action == "ultimate" and fighter_for(b.player): text = "%d%%" % fighter_for(b.player).meter if lock > 0 else "ULT"
		var font_size := maxi(11,int(b.radius*.35))
		var extent := UI.BODY.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
		draw_string(UI.BODY,b.center+Vector2(-extent.x/2,UI.BODY.get_ascent(font_size)*.35),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,UI.IVORY if lock == 0 else UI.MUTED)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree(): release_all()
