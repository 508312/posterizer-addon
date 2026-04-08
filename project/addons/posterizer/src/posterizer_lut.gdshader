shader_type spatial;
render_mode unshaded, skip_vertex_transform, depth_test_disabled, depth_draw_never; 
#include "color_conversion_helpers.gdshaderinc"
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler3D palette_lut : filter_nearest, source_color;

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 posterize_lut(vec3 color) {
	float max_val = max(color.r, max(color.g, color.b));
	vec3 mapped_color = color;
	// Try to move HDRed values closer to white. We are losing hue by clamping anyway, so might as well nudge it to white which makes more sense.
    if (max_val > 1.0) {
        vec3 scaled = color / max_val;
        float base_blowout = 1.0 - (1.0 / max_val);
		
		const float blowout_power = 1.5; // Modify this if your specular highlight look wrong.
		float blowout = pow(base_blowout, blowout_power);
        mapped_color = mix(scaled, vec3(1.0), blowout);
    }
	
	vec3 srgb_coords = clamp(linear_to_srgb(mapped_color), vec3(0.0001), vec3(0.9999));
	vec3 lut_uvw = srgb_coords;
	vec3 sampled_srgb = texture(palette_lut, lut_uvw).rgb;
	return sampled_srgb;
}

void fragment() {
    vec4 original_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    ALBEDO = posterize_lut(original_color.rgb);
    ALPHA = 1.0;
}