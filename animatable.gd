extends AnimatableBody3D

@export var move_speed = 1.5  # سرعت حرکت
@export var rotation_speed = 1.5 # سرعت چرخش

var start_x = -1.667
var end_x = -5.439

var start_rotation = 45.0
var end_rotation = -45.0

# متغیرهای پیشرفت (به جای اینکه بین 0 و 1 باشند، مدام زیاد می‌شوند)
var move_progress = 0.0
var rotation_progress = 0.0

func _ready():
	position.x = start_x
	rotation_degrees.z = start_rotation

func _physics_process(delta):
	# --- حرکت رفت و برگشتی ---
	move_progress += move_speed * delta
	# تبدیل موج سینوسی از (-1 تا 1) به (0 تا 1) برای نرمی حرکت
	var move_value = (sin(move_progress) * 0.5) + 0.5
	position.x = lerp(start_x, end_x, move_value)

	# --- چرخش رفت و برگشتی ---
	rotation_progress += rotation_speed * delta
	var rotation_value = (sin(rotation_progress) * 0.5) + 0.5
	rotation_degrees.z = lerp(start_rotation, end_rotation, rotation_value)
