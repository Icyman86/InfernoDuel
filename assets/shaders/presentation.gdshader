shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_texture : source_color, filter_linear;
uniform sampler2D overlay_texture : source_color, filter_linear;
uniform sampler2D motion_field : filter_linear;
uniform bool flow_blend = false;
uniform float flow_mix = 0.0;
uniform vec4 overlay_uv = vec4(1.0,1.0,0.0,0.0);
uniform vec4 overlay_bounds = vec4(0.0,0.0,1.0,1.0);
uniform vec4 source_bounds = vec4(0.0,0.0,1.0,1.0);
uniform vec4 flow_uv = vec4(1.0,1.0,0.0,0.0);
uniform vec4 flow_pixel_uv = vec4(1.0);
uniform vec2 flow_canvas_size = vec2(640.0,448.0);
uniform float flow_range = 144.0;
float bounds_mask(vec2 p,vec4 r) {return step(r.x,p.x)*step(r.y,p.y)*step(p.x,r.z)*step(p.y,r.w);}
vec4 field_at(vec2 p) {return (texture(motion_field,p)*255.0-128.0)*(flow_range/127.0);}
void fragment() {
	vec4 color = texture(base_texture,UV);
	if (flow_blend) {
		vec2 p = UV*flow_uv.xy+flow_uv.zw;
		vec4 initial = field_at(p);
		vec2 forward = field_at(p-flow_mix*initial.xy/flow_canvas_size).xy;
		vec2 backward = field_at(p-(1.0-flow_mix)*initial.zw/flow_canvas_size).zw;
		vec2 a_uv = UV-flow_mix*forward*flow_pixel_uv.xy;
		vec2 b_uv = UV*overlay_uv.xy+overlay_uv.zw-(1.0-flow_mix)*backward*flow_pixel_uv.zw;
		vec4 a = texture(base_texture,a_uv)*bounds_mask(a_uv,source_bounds);
		vec4 b = texture(overlay_texture,b_uv)*bounds_mask(b_uv,overlay_bounds);
		float alpha = mix(a.a,b.a,flow_mix);
		vec3 rgb = mix(a.rgb*a.a,b.rgb*b.a,flow_mix)/max(alpha,.001);
		float occlusion = smoothstep(.1,.9,abs(a.a-b.a));
		vec4 nearest_pose = flow_mix < .5 ? a : b;
		color = vec4(mix(rgb,nearest_pose.rgb,occlusion),mix(alpha,nearest_pose.a,occlusion));
	}
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = .12;
	ROUGHNESS = .8;
}
