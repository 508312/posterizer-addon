class_name PosterizerLUTGeneratorGDScript extends RefCounted

var palette_image: Image
var oklab_palette_image: PackedVector3Array
# Adapted from https://bottosson.github.io/posts/oklab/
func _linear_srgb_to_oklab(c: Color) -> Vector3:
	var l: float = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b
	var m: float = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b
	var s: float = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b

	var l_: float = pow(l, 1.0/3.0)
	var m_: float = pow(m, 1.0/3.0)
	var s_: float = pow(s, 1.0/3.0)

	return Vector3(
		0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_,
		1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_,
		0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_
		)

func _generate_oklab_palette() -> void:
	var width := palette_image.get_width()
	var height := palette_image.get_height()
	oklab_palette_image.resize(width * height)
	for y in range(height):
		for x in range(width):
			var linear_palette_color := palette_image.get_pixel(x, y).srgb_to_linear()
			oklab_palette_image[y * width + x] = _linear_srgb_to_oklab(linear_palette_color)

func _find_closest_palette_color(linear_color: Color) -> Color:
	var min_dist: float = 99999
	var best_color: Color = Color(1, 0, 1)
	var oklab_color := _linear_srgb_to_oklab(linear_color)
	for y in palette_image.get_height():
		for x in palette_image.get_width():
			var dist : float = oklab_color.distance_squared_to(
								oklab_palette_image[y * palette_image.get_height() + x])
			
			if dist < min_dist:
				min_dist = dist
				best_color = palette_image.get_pixel(x, y)
	
	return best_color

# Personal benchmarks 4X4image: 76sec 256LUT | 9sec 128LUT | 1sec 64LUT
# Pretty awful, considering 16x16 is the palette I want. Wish multithreaded worked better.
# Might write a C script/gdextension plugin to generate LUTs if enough ppl bother me, just being lazy rn :p.
func _generate_lut_single_threaded(width:int, height:int, depth:int) -> ImageTexture3D:
	var format := Image.FORMAT_RGB8
	
	var layers: Array[Image] = []
	layers.resize(depth)
	_generate_oklab_palette()
	for b in range(depth):
		var img := Image.create(width, height, false, format)
		for g in range(height):
			for r in range(width):
				var srgb_color := Color((r+0.5)/(width),
									(g+0.5)/(height), 
									(b+0.5)/(depth))
				
				var linear_color := srgb_color.srgb_to_linear()
				var palette_color := _find_closest_palette_color(linear_color)
				img.set_pixel(r, g, palette_color)
		layers[b] = img

		
	var tex3d := ImageTexture3D.new()
	var err := tex3d.create(format, width, height, depth, false, layers)
	if err != OK:
		push_error("Failed to create ImageTexture3D. Error code: ", err)
		return null
	return tex3d

# Uh yeah seems like threads are super fucked when run in debug/editor.
# They seem to execute the inner loop literally 10x slower for whatever reason.
# Thread creation is not the bottleneck. Performance of the inner loop on generated threads is.
# I reckon it would have been good enough for 256LUT if this worked. 
# Too lazy to write gdextension/c script for lut generation. Sorry >:P
func _generate_lut_multi_threaded(nthreads: int, width:int, height:int, depth:int) -> ImageTexture3D:
	assert(depth%nthreads == 0)
	
	var format := Image.FORMAT_RGB8
	
	var layers: Array[Image] = []
	layers.resize(depth)
	
	var threads: Array[Thread] = []
	for i in range(nthreads):
		threads.append(Thread.new())
	
	
	# ugly ass lambda not to pollute the class space
	var inner_loop := func (b: int, img: Image) -> void:
		#var time_start := Time.get_ticks_msec()
		#print("Inner loop start.")
		for g in range(height):
			for r in range(width):
				var srgb_color := Color((r+0.5)/(width),
									(g+0.5)/(height), 
									(b+0.5)/(depth))
				
				var linear_color := srgb_color.srgb_to_linear()
				var palette_color := _find_closest_palette_color(linear_color)
				img.set_pixel(r, g, palette_color)
		layers[b] = img
		#print("Inner loop end. Time taken: ", Time.get_ticks_msec() - time_start)
		
	_generate_oklab_palette()
	
	for b_start in range(depth / nthreads):
		for t in range(nthreads):
			var img := Image.create(width, height, false, format)
			threads[t].start(inner_loop.bind(b_start + t, img))
		
		for t in range(nthreads):	
			threads[t].wait_to_finish()
		
	
	var tex3d := ImageTexture3D.new()
	var err := tex3d.create(format, width, height, depth, false, layers)
	if err != OK:
		push_error("Failed to create ImageTexture3D. Error code: ", err)
		return null
	return tex3d

func generate_lut(img: Image, width: int, height: int, depth: int) -> ImageTexture3D:
	palette_image = img
	return _generate_lut_single_threaded(width, height, depth)
