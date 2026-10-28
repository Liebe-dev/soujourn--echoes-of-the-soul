shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 tint : source_color = vec4(0.937254902, 0.141176471, 0.117647059, 1.0); // #ef241e
uniform vec4 highlight_tint : source_color = vec4(0.960784314, 0.364705882, 0.345098039, 1.0); // #f55d58
uniform vec4 paint_base : source_color = vec4(0.937254902, 0.141176471, 0.117647059, 1.0);
uniform vec4 paint_accent : source_color = vec4(0.960784314, 0.364705882, 0.345098039, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	vec3 direction = paint_accent.rgb - paint_base.rgb;
	float accent = dot(ink.rgb - paint_base.rgb, direction) / max(dot(direction, direction), 0.00001);
	accent = smoothstep(0.18, 0.8, accent);
	// Remove faint generation fringe and keep the painted core fully opaque.
	float coverage = smoothstep(0.5, 0.9, ink.a);
	COLOR = vec4(mix(tint.rgb, highlight_tint.rgb, accent), coverage * opacity * tint.a);
}
