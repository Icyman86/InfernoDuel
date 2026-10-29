class_name CombatChrome
extends Control
## Angular armor plates, gold seams and fast, bounded geometry for mobile HUDs.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	for side in 2:
		var points := PackedVector2Array([Vector2(18,8),Vector2(530,8),Vector2(558,35),Vector2(558,132),Vector2(538,150),Vector2(39,150),Vector2(18,127)])
		if side == 1:
			for i in points.size(): points[i].x = 1280-points[i].x
		var color := UI.CYAN if side == 0 else UI.ORANGE
		draw_colored_polygon(points,Color("09111d"))
		points.append(points[0])
		draw_polyline(points,Color(color,.55),1.5,true)
		for i in 6:
			var x := 145.0+i*19
			if side == 1: x = 1280-x
			draw_line(Vector2(x,14),Vector2(x+(-9 if side else 9),22),Color(color,.4),3,true)
		var a := Vector2(128 if side == 0 else 748,59)
		draw_line(a,a+Vector2(404,0),Color("344452"),2,true)
		draw_line(a+Vector2(0,32),a+Vector2(404,32),Color(color,.7),1,true)
	var center := PackedVector2Array([Vector2(565,10),Vector2(715,10),Vector2(731,28),Vector2(713,145),Vector2(567,145),Vector2(549,28)])
	draw_colored_polygon(center,Color("101722"))
	center.append(center[0])
	draw_polyline(center,Color("a47a3a"),2,true)
	draw_line(Vector2(581,138),Vector2(699,138),UI.GOLD,3,true)
