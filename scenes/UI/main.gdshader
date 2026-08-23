shader_type canvas_item;

// Khai báo 2 biến để bạn có thể chỉnh trực tiếp ở bảng Inspector
uniform vec2 shadow_offset = vec2(5.0, 5.0); // Độ lệch của bóng (tính bằng pixel)
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5); // Màu và độ mờ của bóng (Mặc định: Đen, mờ 50%)

void fragment() {
	
    vec2 ps = TEXTURE_PIXEL_SIZE;
    vec4 shadow_sample = texture(TEXTURE, UV - shadow_offset * ps);
    vec4 final_shadow = vec4(shadow_color.rgb, shadow_sample.a * shadow_color.a);
    vec4 original_color = texture(TEXTURE, UV);
    COLOR = mix(final_shadow, original_color, original_color.a);
}
