class_name UltimateGauge
extends Control
var accent := UI.CYAN
var reversed := false
var duel: DuelMatch
var shader_fx: ShaderMaterial
var clock := 0.0
var value := 0.0:
	set(next):
		value = clampf(next,0,100)
		if shader_fx: shader_fx.set_shader_parameter("charge",value/100.0)
var glowing: bool:
	get: return value >= 100

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strip := ColorRect.new()
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shader_fx = ShaderMaterial.new()
	shader_fx.shader = preload("res://assets/shaders/ultimate_bar.gdshader")
	shader_fx.set_shader_parameter("accent",accent)
	shader_fx.set_shader_parameter("reversed",reversed)
	shader_fx.set_shader_parameter("charge",value/100.0)
	strip.material = shader_fx
	add_child(strip)

func _process(delta: float) -> void:
	if is_instance_valid(duel) and duel.stopped: return
	clock += delta
	shader_fx.set_shader_parameter("phase_time",clock)
