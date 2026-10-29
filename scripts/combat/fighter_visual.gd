class_name FighterVisual
extends Node2D
## Reference-derived, alpha-separated animation keys. Combat logic owns timing.
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
		fx.shader = preload("res://assets/shaders/fighter.gdshader")
		fx.set_shader_parameter("team_color",accent)
		fx.set_shader_parameter("leg_swing",float(motion.profile.leg_swing))
		fx.set_shader_parameter("arm_swing",float(motion.profile.arm_swing))
		fx.set_shader_parameter("body_bounce",float(motion.profile.bounce)/target_height)
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
		var walk: Dictionary = metadata.animations.walk
		WalkPoseFields.prime(profile.id)
		if not WalkPoseFields.available(profile.id): rig_geometry(frame_data(walk.get("atlas","core"),walk.frames[0]))
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
			"pivot":Vector2(frame.pivot[0],frame.pivot[1]),"origin":Vector2(r[0],r[1]),"extent":Vector2(r[2],r[3]),
			"scale":pixels_to_world*float(metadata[source].get("scale",1.0)),
			"height":float(metadata.base_height)/float(metadata[source].get("scale",1.0))}
		geometry_builds += 1
	return geometry_cache[key]

func rig_geometry(data: Dictionary) -> void:
	if data.has("rig_vertices"): return
	var vertices: PackedVector2Array = data.vertices.duplicate()
	var triangles := Geometry2D.triangulate_polygon(vertices)
	# Two subdivisions add interior joints to the authored outline. UVs stay
	# tied to the original drawing while the GPU articulates legs and arms.
	for subdivision in 2:
		var edges := {}
		var refined := PackedInt32Array()
		for i in range(0,triangles.size(),3):
			var a: int = triangles[i]
			var b: int = triangles[i+1]
			var c: int = triangles[i+2]
			var mids: Array[int] = []
			for edge in [[a,b],[b,c],[c,a]]:
				var key: int = (mini(edge[0],edge[1]) << 32) | maxi(edge[0],edge[1])
				if not edges.has(key):
					edges[key] = vertices.size()
					vertices.append((vertices[edge[0]]+vertices[edge[1]])*.5)
				mids.append(edges[key])
			refined.append_array(PackedInt32Array([a,mids[0],mids[2],mids[0],b,mids[1],mids[2],mids[1],c,mids[0],mids[1],mids[2]]))
		triangles = refined
	var uv := PackedVector2Array()
	for point in vertices: uv.append(point+Vector2(data.origin))
	var polygons: Array[PackedInt32Array] = []
	for i in range(0,triangles.size(),3): polygons.append(PackedInt32Array([triangles[i],triangles[i+1],triangles[i+2]]))
	data.rig_vertices = vertices
	data.rig_uv = uv
	data.rig_triangles = polygons

func assign_frame(node: Polygon2D, data: Dictionary, rigged := false) -> void:
	var key: String = data.key+("-rig" if rigged else "")
	if node.get_meta("frame_key","") != key:
		if rigged: rig_geometry(data)
		node.polygons = data.rig_triangles if rigged else []
		node.polygon = data.rig_vertices if rigged else data.vertices
		node.uv = data.rig_uv if rigged else data.uv
		node.texture = data.texture
		node.set_meta("frame_key",key)
		node.set_meta("frame_data",data)
		node.set_meta("rigged",rigged)
		node.material.set_shader_parameter("pivot_pixels",data.pivot)
		node.material.set_shader_parameter("body_height_pixels",data.height)
		geometry_assignments += 1

