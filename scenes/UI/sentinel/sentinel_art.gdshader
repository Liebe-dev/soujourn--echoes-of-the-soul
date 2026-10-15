shader_type canvas_item;

uniform vec3 background_key : source_color = vec3(0.6392157);
uniform float key_tolerance : hint_range(0.0, 0.1) = 0.012;
varying vec4 item_tint;

void vertex() {
    item_tint = COLOR;
}

void fragment() {
    vec4 art = texture(TEXTURE, UV);
    float keyed = smoothstep(key_tolerance, key_tolerance + 0.016, distance(art.rgb, background_key));
    COLOR = vec4(art.rgb, art.a * keyed) * item_tint;
}
