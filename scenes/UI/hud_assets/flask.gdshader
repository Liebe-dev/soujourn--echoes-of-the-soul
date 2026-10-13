shader_type canvas_item;

uniform float hp : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D bottle_mask : filter_linear;
uniform bool shell_only = false;
varying vec4 art_tint;

void vertex() {
    art_tint = COLOR;
}

void fragment() {
    // Sample the original mockup without changing or duplicating its bitmap.
    vec4 source = texture(TEXTURE, vec2(UV.x * 176.0 / 629.0, UV.y));
    vec4 mask = texture(bottle_mask, UV);
    float neutral = max(source.r, max(source.g, source.b)) - min(source.r, min(source.g, source.b));
    float dark_shell = (1.0 - smoothstep(0.26, 0.36, source.r)) * (1.0 - smoothstep(0.02, 0.08, neutral));
    float cavity = (1.0 - mask.r) * mask.a * (1.0 - dark_shell);
    float background = 1.0 - smoothstep(0.008, 0.025, distance(source.rgb, vec3(181.0 / 255.0)));
    float shell_alpha = mask.a * (1.0 - cavity) * (1.0 - background);
    vec3 glass = mix(vec3(0.97), vec3(0.58), clamp((UV.y - 0.19) / 0.72, 0.0, 1.0));
    float surface = mix(0.91, 0.19, clamp(hp, 0.0, 1.0));
    surface += sin(UV.x * 47.0 + TIME * 1.4) * 0.003 * step(0.001, hp) * step(hp, 0.999);
    float fluid = smoothstep(surface - 0.003, surface + 0.003, UV.y) * step(0.001, hp);
    vec3 blood = mix(vec3(0.95, 0.02, 0.035), vec3(0.57, 0.0, 0.015), clamp((UV.y - surface) / 0.7, 0.0, 1.0));
    blood += vec3(0.16, 0.075, 0.075) * (1.0 - smoothstep(0.0, 0.023, abs(UV.y - surface)));
    vec3 interior = mix(glass, blood, fluid);
    COLOR = (shell_only ? vec4(source.rgb, shell_alpha) : vec4(interior, cavity)) * art_tint;
}