func assign_flow_frame(base: Dictionary, next: Dictionary) -> void:
	var key: String = base.key+"-flow-"+next.key
	if sprite.get_meta("frame_key","") == key: return
	if not base.has("flow_meshes"): base.flow_meshes = {}
	if not base.flow_meshes.has(next.key):
		var points: PackedVector2Array = base.vertices.duplicate()
		for point in next.vertices:
			points.append((point-Vector2(next.pivot))*float(next.scale)/float(base.scale)+Vector2(base.pivot))
		var hull := Geometry2D.convex_hull(points)
		if hull.size() > 1 and hull[0] == hull[-1]: hull.resize(hull.size()-1)
		var uv := PackedVector2Array()
		for point in hull: uv.append(point+Vector2(base.origin))
		base.flow_meshes[next.key] = [hull,uv]
	sprite.polygons = []
	sprite.polygon = base.flow_meshes[next.key][0]
	sprite.uv = base.flow_meshes[next.key][1]
	sprite.texture = base.texture
	sprite.set_meta("frame_data",base)
	sprite.set_meta("frame_key",key)
	sprite.set_meta("rigged",false)
	material_fx.set_shader_parameter("pivot_pixels",base.pivot)
	material_fx.set_shader_parameter("body_height_pixels",base.height)
	blend_coverage(base,next)
	WalkPoseFields.bind(material_fx,profile.id,frame_number,base,next,target_height)
	geometry_assignments += 1

