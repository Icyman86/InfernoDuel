class_name WalkPoseFields
extends RefCounted
## GPU-ready motion vectors, analyzed from the unchanged authored walk poses.
static var data: Dictionary = {}
static var textures: Dictionary = {}

static func available(id: String) -> bool:
	if data.is_empty(): data = JSON.parse_string(FileAccess.get_file_as_string("res://data/walk_motion_fields.json"))
	return data.get("profiles",{}).has(id)

static func texture(id: String, index: int) -> Texture2D:
	var key := id+":"+str(index)
	if not textures.has(key):
		var bytes := Marshalls.base64_to_raw(data.profiles[id][index])
		var picture := Image.create_from_data(data.grid[0],data.grid[1],false,Image.FORMAT_RGBA8,bytes)
		textures[key] = ImageTexture.create_from_image(picture)
	return textures[key]

static func prime(id: String) -> void:
	if not available(id): return
	for index in data.profiles[id].size(): texture(id,index)

static func bind(material: ShaderMaterial, id: String, index: int, base: Dictionary, next: Dictionary, height: float) -> void:
	bind_texture(material,texture(id,index),base,next,height,data)

static func bind_texture(material: ShaderMaterial, field: Texture2D, base: Dictionary, next: Dictionary, height: float, config: Dictionary) -> void:
	material.set_shader_parameter("motion_field",field)
	var canvas := Vector2(config.canvas[0],config.canvas[1])
	var foot := Vector2(config.foot[0],config.foot[1])
	var size_a: Vector2 = base.texture.get_size()
	var size_b: Vector2 = next.texture.get_size()
	var a: float = float(base.scale)*float(config.body_height)/height
	var b: float = float(next.scale)*float(config.body_height)/height
	var scale_uv := size_a*a/canvas
	var offset_uv: Vector2 = (foot-(Vector2(base.origin)+Vector2(base.pivot))*a)/canvas
	material.set_shader_parameter("flow_uv",Vector4(scale_uv.x,scale_uv.y,offset_uv.x,offset_uv.y))
	material.set_shader_parameter("flow_pixel_uv",Vector4(1.0/(a*size_a.x),1.0/(a*size_a.y),1.0/(b*size_b.x),1.0/(b*size_b.y)))
	material.set_shader_parameter("flow_canvas_size",canvas)
	material.set_shader_parameter("flow_range",float(config.range))
	var lo: Vector2 = base.origin/size_a
	var hi: Vector2 = (Vector2(base.origin)+Vector2(base.extent))/size_a
	material.set_shader_parameter("source_bounds",Vector4(lo.x,lo.y,hi.x,hi.y))
