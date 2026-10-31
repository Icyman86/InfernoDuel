class_name ArenaRules
extends RefCounted
## All clocks advance only from the authoritative combat tick.
const TRAP_POSITIONS := [460.0,820.0]
var elapsed := 0.0
var grabs: Array[Dictionary] = []
var trap_hits: Array[Dictionary] = [{},{}]

func reset() -> void:
	elapsed = 0
	grabs.clear()
	trap_hits = [{},{}]

func trap_phase(index: int) -> String:
	var age := fposmod(elapsed+index*3.6,8.0)
	if age >= 5.0 and age < 6.2: return "warning"
	if age >= 6.2 and age < 6.65: return "active"
	return "cooldown"

func step(delta: float, fighters: Array[DuelFighter], inputs: Array[Dictionary]) -> void:
	elapsed += delta
	# Simultaneous grabs tech before either player can acquire a victim.
	var requests: Array[bool] = []
	for i in 2:
		var a := fighters[i]
		var b := fighters[1-i]
		requests.append(inputs[i].get("grab",false) and a.hp > 0 and a.grounded() and a.stun <= 0 and not a.attack and a.grab_cooldown <= 0 and b.hp > 0 and b.grounded() and b.throw_protection <= 0 and absf(a.position.x-b.position.x) <= 115)
	if requests[0] and requests[1]:
		for f in fighters: _tech(f)
	else:
		for i in 2:
			if requests[i] and grabs.is_empty():
				fighters[i].grapple_pose = .5
				fighters[1-i].throw_pose = .45
				fighters[i].grab_cooldown = 1.1
				fighters[i].stun = .45
				fighters[1-i].stun = .45
				fighters[1-i].guarding = false
				fighters[1-i].attack = null
				grabs.append({"owner":i,"age":0.0,"hp":fighters[i].hp,"back":float(inputs[i].get("axis",0))*fighters[i].facing < -.4})
				fighters[i].command_notice = "GRAB · THROW"
				fighters[i].notice_time = .6
	for index in range(grabs.size()-1,-1,-1):
		var grab: Dictionary = grabs[index]
		var owner: int = grab.owner
		var a := fighters[owner]
		var b := fighters[1-owner]
		grab.age += delta
		if a.hp < grab.hp or a.trapped or a.hp <= 0 or b.hp <= 0 or b.immunity > 0 or a.stun <= 0:
			b.stun = minf(b.stun,.1)
			b.throw_pose = 0
			a.grapple_pose = 0
			grabs.remove_at(index)
			continue
		if grab.age <= .22 and inputs[1-owner].get("grab",false):
			_tech(a)
			_tech(b)
			grabs.remove_at(index)
		elif grab.age >= .25:
			var direction := -a.facing if grab.back else a.facing
			b.guarding = false
			var hit := AttackData.new()
			hit.damage = 18
			hit.knockback = 440
			hit.hitstun = .6
			b.receive_hit(hit,b.position.x-direction*100)
			b.position.x = clampf(a.position.x+direction*105,DuelFighter.LEFT,DuelFighter.RIGHT)
			b.velocity = Vector2(direction*440,-280)
			b.throw_pose = .65
			b.throw_protection = 1.3
			a.meter = mini(100,a.meter+10)
			grabs.remove_at(index)
	for index in 2:
		if trap_phase(index) != "active":
			trap_hits[index].clear()
			continue
		for f in fighters:
			if trap_hits[index].has(f.player) or f.hp <= 0 or not f.grounded() or f.immunity > 0: continue
			if absf(f.position.x-TRAP_POSITIONS[index]) <= 44:
				trap_hits[index][f.player] = true
				f.stun = maxf(f.stun,.75)
				f.attack = null
				f.guarding = false
				f.trapped = true
				f.velocity = Vector2.ZERO
				f.command_notice = "CLAMPED · BREAK FREE / WAIT"
				f.notice_time = .75
				f.throw_protection = .95

func _tech(f: DuelFighter) -> void:
	f.stun = 0
	f.grapple_pose = 0
	f.throw_pose = 0
	f.throw_protection = .7
	f.grab_cooldown = .7
	f.command_notice = "THROW TECH"
	f.notice_time = .8
	f.velocity.x = -f.facing*220
