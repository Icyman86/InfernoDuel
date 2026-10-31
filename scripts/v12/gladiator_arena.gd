class_name GladiatorArena3D
extends Node2D
var duel: DuelMatch
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var models: Array[FighterModel3D] = []
var clamps: Array[Node3D] = []
var warnings: Array[MeshInstance3D] = []
var projectile_models: Array[MeshInstance3D] = []
var stone: StandardMaterial3D
var bronze: StandardMaterial3D
var dark: StandardMaterial3D
var gold: StandardMaterial3D
var red: StandardMaterial3D
var clock := 0.0
var debug_models: Array[MeshInstance3D] = []
var impacts: Array[Dictionary] = []

func impact_at(target: DuelFighter, blocked: bool) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = .14
	ring.outer_radius = .20
	var effect := mesh(world,ring,Vector3((target.position.x-640)/100,1.6+(DuelFighter.FLOOR-target.position.y)/100,.3),Vector3.ONE,gold if blocked else red)
	effect.rotation.x = PI*.5
	impacts.append({"node":effect,"age":0.0})

func mat(color: String, metal := 0.0, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.metallic = metal
	m.roughness = .6
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = glow
	return m

func mesh(parent: Node3D, resource: Mesh, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = resource
	node.position = at
	node.scale = size
	node.material_override = material
	parent.add_child(node)
	return node

func block(at: Vector3, size: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	return mesh(world if parent == null else parent,BoxMesh.new(),at,size,material)

func pillar(at: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius*1.08
	cylinder.height = height
	cylinder.radial_segments = 12
	return mesh(world,cylinder,at,Vector3.ONE,material)

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var image := TextureRect.new()
	image.texture = viewport.get_texture()
	image.size = Vector2(1280,720)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	world = Node3D.new()
	viewport.add_child(world)
	stone = mat("514a48")
	bronze = mat("886242",.65)
	dark = mat("1a202b",.4)
	gold = mat("eebb55",.45,1)
	red = mat("ff4d27",.2,2)
	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("111722")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color("9aaec9")
	sky.ambient_light_energy = .38
	sky.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = sky
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50,-25,0)
	sun.light_color = Color("ffdab0")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25,155,0)
	fill.light_color = Color("659ee5")
	fill.light_energy = .5
	world.add_child(fill)
	camera = Camera3D.new()
	camera.position = Vector3(0,3.6,12.2)
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 40
	camera.size = 14.2
	world.add_child(camera)
	camera.look_at(Vector3(0,1.5,0))
	camera.current = true
	# Physical stone ring with tessellated slabs, radial galleries and real depth.
	pillar(Vector3(0,-.32,0),7.5,.6,bronze)
	pillar(Vector3(0,-.11,0),7.28,.22,stone)
	for x in range(-7,8):
		for z in range(-4,5):
			if Vector2(x,z).length() > 7.0: continue
			var slab := block(Vector3(x,-.015,z),Vector3(.98,.04,.98),stone)
			slab.rotation.y = .007*sin(x*17+z*43)
	for tier in 4:
		var radius := 8.0+tier*.65
		for i in 32:
			var angle := PI+PI*i/31.0
			var point := Vector3(cos(angle)*radius,tier*.55+.35,sin(angle)*radius-1)
			var seat := block(point,Vector3(1.5,.52,.9),dark if tier%2 == 0 else stone)
			seat.rotation.y = -angle
	for i in 11:
		var x := (i-5)*1.65
		pillar(Vector3(x,2.4,-5.9),.24,4.8,stone)
		block(Vector3(x,4.8,-5.9),Vector3(.7,.24,.7),bronze)
		block(Vector3(x,0.18,-5.9),Vector3(.8,.35,.8),bronze)
		if i < 10:
			for j in 7:
				var angle := PI*j/6
				var voussoir := block(Vector3(x+.825+cos(angle)*.78,3.42+sin(angle)*.8,-5.9),Vector3(.4,.32,.52),stone)
				voussoir.rotation.z = angle-PI*.5
	for side in [-1,1]:
		for z in [-3.6,2.6]:
			pillar(Vector3(side*6.7,.75,z),.27,1.5,dark)
			var fire := SphereMesh.new()
			mesh(world,fire,Vector3(side*6.7,1.7,z),Vector3(.35,.65,.35),red)
			var light := OmniLight3D.new()
			light.position = Vector3(side*6.7,2,z)
			light.light_color = Color("ff752d")
			light.light_energy = 2.5
			light.omni_range = 5
			world.add_child(light)
	for i in 2:
		var clamp_node := Node3D.new()
		clamp_node.position.x = (ArenaRules.TRAP_POSITIONS[i]-640)/100
		world.add_child(clamp_node)
		clamps.append(clamp_node)
		block(Vector3(0,.03,0),Vector3(.9,.06,.9),dark,clamp_node)
		var ring := TorusMesh.new()
		ring.inner_radius = .42
		ring.outer_radius = .47
		warnings.append(mesh(clamp_node,ring,Vector3(0,.07,0),Vector3.ONE,gold))
		for side in [-1,1]:
			var jaw := Node3D.new()
			jaw.position = Vector3(side*.35,.08,0)
			clamp_node.add_child(jaw)
			block(Vector3(0,.06,0),Vector3(.15,.12,.72),bronze,jaw)
			for tooth in 5:
				var spike := CylinderMesh.new()
				spike.top_radius = 0
				spike.bottom_radius = .045
				spike.height = .22
				mesh(jaw,spike,Vector3(0,.23,(tooth-2)*.13),Vector3.ONE,bronze)
	for f in duel.fighters:
		f.hide()
		var model := FighterModel3D.new()
		model.actor = f
		world.add_child(model)
		models.append(model)
	for i in 4:
		var debug_material := mat("36e8d8" if i < 2 else "ff3c43")
		debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		debug_material.albedo_color.a = .3
		debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		debug_models.append(mesh(world,BoxMesh.new(),Vector3.ZERO,Vector3.ONE,debug_material))

func _process(delta: float) -> void:
	if not is_instance_valid(duel): return
	# Render at the actual pixel density of the logical stage after window
	# scaling, rather than stretching a permanently fixed 720p framebuffer.
	var pixels := Vector2i((Vector2(1280,720)*get_global_transform().get_scale().abs()).round())
	if pixels.x > 0 and pixels.y > 0 and viewport.size != pixels: viewport.size = pixels
	var paused := duel.stopped or duel.phase != "fight"
	if not paused: clock += delta
	for i in range(impacts.size()-1,-1,-1):
		if not paused: impacts[i].age += delta
		var age: float = impacts[i].age
		impacts[i].node.scale = Vector3.ONE*(.3+age*6)
		if age > .18:
			impacts[i].node.queue_free()
			impacts.remove_at(i)
	for model in models: model.sync(delta,paused)
	for i in 4:
		var f := duel.fighters[i%2]
		var rect := f.hurtbox() if i < 2 else f.hitbox()
		debug_models[i].visible = duel.debug_boxes and (i < 2 or f.is_active())
		debug_models[i].position = Vector3((rect.get_center().x-640)/100,(DuelFighter.FLOOR-rect.get_center().y)/100,.5)
		debug_models[i].scale = Vector3(maxf(.001,rect.size.x/100),maxf(.001,rect.size.y/100),.12)
	for i in 2:
		var state := duel.arena_rules.trap_phase(i)
		warnings[i].visible = state != "cooldown"
		warnings[i].material_override = red if state == "active" else gold
		warnings[i].scale = Vector3.ONE*(1+.05*sin(clock*16))
		for j in range(2,clamps[i].get_child_count()):
			clamps[i].get_child(j).rotation.z = (1 if j == 2 else -1)*(.75 if state == "active" else 0)
	while projectile_models.size() < duel.projectiles.size():
		var sphere := SphereMesh.new()
		projectile_models.append(mesh(world,sphere,Vector3.ZERO,Vector3.ONE,gold))
	for i in projectile_models.size():
		var item := projectile_models[i]
		item.visible = i < duel.projectiles.size()
		if not item.visible: continue
		var p := duel.projectiles[i]
		p.hide()
		item.position = Vector3((p.position.x-640)/100,(DuelFighter.FLOOR-p.position.y)/100,.15)
		item.scale = Vector3(maxf(.12,p.size.x/100),maxf(.12,p.size.y/100),.24)
		item.material_override = models[p.source.player].accent
