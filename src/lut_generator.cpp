//License: MIT - Copyright (c) [2026] [508312|https://github.com/508312/posterizer-addon]
#include "lut_generator.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <vector>
#include <numeric>
#include <execution>
#include <godot_cpp/classes/worker_thread_pool.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

PosterizerLUTGeneratorCPP::PosterizerLUTGeneratorCPP() {
}

PosterizerLUTGeneratorCPP::~PosterizerLUTGeneratorCPP() {
}

void PosterizerLUTGeneratorCPP::_bind_methods() {
    ClassDB::bind_method(D_METHOD("generate_lut", "image", "width", "height", "depth"), &PosterizerLUTGeneratorCPP::generate_lut_multithreaded);
    ClassDB::bind_method(D_METHOD("generate_lut_single_threaded", "image", "width", "height", "depth"), &PosterizerLUTGeneratorCPP::generate_lut_single_threaded);
}

// Potential mimatch with gdscript because gdscript version is doubles by default(truncated at Vector3 step)? Should be impreceptible.
Vector3 PosterizerLUTGeneratorCPP::linear_srgb_to_oklab(Color c) {
    float l = 0.4122214708f * c.r + 0.5363325363f * c.g + 0.0514459929f * c.b;
    float m = 0.2119034982f * c.r + 0.6806995451f * c.g + 0.1073969566f * c.b;
    float s = 0.0883024619f * c.r + 0.2817188376f * c.g + 0.6299787005f * c.b;

    float l_ = pow(l, 1.0f/3.0f);
    float m_ = pow(m, 1.0f/3.0f);
    float s_ = pow(s, 1.0f/3.0f);

    return Vector3{
                0.2104542553f * l_ + 0.7936177850f * m_ - 0.0040720468f * s_,
                1.9779984951f * l_ - 2.4285922050f * m_ + 0.4505937099f * s_,
                0.0259040371f * l_ + 0.7827717662f * m_ - 0.8086757660f * s_
            };
}

// Quite ugly, but the best way to make use of godot threads.
// Possible to get rid of height width and depth thingies. Mb later, but its really nbd.
// Creates 1 layer of 3D LUT.
void PosterizerLUTGeneratorCPP::_process_depth_layer(int b, int width, int height, int depth, TypedArray<Image> layers, Image::Format format) {
	Ref<Image> img = layers[b];
	for (int g = 0; g < height; ++g) {
		for (int r = 0; r < width; ++r) {
			Color srgb_color = Color((r + 0.5f) / width,
				(g + 0.5f) / height,
				(b + 0.5f) / depth);

			Color palette_color = find_closest_palette_color(srgb_color.srgb_to_linear());
            img->set_pixel(r, g, palette_color);
		}
	}
}

Ref<ImageTexture3D> PosterizerLUTGeneratorCPP::generate_lut(int width, int height, int depth, bool enable_multithreading) {
    Image::Format format = Image::Format::FORMAT_RGB8;
    TypedArray<Image> layers;
    layers.resize(depth);
    generate_oklab_palette();

    Callable task_callable = callable_mp(this, &PosterizerLUTGeneratorCPP::_process_depth_layer);

    if (enable_multithreading) {
        std::vector<int64_t> id_vec(depth);
        for (int b = 0; b < depth; ++b) {
	        layers[b] = Image::create(width, height, false, format);
            int64_t task_id = WorkerThreadPool::get_singleton()->add_task(task_callable.bind(b, width, height, depth, layers, format));
            id_vec[b] = task_id;
        }
        for (int b = 0; b < depth; ++b) {
            WorkerThreadPool::get_singleton()->wait_for_task_completion(id_vec[b]);
        }

    } else {
        for (int b = 0; b < depth; ++b) {
            _process_depth_layer(b, width, height, depth, layers, format);
        }
    }

    Ref<ImageTexture3D> tex3d;
    tex3d.instantiate();
    Error err = tex3d->create(format, width, height, depth, false, layers);
    if (err != OK) {
        UtilityFunctions::push_error("Failed to create ImageTexture3D. Error code: ", err);
        return Ref<ImageTexture3D>();
    }
    return tex3d;
}

Ref<ImageTexture3D> PosterizerLUTGeneratorCPP::generate_lut_multithreaded(Ref<Image> img, int width, int height, int depth) {
    palette_image = img;
    return generate_lut(width, height, depth, true);
}

Ref<ImageTexture3D> PosterizerLUTGeneratorCPP::generate_lut_single_threaded(Ref<Image> img, int width, int height, int depth) {
    palette_image = img;
    return generate_lut(width, height, depth, false);
}

void PosterizerLUTGeneratorCPP::generate_oklab_palette() {
    int width = palette_image->get_width();
    int height = palette_image->get_height();
    oklab_palette_image.resize(width * height);
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            Color linear_palette_color = palette_image->get_pixel(x, y).srgb_to_linear();
            oklab_palette_image[y * width + x] = linear_srgb_to_oklab(linear_palette_color);
        }
    }
}

Color PosterizerLUTGeneratorCPP::find_closest_palette_color(Color linear_color) {
    int width = palette_image->get_width();
    int height = palette_image->get_height();

    float min_dist = 99999;
    Color best_color = Color{ 1, 0, 1 };
   
    Vector3 oklab_color = linear_srgb_to_oklab(linear_color);
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            float dist = oklab_color.distance_squared_to(oklab_palette_image[y * width + x]);
            if (dist < min_dist) {
                min_dist = dist;
                best_color = palette_image->get_pixel(x, y);
            }
        }
    }
    return best_color;
}
