shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float lod: hint_range(0.0, 5) = 1.0; // Số 3.0 là độ nhòe, bạn có thể chỉnh cao hơn nếu thích

void fragment(){
	COLOR = textureLod(screen_texture, SCREEN_UV, lod);
}