class_name UltimateAura
extends Node2D
## Bounded, texture-free mobile effect driven only by authoritative sim time.
var actor: DuelFighter
func _ready() -> void:
	z_index = 0
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
func _process(_delta: float) -> void:
	visible = is_instance_valid(actor) and actor.hp > 0 and actor.ultimate_time > 0 and actor.get_parent().get("phase") == "fight"
	if visible: queue_redraw()
func _draw() -> void:
	if not is_instance_valid(actor) or actor.ultimate_time <= 0: return
	var age := DuelFighter.ULTIMATE_AURA_DURATION-actor.ultimate_time
	var fade := minf(1.0,actor.ultimate_time/.35)
	var color := Color(actor.profile.get("accent","ffd369")).lerp(Color("ffd369"),.45)
	var pulse := 1.0+.045*sin(age*7)
	draw_set_transform(Vector2(0,-130),0,Vector2(.75,1.25)*pulse)
	for i in range(6,0,-1):
		draw_circle(Vector2.ZERO,72+i*9,Color(color,.045*fade))
	for i in 14:
		var a := i*TAU/14+age*.35
		var radius := 90+sin(i*3.2+age*3)*10
		var p := Vector2(cos(a),sin(a))*radius
		draw_line(p,p*1.16,Color(color,.85*fade),3,true)
	draw_arc(Vector2.ZERO,112,age,age+PI*1.3,48,Color(color,.85*fade),4,true)
	draw_set_transform(Vector2(0,-3),-age*.3,Vector2(1,.22))
	draw_arc(Vector2.ZERO,110,0,TAU,64,Color(color,.8*fade),4,true)
	if age < .55:
		draw_arc(Vector2.ZERO,80+age*180,0,TAU,64,Color("fff0b5",(1-age/.55)*.8),4,true)
