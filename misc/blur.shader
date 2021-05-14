shader_type canvas_item;
render_mode blend_mix;

uniform float radius : hint_range(0, 10);

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;
    vec4 col = texture(TEXTURE, UV);
	//vec3 rgb = col.rgb;
    //float totalAlpha = 0.;
    //COLOR = textureLod(TEXTURE, UV, radius);
    //float a = (sum of alpha pixels of input image);
    //resultColor = (sum of pixels of input image) * 1 / resultAlpha;
    //resultAlpha = resultAlpha * 1 / radius;
//    vec4 neighbours = texture(TEXTURE, UV + vec2(0.0, -radius) * ps);
//    rgb += neighbours.rgb * neighbours.a;
//    totalAlpha += neighbours.a;
//
//    neighbours = texture(TEXTURE, UV + vec2(0.0, radius) * ps);
//    rgb += neighbours.rgb * neighbours.a;
//    totalAlpha += neighbours.a;
//
//    neighbours = texture(TEXTURE, UV + vec2(-radius, 0.0) * ps);
//    rgb += neighbours.rgb * neighbours.a;
//    totalAlpha += neighbours.a;
//
//    neighbours = texture(TEXTURE, UV + vec2(radius, 0.0) * ps);
//    rgb += neighbours.rgb * neighbours.a;
//    totalAlpha += neighbours.a;
//
//    rgb /= 5.0;
//    col.rgb = rgb;
//    col.a = totalAlpha * 1.0 / radius;
    float a = col.a;
	col += texture(TEXTURE, UV + vec2(0.0, -radius) * ps);
	col += texture(TEXTURE, UV + vec2(0.0, radius) * ps);
	col += texture(TEXTURE, UV + vec2(-radius, 0.0) * ps);
	col += texture(TEXTURE, UV + vec2(radius, 0.0) * ps);
    col.rgb /= 2.5; // 5 is correct but want brighter
    //col.a = (max(1.0, col.a / 5.) + a) / 2.;
    //col.a = max(1.0, col.a / 5.);
	COLOR = col;
}