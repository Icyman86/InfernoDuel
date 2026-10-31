class_name FighterModel3D
extends Node3D
## Original, procedural articulated volume models. No sprite billboards.
## A transform rig, not a claimed production skeletal/mocap asset.
var actor: DuelFighter
var torso: Node3D
var head: Node3D
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var root: Node3D
var accent: StandardMaterial3D
var body: StandardMaterial3D
var dark: StandardMaterial3D
var cloth: StandardMaterial3D
var bone := StandardMaterial3D.new()
var mesh_count := 0

func material(color: Color, metal := 0.0, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = .42 if metal > 0 else .72
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

func shape(parent: Node3D, mesh: Mesh, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = mat
	item.position = at
	item.scale = size
	parent.add_child(item)
	mesh_count += 1
	return item

func orb(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 10
	return shape(parent,mesh,at,size,mat)

func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	return shape(parent,BoxMesh.new(),at,size,mat)

func spike(parent: Node3D, at: Vector3, length: float, radius: float, mat: Material, tilt := 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 8
	var item := shape(parent,mesh,at,Vector3.ONE,mat)
	item.rotation.z = tilt
	return item

func pivot(parent: Node3D, at: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.position = at
	parent.add_child(joint)
	return joint

func _ready() -> void:
	var id: String = actor.profile.id
	var colors := {"sharkbyte":"597d9a","bullet":"9b5842","nachtelf":"6e3834","poisonboy":"80a251","spinegrin":"829c45","chainveil":"d1b6b0","cheese_rat":"34323b","lava_stone":"44444c","crystal_fang":"322c43","phoenix_reign":"a34b24"}
	body = material(Color(colors[id]),.15 if id == "lava_stone" else 0)
	dark = material(Color("151922"),.45)
	cloth = material(Color("e1dccc") if id == "sharkbyte" else (Color("d9a928") if id == "cheese_rat" else Color("292b37")))
	accent = material(Color(actor.profile.accent),.35,1.8)
	bone = material(Color("f3dfbd"))
	root = pivot(self,Vector3.ZERO)
	torso = pivot(root,Vector3(0,1.18,0))
	orb(torso,Vector3(0,.34,0),Vector3(.57,.88,.79),body)
	box(torso,Vector3(0,.14,0),Vector3(.46,.44,.58),cloth)
	orb(torso,Vector3(-.07,.61,0),Vector3(.48,.24,.66),dark)
	box(torso,Vector3(.24,.40,0),Vector3(.04,.34,.36),accent)
	head = pivot(torso,Vector3(0,.78,0))
	orb(head,Vector3(0,.16,0),Vector3(.47,.49,.45),body)
	var animal: bool = id in ["sharkbyte","bullet","cheese_rat","crystal_fang","phoenix_reign"]
	if animal:
		orb(head,Vector3(.22,.10,0),Vector3(.51,.22,.34),body)
		box(head,Vector3(.29,.04,0),Vector3(.3,.04,.27),dark)
	for side in [-1,1]:
		orb(head,Vector3(.15,.23,side*.19),Vector3(.1,.065,.06),accent)
		var shoulder := pivot(torso,Vector3(0,.55,side*.39))
		arms.append(shoulder)
		orb(shoulder,Vector3.ZERO,Vector3(.37,.36,.35),dark if id == "sharkbyte" else body)
		orb(shoulder,Vector3(0,-.24,0),Vector3(.24,.51,.24),body)
		var elbow := pivot(shoulder,Vector3(0,-.46,0))
		elbows.append(elbow)
		orb(elbow,Vector3(0,-.20,0),Vector3(.25,.43,.27),dark)
		orb(elbow,Vector3(0,-.43,0),Vector3(.29,.25,.28),body)
		box(elbow,Vector3(.03,-.28,0),Vector3(.26,.1,.29),accent)
		var hip := pivot(root,Vector3(0,1.04,side*.22))
		legs.append(hip)
		orb(hip,Vector3(0,-.24,0),Vector3(.34,.56,.36),cloth)
		var knee := pivot(hip,Vector3(0,-.48,0))
		knees.append(knee)
		orb(knee,Vector3(0,-.22,0),Vector3(.27,.49,.29),cloth)
		if id in ["crystal_fang","phoenix_reign"]:
			orb(knee,Vector3(.08,-.47,0),Vector3(.42,.18,.32),body)
			for toe in 3:
				var claw := spike(knee,Vector3(.30,-.48,(toe-1)*.10),.18,.04,bone,-PI*.5)
				claw.rotation.x = .1
		else:
			box(knee,Vector3(.1,-.47,0),Vector3(.47,.18,.34),dark)
			box(knee,Vector3(.1,-.54,0),Vector3(.49,.045,.36),accent)
		if id in ["bullet","crystal_fang","nachtelf"]:
			spike(head,Vector3(-.05,.48,side*.2),.40,.1,bone if id == "bullet" else accent,-side*.35)
		if id == "cheese_rat":
			orb(head,Vector3(-.08,.38,side*.22),Vector3(.1,.32,.30),body)
			orb(head,Vector3(-.025,.38,side*.22),Vector3(.04,.19,.18),material(Color("a35565")))
		if id in ["phoenix_reign","crystal_fang","spinegrin"]:
			for i in 4:
				spike(shoulder,Vector3(-.10,.15-i*.12,side*.13),.27,.09,accent,-.7)
		if id == "phoenix_reign":
			var wing := pivot(torso,Vector3(-.12,.55,side*.39))
			for i in 7:
				var feather := box(wing,Vector3(-.35-i*.10,-i*.075,side*(.12+i*.09)),Vector3(.15,.65-i*.045,.1),accent if i%2 == 0 else body)
				feather.rotation.z = -.6
	if id == "sharkbyte":
		spike(head,Vector3(-.16,.48,0),.40,.20,accent,.35)
		spike(torso,Vector3(-.38,.48,0),.6,.24,accent,.8)
		for side in [-1,1]:
			for i in 5: spike(head,Vector3(.15+i*.06,.015,side*.13),.055,.023,bone,PI)
	if id in ["sharkbyte","cheese_rat","crystal_fang"]:
		var tail := pivot(root,Vector3(-.15,1.0,0))
		for i in 6:
			orb(tail,Vector3(-.18-i*.12,-i*.045,0),Vector3(.23-i*.025,.15-i*.012,.14-i*.012),body)
	if id == "spinegrin":
		for i in 6: spike(torso,Vector3(-.32,.65-i*.12,0),.4,.1,accent,.9)
	if id == "chainveil":
		orb(head,Vector3(-.13,.16,0),Vector3(.35,.63,.55),dark)
		for side in [-1,1]:
			for i in 12:
				var ring := TorusMesh.new()
				ring.inner_radius = .035
				ring.outer_radius = .055
				var link := shape(torso,ring,Vector3(-.15,.30-i*.08,side*(.42+.08*sin(i))),Vector3.ONE,accent if i%4 == 0 else dark)
				link.rotation.x = PI*.5 if i%2 == 0 else 0
	if id == "lava_stone":
		for i in 8:
			var plate := box(torso,Vector3(.22,.10+i*.07,0),Vector3(.09,.07,.55),body)
			plate.rotation.x = i*.21
	if id == "cheese_rat":
		for i in 5: orb(torso,Vector3(.24,.10+i*.1,.13*sin(i*2)),Vector3(.035,.06,.055),dark)
	if id in ["nachtelf","poisonboy"]:
		spike(head,Vector3(-.03,.49,0),.52,.23,dark,-.3)
		for side in [-1,1]: box(torso,Vector3(-.16,-.15,side*.26),Vector3(.20,.8,.22),dark)
	if id == "bullet": root.scale = Vector3(1.17,1.07,1.2)
	elif id == "cheese_rat": root.scale = Vector3(.9,.93,.9)
	elif id == "lava_stone": root.scale = Vector3(1.18,1.05,1.18)

func sync(delta: float, paused: bool) -> void:
	if not is_instance_valid(actor): return
	position = Vector3((actor.position.x-640)/100,(DuelFighter.FLOOR-actor.position.y)/100,0)
	rotation.y = 0 if actor.facing > 0 else PI
	if paused: return
	var t := actor.anim_time
	var gait := actor.walk_distance/55.0
	var walking := clampf(absf(actor.locomotion_speed)/230,0,1)
	var attack_weight := 0.0
	var heavy := false
	if actor.attack:
		heavy = actor.attack.slot != "light"
		var move := actor.attack
		if actor.attack_time < move.startup:
			attack_weight = -.35*sin(PI*.5*actor.attack_time/maxf(.01,move.startup))
		elif actor.attack_time < move.startup+move.active: attack_weight = 1
		else: attack_weight = maxf(0,1-(actor.attack_time-move.startup-move.active)/maxf(.01,move.recovery))
	var hurt := actor.stun > 0
	var down := actor.hp <= 0
	torso.rotation.z = -.22 if hurt else (-.10+sin(t*2)*.025+attack_weight*.18)
	root.rotation.z = lerp_angle(root.rotation.z,-1.25 if down else (-.8 if actor.throw_pose > 0 else 0),1-exp(-delta*12))
	root.position.y = .018*sin(t*3) - (.12 if actor.guarding else 0)
	head.rotation.z = .25 if hurt else -.06
	for i in 2:
		var wave := sin(gait+i*PI)*walking
		var arm_angle := .45+wave*.45
		var bend := .8
		if actor.grapple_pose > 0:
			arm_angle = 1.5
			bend = .15
		elif actor.guarding:
			arm_angle = 1.2
			bend = 1.4
		elif actor.attack:
			arm_angle = (.5+attack_weight*1.35) if i == 0 else (.4-attack_weight*.6)
			bend = .2 if attack_weight > .4 else 1.4
		elif hurt:
			arm_angle = -.35
			bend = .5
		arms[i].rotation.z = arm_angle
		elbows[i].rotation.z = bend
		legs[i].rotation.z = wave*.52 + (attack_weight*.85 if heavy and i == 1 else -.06)
		knees[i].rotation.z = -.15-maxf(0,-wave)*.7
	accent.emission_energy_multiplier = 3.2 if actor.meter >= 100 else 1.2
