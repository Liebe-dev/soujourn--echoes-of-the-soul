shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float age = 0.0;
uniform float opacity = 0.82;
uniform vec2 bounds_origin = vec2(170.0,800.0);
uniform vec2 bounds_size = vec2(1460.0,134.0);

float stroke(vec2 p,vec2 start,vec2 finish,float height,float thickness,float cut) {
	float u=(p.x-start.x)/(finish.x-start.x);
	float v=clamp(u,0.0,1.0);
	float taper=pow(max(0.0,sin(v*3.14159265)),0.8);
	float center=mix(start.y,finish.y,v)-height*sin(v*3.14159265);
	float half_width=thickness*taper;
	float body=1.0-smoothstep(half_width,half_width+0.85,abs(p.y-center));
	float clear=smoothstep(cut-0.045,cut+0.045,v);
	return body*clear*step(0.0,u)*step(u,1.0);
}

void fragment() {
	vec2 p=bounds_origin+UV*bounds_size;
	float t=max(age,0.0);
	float progress=clamp(t/0.26,0.0,1.0);
	float expand=1.0-pow(1.0-progress,2.0);
	float cut=smoothstep(0.055,0.25,t)*0.96;
	float width=mix(7.5,0.6,pow(progress,0.75));
	// Two clean, low pressure ribbons; no volumetric noise, smoke or floating particles.
	float left=stroke(p,vec2(930.0-150.0*expand,917.0),vec2(370.0-130.0*expand,921.0),15.0+7.0*expand,width,cut);
	float right=stroke(p,vec2(1000.0+80.0*expand,917.0),vec2(1440.0+100.0*expand,921.0),12.0+4.0*expand,width*0.8,cut);
	float fine=stroke(p,vec2(920.0-170.0*expand,921.5),vec2(480.0-210.0*expand,922.0),4.0,width*0.25,cut+0.10)*0.45;
	// A short, flat contact mark links the downward crush to the outgoing air.
	float q=(p.x-1170.0)/190.0;
	float height=max(0.0,1.0-q*q)*11.0;
	float contact=(1.0-smoothstep(height,height+0.8,923.0-p.y))*step(p.y,923.0)*step(0.0,height);
	contact*=1.0-smoothstep(0.015,0.070,t);
	float a=max(max(left,right),max(fine,contact));
	a*=step(0.0,age)*(1.0-smoothstep(0.22,0.27,t));
	a*=1.0-smoothstep(922.7,923.5,p.y);
	COLOR=vec4(vec3(0.96,0.97,0.99),a*opacity);
}
