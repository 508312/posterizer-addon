extends Node

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var img: Image = get_viewport().get_texture().get_image()
		var timestamp: String = Time.get_datetime_string_from_system().replace(":", "_")
		var path: String = "user://screenshot_" + timestamp + ".png"
		var err: Error = img.save_png(path)
		if err == OK:
			print("Successfully saved the image to: " + ProjectSettings.globalize_path(path))
		else:
			print("Failed to save image.")
