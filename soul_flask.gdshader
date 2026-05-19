shader_type canvas_item;

uniform float hp : hint_range(0.0, 1.0) = 1.0;
uniform vec4 hp_color : source_color = vec4(0.9, 0.2, 0.2, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 0.6, 0.6, 0.45);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float fill = clamp(hp, 0.0, 1.0);
    float threshold = 1.0 - fill;
    // soft mask around the fluid surface
    float edge = 0.02;
    float surface_mask = smoothstep(threshold - edge, threshold + edge, UV.y);

    // Robust interior detection using a circular mask (center + radius)
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);
    // Tune these if needed to match your border texture
    float radius = 0.47; // inner radius of the visible circle
    float border_thickness = 0.08; // softness/width of the border area
    // interior_mask = 1.0 inside the inner circle, 0.0 outside the border area
    float interior_mask = 1.0 - smoothstep(radius - border_thickness, radius, dist);

    // Final mask: only fill where both interior and surface masks are active
    float final_mask = interior_mask * surface_mask;

    // Mix the fill color over the texture while keeping the border visible
    vec3 mixed_rgb = mix(tex.rgb, hp_color.rgb, final_mask);
    float mixed_a = max(tex.a, hp_color.a * final_mask);
    COLOR = vec4(mixed_rgb, mixed_a);
}
