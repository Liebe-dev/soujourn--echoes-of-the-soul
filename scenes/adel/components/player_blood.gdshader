shader_type canvas_item;

uniform sampler2D blood_atlas : filter_linear, repeat_disable;
uniform vec4 blood_tint : source_color = vec4(0.521568627, 0.019607843, 0.019607843, 1.0);
uniform vec2 source_size;
uniform vec2 frame_origin;
uniform bool filter_material = false;
uniform int mark_count = 0;
uniform vec4 mark_pose[9]; // center in source-frame pixels, fitted size
uniform vec4 mark_ink[9]; // normalized atlas crop
uniform vec4 mark_style[9]; // angle, opacity, body site
uniform int region_counts[5];
uniform vec2 region_points[60];
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

bool in_region(vec2 p, int site) {
	int count = region_counts[site];
	if (count < 3) { return true; }
	bool inside = false;
	int previous = count - 1;
	for (int j = 0; j < 12; j++) {
		if (j >= count) { break; }
		vec2 a = region_points[site * 12 + j];
		vec2 b = region_points[site * 12 + previous];
		if ((a.y > p.y) != (b.y > p.y)) {
			float crossing = (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x;
			if (p.x < crossing) { inside = !inside; }
		}
		previous = j;
	}
	return inside;
}

void fragment() {
	vec4 body = texture(TEXTURE, UV);
	vec2 pixel = UV * source_size - frame_origin;
	float coverage = 0.0;
	for (int i = 0; i < 9; i++) {
		if (i >= mark_count) { break; }
		vec4 pose = mark_pose[i];
		vec4 style = mark_style[i];
		int site = int(style.z);
		if (pose.z <= 0.0 || pose.w <= 0.0 || !in_region(pixel, site)) { continue; }
		vec2 d = pixel - pose.xy;
		float c = cos(style.x);
		float s = sin(style.x);
		vec2 p = vec2(c*d.x+s*d.y, -s*d.x+c*d.y) / pose.zw + vec2(0.5);
		if (any(lessThan(p, vec2(0.0))) || any(greaterThan(p, vec2(1.0)))) { continue; }
		float eligible = 1.0;
		float high = max(body.r, max(body.g, body.b));
		float low = min(body.r, min(body.g, body.b));
		if (site == 4) {
			// Exposed cheek only; retain hair, eye, mask and the existing scar.
			eligible = step(body.g * 1.06, body.r) * step(body.b * 1.08, body.r) * step(0.30, body.g);
		} else if (filter_material) {
			if (site < 2) {
				eligible = step(0.43, low) * step(high - low, 0.12);
			} else {
				eligible = step(high, 0.38) * step(high - low, 0.09);
			}
		}
		vec4 ink = mark_ink[i];
		float alpha = texture(blood_atlas, ink.xy + p * ink.zw).a;
		coverage = max(coverage, alpha * style.y * eligible);
	}
	float preserve_line = smoothstep(0.025, 0.105, dot(body.rgb, vec3(0.2126,0.7152,0.0722)));
	COLOR = vec4(mix(body.rgb, blood_tint.rgb, coverage * preserve_line), body.a) * vertex_tint;
}
