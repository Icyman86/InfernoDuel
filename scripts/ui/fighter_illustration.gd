class_name FighterIllustration
extends Node2D
## Complete high-resolution illustrated silhouettes, without 3D reconstruction.
signal completed
var profile: Dictionary
var texture: Texture2D
var metadata: Dictionary = {}
var figure: Node2D
var portrait := false
var signature := false
var elapsed := 0.0
var finished := false
var framed_rect := Rect2()
var image_size := Vector2.ZERO
var cached_size := Vector2.ZERO
var accent := Color.WHITE
var custom_size := Vector2.ZERO
var show_background := true
var facing := 1
var fallback_used := false

func _ready() -> void:
	accent = Color(profile.accent)
	metadata = JSON.parse_string(FileAccess.get_file_as_string("res://data/intro_atlases.json"))[profile.id]
	var path := "res://"+str(metadata.path)
	if ResourceLoader.exists(path): texture = load(path)
	if not texture:
		# A failed export must still show a real portrait, never an untextured mesh.
		fallback_used = true
		texture = load("res://"+str(profile.reference_art_path))
		var r: Array = profile.portrait_region
		var frame := {"rect":r,"polygons":[[[0,0],[r[2],0],[r[2],r[3]],[0,r[3]]]]}
		metadata = {"frames":[frame,frame,frame,frame]}
	figure = Node2D.new()
	add_child(figure)
	build_pose()
	replay()

func build_pose() -> void:
	for child in figure.get_children():
		figure.remove_child(child)
		child.queue_free()
	var info: Dictionary = metadata.frames[0 if portrait else (3 if signature else 1)]
	image_size = Vector2(info.rect[2],info.rect[3])
	for polygon in info.polygons:
		var mesh := Polygon2D.new()
		mesh.texture = texture
		mesh.antialiased = true
		var vertices := PackedVector2Array()
		var uvs := PackedVector2Array()
		for point in polygon:
			var p := Vector2(point[0],point[1])
			vertices.append(p-image_size*.5)
			uvs.append(p+Vector2(info.rect[0],info.rect[1]))
		mesh.polygon = vertices
		mesh.uv = uvs
		figure.add_child(mesh)
	frame_image()

func frame_image() -> void:
	cached_size = canvas_size()
	var scale_factor := minf(cached_size.x*.90/image_size.x,cached_size.y*.88/image_size.y)
	figure.scale = Vector2(facing,1)*scale_factor
	var size := image_size*scale_factor
	framed_rect = Rect2((cached_size-size)*.5,size)
	figure.position = cached_size*.5
	queue_redraw()

func set_portrait(value: bool) -> void:
	portrait = value
	build_pose()

func toggle_signature() -> void:
	signature = not signature
	portrait = false
	build_pose()
	replay()

func replay() -> void:
	if figure: figure.modulate.a = 0
	elapsed = 0
	finished = false
	set_process(true)

func _process(delta: float) -> void:
	elapsed += delta
	if cached_size != canvas_size(): frame_image()
	figure.modulate.a = smoothstep(0,.25,elapsed)
	figure.position = cached_size*.5+Vector2(0,14*pow(1-clampf(elapsed/.6,0,1),2))
	if elapsed >= .6 and not finished:
		finished = true
		completed.emit()

func canvas_size() -> Vector2:
	return custom_size if custom_size.x > 0 and custom_size.y > 0 else get_viewport().get_visible_rect().size

func _draw() -> void:
	if not show_background: return
	draw_rect(Rect2(Vector2.ZERO,cached_size),Color("080d16"))
	for layer in range(8,0,-1):
		draw_circle(cached_size*Vector2(.5,.44),cached_size.y*(.20+layer*.035),Color(accent,.010))
	if not portrait:
		draw_set_transform(Vector2(cached_size.x*.5,cached_size.y*.96),0,Vector2(1,.16))
		draw_circle(Vector2.ZERO,cached_size.y*.28,Color(0,0,0,.30))
		draw_arc(Vector2.ZERO,cached_size.y*.28,0,TAU,72,Color(accent,.28),2,true)
		draw_set_transform(Vector2.ZERO)
