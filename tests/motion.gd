extends Node
const DT := 1.0/60.0
var passed := 0
var failed := 0

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ",message)
	else:
		failed += 1
		push_error(message)

func tick(hero: DuelFighter, rival: DuelFighter, input: Dictionary) -> void:
	hero.step(DT,input,rival)
	hero.visual._process(DT)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var roster: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json")).fighters
	for profile in roster:
		var duel := DuelMatch.new()
		duel.profiles.assign([profile,roster[1]])
		add_child(duel)
		duel.set_physics_process(false)
		var hero := duel.fighters[0]
		var rival := duel.fighters[1]
		rival.position.x = 1150
		hero.reset_at(350)
		var view := hero.visual
		view._process(DT)
		var observed := {view.motion_state:true}
		var clock_before := view.clock
		tick(hero,rival,{"axis":1})
		observed[view.motion_state] = true
		check(view.motion_state == "start",profile.id+" enters its start movement clip through real input")
		var blends := {}
		for frame in 36:
			tick(hero,rival,{"axis":1})
			blends[int(float(view.material_fx.get_shader_parameter("gait_phase"))*1000)] = true
		check(blends.size() >= 25 and view.clock > clock_before+.5 and bool(view.material_fx.get_shader_parameter("flow_blend")) and not view.previous_sprite.visible,profile.id+" renders motion-aligned authored walking poses in one pass at 60 render steps")
		var before_cache := view.geometry_builds
		for frame in 60: tick(hero,rival,{"axis":1})
		check(view.geometry_builds-before_cache <= 2,profile.id+" reuses warmed walk geometry instead of rebuilding it each render")
		for frame in 8:
			tick(hero,rival,{})
			observed[view.motion_state] = true
		check(observed.has("brake"),profile.id+" plays an actual stop/brake transition")
		hero.reset_at(550)
		view._process(DT)
		for frame in 30:
			tick(hero,rival,{"axis":-1})
			observed[view.motion_state] = true
		check(observed.has("backstep") and view.motion.gait < 0,profile.id+" has a reverse gait when moving away from the opponent")
		hero.reset_at(350)
		view._process(DT)
		for frame in 18: tick(hero,rival,{"axis":1})
		for frame in 15:
			tick(hero,rival,{"axis":-1})
			observed[view.motion_state] = true
		check(observed.has("pivot"),profile.id+" reverses direction with a pivot animation")
		hero.reset_at(350)
		view._process(DT)
		tick(hero,rival,{"jump":true})
		observed[view.motion_state] = true
		for frame in 58:
			tick(hero,rival,{})
			observed[view.motion_state] = true
		check(observed.has("rise") and observed.has("apex") and observed.has("fall") and observed.has("land"),profile.id+" animates takeoff, apex, falling and landing through a real jump")
		check(hero.position.y == DuelFighter.FLOOR and hero.hp == 100 and hero.meter == 0,profile.id+" movement animation does not change floor collision, HP or meter")
		hero.reset_at(350)
		view._process(DT)
		tick(hero,rival,{"block":true})
		check(view.motion_state == "guard_in",profile.id+" eases into block")
		tick(hero,rival,{})
		check(view.motion_state == "guard_out",profile.id+" eases out of block")
		duel.set_stopped(true)
		var frozen := view.motion.clock
		view._process(.5)
		check(view.motion.clock == frozen,profile.id+" freezes movement clips while paused")
		duel.set_stopped(false)
		hero.reset_at(350)
		check(view.motion.gait == 0 and view.motion.clip == "idle",profile.id+" round reset clears old movement phases")
		duel.queue_free()
	# Curves should be time-based and invariant to render cadence.
	var a := FighterMotion.new()
	var b := FighterMotion.new()
	a.configure("bullet")
	b.configure("bullet")
	for frame in 60: a.update(1.0/60,220,0,true,1,false)
	for frame in 120: b.update(1.0/120,220,0,true,1,false)
	check(absf(a.gait-b.gait) < .0001 and a.offset.distance_to(b.offset) < .1,"continuous motion remains consistent at 60 and 120 render samples")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(.6).timeout
	print("MOTION RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
