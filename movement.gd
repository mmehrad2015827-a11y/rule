
extends Control

@export var joystick_radius = 75.0

var touch_index = -1
var mouse_pressed = false
var joystick_vector = Vector2.ZERO


func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _draw():
	var center = size / 2.0

	# دایره اصلی
	draw_circle(
		center,
		joystick_radius,
		Color(0.2, 0.2, 0.2, 0.6)
	)

	# دایره داخلی
	draw_circle(
		center + joystick_vector * joystick_radius,
		joystick_radius * 0.4,
		Color(0.85, 0.85, 0.85, 0.9)
	)


func _gui_input(event):

	# --- کنترل لمسی گوشی ---
	if event is InputEventScreenTouch:

		if event.pressed and touch_index == -1:
			touch_index = event.index
			update_joystick(event.position)

		elif not event.pressed and event.index == touch_index:
			reset_joystick()

	elif event is InputEventScreenDrag:

		if event.index == touch_index:
			update_joystick(event.position)

	# --- کنترل با ماوس کامپیوتر ---
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:

			mouse_pressed = event.pressed

			if mouse_pressed:
				update_joystick(event.position)
			else:
				reset_joystick()

	elif event is InputEventMouseMotion:
		if mouse_pressed:
			update_joystick(event.position)


func update_joystick(touch_position):

	var center = size / 2.0
	var offset = touch_position - center

	joystick_vector = (
		offset.limit_length(joystick_radius)
		/ joystick_radius
	)

	update_movement_actions()
	queue_redraw()


func update_movement_actions():

	if joystick_vector.x < -0.3:
		Input.action_press("ui_left")
	else:
		Input.action_release("ui_left")

	if joystick_vector.x > 0.3:
		Input.action_press("ui_right")
	else:
		Input.action_release("ui_right")

	if joystick_vector.y < -0.3:
		Input.action_press("ui_up")
	else:
		Input.action_release("ui_up")

	if joystick_vector.y > 0.3:
		Input.action_press("ui_down")
	else:
		Input.action_release("ui_down")


func reset_joystick():

	touch_index = -1
	mouse_pressed = false
	joystick_vector = Vector2.ZERO

	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	Input.action_release("ui_down")

	queue_redraw()


func _on_control_ready() -> void:
	pass # Replace with function body.


func _on_control_tree_exiting() -> void:
	pass # Replace with function body.
