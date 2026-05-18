shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float shake_amount : hint_range(0.0, 1.0) = 0.0;
uniform float shake_time = 0.0;

void fragment() {
	vec2 offset = vec2(
		sin(shake_time * 52.0),
		cos(shake_time * 43.0)
	) * shake_amount * 0.012;
	COLOR = texture(screen_texture, SCREEN_UV + offset);
}
