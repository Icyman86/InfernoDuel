class_name DuelProjectile
extends Node2D
var source: DuelFighter
var move: AttackData
var direction := 1
var age := 0.0
var spent := false

func setup(fighter: DuelFighter, data: AttackData) -> void:
	source = fighter
	move = data
	direction = fighter.facing
	position = fighter.position + Vector2(direction * 45, -55)

func step(delta: float) -> void:
	position.x += direction * 650.0 * delta
	age += delta
	if age > 1.8 or position.x < 0 or position.x > 1280: spent = true
	queue_redraw()

func hitbox() -> Rect2:
	return Rect2(position - Vector2(25,55), Vector2(50,110))

func _draw() -> void:
	var amber := Color("ffca7a")
	draw_set_transform(Vector2.ZERO,0,Vector2(direction,1))
	for layer in range(4,0,-1):
		draw_arc(Vector2(0,24),18+layer*10,-2.8,-0.3,24,Color(1,0.28,0.05,0.12*layer),layer*3,true)
	for strand in 7:
		var points := PackedVector2Array()
		for i in 14:
			var t := float(i)/13
			points.append(Vector2(-35+t*67,28-sin(t*PI)*(65+strand*4)+sin(t*13+age*21+strand)*5))
		draw_polyline(points,Color(amber,0.65),1.5,true)
	draw_set_transform(Vector2.ZERO)
