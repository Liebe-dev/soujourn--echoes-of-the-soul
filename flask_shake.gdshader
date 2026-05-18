shader_type canvas_item;

uniform float shake_amount : hint_range(0.0, 1.0) = 0.0;
uniform float shake_time = 0.0;

void fragment() {
	vec2 offset = vec2(
		sin(shake_time * 64.0),
		cos(shake_time * 58.0)
	) * shake_amount * 0.018;
	COLOR = texture(TEXTURE, UV + offset);
}
