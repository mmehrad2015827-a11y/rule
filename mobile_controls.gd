
extends CanvasLayer

func _ready():
	var game = get_tree().current_scene
	var target = game.find_child("Node Rule", true, false)

	if target == null:
		print("ERROR: Node Rule not found!")
		return

	var old_parent = get_parent()

	if old_parent != target:
		old_parent.remove_child(self)
		target.add_child(self)

	print("MobileControls moved to Node Rule!")


func _on_mot_ready_wqiw() -> void:
	pass # Replace with function body.


func _on_movement_ready() -> void:
	pass # Replace with function body.


func _on_movement_tree_exited() -> void:
	pass # Replace with function body.


func _on_control_ready() -> void:
	pass # Replace with function body.


func _on_control_tree_exiting() -> void:
	pass # Replace with function body.
