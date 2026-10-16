shader_type canvas_item;
uniform float inset_opacity : hint_range(0.0, 1.0) = 0.32;
varying vec4 item_tint;
void vertex() { item_tint = COLOR; }
void fragment() {
    vec2 sample_uv = UV;
    // The source was cut around skill badges. Restore the lower weapon insets
    // from their intact upper halves, leaving the central ornament untouched.
    if (UV.y > 0.5 && (UV.x < 73.0 / 204.0 || UV.x >= 131.0 / 204.0)) {
        sample_uv.y = 1.0 - UV.y;
    }
    vec4 art = texture(TEXTURE, sample_uv);
    // Authored Layer 10 has 87/255 alpha in its flat fill; normalize before tuning.
    COLOR = vec4(art.rgb, clamp(art.a / (87.0 / 255.0), 0.0, 1.0) * inset_opacity) * item_tint;
}
