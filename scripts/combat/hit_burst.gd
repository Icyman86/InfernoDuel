class_name HitBurst
extends Node2D
var color := Color("ffca7a")
var blocked := false
var age := 0.0
var seed_angle := 0.0

func _process(delta: float) -> void:
	age += delta
	if age >= 0.26:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var t := age/0.26
	var alpha := pow(1.0-t,2)
	var radius := 12+80*t
	draw_circle(Vector2.ZERO,28*(1-t),Color(color,0.25*alpha))
	if blocked:
		draw_arc(Vector2.ZERO,radius*0.7,0,TAU,32,Color(color,alpha),2,true)
	else:
		for i in 11:
			var angle := i*TAU/11+seed_angle
			var axis := Vector2.from_angle(angle)
			var outer := radius*(0.6+0.4*sin(i*13.0))
			draw_line(axis*radius*0.25,axis*outer,Color(color,alpha),2.5*(1-t),true)
		draw_line(Vector2(-radius,0),Vector2(radius,0),Color(1,0.93,0.8,alpha),2,true)