func blend_coverage(base: Dictionary, overlay: Dictionary) -> void:
	var pair: String = base.key+":"+overlay.key
	if sprite.get_meta("blend_pair","") == pair: return
	sprite.set_meta("blend_pair",pair)
	var size_a: Vector2 = base.texture.get_size()
	var size_b: Vector2 = overlay.texture.get_size()
	var ratio: float = float(base.scale)/float(overlay.scale)
	var uv_scale := size_a*ratio/size_b
	var uv_offset: Vector2 = ((-Vector2(base.origin)-Vector2(base.pivot))*ratio+Vector2(overlay.pivot)+Vector2(overlay.origin))/size_b
	material_fx.set_shader_parameter("overlay_texture",overlay.texture)
	material_fx.set_shader_parameter("overlay_uv",Vector4(uv_scale.x,uv_scale.y,uv_offset.x,uv_offset.y))
	var lo: Vector2 = overlay.origin/size_b
	var hi: Vector2 = (Vector2(overlay.origin)+Vector2(overlay.extent))/size_b
	material_fx.set_shader_parameter("overlay_bounds",Vector4(lo.x,lo.y,hi.x,hi.y))

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
			var impact := 0.5 if state in ["heavy","strike"] else 0.25
			if actor.attack_time < move.startup:
				progress = impact*actor.attack_time/move.startup
			elif actor.is_active():
				progress = impact+(.75-impact)*(actor.attack_time-move.startup)/move.active
			else:
				progress = .75+.249*(actor.attack_time-move.startup-move.active)/move.recovery
		elif not actor.grounded(): state = "jump"
		elif absf(actor.velocity.x) > 18: state = "walk"
		else: state = "idle"
		if delta > 0: motion.update(delta,actor.velocity.x,actor.velocity.y,actor.grounded(),actor.facing,actor.guarding,locked)
		if float(actor.facing) != facing_target:
			facing_from = shown_facing
			facing_target = actor.facing
			turn_age = 0
		turn_age += delta
		shown_facing = lerpf(facing_from,facing_target,smoothstep(0,.12,turn_age))
		scale.x = shown_facing
		var flash := minf(1.0,actor.flash/.12)
		material_fx.set_shader_parameter("hit_flash",flash)
		previous_material.set_shader_parameter("hit_flash",flash)
	elif delta > 0:
		motion.update(delta,200.0 if state == "walk" else 0.0,0.0,state != "jump",1,state == "guard",state not in ["idle","walk","jump","guard"])
	motion_state = motion.clip
	var animation: Dictionary = metadata.animations.get(state,metadata.animations.idle)
	var indices: Array = animation.frames
	var phase := 0.0
	var flowing := actor != null and state == "walk" and progress < 0 and WalkPoseFields.available(profile.id)
	var rigged := actor != null and state == "walk" and progress < 0 and not flowing
	var cyclic := progress < 0 and state in ["idle","walk"] and indices.size() > 1 and not rigged
	if progress >= 0:
		frame_number = mini(indices.size()-1,int(progress*indices.size()))
	elif state == "walk":
		walk_phase = fposmod(motion.gait,1.0)*indices.size()
		phase = walk_phase
		frame_number = 0 if rigged else int(phase)%indices.size()
	else:
		phase = clock*float(animation.get("fps",8))*float(motion.profile.tempo)
		frame_number = int(phase)%indices.size()
	var source: String = animation.get("atlas","core")
	var data := frame_data(source,indices[frame_number])
	material_fx.set_shader_parameter("flow_blend",flowing)
	if cyclic:
		# Blend toward the next authored key for the ENTIRE interval. There is no
		# static hold between keys, even on four-key legacy walk cycles.
		var next := frame_data(source,indices[(frame_number+1)%indices.size()])
		if flowing:
			assign_flow_frame(data,next)
			cycle_blend = fposmod(phase,1.0)
			material_fx.set_shader_parameter("flow_mix",cycle_blend)
			material_fx.set_shader_parameter("pose_alpha",1.0)
			previous_sprite.visible = false
		else:
			assign_frame(sprite,data)
			assign_frame(previous_sprite,next)
			cycle_blend = smoothstep(0,1,fposmod(phase,1.0))
			material_fx.set_shader_parameter("pose_alpha",1.0-cycle_blend if next.key != data.key else 1.0)
			previous_material.set_shader_parameter("pose_alpha",cycle_blend if next.key != data.key else 0.0)
			previous_sprite.visible = next.key != data.key and cycle_blend > .001
	else:
		if data.key != last_key and last_key != "":
			var outgoing: Dictionary = sprite.get_meta("frame_data",data)
			assign_frame(previous_sprite,outgoing,bool(sprite.get_meta("rigged",false)))
			previous_sprite.visible = true
			blend_age = 0
		assign_frame(sprite,data,rigged)
		blend_age += delta
		var alpha := smoothstep(0,.075,blend_age)
		material_fx.set_shader_parameter("pose_alpha",alpha if previous_sprite.visible else 1.0)
		previous_material.set_shader_parameter("pose_alpha",1-alpha)
		if alpha >= 1: previous_sprite.visible = false
	material_fx.set_shader_parameter("blend_base",previous_sprite.visible)
	if previous_sprite.visible:
		blend_coverage(data,previous_sprite.get_meta("frame_data",data))
		material_fx.set_shader_parameter("overlay_weight",cycle_blend if cyclic else 1.0-smoothstep(0,.075,blend_age))
	last_key = data.key
	current_pivot = data.pivot
	current_texture = texture_cache[data.key]
	var stretch := motion.stretch if not locked else Vector2.ONE
	var offset := motion.offset if not locked else Vector2.ZERO
	if actor and actor.attack and actor.attack.command == "down" and actor.attack.slot == "light": stretch.y *= .94
	body_lean = motion.lean if not locked else 0.0
	if state in ["light","heavy","special","ultimate","peck"] and progress >= 0:
		body_lean += sin(progress*PI)*(.13 if state == "peck" else .035)
	if state == "hit": offset.x -= 5
	for node in [sprite,previous_sprite]:
		var frame: Dictionary = node.get_meta("frame_data",data)
		node.scale = Vector2.ONE*float(frame.scale)*stretch
		# Scale around the foot pivot, not the atlas rectangle's top-left.
		node.position = -Vector2(frame.pivot)*node.scale+offset
		node.rotation = 0
		node.material.set_shader_parameter("gait_phase",motion.gait*TAU)
		node.material.set_shader_parameter("walk_weight",motion.blend_speed if not locked else 0.0)
		node.material.set_shader_parameter("body_lean",body_lean)

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
