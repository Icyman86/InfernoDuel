shader_type canvas_item;
uniform float hit_flash = 0.0;
uniform float ultimate_glow = 0.0;
uniform vec4 ultimate_color : source_color = vec4(1.0,.7,.2,1.0);
uniform vec4 team_color : source_color = vec4(.3,.8,.9,1.0);
// Exposed diagnostics describe presentation. They never modify UV or vertices.
uniform bool flow_blend = false;
uniform float gait_phase = 0.0;
void fragment() {
	vec4 ink = texture(TEXTURE,UV);
	if (ultimate_glow > 0.0) {
		vec2 pixel = TEXTURE_PIXEL_SIZE * 2.0;
		float edge = min(min(texture(TEXTURE,UV+vec2(pixel.x,0)).a,texture(TEXTURE,UV-vec2(pixel.x,0)).a),min(texture(TEXTURE,UV+vec2(0,pixel.y)).a,texture(TEXTURE,UV-vec2(0,pixel.y)).a));
		ink.rgb += ultimate_color.rgb * ultimate_glow * (.12 + (1.0-edge)*.8);
	}
	ink.rgb = mix(ink.rgb,vec3(1.0,.95,.87),hit_flash*.8);
	COLOR = ink;
}
