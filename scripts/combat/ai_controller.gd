class_name DuelAI
extends RefCounted
var decision_time := 0.0
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func sample(delta: float, fighter: DuelFighter, target: DuelFighter) -> Dictionary:
	decision_time -= delta
	var distance := target.position.x - fighter.position.x
	var result := {"axis": signf(distance) if absf(distance) > 98 else 0, "block": false}
	if decision_time <= 0.0:
		decision_time = rng.randf_range(0.22, 0.5)
		if target.is_active() and absf(distance) < 180 and rng.randf() < 0.45:
			result.block = true
		elif fighter.meter >= 100 and absf(distance) < 190:
			result.ultimate = true
		elif absf(distance) < 125:
			result["heavy" if rng.randf() < 0.35 else "light"] = true
		elif absf(distance) < 380 and rng.randf() < 0.65:
			result.special = true
		if rng.randf() < 0.08: result.jump = true
	return result
