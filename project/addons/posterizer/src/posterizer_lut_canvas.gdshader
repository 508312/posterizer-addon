shader_type canvas_item;

#include "color_conversion_helpers.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler3D palette_lut : filter_nearest, source_color;

vec3 posterize_lut(vec3 color) {
	vec3 srgb_coords = clamp(linear_to_srgb(color), vec3(0.0), vec3(1.0));
	vec3 lut_uvw = srgb_coords;
	vec3 sampled_srgb = texture(palette_lut, lut_uvw).rgb;
	return sampled_srgb;
}

void fragment() {
	vec3 original_color = srgb_to_linear(texture(SCREEN_TEXTURE, SCREEN_UV).rgb);
	COLOR.rgb = posterize_lut(original_color);
	COLOR.a = 1.0; 
}