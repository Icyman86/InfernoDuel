class_name IntroCinematic
extends Control
## The renderer used to author the shipped short intro videos.
signal finished
const DURATION := 6.4
var profile: Dictionary = {}
var elapsed := 0.0
var playing := true
var frames: Array = []
var texture: Texture2D
var art_root: Node2D
var title: Label
var subtitle: Label
var fade: ColorRect
var last_frame := -1
var played_impact := false
var metadata: Dictionary = {}

func _ready() -> void:
	theme = UI.theme()
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://data/intro_atlases.json"))[profile.id]
	texture = load("res://"+metadata.path)
	add_child(preload("res://scenes/arenas/infernal_citadel.tscn").instantiate())
	var shade := ColorRect.new()
	shade.color = Color(0.01,0.008,0.02,0.48)
	add_child(UI.place(shade,0,0,1280,720))
	art_root = Node2D.new()
	add_child(art_root)
	for rect in [Rect2(0,0,1280,48),Rect2(0,666,1280,54)]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		add_child(UI.place(bar,rect.position.x,rect.position.y,rect.size.x,rect.size.y))
	title = UI.label(profile.display_name.to_upper(),32,UI.IVORY,true)
	title.add_theme_constant_override("outline_size",6)
	title.add_theme_color_override("font_outline_color",Color("100912"))
	add_child(UI.place(title,40,668,1200,46))
	subtitle = UI.label("INFERNO DUEL : LEGENDS",16,Color(profile.accent))
	add_child(UI.place(subtitle,40,9,1200,28))
	fade = ColorRect.new()
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.color = Color(0,0,0,0)
	add_child(UI.place(fade,0,0,1280,720))
	seek(0)

func _process(delta: float) -> void:
	if not playing: return
	seek(elapsed+delta)
	if elapsed >= DURATION:
		playing = false
		finished.emit()

func seek(time: float) -> void:
	elapsed = clampf(time,0,DURATION)
	var frame := 0
	var zoom := 1.0
	var center := Vector2(640,335)
	var target := Vector2(900,460)
	if elapsed < 2.2:
		frame = 0
		zoom = lerpf(0.98,1.13,elapsed/2.2)
	elif elapsed < 2.95:
		frame = 1
		target = Vector2(780,540)
		zoom = lerpf(0.98,1.05,(elapsed-2.2)/0.75)
	elif elapsed < 3.18:
		frame = 2
		target = Vector2(900,550)
		zoom = lerpf(1.0,1.07,(elapsed-2.95)/0.23)
	else:
		frame = 3
		target = Vector2(1070,520)
		center.y = 355
		var t := minf(1.0,(elapsed-3.18)/0.24)
		zoom = lerpf(0.86,1.15,1.0-pow(1.0-t,3))
		center.x += sin(elapsed*75)*4*maxf(0,1-(elapsed-3.18)/0.35)
		if playing and not played_impact:
			played_impact = true
			Sound.play("hit")
	if frame != last_frame:
		for child in art_root.get_children():
			art_root.remove_child(child)
			child.queue_free()
		var info: Dictionary = metadata.frames[frame]
		for polygon in info.polygons:
			var mesh := Polygon2D.new()
			mesh.texture = texture
			mesh.antialiased = true
			var vertices := PackedVector2Array()
			var uv := PackedVector2Array()
			for point in polygon:
				var p := Vector2(point[0],point[1])
				vertices.append(p-Vector2(info.rect[2],info.rect[3])*0.5)
				uv.append(p+Vector2(info.rect[0],info.rect[1]))
			mesh.polygon = vertices
			mesh.uv = uv
			art_root.add_child(mesh)
		last_frame = frame
	var r: Array = metadata.frames[frame].rect
	art_root.scale = Vector2.ONE*minf(target.x/r[2],target.y/r[3])*zoom
	art_root.position = center
	title.modulate.a = 1.0 if elapsed >= 2.2 else 0.85
	var flash := maxf(0.0,1.0-absf(elapsed-3.20)/0.07)*0.45
	fade.color = Color(1,0.94,0.8,flash) if flash > 0 else Color(0,0,0,maxf(0,(elapsed-5.8)/0.6))
