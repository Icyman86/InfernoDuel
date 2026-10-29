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

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var roster: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighters.json")).fighters
	var clips := 0
	for profile in roster:
		var duel := DuelMatch.new()
		duel.profiles.assign([profile,roster[1]])
		add_child(duel)
		duel.set_physics_process(false)
		var hero := duel.fighters[0]
		var rival := duel.fighters[1]
		var view := hero.visual
		view.set_process(false)
		rival.visual.set_process(false)
		check(hero.hp == 200 and rival.hp == 200,profile.id+" starts with 200 HP and zero meter")
		view.actor = null
		for animation in view.metadata.animations:
			if animation in ["idle","walk","jump","guard","hit","ko"]: continue
			clips += 1
			var intact := true
			view.preview_pose = animation
			for frame in 61:
				view.preview_progress = frame/60.0
				view._update_pose()
				var raw: Dictionary = view.sprite.get_meta("frame_data")
				intact = intact and view.sprite.polygon == raw.vertices and view.sprite.uv == raw.uv and view.sprite.scale.x == view.sprite.scale.y and not view.previous_sprite.visible
			check(intact,profile.id+"/"+animation+" uses intact drawn pose geometry and UVs through its full timeline")
		view.actor = hero
		view.preview_progress = -1
		hero.begin_attack("heavy")
		var variations := {}
		var support := Vector2.ZERO
		var fixed := true
		for frame in 90:
			hero.step(DT,{},rival)
			view._process(DT)
			if hero.attack:
				variations[str(view.sprite.get_meta("frame_key"))+str(snappedf(view.action_blend,.001))] = true
				var foot: Vector2 = view.sprite.position+view.current_pivot*view.sprite.scale
				if frame == 0: support = foot
				fixed = fixed and foot.distance_to(support) < .01
		check(variations.size() >= 9 and fixed,profile.id+" actual heavy renders at least nine distinct drawings around a fixed support foot")
		check(hero.attack == null and view.state == "idle",profile.id+" heavy returns to its resting animation")
		duel.start_round(false)
		duel.phase = "fight"
		# Normal combat: no health or meter fixtures and no repositioning during play.
		var ready_hp := 0
		var spent := false
		var spent_hp := 0
		var ended := false
		for frame in 2400:
			var command := {}
			var gap := absf(hero.position.x-rival.position.x)
			if gap > 96:
				command.axis = signf(rival.position.x-hero.position.x)
			elif hero.attack == null and hero.stun == 0 and rival.immunity == 0:
				if hero.meter == 100 and not spent:
					ready_hp = rival.hp
					spent_hp = rival.hp
					command.ultimate = true
				else:
					command.heavy = true
			duel.advance_fight(DT,[command,{}])
			if command.has("ultimate"):
				spent = hero.attack != null and hero.attack.slot == "ultimate" and hero.meter == 0
			if spent and hero.attack == null and duel.projectiles.is_empty():
				ended = true
				break
		check(ready_hp > 0 and spent and ended and rival.hp < spent_hp,profile.id+" earns and lands an ultimate before KO using only normal heavy/movement input")
		print("ULT BALANCE ",profile.id," ready target HP=",ready_hp," after ultimate=",rival.hp," elapsed=",60-duel.remaining)
		duel.start_round(false)
		hero.receive_hit(DuelFighter.ATTACKS.heavy,900)
		check(hero.hp == 188 and hero.meter == 5,profile.id+" incoming heavy grants five meter without changing its damage")
		hero.reset_at(560)
		hero.guarding = true
		hero.receive_hit(DuelFighter.ATTACKS.heavy,900)
		check(hero.hp == 197 and hero.meter == 4,profile.id+" blocking retains quarter damage and four meter")
		duel.phase = "fight"
		hero.reset_at(560)
		rival.reset_at(646)
		var opposing: Array[Dictionary] = [{"axis":200.0/float(hero.profile.combat.get("speed",285.0))},{"axis":-200.0/float(rival.profile.combat.get("speed",285.0))}]
		for frame in 120:
			duel.advance_fight(DT,opposing)
			view._process(DT)
		var travel := hero.walk_distance
		var gait := view.motion.gait
		for frame in 60:
			duel.advance_fight(DT,opposing)
			view._process(DT)
		check(absf(hero.walk_distance-travel) < .01 and absf(view.motion.gait-gait) < .001,profile.id+" feet stop cycling when both fighters push against each other")
		hero.reset_at(DuelFighter.RIGHT)
		rival.reset_at(DuelFighter.LEFT)
		for frame in 60:
			duel.advance_fight(DT,[{"axis":1},{}])
			view._process(DT)
		check(hero.walk_distance == 0 and view.motion.gait == 0 and view.motion.offset == Vector2.ZERO,profile.id+" wall contact produces no skating or whole-body hopping")
		hero.hp = 100
		hero.meter = 100
		duel.update_hud()
		check(duel.health[0].get_as_ratio() == .5 and duel.meters[0].glowing,profile.id+" half health and a ready ultimate are represented correctly in the HUD")
		hero.meter = 99
		duel.update_hud()
		check(not duel.meters[0].glowing,profile.id+" ultimate glow requires a fully charged meter")
		duel.set_stopped(true)
		var clock := duel.meters[0].clock
		duel.meters[0]._process(.5)
		check(duel.meters[0].clock == clock,profile.id+" ultimate animation freezes on pause")
		duel.queue_free()
		await get_tree().process_frame
	check(clips == 49,"all 49 attack clips render without texture or mesh warping")
	await get_tree().process_frame
	await get_tree().create_timer(.6).timeout
	print("QUALITY RESULT: %d passed, %d failed" % [passed,failed])
	get_tree().quit(0 if failed == 0 else 1)
