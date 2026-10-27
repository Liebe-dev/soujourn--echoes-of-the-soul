shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 texture_frame_origin;
uniform vec2 texture_frame_size;
uniform vec2 arc_center;
uniform vec2 arc_radii;
uniform float arc_start;
uniform float arc_sweep;
uniform bool reverse_artwork = false;
uniform float motion_progress : hint_range(0.0, 1.0) = 0.0;
uniform float tail_phase = 0.0;
uniform float head_phase = 1.0;
uniform float width_scale = 1.0;
uniform float stroke_width : hint_range(0.05, 2.0) = 1.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float detail_cutoff : hint_range(0.0, 0.5) = 0.0;

void fragment() {
	vec2 frame_point = texture_frame_origin + UV * texture_frame_size;
	vec2 ellipse_point = (frame_point - arc_center) / arc_radii;
	vec2 sample_uv = UV;
	float coverage = 1.0;
	if (motion_progress > 0.0001 || abs(stroke_width - 1.0) > 0.0001 || reverse_artwork) {
		float angle = atan(ellipse_point.y, ellipse_point.x);
		float span = abs(arc_sweep);
		float distance_along = mod((angle - arc_start) * sign(arc_sweep) + TAU, TAU);
		// Unwrap the angle beyond both ends so the head can keep travelling.
		// Clamping it to the original arc would leave the old stationary tip.
		if (distance_along > span + PI * 0.5) {
			distance_along -= TAU;
		}
		float phase = distance_along / span;
		float source_phase = (phase - tail_phase) / max(head_phase - tail_phase, 0.001);
		float source_radius = 1.0 + (length(ellipse_point) - 1.0) / max(width_scale * stroke_width, 0.01);
		// Reversing travel also reverses the painted head/tail at full length.
		// Keeping the source phase unchanged would reverse only its disappearance.
		float painted_phase = reverse_artwork ? 1.0 - source_phase : source_phase;
		float source_angle = arc_start + arc_sweep * painted_phase;
		vec2 source_frame = arc_center + vec2(cos(source_angle), sin(source_angle)) * arc_radii * source_radius;
		sample_uv = (source_frame - texture_frame_origin) / texture_frame_size;
		// Remap the whole painted slash into a moving, narrowing arc window.
		// Its brush marks compress and move with the stroke, rather than being
		// revealed behind a wipe edge. Reject negative radii to avoid reflections.
		coverage *= smoothstep(-0.02, 0.02, source_phase);
		coverage *= 1.0 - smoothstep(0.98, 1.02, source_phase);
		coverage *= step(0.0, source_radius);
		coverage *= step(0.0, sample_uv.x) * step(sample_uv.x, 1.0);
		coverage *= step(0.0, sample_uv.y) * step(sample_uv.y, 1.0);
	}
	vec3 ink_rgb = texture(TEXTURE, sample_uv).rgb;
	float ink = max(ink_rgb.r, max(ink_rgb.g, ink_rgb.b));
	// Lose the faint rim and softer brush fibres first, while the white core
	// keeps its contrast. Only the tiny last remnant uses an opacity fade.
	float erosion = smoothstep(0.35, 0.95, motion_progress) * 0.22;
	float detail = smoothstep(detail_cutoff + erosion, detail_cutoff + erosion + 0.045, ink);
	float last_remnant = 1.0 - smoothstep(0.90, 1.0, motion_progress);
	COLOR = vec4(vec3(1.0), ink * detail * coverage * opacity * last_remnant);
}
