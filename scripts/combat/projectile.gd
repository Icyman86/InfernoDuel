class_name DuelProjectile
extends Node2D
var source: DuelFighter
var move: AttackData
var direction := 1
var age := 0.0
var spent := false
var kind := "ground_shock"
var speed := 650.0
var lifetime := 1.8
var size := Vector2(50,110)

func setup(fighter: DuelFighter, data: AttackData) -> void:
	source = fighter
	move = data
	direction = fighter.facing
	kind = fighter.attack_kind(data.id)
	position = fighter.position + Vector2(direction*45,-55)
	match kind:
		"toxic_orb":
			speed = 460
			lifetime = 2.2
			size = Vector2(58,64)
			position.y -= 100
		"venom_cloud":
			speed = 280
			lifetime = 2.4
			size = Vector2(165,190)
			position.y -= 45
		"cheese_ball":
			speed = 560
			size = Vector2(60,66)
			position.y -= 90
			if fighter.attack_variant == "trap":
				kind = "cheese_trap"
				speed = 0
				lifetime = 4.0
				size = Vector2(74,58)
				position.y = DuelFighter.FLOOR-25
				position.x = fighter.position.x-direction*35
		"cheese_king":
			speed = 430
			lifetime = 2.5
			size = Vector2(135,145)
			position.y -= 90

func step(delta: float) -> void:
	position.x += direction*speed*delta
	age += delta
	if age > lifetime or position.x < -100 or position.x > 1380: spent = true
	queue_redraw()

func hitbox() -> Rect2:
	return Rect2(position-size*0.5,size)

func _draw() -> void:
	if kind in ["toxic_orb","venom_cloud"]:
		var color := Color("94df59")
		var radius := 28.0 if kind == "toxic_orb" else 77.0
		for layer in range(4,0,-1):
			draw_circle(Vector2.ZERO,radius+layer*5,Color(color,0.045))
		for i in 9:
			var angle := age*2+i*TAU/9
			var p := Vector2.from_angle(angle)*radius*0.55
			draw_circle(p,radius*(0.25+0.08*sin(age*9+i)),Color(color,0.35))
			draw_arc(p,radius*0.28,0,TAU,16,Color("d3ff8b"),1.2,true)
		draw_circle(Vector2.ZERO,radius*.42,Color("e2ffac"))
	elif kind in ["cheese_ball","cheese_trap","cheese_king"]:
		var radius := size.x*0.43
		draw_circle(Vector2.ZERO,radius+11,Color(1,0.65,0.08,0.12))
		draw_circle(Vector2.ZERO,radius,Color("ffcb52"))
		for i in 6:
			var p := Vector2.from_angle(age*4+i*TAU/6)*radius*0.6
			draw_circle(p,radius*.14,Color("b97824"))
		if kind == "cheese_king":
			draw_colored_polygon(PackedVector2Array([Vector2(-38,-radius+8),Vector2(-42,-radius-27),Vector2(-18,-radius-14),Vector2(0,-radius-38),Vector2(18,-radius-14),Vector2(42,-radius-27),Vector2(38,-radius+8)]),Color("ffed9d"))
		if kind == "cheese_trap":
			draw_arc(Vector2.ZERO,radius+10,0,TAU,24,Color("ffed9d"),2,true)
	else:
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
