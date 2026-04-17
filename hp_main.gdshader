shader_type canvas_item;

uniform float hp : hint_range(0.0,1.0) = 1.0;

uniform vec4 hp_color : source_color = vec4(0.9,0.1,0.1,1.0);
uniform vec4 highlight_color : source_color = vec4(1.0,1.0,1.0,0.35);

void fragment(){

    vec2 center = vec2(0.5,0.5);
    vec2 pos = UV - center;

    float dist = length(pos);

    if(dist > 0.48){
        discard;
    }

    // đảo chiều quay
    float angle = -atan(pos.y, pos.x);

    // đặt gốc ở 12h
    angle -= 1.5707963;

    if(angle < 0.0){
        angle += 6.2831853;
    }

    float fill_angle = hp * 6.2831853;

    vec4 col = vec4(0.0);

    if(angle <= fill_angle){
        col = hp_color;
    }

    float highlight =
        smoothstep(0.30, 0.0, distance(UV, vec2(0.33,0.28)));

    col.rgb += highlight * highlight_color.rgb;
    col.a = max(col.a, highlight * highlight_color.a);

    float edge = smoothstep(0.48, 0.40, dist);
    col.rgb *= edge;
    col.a *= edge;

    COLOR = col;
}