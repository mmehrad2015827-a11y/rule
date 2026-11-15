extends Node3D

func _ready():
	# وقتی وارد بازی میشیم، موس قفل بشه تا دوربین بچرخه
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	# چک میکنیم که آیا کلید Esc زده شده یا نه
	if event.is_action_pressed("ui_cancel"):
		
		# ۱. اول موس رو آزاد میکنیم تا توی منو گیر نکنه
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		# ۲. برمی‌گردیم به منو
		# ⚠️ اگر اسم فایل منوت چیز دیگه‌ایه، اسمش رو اینجا بنویس
		get_tree().change_scene_to_file("res://StartMenu.tscn")
