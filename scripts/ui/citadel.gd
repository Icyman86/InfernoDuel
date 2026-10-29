class_name Citadel
extends Node2D
const PLATE = preload("res://assets/arenas/infernal_citadel.png")
var time := 0.0
var fighting := false
var view_rect := Rect2(0,0,1280,720)

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	# Fill the real surface, including wide-phone wings and tablet foreground.
	# Keep the painted floor line under the fighters while extending the scenery.
	var pixels := Vector2(PLATE.get_size())
	var floor_y := DuelFighter.FLOOR
	var split := pixels.y*floor_y/720.0
	draw_texture_rect_region(PLATE,Rect2(view_rect.position,Vector2(view_rect.size.x,floor_y-view_rect.position.y)),Rect2(0,0,pixels.x,split))
	draw_texture_rect_region(PLATE,Rect2(view_rect.position.x,floor_y,view_rect.size.x,view_rect.end.y-floor_y),Rect2(0,split,pixels.x,pixels.y-split))
	# Subtle living light and airborne cinders over the painted environment.
	for i in 5:
		var center := Vector2(140+i*260,540+sin(i*2.0)*35)
		var pulse := 0.035+sin(time*1.3+i)*0.012
		draw_set_transform(center,0,Vector2(2.4,0.5))
		draw_circle(Vector2.ZERO,90,Color(1,0.21,0.03,pulse))
		draw_set_transform(Vector2.ZERO)
	for i in 52:
		var x := view_rect.position.x+fmod(i*143.7+sin(time*.5+i)*24,view_rect.size.x)
		var y := 710-fmod(i*63.3+time*(12+i%8),620)
		var a := 0.12+0.25*(y/720.0)
		draw_line(Vector2(x,y),Vector2(x+sin(i)*1.5,y+3),Color(1,0.5,0.22,a),1,true)
