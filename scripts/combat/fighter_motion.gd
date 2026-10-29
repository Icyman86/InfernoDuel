class_name FighterMotion
extends RefCounted
## Render-time movement clips. These never change collision or simulation state.
static var catalogue: Dictionary = {}
var profile: Dictionary = {}
var clip := "idle"
var age := 0.0
var clock := 0.0
var gait := 0.0
var blend_speed := 0.0
var was_grounded := true
var was_guarding := false
var previous_facing := 1
var previous_speed := 0.0
var last_direction := 0.0
var stopped_for := 1.0
var initialized := false
var offset := Vector2.ZERO
var stretch := Vector2.ONE
var lean := 0.0
var direction := 1.0
var previous_travel := 0.0

func configure(id: String) -> void:
	if catalogue.is_empty(): catalogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/movement_animations.json"))
	profile = catalogue.profiles.get(id,catalogue.profiles.sharkbyte)

func reset() -> void:
	clip = "idle"
	age = 0
	gait = 0
	blend_speed = 0
	previous_speed = 0
	last_direction = 0
	stopped_for = 1
	direction = 1
	previous_travel = 0
	initialized = false
	offset = Vector2.ZERO
	stretch = Vector2.ONE
	lean = 0

func play(name: String) -> void:
	clip = name
	age = 0

func update(delta: float, speed: float, vertical: float, grounded: bool, facing: int, guarding: bool, locked := false, travel := INF) -> void:
	clock += delta
	age += delta
	var moving := absf(speed) > 18
	var previously_moving := absf(previous_speed) > 18
	if not initialized:
		was_grounded = grounded
		was_guarding = guarding
		previous_facing = facing
		previous_speed = speed
		initialized = true
	var looping: bool = catalogue.clips.get(clip,{}).get("loop",false)
	var done: bool = age >= float(catalogue.clips.get(clip,{}).get("duration",.15))
	if not locked:
		if grounded and not was_grounded: play("land")
		elif facing != previous_facing or (moving and last_direction != 0 and signf(speed) != last_direction and stopped_for < .12): play("pivot")
		elif not grounded:
			var air := "rise" if vertical < -120 else ("fall" if vertical > 120 else "apex")
			if clip != air: play(air)
		elif guarding != was_guarding: play("guard_in" if guarding else "guard_out")
		elif not guarding and moving and not previously_moving: play("start")
		elif not guarding and not moving and previously_moving: play("brake")
		elif grounded and (looping or done):
			var next := "backstep" if moving and speed*facing < 0 else "idle"
			if next != clip: play(next)
	else:
		if clip != "idle": play("idle")
	var weight := clampf(absf(speed)/285.0,0.0,1.4) if grounded and not guarding and not locked else 0.0
	blend_speed = lerpf(blend_speed,weight,1-exp(-delta*18))
	# Walk phase is distance-driven, so partial thumbstick input does not skate.
	if is_finite(travel):
		if grounded and not locked: gait += (travel-previous_travel)*facing/float(profile.stride)
		previous_travel = travel
	else:
		gait += absf(speed)*delta/float(profile.stride)*(-1.0 if speed*facing < 0 else 1.0) if grounded and not locked else 0.0
	direction = signf(speed*facing) if moving else direction
	var curve := sample(clip,age)
	offset = Vector2(curve.x,curve.y)
	stretch = Vector2(curve.z,curve.w)
	if moving and grounded and clip in ["idle","backstep"]:
		stretch = Vector2.ONE
		offset = Vector2.ZERO
	if grounded: offset = Vector2.ZERO
	if clip == "land":
		stretch.y = 1.0+(stretch.y-1.0)*float(profile.land)/.085
	if clip == "idle" and blend_speed < .1:
		stretch.y += sin(clock*3.3*float(profile.tempo))*float(profile.breath)
	var goal := float(profile.lean)*direction*blend_speed
	if clip == "brake": goal *= -1
	lean = lerpf(lean,goal,1-exp(-delta*22))
	if moving:
		last_direction = signf(speed)
		stopped_for = 0
	else:
		stopped_for += delta
	was_grounded = grounded
	was_guarding = guarding
	previous_facing = facing
	previous_speed = speed

func sample(name: String, seconds: float) -> Vector4:
	var data: Dictionary = catalogue.clips.get(name,catalogue.clips.idle)
	var progress := seconds/float(data.duration)
	progress = fposmod(progress,1.0) if data.get("loop",false) else clampf(progress,0,1)
	var keys: Array = data["keys"]
	for i in range(1,keys.size()):
		if progress <= float(keys[i][0]):
			var a: Array = keys[i-1]
			var b: Array = keys[i]
			var t := smoothstep(float(a[0]),float(b[0]),progress)
			return Vector4(a[1],a[2],a[3],a[4]).lerp(Vector4(b[1],b[2],b[3],b[4]),t)
	return Vector4(0,0,1,1)
