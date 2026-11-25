
extends Control

const MOBILE_CONTROLS = preload("res://mobile_controls.tscn")

var selected_mode = "Unknown"

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Button2.text = "Mod : Unknown"

# انتخاب مود
func _on_button_2_pressed():
	if selected_mode == "Unknown":
		selected_mode = "Computer"
	elif selected_mode == "Computer":
		selected_mode = "Mobile"
	else:
		selected_mode = "Computer"

	$Button2.text = "Mod : " + selected_mode

	print("Selected mode: ", selected_mode)


# دکمه Run!
func _on_button_pressed():
	if selected_mode == "Unknown":
		print("Please select a game mode!")
		return

	var tree = get_tree()
	var is_mobile = selected_mode == "Mobile"

	var error = tree.change_scene_to_file("res://vs.tscn")

	if error != OK:
		print("Failed to load game!")
		return

	await tree.scene_changed

	if is_mobile:
		var game = tree.current_scene
		var target_node = game.find_child("Node Rule", true, false)

		if target_node == null:
			print("ERROR: Node Rule not found!")
			return

		var controls = MOBILE_CONTROLS.instantiate()
		target_node.add_child(controls)

		print("MobileControls successfully added to Node Rule!")
