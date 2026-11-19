
extends CharacterBody3D

# --- تنظیمات حرکت ---
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var Last_jump_velocity = 5
@export var mouse_sensitivity = 0.003
@export var run_multiplier = 2.5
@export var run_jump_multiplier = 1.5
@export var max_jumps = 2.5

# --- تنظیمات انرژی ---
@export var max_stamina = 100.0
@export var stamina_regen = 15.0
@export var run_drain = 25.0
@export var jump_drain = 20.0
@export var Last_jump_drain = 30.0

# --- تنظیمات سلامتی و دمیج ---
@export var max_health = 100.0
@export var health_regen_rate = 4.0
@export var void_death_y = -20.0
@export var base_fall_height = 7.5
@export var fall_damage_step = 1.5
@export var damage_per_step = 12.0

# --- نودها ---
@onready var cam_first_person = $G1
@onready var cam_third_person = $G3
@onready var stamina_bar = $"../CanvasLayer/StaminaBar"
@onready var health_bar = $"../CanvasLayer/HealthBar"
@onready var death_screen = $"../CanvasLayer/DeathScreen"

# --- متغیرهای داخلی ---
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_first_person = true
var jumps_left = 0
var current_stamina = 100.0
var is_exhausted = false

var current_health = 100.0
var is_dead = false
var fall_start_y = 0.0
var is_falling = false
var void_timer = 0.0


func _ready():
	cam_first_person.make_current()
	is_first_person = true

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	death_screen.hide()
	health_bar.value = current_health


func _input(event):
	if is_dead:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		var active_cam = cam_first_person if is_first_person else cam_third_person

		active_cam.rotate_x(-event.relative.y * mouse_sensitivity)
		active_cam.rotation.x = clamp(
			active_cam.rotation.x,
			deg_to_rad(-89),
			deg_to_rad(89)
		)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			is_first_person = not is_first_person

			if is_first_person:
				cam_first_person.make_current()
			else:
				cam_third_person.make_current()


func _physics_process(delta):
	if is_dead:
		return

	# --- سقوط و Void ---
	if not is_on_floor():
		if not is_falling:
			is_falling = true
			fall_start_y = global_position.y

		if global_position.y < void_death_y:
			void_timer += delta

			if void_timer >= 1.0:
				die()
		else:
			void_timer = 0.0

	else:
		if is_falling:
			is_falling = false

			var fall_distance = fall_start_y - global_position.y

			if fall_distance >= base_fall_height:
				var extra_distance = fall_distance - base_fall_height
				var extra_damage_steps = floor(extra_distance / fall_damage_step)

				var total_damage = damage_per_step + (
					extra_damage_steps * damage_per_step
				)

				take_damage(total_damage)

				print(
					"سقوط کردی از ارتفاع ",
					fall_distance,
					" متری! دمیج: ",
					total_damage
				)

	# --- جاذبه و پرش ---
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		jumps_left = max_jumps

	var input_dir = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	var is_moving = input_dir.length() > 0
	var wants_to_run = Input.is_physical_key_pressed(KEY_CTRL)

	var is_running = (
		wants_to_run
		and is_moving
		and not is_exhausted
		and is_on_floor()
	)

	# --- مصرف و بازیابی استقامت ---
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

	# --- سیستم پرش ---
	if Input.is_action_just_pressed("ui_accept") and jumps_left > 0:

		var is_last_jump = is_equal_approx(jumps_left, 0.5)

		# تعیین هزینه انرژی پرش
		var required_stamina = jump_drain

		if is_last_jump:
			required_stamina = Last_jump_drain

		# فقط در صورت داشتن انرژی کافی اجازه پرش بده
		if current_stamina >= required_stamina:

			var current_jump = jump_velocity

			# پرش آخر
			if is_last_jump:
				current_jump = Last_jump_velocity

			elif is_exhausted:
				current_jump /= 1.5

			elif is_running:
				current_jump *= run_jump_multiplier

			velocity.y = current_jump

			jumps_left -= 1

			# مصرف انرژی متناسب با نوع پرش
			current_stamina -= required_stamina

			current_stamina = max(current_stamina, 0.0)

	# --- حرکت بازیکن ---
	var direction = (
		transform.basis *
		Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

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

	# --- بازیابی سلامتی ---
	if (
		current_stamina >= max_stamina
		and current_health < max_health
		and not is_dead
	):
		current_health += health_regen_rate * delta
		current_health = clamp(current_health, 0, max_health)

		health_bar.value = current_health


func take_damage(amount):
	current_health -= amount
	health_bar.value = current_health

	if current_health <= 0:
		die()


func die():
	is_dead = true
	velocity = Vector3.ZERO

	death_screen.show()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	print("بازیکن مرد! 💀")

	await get_tree().create_timer(3.0).timeout

	get_tree().reload_current_scene()
