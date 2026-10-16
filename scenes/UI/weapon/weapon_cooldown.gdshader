shader_type canvas_item;
uniform float remaining_ratio : hint_range(0.0, 1.0) = 0.0;
uniform float overlay_opacity : hint_range(0.0, 1.0) = 0.6;
varying vec4 item_tint;
void vertex() { item_tint = COLOR; }

void fragment() {
    // As cooldown expires, the upper edge moves down: only the bottom remains covered.
    vec2 p = abs(UV - vec2(0.5)) - vec2(0.40);
    float rounded = 1.0 - smoothstep(0.095, 0.105, length(max(p, vec2(0.0))));
    float covered = step(1.0 - remaining_ratio, UV.y);
    COLOR = vec4(0.0, 0.0, 0.0, rounded * covered * overlay_opacity) * item_tint;
}
