shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform bool ready = false;
uniform float visual_time = 0.0;
uniform float fire_speed : hint_range(0.0, 3.0) = 0.35;
varying vec4 item_tint;

void vertex() {
    item_tint = COLOR;
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
               mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x), f.y);
}

float smoke(vec2 p) {
    return noise(p) * 0.57 + noise(p * 2.03 + vec2(8.4, 1.7)) * 0.28 + noise(p * 4.07) * 0.15;
}

void fragment() {
    float t = visual_time * fire_speed;
    vec2 p = vec2(UV.x * 8.0, UV.y * 2.2 + t);
    float drift = smoke(p + vec2(t * 0.25, 2.0));
    float flame = smoke(p + vec2(drift * 2.8, -drift));
    vec3 ink = mix(vec3(0.008, 0.007, 0.012), vec3(0.11, 0.075, 0.085), flame * (ready ? 1.0 : 0.28));
    float ember = smoothstep(0.62, 0.87, flame) * smoothstep(0.25, 1.0, UV.y);
    ink += vec3(0.1, 0.006, 0.012) * ember * (ready ? 1.0 : 0.0);
    float edge = 1.0 - smoothstep(progress - 0.004, progress + 0.004, UV.x);
    COLOR = vec4(ink, edge * step(0.00001, progress)) * item_tint;
}
