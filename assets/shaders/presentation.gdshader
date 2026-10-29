shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_texture : source_color, filter_linear;
void fragment() {
	vec4 color = texture(base_texture,UV);
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = .12;
	ROUGHNESS = .8;
}
