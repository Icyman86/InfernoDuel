class_name UltimateBanner
extends Control
var actor: DuelFighter
var title: Label
var detail: Label
var power: Label
var panel_style: StyleBoxFlat
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_style = UI.style(Color("18202c"),UI.GOLD,2)
	visible = false
	title = UI.label("ULTIMATE!",32,UI.GOLD,true)
	detail = UI.label("",16,UI.IVORY)
	power = UI.label("",17,UI.GOLD)
	for item in [title,detail,power]:
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(item)
	UI.place(title,6,2,393,39)
	UI.place(detail,6,42,393,24)
	UI.place(power,6,70,393,24)
func refresh() -> void:
	if not is_instance_valid(actor) or not title: return
	var age := DuelFighter.ULTIMATE_AURA_DURATION-actor.ultimate_time
	title.text = "ULTIMATE!" if age < 1.1 else "ULTIMATE POWER"
	title.add_theme_font_size_override("font_size",32 if age < 1.1 else 25)
	detail.text = str(actor.profile.display_name).to_upper()+" · "+actor.ultimate_move.to_upper()
	power.text = "+20%% FOLLOW-UP DAMAGE  ·  %.1fs" % actor.ultimate_time
	queue_redraw()
func _draw() -> void:
	draw_style_box(panel_style,Rect2(Vector2.ZERO,size))
	draw_line(Vector2(12,0),Vector2(size.x-12,0),UI.GOLD,4,true)
