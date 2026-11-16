extends CharacterBody3D

# --- تنظیمات حرکت ---
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.003
@export var run_multiplier = 2.5
@export var run_jump_multiplier = 1.5
@export var max_jumps = 2

# --- تنظیمات انرژی ---
@export var max_stamina = 100.0
@export var stamina_regen = 15.0 
@export var run_drain = 25.0 
@export var jump_drain = 20.0 

# --- تنظیمات سلامتی و دمیج ---
@export var max_health = 100.0
@export var health_regen_rate = 5.0 # سرعت پر شدن جون در هر ثانیه
@export var void_death_y = -20.0 # ارتفاعی که پایین‌تر از اون یعنی افتادیم توی وید
@export var base_fall_height = 10.0 # سقوط از 10 متری شروع دمیج
@export var fall_damage_step = 2.0 # هر 2 متر بیشتر
@export var damage_per_step = 10.0 # مقدار دمیج هر مرحله (نیم قلب)

# --- نودها ---
@onready var cam_first_person = $G1
@onready var cam_third_person = $G3
@onready var stamina_bar = $"../CanvasLayer/StaminaBar"
@onready var health_bar = $"../CanvasLayer/HealthBar"
@onready var death_screen = $"../CanvasLayer/DeathScreen"

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_first_person = true 
var jumps_left = 0 
var current_stamina = 100.0
var is_exhausted = false

# --- متغیرهای جدید سلامتی ---
var current_health = 100.0
var is_dead = false
var fall_start_y = 0.0 # ذخیره ارتفاع لحظه شروع سقوط
var is_falling = false
var void_timer = 0.0 # برای 1 ثانیه مکث در وید

func _ready():
	cam_first_person.make_current()
	is_first_person = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	death_screen.hide() # صفحه مرگ در ابتدا مخفی باشه
	health_bar.value = current_health

func _input(event):
	if is_dead: return # اگر مرده، دیگه کاری نکن

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		var active_cam = cam_first_person if is_first_person else cam_third_person
		active_cam.rotate_x(-event.relative.y * mouse_sensitivity)
		active_cam.rotation.x = clamp(active_cam.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			is_first_person = not is_first_person
			if is_first_person:
				cam_first_person.make_current()
			else:
				cam_third_person.make_current()

func _physics_process(delta):
	if is_dead: return # اگر مرده، فیزیک متوقف میشه

	# --- منطق سقوط و دمیج (Fall Damage) ---
	if not is_on_floor():
		if not is_falling:
			is_falling = true
			fall_start_y = global_position.y # ثبت ارتفاع در لحظه شروع سقوط
			
		# چک کردن وید (Void)
		if global_position.y < void_death_y:
			void_timer += delta
			if void_timer >= 1.0: # اگر 1 ثانیه توی وید بود
				die()
		else:
			void_timer = 0.0 # اگر از وید خارج شد، تایمر ریست میشه
	else:
		if is_falling:
			is_falling = false
			# محاسبه فاصله افتادن
			var fall_distance = fall_start_y - global_position.y
			
			if fall_distance >= base_fall_height:
				# محاسبه دمیج: 10 متر اول (10 دمیج) + هر 2 متر بیشتر (10 دمیج)
				var extra_distance = fall_distance - base_fall_height
				var extra_damage_steps = floor(extra_distance / fall_damage_step)
				var total_damage = damage_per_step + (extra_damage_steps * damage_per_step)
				
				take_damage(total_damage)
				print("سقوط کردی از ارتفاع ", fall_distance, " متری! دمیج: ", total_damage)

	# --- جاذبه و پرش ---
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		jumps_left = max_jumps

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var is_moving = input_dir.length() > 0
	var wants_to_run = Input.is_physical_key_pressed(KEY_CTRL)
	var is_running = wants_to_run and is_moving and not is_exhausted and is_on_floor()

	if is_running:
		current_stamina -= run_drain * delta
	elif is_on_floor():
		current_stamina += stamina_regen * delta

	current_stamina = clamp(current_stamina, 0, max_stamina)
	
	if current_stamina <= 0:
		is_exhausted = true
	elif current_stamina > 25.0:
		is_exhausted = false

	if stamina_bar:
		stamina_bar.value = current_stamina

	if Input.is_action_just_pressed("ui_accept") and jumps_left > 0:
		if not is_exhausted or jumps_left == max_jumps:
			var current_jump = jump_velocity
			if is_exhausted:
				current_jump /= 1.5
			elif is_running:
				current_jump *= run_jump_multiplier
			velocity.y = current_jump
			jumps_left -= 1
			current_stamina -= jump_drain
			if current_stamina < 0: current_stamina = 0

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = speed
	if is_exhausted:
		current_speed /= 1.9
	elif is_running:
		current_speed *= run_multiplier
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# --- شارژ شدن جون (Health Regen) ---
	# اگر انرژی 100 باشه و نمرده باشیم، جون کم کم زیاد میشه
	if current_stamina >= max_stamina and current_health < max_health and not is_dead:
		current_health += health_regen_rate * delta
		current_health = clamp(current_health, 0, max_health)
		health_bar.value = current_health

# تابع اعمال دمیج
func take_damage(amount):
	current_health -= amount
	health_bar.value = current_health
	if current_health <= 0:
		die()

# تابع مرگ
func die():
	is_dead = true
	velocity = Vector3.ZERO # توقف کامل
	death_screen.show() # نمایش صفحه قرمز
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # آزاد کردن موس برای دیدن صفحه
	print("بازیکن مرد! 💀")
	
	# می‌تونی اینجا یه تایمر بذاری که بعد از 3 ثانیه بازی رو ری استارت کنه:
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
