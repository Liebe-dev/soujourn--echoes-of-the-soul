shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D ink_texture : filter_linear, repeat_disable;
uniform float crush = 0.0;
uniform float age = 0.0;
uniform float floor_y = 923.0;
uniform float opacity = 0.96;
varying float local_y;

void vertex() {
	local_y=VERTEX.y;
}

void fragment() {
	// Keep the source artwork fixed on the ribbon: never remap a shrinking tail.
	float phase=UV.x;
	float radius=1.0+(UV.y-0.5)*1.4;
	float angle=1.98-3.03*phase;
	vec2 source=vec2(950.0,450.0)+vec2(cos(angle),sin(angle))*vec2(620.0,360.0)*radius;
	vec2 sample_uv=(source-vec2(647.1531,2.1739))/vec2(1158.4567,957.3913);
	float coverage=smoothstep(-0.015,0.015,phase)*(1.0-smoothstep(0.985,1.015,phase));
	coverage*=step(0.0,radius)*step(0.0,sample_uv.x)*step(sample_uv.x,1.0)*step(0.0,sample_uv.y)*step(sample_uv.y,1.0);
	coverage*=1.0-smoothstep(floor_y-0.5,floor_y+0.5,local_y);
	vec3 sampled=texture(ink_texture,sample_uv).rgb;
	float ink=max(sampled.r,max(sampled.g,sampled.b));
	float erase=smoothstep(0.15,1.0,crush);
	float edge=phase+sin(UV.y*29.0+phase*11.0)*0.022;
	coverage*=smoothstep(erase-0.045,erase+0.045,edge);
	float detail=smoothstep(0.035+crush*0.38,0.080+crush*0.38,ink);
	// Clear the very flat final contact before it can become a bright floor dot.
	float end=1.0-smoothstep(0.092,0.125,age);
	COLOR=vec4(vec3(1.0),ink*detail*coverage*end*opacity);
}
