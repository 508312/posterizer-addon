@tool
extends EditorPlugin

var dock_instance: Control

func _enter_tree():
	dock_instance = preload("res://addons/posterizer/src/lut_generator_ui.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_BOTTOM, dock_instance)

func _exit_tree():
	if dock_instance:
		remove_control_from_docks(dock_instance)
		dock_instance.free()
