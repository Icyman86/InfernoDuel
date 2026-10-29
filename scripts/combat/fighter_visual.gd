class_name FighterVisual
extends Node2D
## Discrete illustrated poses. No UV interpolation, mesh morph or ghost layers.
const ART_DATA_PATH := "res://data/sprite_atlases.json"
static var art_cache: Dictionary = {}
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
var previous_sprite: Polygon2D
var previous_material: ShaderMaterial
var last_key := ""
var blend_age := 1.0
var walk_phase := 0.0
var body_lean := 0.0
var geometry_cache: Dictionary = {}
var geometry_builds := 0
var geometry_assignments := 0
var motion := FighterMotion.new()
var shown_facing := 1.0
var facing_from := 1.0
var facing_target := 1.0
var turn_age := 1.0
var cycle_blend := 0.0
var motion_state := "idle"
var action_blend := 0.0
var support_anchor := Vector2.ZERO
var previous_action := false

func _ready() -> void:
	if art_cache.is_empty(): art_cache = JSON.parse_string(FileAccess.get_file_as_string(ART_DATA_PATH))
	metadata = art_cache.get(profile.get("id","sharkbyte"), {})
	if metadata.is_empty(): return
	for key in metadata:
		if metadata[key] is Dictionary and metadata[key].has("path"):
			atlases[key] = load("res://"+metadata[key].path)
	pixels_to_world = target_height / float(metadata.base_height)
	motion.configure(profile.get("id","sharkbyte"))
	for previous in [true,false]:
		var node := Polygon2D.new()
		node.antialiased = true
		node.z_index = 1 if previous else 0
		var fx := ShaderMaterial.new()
		fx.shader = preload("res://assets/shaders/cel.gdshader")
		fx.set_shader_parameter("team_color",accent)
		node.material = fx
		add_child(node)
		if previous:
			previous_sprite = node
			previous_material = fx
			node.visible = false
		else:
			sprite = node
			material_fx = fx
	if actor:
		# Warm immutable pose geometry; no optical-flow textures are loaded.
		for name in ["walk","heavy"]:
			var clip: Dictionary = metadata.animations[name]
			for index in clip.frames: frame_data(clip.get("atlas","core"),index)
		shown_facing = actor.facing
		facing_from = actor.facing
		facing_target = actor.facing
	_update_pose()

func reset_motion() -> void:
	motion.reset()
	walk_phase = 0
	turn_age = 1
	if actor:
		shown_facing = actor.facing
		facing_from = actor.facing
		facing_target = actor.facing
		scale.x = shown_facing

func _process(delta: float) -> void:
	if actor and actor.get_parent().get("stopped") == true: return
	clock += delta
	_update_pose(delta)
	queue_redraw()

func frame_data(source: String, index: int) -> Dictionary:
	var key := source+str(index)
	if not geometry_cache.has(key):
		var frame: Dictionary = metadata[source].frames[index]
		var pivot := Vector2(frame.pivot[0],frame.pivot[1])
		var r: Array = frame.rect
		var vertices := PackedVector2Array()
		var uvs := PackedVector2Array()
		for point in frame.polygon:
			var vertex := Vector2(point[0],point[1])
			vertices.append(vertex)
			uvs.append(vertex+Vector2(r[0],r[1]))
		var texture := AtlasTexture.new()
		texture.atlas = atlases[source]
		texture.region = Rect2(r[0],r[1],r[2],r[3])
		texture.filter_clip = true
		texture_cache[key] = texture
		geometry_cache[key] = {"key":key,"vertices":vertices,"uv":uvs,"texture":atlases[source],
			"pivot":pivot,"origin":Vector2(r[0],r[1]),"extent":Vector2(r[2],r[3]),
			"scale":pixels_to_world*float(metadata[source].get("scale",1.0)),
			"height":float(metadata.base_height)/float(metadata[source].get("scale",1.0))}
		geometry_builds += 1
	return geometry_cache[key]

func assign_frame(node: Polygon2D, data: Dictionary) -> void:
	if node.get_meta("frame_key","") == data.key: return
	node.polygon = data.vertices
	node.uv = data.uv
	node.texture = data.texture
	node.set_meta("frame_key",data.key)
	node.set_meta("frame_data",data)
	geometry_assignments += 1

