//License: MIT - Copyright (c) [2026] [508312|https://github.com/508312/posterizer-addon]

// Adapted from https://github.com/godotengine/godot/blob/master/core/math/color.h
// Not needed. Shaders are already linear.
vec3 srgb_to_linear(vec3 color) {
	return vec3(
			color.r < 0.04045f ? color.r * (1.0f / 12.92f) : pow(float((color.r + 0.055) * (1.0 / (1.0 + 0.055))), 2.4f),
			color.g < 0.04045f ? color.g * (1.0f / 12.92f) : pow(float((color.g + 0.055) * (1.0 / (1.0 + 0.055))), 2.4f),
			color.b < 0.04045f ? color.b * (1.0f / 12.92f) : pow(float((color.b + 0.055) * (1.0 / (1.0 + 0.055))), 2.4f)
			);
}

// Adapted from https://github.com/godotengine/godot/blob/master/core/math/color.h
vec3 linear_to_srgb(vec3 color) {
	return vec3(
			color.r < 0.0031308f ? 12.92f * color.r : (1.0 + 0.055) * pow(color.r, 1.0f / 2.4f) - 0.055,
			color.g < 0.0031308f ? 12.92f * color.g : (1.0 + 0.055) * pow(color.g, 1.0f / 2.4f) - 0.055,
			color.b < 0.0031308f ? 12.92f * color.b : (1.0 + 0.055) * pow(color.b, 1.0f / 2.4f) - 0.055
			);
}

// Adapted from https://bottosson.github.io/posts/oklab/
vec3 linear_srgb_to_oklab(vec3 c) {
    float l = 0.4122214708f * c.r + 0.5363325363f * c.g + 0.0514459929f * c.b;
	float m = 0.2119034982f * c.r + 0.6806995451f * c.g + 0.1073969566f * c.b;
	float s = 0.0883024619f * c.r + 0.2817188376f * c.g + 0.6299787005f * c.b;

    float l_ = pow(l, 1.0/3.0);
    float m_ = pow(m, 1.0/3.0);
    float s_ = pow(s, 1.0/3.0);

    return vec3(
        0.2104542553f*l_ + 0.7936177850f*m_ - 0.0040720468f*s_,
        1.9779984951f*l_ - 2.4285922050f*m_ + 0.4505937099f*s_,
        0.0259040371f*l_ + 0.7827717662f*m_ - 0.8086757660f*s_
		);
}

vec3 srgb_to_oklab(vec3 color) {
	return linear_srgb_to_oklab(srgb_to_linear(color));
}

// Remaps color to be in 0.0-1.0 range. Loses hue, shifts it towards white. Blowout power determines strength of the effect.
// An alternative is to scale down to non hdr range, but then specular highlights are lost.
vec3 remap_hdr(vec3 color, float blowout_power) {
	float max_val = max(color.r, max(color.g, color.b));
	vec3 mapped_color = color;
    if (max_val > 1.0) {
        vec3 scaled = color / max_val;
        float base_blowout = 1.0 - (1.0 / max_val);
		
		float blowout = pow(base_blowout, blowout_power);
        mapped_color = mix(scaled, vec3(1.0), blowout);
    }
	return mapped_color;
}

vec3 remap_hdr(vec3 color) {
	return remap_hdr(color, 1.5);
}
