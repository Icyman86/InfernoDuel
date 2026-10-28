class_name FighterVisual
extends Node2D
## Reference-derived, alpha-separated animation keys. Combat logic owns timing.
const ART_DATA_PATH := "res://data/sprite_atlases.json"
var profile: Dictionary = {}
var actor: DuelFighter
var accent := Color("49c4d7")
var target_height := 270.0
var clock := 0.0
var state := "idle"
var frame_number := 0
var sprite: Polygon2D
var material_fx: ShaderMaterial
var metadata: Dictionary = {}
var atlases: Dictionary = {}
var current_texture: AtlasTexture
var current_pivot := Vector2.ZERO
var pixels_to_world := 1.0
var texture_cache: Dictionary = {}
var preview_pose := "idle"
var preview_progress := -1.0

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART_DATA_PATH))
	metadata = data.get(profile.get("id","sharkbyte"), {})
	if metadata.is_empty(): return
	for key in ["core","actions","walk"]:
		atlases[key] = load("res://"+metadata[key].path)
	pixels_to_world = target_height / float(metadata.base_height)
	sprite = Polygon2D.new()
	sprite.antialiased = true
	material_fx = ShaderMaterial.new()
	material_fx.shader = preload("res://assets/shaders/fighter.gdshader")
	material_fx.set_shader_parameter("team_color",accent)
	sprite.material = material_fx
	add_child(sprite)
	_update_pose()

func _process(delta: float) -> void:
	if actor and actor.get_parent().get("stopped") == true: return
	clock += delta
	_update_pose()
	queue_redraw()

func _update_pose() -> void:
	if not sprite or metadata.is_empty(): return
	state = preview_pose
	var progress := preview_progress
	if actor:
		if actor.hp <= 0:
			state = "ko"
		elif actor.stun > 0:
			state = "hit"
		elif actor.guarding:
			state = "guard"
		elif actor.attack:
			state = actor.attack.id
			var move := actor.attack
			if actor.attack_time < move.startup:
				progress = 0.25 * actor.attack_time / move.startup
			elif actor.is_active():
				progress = 0.25 + 0.5 * (actor.attack_time-move.startup) / move.active
			else:
				progress = 0.75 + 0.249 * (actor.attack_time-move.startup-move.active) / move.recovery
		elif not actor.grounded():
			state = "jump"
		elif absf(actor.velocity.x) > 35:
			state = "walk"
		else:
			state = "idle"
		scale.x = float(actor.facing)
		material_fx.set_shader_parameter("hit_flash",minf(1.0,actor.flash/0.12))
	var animation: Dictionary = metadata.animations.get(state,metadata.animations.idle)
	var indices: Array = animation.frames
	if progress >= 0:
		frame_number = mini(indices.size()-1,int(progress*indices.size()))
	else:
		frame_number = int(clock*float(animation.get("fps",8))) % indices.size()
	var source: String = animation.get("atlas","core")
	var frame: Dictionary = metadata[source].frames[indices[frame_number]]
	var r: Array = frame.rect
	current_pivot = Vector2(frame.pivot[0],frame.pivot[1])
	var cache_key := source+str(indices[frame_number])
	if not texture_cache.has(cache_key):
		var texture := AtlasTexture.new()
		texture.atlas = atlases[source]
		texture.region = Rect2(r[0],r[1],r[2],r[3])
		texture.filter_clip = true
		texture_cache[cache_key] = texture
	current_texture = texture_cache[cache_key]
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	for point in frame.polygon:
		var vertex := Vector2(point[0],point[1])
		vertices.append(vertex)
		uvs.append(vertex+Vector2(r[0],r[1]))
	sprite.polygon = vertices
	sprite.uv = uvs
	sprite.texture = atlases[source]
	var frame_scale := pixels_to_world * float(metadata[source].get("scale",1.0))
	sprite.position = -current_pivot * frame_scale
	sprite.scale = Vector2.ONE * frame_scale
	# Secondary motion stays small; silhouettes and attack keys supply primary motion.
	var breathe := sin(clock*3.3)*0.003 if state == "idle" else 0.0
	sprite.scale.y *= 1.0+breathe
	if state == "guard": sprite.position.y += sin(clock*7.0)*0.7
	if state == "hit": sprite.position.x -= 5.0

func _draw() -> void:
	if metadata.is_empty(): return
	if actor and actor.attack and actor.is_active() and actor.attack_kind(actor.attack.id) in ["chain","chain_super"]:
		var reach := actor.attack.reach
		var chain_color := Color("dfa9c5")
		for strand in (2 if actor.attack.id == "ultimate" else 1):
			var points := PackedVector2Array()
			for i in 24:
				var t := float(i)/23
				var p := Vector2(20+t*reach,-175+sin(t*PI*3+clock*16+strand)*12+strand*22)
				points.append(p)
				draw_arc(p,4.0,0,TAU,8,Color(chain_color,0.95),1.5,true)
			draw_polyline(points,Color(0.95,0.2,0.48,0.35),3,true)
	if actor and actor.attack and actor.attack.id in ["special","ultimate"] and actor.attack_kind(actor.attack.id) not in ["chain","chain_super"] and actor.is_active() and current_texture:
		for i in range(3,0,-1):
			draw_texture_rect(current_texture,Rect2(-current_pivot*sprite.scale.x-Vector2(i*17,0),current_texture.get_size()*sprite.scale.x),false,Color(accent,0.07*(4-i)))
