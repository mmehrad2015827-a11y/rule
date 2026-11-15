extends CharacterBody3D

# --- تنظیمات حرکت ---
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.003

# --- تنظیمات پارکور ---
@export var run_multiplier = 2.5
@export var run_jump_multiplier = 1.5
@export var max_jumps = 2

# --- تنظیمات انرژی (استامینا) ---
@export var max_stamina = 100.0
@export var stamina_regen = 15.0 # سرعت پر شدن انرژی
@export var run_drain = 25.0 # مقدار مصرف انرژی در ثانیه هنگام دویدن
@export var jump_drain = 20.0 # مقدار مصرف انرژی هنگام پرش

@onready var cam_first_person = $G1
@onready var cam_third_person = $G3
# وصل کردن نوار انرژی
@onready var stamina_bar = $"../CanvasLayer/StaminaBar"

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_first_person = true 
var jumps_left = 0 

# متغیرهای انرژی
var current_stamina = 100.0
var is_exhausted = false # آیا انرژی تموم شده؟

func _ready():
	cam_first_person.make_current()
	is_first_person = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# چرخش با موس
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		var active_cam = cam_first_person if is_first_person else cam_third_person
		active_cam.rotate_x(-event.relative.y * mouse_sensitivity)
		active_cam.rotation.x = clamp(active_cam.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# تغییر دوربین
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			is_first_person = not is_first_person
			if is_first_person:
				cam_first_person.make_current()
			else:
				cam_third_person.make_current()

func _physics_process(delta):
	# --- جاذبه ---
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		jumps_left = max_jumps # شارژ پرش‌ها روی زمین

	# --- منطق انرژی (دویدن) ---
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var is_moving = input_dir.length() > 0
	var wants_to_run = Input.is_physical_key_pressed(KEY_CTRL)
	
	# آیا واقعاً داره می‌دوه؟ (فقط اگر روی زمین باشه و انرژی داشته باشه)
	var is_running = wants_to_run and is_moving and not is_exhausted and is_on_floor()

	if is_running:
		current_stamina -= run_drain * delta # کم کردن انرژی
	elif is_on_floor():
		current_stamina += stamina_regen * delta # پر شدن انرژی وقتی ایستاده

	# محدود کردن انرژی بین 0 تا 100
	current_stamina = clamp(current_stamina, 0, max_stamina)
	
	# چک کردن خستگی
	if current_stamina <= 0:
		is_exhausted = true
	elif current_stamina > 25.0: # وقتی 25 درصد پر شد، دوباره می‌تونه بدوه
		is_exhausted = false

	# آپدیت کردن UI
	if stamina_bar:
		stamina_bar.value = current_stamina

	# --- پرش و دابل جامپ ---
	if Input.is_action_just_pressed("ui_accept") and jumps_left > 0:
		# اگر خسته نیست، یا اینکه این پرش اولشه (روی زمینه)
		if not is_exhausted or jumps_left == max_jumps:
			var current_jump = jump_velocity
			
			if is_exhausted:
				current_jump /= 1.5 # پرش ضعیف‌تر وقتی خسته‌ست
			elif is_running:
				current_jump *= run_jump_multiplier # پرش قوی‌تر وقتی می‌دوه

			velocity.y = current_jump
			jumps_left -= 1
			
			# کم کردن انرژی بابت پرش
			current_stamina -= jump_drain
			if current_stamina < 0: current_stamina = 0

	# --- حرکت و اعمال سرعت ---
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = speed
	
	if is_exhausted:
		current_speed /= 1.9 # سرعت تقسیم بر 1.9 میشه
	elif is_running:
		current_speed *= run_multiplier # سرعت دویدن
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
