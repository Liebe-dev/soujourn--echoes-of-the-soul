shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D ink_texture : filter_linear, repeat_disable;
uniform float tail_phase = 0.0;
uniform float head_phase = 1.0;
uniform float width_scale = 1.0;
uniform float opacity = 1.0;
uniform float detail_cutoff = 0.0;
uniform float progress = 0.0;
uniform float floor_clip = 10000.0;
uniform float remnant_start = 0.90;
uniform float remnant_end = 1.0;
varying float local_y;

void vertex() {
	local_y=VERTEX.y;
}

void fragment() {
	float phase = (UV.x - tail_phase) / max(head_phase - tail_phase, 0.001);
	float radius = 1.0 + (UV.y - 0.5) * 1.4 / max(width_scale, 0.02);
	float angle = 1.98 - 3.03 * phase;
	vec2 source_frame = vec2(950.0, 450.0) + vec2(cos(angle), sin(angle)) * vec2(620.0, 360.0) * radius;
	vec2 sample_uv = (source_frame - vec2(647.1531, 2.1739)) / vec2(1158.4567, 957.3913);
	float coverage = smoothstep(-0.015, 0.015, phase) * (1.0 - smoothstep(0.985, 1.015, phase));
	coverage *= step(0.0, radius) * step(0.0, sample_uv.x) * step(sample_uv.x, 1.0) * step(0.0, sample_uv.y) * step(sample_uv.y, 1.0);
	coverage *= 1.0-smoothstep(floor_clip-0.5,floor_clip+0.5,local_y);
	vec3 sampled = texture(ink_texture, sample_uv).rgb;
	float ink = max(sampled.r, max(sampled.g, sampled.b));
	float cutoff = detail_cutoff + 0.20 * smoothstep(0.35, 0.95, progress);
	float detail = smoothstep(cutoff, cutoff + 0.045, ink);
	float final_remnant = 1.0 - smoothstep(remnant_start, remnant_end, progress);
	COLOR = vec4(vec3(1.0), ink * detail * coverage * opacity * final_remnant);
}
