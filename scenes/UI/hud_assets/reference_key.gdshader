shader_type canvas_item;
// The existing RGB icons use the same gray background as the mockup.
void fragment() {
    vec3 original = texture(TEXTURE, UV).rgb;
    COLOR.a *= smoothstep(0.008, 0.026, distance(original, vec3(181.0 / 255.0)));
}
