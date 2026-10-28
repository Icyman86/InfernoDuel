class_name UI
extends RefCounted
const IVORY := Color("f6e7d9")
const GOLD := Color("ffca7a")
const CYAN := Color("49c4d7")
const ORANGE := Color("f46b35")
const MUTED := Color("b3a3ac")
const BODY = preload("res://assets/fonts/DejaVuSans.ttf")
const DISPLAY = preload("res://assets/fonts/DejaVuSerif-Bold.ttf")

static func style(color: Color, border := Color("59424a"), width := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(3)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = BODY
	t.default_font_size = 18
	t.set_color("font_color","Label",IVORY)
	t.set_color("font_color","Button",IVORY)
	t.set_color("font_hover_color","Button",GOLD)
	t.set_color("font_focus_color","Button",GOLD)
	t.set_stylebox("normal","Button",style(Color("19131e")))
	t.set_stylebox("hover","Button",style(Color("35202a"),GOLD))
	t.set_stylebox("pressed","Button",style(Color("513027"),GOLD,2))
	t.set_stylebox("focus","Button",style(Color(0,0,0,0),GOLD,2))
	t.set_constant("separation","VBoxContainer",10)
	t.set_constant("separation","HBoxContainer",12)
	return t

static func label(text: String, size := 20, color := IVORY, display := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	if display: l.add_theme_font_override("font",DISPLAY)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func button(text: String, action: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0,44)
	if primary:
		b.add_theme_stylebox_override("normal",style(Color("543322"),GOLD))
		b.add_theme_color_override("font_color",GOLD)
	b.pressed.connect(func():
		Sound.play("confirm")
		action.call())
	return b

static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel",style(Color("14111c")))
	return p

static func place(control: Control, x: float, y: float, w: float, h: float) -> Control:
	control.position = Vector2(x,y)
	control.size = Vector2(w,h)
	return control

static func bar(color: Color, value := 100.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.value = value
	b.add_theme_stylebox_override("background",style(Color("17121d"),Color("59424a")))
	b.add_theme_stylebox_override("fill",style(color,color,0))
	return b
