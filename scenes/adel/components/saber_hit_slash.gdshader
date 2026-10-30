shader_type canvas_item;
render_mode unshaded;

uniform vec4 ink_color : source_color = vec4(0.929411765, 0.952941176, 0.968627451, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float lightness = max(source.r, max(source.g, source.b));
	vec3 rgb = mix(source.rgb, ink_color.rgb, smoothstep(0.25, 0.6, lightness));
	COLOR = vec4(rgb, source.a * opacity * ink_color.a);
}
