#pragma once
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/classes/image_texture3d.hpp>

namespace godot {
	class PosterizerLUTGeneratorCPP : public RefCounted {
		GDCLASS(PosterizerLUTGeneratorCPP, RefCounted)

	private:
		Ref<Image> palette_image;
		PackedVector3Array oklab_palette_image;

		Vector3 linear_srgb_to_oklab(Color color);
		void generate_oklab_palette();
		Color find_closest_palette_color(Color linear_color);

		Ref<ImageTexture3D> generate_lut(int width, int height, int depth, bool multithreading_enabled);

		void _process_depth_layer(int b, int width, int height, int depth, TypedArray<Image> layers, Image::Format format);

	protected:
		static void _bind_methods();

	public:
		PosterizerLUTGeneratorCPP();
		~PosterizerLUTGeneratorCPP();

		Ref<ImageTexture3D> generate_lut_multithreaded(Ref<Image> img, int width, int height, int depth);
		Ref<ImageTexture3D> generate_lut_single_threaded(Ref<Image> img, int width, int height, int depth);
	};

}
