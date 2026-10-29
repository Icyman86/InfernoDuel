shader_type canvas_item;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 team_color : source_color = vec4(0.3,0.8,0.9,1.0);
uniform float team_rim : hint_range(0.0,1.0) = 0.25;
uniform float pose_alpha : hint_range(0.0,1.0) = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 pixel = TEXTURE_PIXEL_SIZE * 1.2;
	float rim = max(max(texture(TEXTURE,UV+vec2(pixel.x,0)).a,texture(TEXTURE,UV-vec2(pixel.x,0)).a),max(texture(TEXTURE,UV+vec2(0,pixel.y)).a,texture(TEXTURE,UV-vec2(0,pixel.y)).a));
	vec3 body = mix(c.rgb, vec3(1.0,0.95,0.87), hit_flash * 0.8);
	float outside = max(0.0, rim - c.a);
	COLOR = vec4(mix(body,team_color.rgb,outside),max(c.a,outside*team_rim));
	COLOR.a *= pose_alpha;
}
