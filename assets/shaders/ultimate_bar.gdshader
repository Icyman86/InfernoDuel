shader_type canvas_item;
uniform float charge = 0.0;
uniform float phase_time = 0.0;
uniform bool reversed = false;
uniform vec4 accent : source_color = vec4(0.2,0.8,1.0,1.0);
void fragment() {
	vec2 uv = UV;
	if (reversed) uv.x = 1.0-uv.x;
	float x = (uv.x-0.02)/0.96;
	float edge = max(abs(uv.y-0.5)-0.19,max(-x,x-1.0));
	float casing = 1.0-smoothstep(0.015,0.045,edge);
	float bar = (1.0-smoothstep(-0.015,0.005,edge))*step(x,charge);
	float ready = step(0.999,charge);
	float pulse = 0.75+0.25*sin(phase_time*5.5);
	vec3 energy = mix(accent.rgb,vec3(1.0,0.57,0.09),ready);
	float streak = pow(max(0.0,1.0-abs(fract(x-phase_time*.35)-.5)*8.0),4.0);
	float glow = exp(-max(edge,0.0)*18.0)*ready*pulse*.5;
	float ribs = 1.0-step(.91,fract(x*18.0));
	vec3 color = vec3(.04,.07,.11)*casing;
	color += energy*bar*(.65+.35*uv.y+ready*(.5+streak))*ribs;
	color += energy*glow;
	COLOR = vec4(color,max(casing*.92,glow)*step(-.02,x)*step(x,1.02));
}
