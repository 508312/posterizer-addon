//License: MIT - Copyright (c) [2026] [508312|https://github.com/508312/posterizer-addon]
shader_type spatial;
render_mode unshaded, skip_vertex_transform, depth_test_disabled, depth_draw_never; 
#include "posterizer_color_conversion_helpers.gdshaderinc"
#include "posterizer_funcs.gdshaderinc"
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler3D palette_lut : filter_nearest, source_color;
uniform float specular_highlights_power = 1.0;

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    vec3 original_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    ALBEDO = posterize_lut(remap_hdr(original_color, 1.0/specular_highlights_power), palette_lut);
    ALPHA = 1.0;
}
