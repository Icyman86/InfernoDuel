class_name FighterPresentation
extends Node3D
## Imported, skinned Blender sculptures with an actual volume and skeleton.
## Full-body framing uses all eight corners of each character's model bounds.
signal completed
var profile: Dictionary
var model: Node3D
var rig: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var rings: Array[MeshInstance3D] = []
var camera: Camera3D
var elapsed := 0.0
var finished := false
var accent := Color("55d9ef")
var model_bounds := AABB()
var framed_points: Array[Vector3] = []
var yaw := .40
var portrait := false
var model_triangles := 0
var model_bones := 0
var frame_fill := .90
var cached_aspect := 0.0
var target := Vector3.ZERO
var camera_distance := 5.0
var material_count := 0
const CATALOG := "res://data/character_models.json"

func solid(color: Color, metal := .0, glow := .0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .35
	material.metallic = metal
	if glow > 0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material

func cylinder(radius: float, height: float, y: float, material: Material) -> void:
	var node := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 96
	node.mesh = shape
	node.material_override = material
	node.position.y = y
	add_child(node)

func _ready() -> void:
	accent = Color(profile.get("accent","55d9ef"))
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("080d16")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("9facbf")
	env.environment.ambient_light_energy = .32
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	camera = Camera3D.new()
	camera.fov = 34
	camera.near = .05
	camera.far = 50
	add_child(camera)
	camera.current = true
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-32,-28,0)
	key.light_color = Color("f0e5d2")
	key.light_energy = .9
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 12
	key.light_angular_distance = .4
	add_child(key)
	for item in [[Vector3(-2.5,2.6,3),Color("8ebcff"),.7],[Vector3(2.4,2.8,-1.8),accent,1.5],[Vector3(-2,1.5,-1),Color("c8def5"),.6]]:
		var light := OmniLight3D.new()
		light.position = item[0]
		light.light_color = item[1]
		light.light_energy = item[2]
		light.omni_range = 7
		add_child(light)
	cylinder(1.38,.12,-.09,solid(Color("141b27"),.65))
	cylinder(1.39,.012,-.026,solid(accent,.6,.55))
	cylinder(1.32,.022,-.014,solid(Color("1d2632"),.5))
	for radius in [1.08,1.25]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius
		torus.outer_radius = radius+.009
		torus.rings = 64
		torus.ring_segments = 8
		ring.mesh = torus
		ring.material_override = solid(accent,.45,.8)
		ring.position.y = -.001
		add_child(ring)
		rings.append(ring)
	var floor_node := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200,200)
	floor_node.mesh = plane
	floor_node.material_override = solid(Color("0c131e"),.3)
	floor_node.position.y = -.16
	add_child(floor_node)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG)).fighters
	var info: Dictionary = catalog[profile.id]
	model_triangles = int(info.triangles)
	model_bones = int(info.bones)
	material_count = int(info.materials)
	var low := Vector3(info.bounds_min[0],info.bounds_min[1],info.bounds_min[2])
	var high := Vector3(info.bounds_max[0],info.bounds_max[1],info.bounds_max[2])
	model_bounds = AABB(Vector3(-.5*(high.x-low.x),0,-.5*(high.z-low.z)),high-low)
	rig = Node3D.new()
	add_child(rig)
	model = (load("res://"+info.path) as PackedScene).instantiate()
	model.position = Vector3(-.5*(high.x+low.x),-low.y,-.5*(high.z+low.z))
	rig.add_child(model)
	_find_rig(model)
	for i in 8: framed_points.append(model_bounds.get_endpoint(i))
	if animator:
		for animation in animator.get_animation_list():
			if "Gallery_Idle" in animation:
				animator.get_animation(animation).loop_mode = Animation.LOOP_LINEAR
				animator.play(animation)
				break
	frame_camera()
	replay()

func _find_rig(node: Node) -> void:
	if node is Skeleton3D: skeleton = node
	if node is AnimationPlayer: animator = node
	for child in node.get_children(): _find_rig(child)

func replay() -> void:
	elapsed = 0
	finished = false
	set_process(true)
	if animator: animator.seek(0,true)

func turn(amount: float) -> void:
	yaw += amount
	frame_camera()

func set_portrait(value: bool) -> void:
	portrait = value
	frame_camera()

func frame_camera() -> void:
	if not camera: return
	var size: Vector2 = get_viewport().get_visible_rect().size
	if size.y <= 0: return
	var aspect := size.x/size.y
	cached_aspect = aspect
	var bounds := model_bounds
	if portrait:
		bounds.position.y = model_bounds.size.y*.52
		bounds.size.y = model_bounds.size.y*.48
		bounds.position.x *= .6
		bounds.size.x *= .6
	target = rig.transform*bounds.get_center()
	# Match Camera3D's vertical FOV and aspect, including rotation and depth.
	var direction := Vector3(sin(yaw),.045,cos(yaw)).normalized()
	var right := Vector3(cos(yaw),0,-sin(yaw))
	var up := direction.cross(right).normalized()
	var tangent_v := tan(deg_to_rad(camera.fov)*.5)
	var tangent_h := tangent_v*aspect
	camera_distance = 0
	for corner in 8:
		var p := rig.transform*bounds.get_endpoint(corner)-target
		var depth := p.dot(direction)
		camera_distance = maxf(camera_distance,depth+absf(p.dot(up))/(tangent_v*frame_fill))
		camera_distance = maxf(camera_distance,depth+absf(p.dot(right))/(tangent_h*frame_fill))
	camera.position = target+direction*camera_distance
	camera.look_at(target)

func _process(delta: float) -> void:
	elapsed += delta
	if not finished:
		rig.rotation.y = -.16*pow(1-clampf(elapsed/1.4,0,1),2)
		frame_camera()
	elif cached_aspect != get_viewport().get_visible_rect().size.aspect(): frame_camera()
	# The skeleton drives breathing; feet and the model's scale remain fixed.
	if elapsed >= 1.4 and not finished:
		finished = true
		completed.emit()
