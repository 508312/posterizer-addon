@tool
extends Control

@onready var input_line_edit: LineEdit = %InputLineEdit
@onready var input_button: Button = %InputButton
@onready var output_line_edit: LineEdit = %OutputLineEdit
@onready var output_button: Button = %OutputButton
@onready var input_file_dialog: FileDialog = %InputFileDialog
@onready var output_file_dialog: FileDialog = %OutputFileDialog
@onready var generate_button: Button = %GenerateButton
@onready var lut_resolution_input: SpinBox = %LUTResolutionInput


func _ready():
	if Engine.is_editor_hint():
		input_button.pressed.connect(_on_browse_input_pressed)
		output_button.pressed.connect(_on_browse_output_pressed)
		generate_button.pressed.connect(_on_process_pressed)
		
		input_file_dialog.file_selected.connect(_on_input_file_selected)
		output_file_dialog.file_selected.connect(_on_output_file_selected)

func _on_browse_input_pressed():
	input_file_dialog.popup_centered(Vector2(600, 400))

func _on_browse_output_pressed():
	output_file_dialog.popup_centered(Vector2(600, 400))

func _on_input_file_selected(path: String):
	input_line_edit.text = path

func _on_output_file_selected(path: String):
	output_line_edit.text = path

func _on_process_pressed():
	var in_path := input_line_edit.text
	var out_path := output_line_edit.text
	
	if in_path == "" or out_path == "":
		push_error("Error: Please specify both input and output paths.")
		return
		
	var img := Image.new()
	var err := img.load(in_path)
	if err != OK:
		push_error("Error loading image at: ", in_path)
		return
	
	var resolution := int(lut_resolution_input.value)
	# Use GDScript if CPP fails
	#var generatorGDScript := PosterizerLUTGeneratorGDScript.new()
	var generatorCPP := PosterizerLUTGeneratorCPP.new()
	
	# Is this horrible?
	generate_button.text = "Generating..."
	generate_button.disabled = true
	await get_tree().process_frame
	await get_tree().process_frame
	
	var time := Time.get_ticks_msec()
	#var lut := generatorCPP.generate_lut_single_threaded(img, resolution, resolution, resolution)
	#print("st took ", Time.get_ticks_msec() - time)
	time = Time.get_ticks_msec()
	var lut := generatorCPP.generate_lut(img, resolution, resolution, resolution)
	print("mt took ", Time.get_ticks_msec() - time)
	
	generate_button.text = "Generate LUT"
	generate_button.disabled = false
	
	var save_err = ResourceSaver.save(lut, out_path)
	if save_err == OK:
		var updated_lut := ResourceLoader.load(out_path, "", ResourceLoader.CACHE_MODE_REPLACE)
		EditorInterface.get_resource_filesystem().update_file(out_path)
		EditorInterface.get_resource_filesystem().scan()
		print("Success! LUT saved to: ", out_path)
	else:
		push_error("Error saving LUT to: ", out_path)
