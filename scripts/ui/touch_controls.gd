class_name TouchControls
extends Control
## Finger ownership is independent of mouse emulation and keyboard input.
signal pause_requested
var solo := true
var active := false
var buttons: Array[Dictionary] = []
var fingers: Dictionary = {}
var input_generation := -1

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
	if active != value:
		release_all()
	active = value
	visible = value
	queue_redraw()

func rebuild() -> void:
	release_all()
	buttons.clear()
	var safe := safe_rect(get_viewport()).grow(-16)
	var scale_factor := minf(safe.size.x / 1248.0, safe.size.y / 688.0)
	var unit := 86.0 * scale_factor
	var gap := 10.0 * scale_factor
	for p in (1 if solo else 2):
		var region := safe
		if not solo:
			region.size.x = safe.size.x / 2.0 - gap
			region.position.x += p * (safe.size.x / 2.0 + gap)
		var step := unit + gap
		var left := Vector2(region.position.x, region.end.y - unit * 2 - gap)
		var right := Vector2(region.end.x - unit * 2 - gap, left.y)
		for item in [["move_left", "◀", left + Vector2(0, step)],
			["move_right", "▶", left + Vector2(step, step)],
			["jump", "JUMP", left], ["block", "GUARD", left + Vector2(step, 0)],
			["light", "LIGHT", right], ["heavy", "HEAVY", right + Vector2(step, 0)],
			["special", "SPECIAL", right + Vector2(0, step)],
			["ultimate", "ULT", right + Vector2(step, step)]]:
			buttons.append({"player": p, "action": item[0], "label": item[1], "rect": Rect2(item[2], Vector2.ONE * unit)})
	buttons.append({"player": 0, "action": "pause", "label": "Ⅱ", "rect": Rect2(Vector2(safe.get_center().x - unit / 2, safe.position.y + 125 * scale_factor), Vector2(unit, unit * 0.7))})
	queue_redraw()

func release_all() -> void:
	for p in 2:
		for action in ["move_left", "move_right", "jump", "block", "light", "heavy", "special", "ultimate"]:
			InputRouter.set_touch(p, action, false)
	fingers.clear()
	input_generation = InputRouter.generation
	queue_redraw()

func _process(_delta: float) -> void:
	# Countdown, round transitions and focus changes invalidate old contacts.
	if input_generation != InputRouter.generation:
		release_all()

func _input(event: InputEvent) -> void:
	if not active: return
	if input_generation != InputRouter.generation: release_all()
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			move_finger(event.index, event.position)
		else:
			fingers.erase(event.index)
			sync_actions()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		move_finger(event.index, event.position)
		get_viewport().set_input_as_handled()

func move_finger(index: int, point: Vector2) -> void:
	var local := get_global_transform_with_canvas().affine_inverse() * point
	var hit := -1
	for i in buttons.size():
		if buttons[i].rect.has_point(local):
			hit = i
			break
	var previous: int = fingers.get(index, -1)
	fingers[index] = hit
	if hit >= 0 and buttons[hit].action == "pause" and previous != hit:
		pause_requested.emit()
		return
	sync_actions()

func sync_actions() -> void:
	for p in 2:
		for action in ["move_left", "move_right", "jump", "block", "light", "heavy", "special", "ultimate"]:
			var down := false
			for index in fingers.values():
				if index >= 0 and buttons[index].player == p and buttons[index].action == action:
					down = true
			InputRouter.set_touch(p, action, down)
	queue_redraw()

func _draw() -> void:
	var font := UI.BODY
	for i in buttons.size():
		var b: Dictionary = buttons[i]
		var down: bool = i in fingers.values()
		var color := UI.CYAN if b.player == 0 else UI.ORANGE
		var style := UI.style(Color(0.025, 0.02, 0.04, 0.85), Color(color, 0.8), 2)
		if down: style.bg_color = Color(color, 0.65)
		style.set_corner_radius_all(12)
		draw_style_box(style, b.rect)
		var font_size := maxi(12, int(b.rect.size.x * 0.18))
		var text_size := font.get_string_size(b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, b.rect.get_center() + Vector2(-text_size.x / 2, font.get_ascent(font_size) / 2), b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UI.IVORY)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree():
		release_all()
