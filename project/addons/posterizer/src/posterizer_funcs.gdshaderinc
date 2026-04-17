//License: MIT - Copyright (c) [2026] [508312|https://github.com/508312/posterizer-addon]
#include "posterizer_color_conversion_helpers.gdshaderinc"

// Takes a linear color as an input
vec3 posterize_lut(vec3 color, sampler3D palette_lut) {
	vec3 srgb_coords = clamp(linear_to_srgb(color), vec3(0.0001), vec3(0.9999));
	return texture(palette_lut, srgb_coords).rgb;
}

// Takes a linear color as an input. 
// Takes the palette_texture in SRGB, not source_colored since that would make it linear for 3d shader and srgb for 2d canvas shader. Ugly, but wanted compat for both 2d and 3d for this function.
vec3 posterize_fullres(vec3 color, sampler2D palette_texture) {
	ivec2 size = textureSize(palette_texture, 0);
	float min_sqdiff = 999999.0;
	// Error magenta color
	vec3 match_color = vec3(1, 0, 1);
	vec3 diff;
	float sqdiff;
	vec3 target_oklab = linear_srgb_to_oklab(color);
	for (int x = 0; x < size.x; x++) {
		for (int y = 0; y < size.y; y++) {
			vec3 palette_color = texelFetch(palette_texture, ivec2(x, y), 0).rgb;
			diff = target_oklab - srgb_to_oklab(palette_color);
			sqdiff = dot(diff, diff);
			if (sqdiff < min_sqdiff) {
				min_sqdiff = sqdiff;
				match_color = palette_color;
			}
		}
	}
	return match_color;
}
