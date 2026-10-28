extends Node
## Deterministic artwork review, not a recorded human-played match.
var game: Control
var duel: DuelMatch
var elapsed := 0.0
var last_state := ""
const STATES := ["idle","walk","guard","jump","light","heavy","special","ultimate","hit","ko"]

func _ready() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	add_child(game)
	game.show_select(false)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < 2.5: return
	if not duel:
		game.start_match()
		duel = game.match_node
		duel.set_physics_process(false)
		duel.phase = "fight"
	var cycle := elapsed-2.5
	var index := int(cycle/1.4)
	if index >= STATES.size():
		get_tree().quit()
		return
	var state: String = STATES[index]
	var t := fmod(cycle,1.4)/1.4
	duel.announcement.text = state.to_upper()
	duel.announcement.add_theme_font_size_override("font_size",32)
	for i in 2:
		var actor := duel.fighters[i]
		actor.position = Vector2(430 if i == 0 else 850,DuelFighter.FLOOR)
		actor.facing = 1 if i == 0 else -1
		actor.hp = 100
		actor.guarding = false
		actor.stun = 0
		actor.attack = null
		actor.velocity = Vector2.ZERO
		if state == "walk":
			actor.velocity.x = actor.facing*200
			actor.position.x += actor.facing*sin(t*TAU)*35
		elif state == "guard": actor.guarding = true
		elif state == "jump": actor.position.y -= sin(PI*t)*145
		elif state == "hit":
			actor.stun = 0.3
			actor.position.x -= actor.facing*sin(t*PI)*20
		elif state == "ko": actor.hp = 0
		elif state in ["light","heavy","special","ultimate"]:
			actor.attack = DuelFighter.ATTACKS[state]
			actor.attack_time = fmod(t*2,1.0)*actor.attack.duration()
			if state == "special": actor.position.x += actor.facing*sin(t*PI)*100
		actor.visual._update_pose()
	duel.update_hud()
