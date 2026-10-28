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
	draw_circle(Vector2.ZERO, 34, Color(source.tint,0.18))
	for i in 3:
		var x := (i - 1) * 16.0
		draw_colored_polygon(PackedVector2Array([Vector2(x-12,50),Vector2(x, -42-i*5),Vector2(x+14,50)]), source.tint)
