shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint : source_color = vec4(0.705882353, 0.713725490, 0.745098039, 1.0); // #b4b6be

void fragment() {
	float edge = smoothstep(0.0, 0.035, UV.y) * (1.0 - smoothstep(0.965, 1.0, UV.y));
	COLOR = vec4(tint.rgb, edge * opacity * tint.a);
}
