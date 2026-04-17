//License: MIT - Copyright (c) [2026] [508312|https://github.com/508312/posterizer-addon]
shader_type spatial;
render_mode unshaded, skip_vertex_transform, depth_test_disabled, depth_draw_never; 
#include "posterizer_color_conversion_helpers.gdshaderinc"
#include "posterizer_funcs.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// If you use this shader I recommend adding source_color to palette texture, and modifying the posterize_fullres function to convert from linear color for pallete instead of srgb. Saves on 1 conversion. Had to do it this(a bit ugly) way for compatability between 2d(with source_color reads as srgb) and 3d(with source_color reads as linear) shaders.
// !!! EXPECTS ImageTexture NOT the default Texture2D import. 
uniform sampler2D palette_texture : filter_nearest;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec4 original_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	ALBEDO = srgb_to_linear(posterize_fullres(original_color.rgb, palette_texture));
	ALPHA = 1.0;
}
