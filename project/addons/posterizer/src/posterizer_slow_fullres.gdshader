shader_type spatial;
render_mode unshaded, skip_vertex_transform, depth_test_disabled, depth_draw_never; 
#include "color_conversion_helpers.gdshaderinc"
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
// EXPRECTS Texture2D (since thats the default import)
uniform sampler2D palette_texture : filter_nearest, source_color; // add ", source_color" if you use ImageTexture

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 posterize_fullres(vec3 color) {
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
			diff = target_oklab - linear_srgb_to_oklab(palette_color);
			sqdiff = dot(diff, diff);
			if (sqdiff < min_sqdiff) {
				min_sqdiff = sqdiff;
				match_color = palette_color;
			}
		}
	}
	return match_color;
}

void fragment() {
	vec4 original_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	ALBEDO = posterize_fullres(original_color.rgb);
	ALPHA = 1.0;
}