func _update_pose(delta := 0.0) -> void:
	if not sprite or metadata.is_empty(): return
	state = preview_pose
	var progress := preview_progress
	var locked := false
	if actor:
		locked = actor.attack != null or actor.stun > 0 or actor.hp <= 0
		if actor.hp <= 0: state = "ko"
		elif actor.stun > 0: state = "hit"
		elif actor.guarding: state = "guard"
		elif actor.attack:
			state = actor.attack.animation
			var move := actor.attack
			if actor.attack_time < move.startup:
				progress = .45*actor.attack_time/move.startup
			elif actor.is_active():
				progress = .45+.20*(actor.attack_time-move.startup)/move.active
			else:
				progress = .65+.35*(actor.attack_time-move.startup-move.active)/move.recovery
		elif not actor.grounded(): state = "jump"
		elif absf(actor.locomotion_speed) > 18: state = "walk"
		else: state = "idle"
		if delta > 0: motion.update(delta,actor.locomotion_speed,actor.velocity.y,actor.grounded(),actor.facing,actor.guarding,locked,actor.walk_distance)
		if float(actor.facing) != facing_target:
			facing_from = shown_facing
			facing_target = actor.facing
			turn_age = 0
		turn_age += delta
		shown_facing = facing_target
		scale.x = shown_facing
		var flash := minf(1.0,actor.flash/.12)
		material_fx.set_shader_parameter("hit_flash",flash)
		previous_material.set_shader_parameter("hit_flash",flash)
	elif delta > 0:
		motion.update(delta,200.0 if state == "walk" else 0.0,0.0,state != "jump",1,state == "guard",state not in ["idle","walk","jump","guard"])
	if state == "idle" and previous_action: clock = 0.0
	previous_action = actor.attack != null if actor else progress > 0 and state not in ["idle","walk","jump","guard","hit","ko"]
	motion_state = motion.clip
	var animation: Dictionary = metadata.animations.get(state,metadata.animations.idle)
	var indices: Array = animation.frames
	frame_number = 0
	if state == "walk" and progress < 0:
		walk_phase = fposmod(motion.gait,1.0)*indices.size()
		frame_number = int(walk_phase)%indices.size()
	elif progress >= 0:
		if animation.has("times"):
			for i in indices.size():
				if progress >= float(animation.times[i]): frame_number = i
		else:
			# Original attacks keep their drawn windup/contact/recovery keys.
			frame_number = mini(indices.size()-1,int(progress*indices.size()))
	elif state not in ["idle","guard"]:
		frame_number = int(clock*float(animation.get("fps",8)))%indices.size()
	var data := frame_data(animation.get("atlas","core"),indices[frame_number])
	assign_frame(sprite,data)
	previous_sprite.visible = false
	current_pivot = data.pivot
	current_texture = texture_cache[data.key]
	support_anchor = Vector2.ZERO
	action_blend = 0
	body_lean = 0
	material_fx.set_shader_parameter("flow_blend",false)
	material_fx.set_shader_parameter("gait_phase",motion.gait*TAU)
	# Every rendered pose is an intact drawing. Neither vertices nor UVs morph.
	sprite.scale = Vector2.ONE*float(data.scale)
	sprite.position = -Vector2(data.pivot)*sprite.scale
	sprite.rotation = 0
	last_key = data.key

func _draw() -> void:
	if metadata.is_empty(): return
	if actor and actor.attack and actor.is_active():
		var move_id := actor.attack.id
		if move_id in ["tail_whip", "tail_spin", "low_cheese_swipe"]:
			var points := PackedVector2Array()
			for i in 18:
				var angle := -PI*.75 + float(i)/17 * PI*1.6 + clock*7
				points.append(Vector2.from_angle(angle)*Vector2(120,35)+Vector2(30,-70))
			draw_polyline(points, Color("997d63"), 9, true)
			draw_polyline(points, Color("ffd366"), 2, true)
	if actor and (actor.armor_time > 0 or actor.empower_time > 0 or actor.immunity > 0):
		var aura := Color(profile.get("accent", "ffca7a"))
		draw_arc(Vector2(0,-130), 135+sin(clock*6)*3, -PI*.9, PI*.25, 40, Color(aura,.45), 3,true)
	if actor and actor.attack and actor.attack.kind == "area" and actor.is_active():
		var radius := actor.attack.reach
		for i in 3:
			draw_arc(Vector2(0,-100),radius*(0.7+i*.1),-PI*.9+clock,PI*.6+clock,40,Color(accent,.32),3,true)
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
	if actor and actor.attack and actor.attack.slot in ["special","ultimate"] and actor.attack_kind(actor.attack.id) not in ["chain","chain_super", "buff"] and actor.is_active() and current_texture:
		for i in range(3,0,-1):
			draw_texture_rect(current_texture,Rect2(-current_pivot*sprite.scale.x-Vector2(i*17,0),current_texture.get_size()*sprite.scale.x),false,Color(accent,0.07*(4-i)))
