shader_type canvas_item;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 team_color : source_color = vec4(0.3,0.8,0.9,1.0);
uniform float team_rim : hint_range(0.0,1.0) = 0.25;
uniform float pose_alpha : hint_range(0.0,1.0) = 1.0;
uniform vec2 pivot_pixels = vec2(0.0);
uniform float body_height_pixels = 250.0;
uniform float gait_phase = 0.0;
uniform float walk_weight = 0.0;
uniform float body_lean = 0.0;
uniform float leg_swing = 0.04;
uniform float arm_swing = 0.03;
uniform float body_bounce = 0.012;
uniform bool blend_base = false;
uniform float overlay_weight = 0.0;
uniform sampler2D overlay_texture : filter_linear;
uniform vec4 overlay_uv = vec4(1.0,1.0,0.0,0.0);
uniform vec4 overlay_bounds = vec4(0.0,0.0,1.0,1.0);
uniform bool flow_blend = false;
uniform sampler2D motion_field : filter_linear;
uniform vec4 flow_uv = vec4(1.0,1.0,0.0,0.0);
uniform vec4 flow_pixel_uv = vec4(1.0);
uniform vec2 flow_canvas_size = vec2(512.0,384.0);
uniform float flow_range = 96.0;
uniform float flow_mix = 0.0;
uniform vec4 source_bounds = vec4(0.0,0.0,1.0,1.0);
void vertex() {
	vec2 p = (VERTEX-pivot_pixels)/body_height_pixels;
	float height = clamp(-p.y,0.0,1.2);
	float side = smoothstep(-0.09,0.09,p.x)*2.0-1.0;
	float leg_phase = gait_phase+side*1.5707963;
	float wave = cos(leg_phase);
	float legs = 1.0-smoothstep(0.30,0.59,height);
	float arms = smoothstep(0.11,0.25,abs(p.x))*smoothstep(0.40,0.58,height)*(1.0-smoothstep(0.82,0.98,height));
	p.x += walk_weight*(flow_blend ? 0.12 : 1.0)*(wave*legs*leg_swing+sin(gait_phase-side)*arms*arm_swing);
	p.y -= walk_weight*(flow_blend ? 0.12 : 1.0)*(max(0.0,-sin(leg_phase))*legs*0.052+abs(sin(gait_phase))*body_bounce*smoothstep(0.12,0.7,height));
	// Rotation around the feet keeps planted feet stable while the torso leans.
	float c = cos(body_lean);
	float s = sin(body_lean);
	p = vec2(c*p.x-s*p.y,s*p.x+c*p.y);
	VERTEX = pivot_pixels+p*body_height_pixels;
}
float bounds_mask(vec2 point, vec4 rect) {
	return step(rect.x,point.x)*step(rect.y,point.y)*step(point.x,rect.z)*step(point.y,rect.w);
}
vec4 field_at(vec2 point) {
	return (texture(motion_field,point)*255.0-128.0)*(flow_range/127.0);
}
void fragment() {
	if (flow_blend) {
		vec2 position = UV*flow_uv.xy+flow_uv.zw;
		vec4 initial = field_at(position);
		vec2 forward = field_at(position-flow_mix*initial.xy/flow_canvas_size).xy;
		vec2 backward = field_at(position-(1.0-flow_mix)*initial.zw/flow_canvas_size).zw;
		vec2 uv_a = UV-flow_mix*forward*flow_pixel_uv.xy;
		vec2 uv_b = UV*overlay_uv.xy+overlay_uv.zw-(1.0-flow_mix)*backward*flow_pixel_uv.zw;
		vec4 a = texture(TEXTURE,uv_a)*bounds_mask(uv_a,source_bounds);
		vec4 b = texture(overlay_texture,uv_b)*bounds_mask(uv_b,overlay_bounds);
		float alpha = mix(a.a,b.a,flow_mix);
		vec3 premultiplied = mix(a.rgb*a.a,b.rgb*b.a,flow_mix);
		vec3 aligned_color = premultiplied/max(alpha,0.001);
		// At disoccluded edges only one pose contains a limb. Prefer that
		// time-nearest silhouette instead of leaving a translucent second foot.
		float occlusion = smoothstep(0.1,0.9,abs(a.a-b.a));
		vec4 nearest_pose = flow_mix < 0.5 ? a : b;
		COLOR = vec4(mix(aligned_color,nearest_pose.rgb,occlusion),mix(alpha,nearest_pose.a,occlusion)*pose_alpha);
	} else {
	vec4 c = texture(TEXTURE, UV);
	vec2 pixel = TEXTURE_PIXEL_SIZE * 1.2;
	float rim = max(max(texture(TEXTURE,UV+vec2(pixel.x,0)).a,texture(TEXTURE,UV-vec2(pixel.x,0)).a),max(texture(TEXTURE,UV+vec2(0,pixel.y)).a,texture(TEXTURE,UV-vec2(0,pixel.y)).a));
	vec3 body = mix(c.rgb, vec3(1.0,0.95,0.87), hit_flash * 0.8);
	float outside = max(0.0, rim - c.a);
	COLOR = vec4(mix(body,team_color.rgb,outside),max(c.a,outside*team_rim));
	COLOR.a *= pose_alpha;
	// Exact over-compositing: overlapping opaque poses stay opaque instead of
	// fading to 75% alpha halfway through every step.
	if (blend_base) {
		vec2 next_uv = UV*overlay_uv.xy+overlay_uv.zw;
		float inside = step(overlay_bounds.x,next_uv.x)*step(overlay_bounds.y,next_uv.y)*step(next_uv.x,overlay_bounds.z)*step(next_uv.y,overlay_bounds.w);
		float coverage = texture(overlay_texture,next_uv).a*inside;
		COLOR.a /= max(0.001,1.0-overlay_weight*coverage);
	}
	}
}
