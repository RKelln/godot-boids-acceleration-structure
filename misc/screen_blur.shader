shader_type canvas_item;
render_mode blend_mix;

uniform float radius : hint_range(0, 10);

void fragment() {
    COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, radius);
}