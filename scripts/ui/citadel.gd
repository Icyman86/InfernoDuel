class_name Citadel
extends Node2D
var time := 0.0
var fighting := false

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720), Color("0b0911"))
	for i in range(11,0,-1):
		draw_circle(Vector2(640,360), i*47, Color(0.13+0.005*i,0.045,0.058,0.1))
	# Distant citadel: broken towers and vaulted windows, parallax drifting smoke.
	for i in 13:
		var x := float(i*112-32)
		var top := 160.0 + sin(i*8.0)*65
		draw_rect(Rect2(x,top,76,420), Color("17131e"))
		draw_colored_polygon(PackedVector2Array([Vector2(x-8,top),Vector2(x+35,top-80),Vector2(x+85,top)]),Color("1e1720"))
		for j in 3:
			var y := top+50+j*90
			draw_style_box(arch_style(),Rect2(x+23,y,30,65))
	for i in 7:
		var x := i*220.0-60
		draw_rect(Rect2(x,320,30,285),Color("211b25"))
		draw_line(Vector2(x+15,320),Vector2(x+75,258),Color("211b25"),14,true)
		draw_line(Vector2(x+75,258),Vector2(x+155,330),Color("211b25"),14,true)
	for i in 9:
		var x := fmod(i*193.0+time*7,1500)-100
		draw_smoke_ellipse(Vector2(x,330+sin(i*4.0+time*.2)*80),Vector2(140,32),Color(0.3,0.23,0.25,0.035))
	# Lava under a freestanding stone platform.
	draw_rect(Rect2(0,604,1280,116), Color("491720"))
	for i in 35:
		var x := i*39.0
		var y := 640+sin(i*2.8+time)*16
		draw_line(Vector2(x,y),Vector2(x+30,y+8),Color(0.94,0.27,0.1,0.28),3,true)
	draw_colored_polygon(PackedVector2Array([Vector2(28,590),Vector2(1252,590),Vector2(1280,632),Vector2(0,632)]),Color("302632"))
	draw_rect(Rect2(28,590,1224,7),Color("77616a"))
	for i in 16:
		var x := float(i*85)
		draw_line(Vector2(x,600),Vector2(x+24,630),Color("17131c"),2)
	for i in 32:
		var x := fmod(i*143.7+sin(time*.7+i)*17,1280)
		var y := 690-fmod(i*63.3+time*(18+i%6),560)
		draw_circle(Vector2(x,y),1.4+i%2,Color(1,0.38,0.14,0.15+0.4*(y/720)))

func arch_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("41202a")
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	return style

func draw_smoke_ellipse(center: Vector2, scale_by: Vector2, color: Color) -> void:
	draw_set_transform(center,0,scale_by)
	draw_circle(Vector2.ZERO,1,color)
	draw_set_transform(Vector2.ZERO)
