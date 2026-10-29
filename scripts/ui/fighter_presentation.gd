class_name FighterPresentation
extends Node3D
## A textured, extruded silhouette in real perspective; preserves authored art.
## This is a 2.5D presentation, not a newly modelled skeletal character.
var profile: Dictionary
var visual: FighterVisual
var rig: Node3D
var face: MeshInstance3D
var edge: MeshInstance3D
var rings: Array[MeshInstance3D] = []
var camera: Camera3D
var elapsed := 0.0
var finished := false
var cached_key := ""
var hero_scale := 1.0
var stage_offset := 0.0
var accent := Color("55d9ef")
var front_material: ShaderMaterial
var mesh_cache: Dictionary = {}
signal completed

func solid(color: Color, emission := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .36
	material.metallic = .45
	if emission > 0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material

func cylinder(radius: float, height: float, y: float, material: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 64
	node.mesh = mesh
	node.material_override = material
	node.position.y = y
	add_child(node)

func _ready() -> void:
	accent = Color(profile.get("accent","55d9ef"))
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("0b101b")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("a2b7ce")
	world.environment.ambient_light_energy = .68
	add_child(world)
	camera = Camera3D.new()
	camera.fov = 37
	add_child(camera)
	camera.current = true
	for item in [[Vector3(-3,6,5),Color("c8edff"),1.3],[Vector3(3,3,-2),accent,2.1]]:
		var light := OmniLight3D.new()
		light.position = item[0]
		light.light_color = item[1]
		light.light_energy = item[2]
		light.omni_range = 12
		add_child(light)
	cylinder(2.4,.24,-.18,solid(Color("151f31")))
	cylinder(2.44,.025,-.055,solid(accent,.8))
	cylinder(2.34,.04,-.02,solid(Color("101724")))
	for radius in [1.76,2.12]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius
		torus.outer_radius = radius+.015
		torus.rings = 48
		torus.ring_segments = 8
		ring.mesh = torus
		ring.material_override = solid(Color(accent,.8),.7)
		ring.position.y = .01
		add_child(ring)
		rings.append(ring)
	rig = Node3D.new()
	add_child(rig)
	face = MeshInstance3D.new()
	edge = MeshInstance3D.new()
	rig.add_child(edge)
	rig.add_child(face)
	front_material = ShaderMaterial.new()
	front_material.shader = preload("res://assets/shaders/presentation.gdshader")
	face.material_override = front_material
	edge.material_override = solid(accent.darkened(.73))
	visual = FighterVisual.new()
	visual.profile = profile
	visual.target_height = 300
	visual.visible = false
	add_child(visual)
	# Drive once from this timeline; the hidden 2D node must not advance again.
	visual.set_process(false)
	# Supplementary bite/kick silhouettes can extend far beyond the idle pivot.
	# Fit the whole authored entrance once, keep the support foot fixed on the podium.
	var envelope := Rect2(Vector2.ZERO,Vector2.ZERO)
	var first := true
	var frames: Array = []
	var signature: Dictionary = visual.metadata.animations.heavy
	for index in signature.frames:
		frames.append([visual.frame_data(signature.get("atlas","core"),index),Vector2.ZERO])
	var idle_animation: Dictionary = visual.metadata.animations.idle
	frames.append([visual.frame_data(idle_animation.get("atlas","core"),idle_animation.frames[0]),Vector2.ZERO])
	for entry in frames:
		var frame: Dictionary = entry[0]
		for point in frame.vertices:
			var world_point: Vector2 = ((point-Vector2(frame.pivot))*float(frame.scale)+Vector2(entry[1]))/80.0
			if first:
				envelope = Rect2(world_point,Vector2.ZERO)
				first = false
			else: envelope = envelope.expand(world_point)
	hero_scale = minf(1.0,minf(3.8/maxf(envelope.size.x,.01),3.55/maxf(envelope.size.y,.01)))
	stage_offset = -envelope.get_center().x*hero_scale
	replay()

func replay() -> void:
	elapsed = 0
	finished = false
	set_process(true)

func build_mesh() -> void:
	var sprite := visual.sprite
	if not sprite or sprite.polygon.size() < 3: return
	var key: String = sprite.get_meta("frame_key",visual.last_key)
	if key == cached_key: return
	cached_key = key
	if not mesh_cache.has(key):
		var vertices := PackedVector3Array()
		var uv := PackedVector2Array()
		var normals := PackedVector3Array()
		for i in sprite.polygon.size():
			var base: Dictionary = sprite.get_meta("frame_data")
			var p: Vector2 = (sprite.polygon[i]-visual.current_pivot)*float(base.scale)/80.0
			vertices.append(Vector3(p.x,-p.y,.075))
			uv.append(sprite.uv[i]/sprite.texture.get_size())
			normals.append(Vector3(0,0,1))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_TEX_UV] = uv
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = Geometry2D.triangulate_polygon(sprite.polygon)
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var walls := SurfaceTool.new()
		walls.begin(Mesh.PRIMITIVE_TRIANGLES)
		var boundary: PackedVector2Array = sprite.get_meta("frame_data").vertices
		var scale_factor: float = sprite.get_meta("frame_data").scale/80.0
		for i in boundary.size():
			var p_a: Vector2 = (boundary[i]-visual.current_pivot)*scale_factor
			var p_b: Vector2 = (boundary[(i+1)%boundary.size()]-visual.current_pivot)*scale_factor
			var a := Vector3(p_a.x,-p_a.y,.075)
			var b := Vector3(p_b.x,-p_b.y,.075)
			var back_a := a-Vector3(0,0,.15)
			var back_b := b-Vector3(0,0,.15)
			for v in [a,back_a,b,b,back_a,back_b]: walls.add_vertex(v)
		walls.generate_normals()
		mesh_cache[key] = [mesh,walls.commit(),sprite.texture]
	face.mesh = mesh_cache[key][0]
	edge.mesh = mesh_cache[key][1]
	front_material.set_shader_parameter("base_texture",mesh_cache[key][2])

func _process(delta: float) -> void:
	elapsed += delta
	visual.clock += delta
	var progress := clampf((elapsed-.65)/1.35,0.0,.999)
	visual.preview_pose = "heavy" if elapsed >= .65 and elapsed < 2.0 else "idle"
	visual.preview_progress = progress if visual.preview_pose == "heavy" else 0.0
	visual._update_pose(delta)
	build_mesh()
	var swing := sin(progress*PI) if visual.preview_pose == "heavy" else 0.0
	var camera_time := minf(elapsed,2.8)
	var idle_time := maxf(0.0,elapsed-2.8)
	rig.rotation.y = sin(camera_time*1.5)*.1-swing*.16+sin(idle_time*1.4)*.012
	rig.position.x = stage_offset+swing*.08+visual.support_anchor.x/80.0*hero_scale if face.mesh else 0.0
	rig.scale = Vector3(hero_scale*visual.motion.stretch.x,hero_scale*visual.motion.stretch.y,hero_scale)
	camera.position = Vector3(1.2*cos(camera_time*.65),2.1,7.5-swing*.35)
	camera.look_at(Vector3(0,1.65,0))
	if elapsed > 2.8 and not finished:
		finished = true
		completed.emit()
