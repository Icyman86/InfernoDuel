class_name FighterBust
extends Control
## A separately painted, high-resolution half-body portrait, moved as one image.
static var catalogue: Dictionary = {}
var profile: Dictionary
var facing := 1
var figure: TextureRect
var origin := Vector2.ZERO
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	if catalogue.is_empty(): catalogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/select_busts.json")).profiles
	var data: Dictionary = catalogue[profile.id]
	var portrait := AtlasTexture.new()
	portrait.atlas = load("res://"+data.path)
	portrait.region = Rect2(data.rect[0],data.rect[1],data.rect[2],data.rect[3])
	portrait.filter_clip = true
	figure = TextureRect.new()
	figure.texture = portrait
	figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	figure.flip_h = false
	figure.size = size-Vector2(-4,12)
	origin = Vector2(-2,12)
	figure.position = origin
	add_child(figure)

func _process(delta: float) -> void:
	elapsed += delta
	if not figure: return
	figure.position = origin+Vector2(sin(elapsed*1.3)*1.5,sin(elapsed*1.8))
	figure.modulate.a = smoothstep(0,.22,elapsed)
	queue_redraw()

func _draw() -> void:
	var accent := Color(profile.get("accent","55d9ef"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("0c1420"))
	for i in 7:
		var y := float(i)*52+fmod(elapsed*6,52)
		draw_line(Vector2(0,y),Vector2(size.x,y-85),Color(accent,.09),1,true)
	draw_line(Vector2(8,size.y-2),Vector2(size.x-8,size.y-2),Color(accent,.75),2,true)
