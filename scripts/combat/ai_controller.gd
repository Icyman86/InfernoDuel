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
		# Learn the same directional commands shown in the move lab. Only select
		# affordable variants; guard is the modifier, not a separate AI ability.
		for slot in ["light", "special", "ultimate"]:
			if result.get(slot, false) and rng.randf() < 0.28:
				var choices: Array[AttackData] = []
				for move in fighter.moves.values():
					if move.slot == slot and move.command != "neutral" and move.meter_cost <= fighter.meter:
						choices.append(move)
				if not choices.is_empty():
					result.merge(MoveCatalog.input_for(choices[rng.randi_range(0, choices.size()-1)], fighter.facing), true)
		if rng.randf() < 0.08: result.jump = true
	return result
