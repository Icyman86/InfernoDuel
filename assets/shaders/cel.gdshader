shader_type canvas_item;
uniform float hit_flash = 0.0;
uniform vec4 team_color : source_color = vec4(.3,.8,.9,1.0);
// Exposed diagnostics describe presentation. They never modify UV or vertices.
uniform bool flow_blend = false;
uniform float gait_phase = 0.0;
void fragment() {
	vec4 ink = texture(TEXTURE,UV);
	ink.rgb = mix(ink.rgb,vec3(1.0,.95,.87),hit_flash*.8);
	COLOR = ink;
}
