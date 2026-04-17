//License: MIT - Copyright (c) [2026] [508312|https://github.com/508312/posterizer-addon]
shader_type canvas_item;

#include "posterizer_color_conversion_helpers.gdshaderinc"
#include "posterizer_funcs.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
// !!! EXPECTS Image NOT the default Texture2D import. 
uniform sampler2D palette_texture : filter_nearest, source_color;

void fragment() {
	vec3 original_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	COLOR.rgb = posterize_fullres(srgb_to_linear(original_color), palette_texture);
	COLOR.a = 1.0; 
}
