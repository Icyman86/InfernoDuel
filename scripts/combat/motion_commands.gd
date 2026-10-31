class_name MotionCommands
extends RefCounted
## Simulation-time history: pauses cannot complete or expire a command.
var clock := 0.0
var history: Array[Dictionary] = []
var last_direction := 5

func reset() -> void:
	clock = 0
	history.clear()
	last_direction = 5

func sample(delta: float, input: Dictionary, facing: int) -> String:
	clock += delta
	var horizontal := float(input.get("axis", 0)) * facing
	var direction := 6 if horizontal > .4 else (4 if horizontal < -.4 else 5)
	if input.get("block", false): direction = 3 if direction == 6 else (1 if direction == 4 else 2)
	if direction != last_direction:
		history.append({"d":direction,"t":clock})
		last_direction = direction
	while not history.is_empty() and clock-float(history[0].t) > .38: history.pop_front()
	if history.size() > 12: history.pop_front()
	var directions: Array[int] = []
	for item in history: directions.append(int(item.d))
	if input.get("special", false) and directions.size() >= 3 and directions.slice(-3) == [2,3,6]:
		history.clear()
		return "rising"
	if input.get("heavy", false) and directions.size() >= 3 and directions.slice(-3) == [6,5,6]:
		history.clear()
		return "rush"
	return ""
