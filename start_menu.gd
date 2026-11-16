extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_button_pressed():
	print("دکمه کلیک شد!") # این خط رو اضافه کردم
	
	# ⚠️ خیلی مهم: اسم فایل بازی اصلیت رو چک کن
	# اگر اسم فایل صحنه بازیت Node3D.tscn نیست، اسمش رو اینجا بنویس
	get_tree().change_scene_to_file("res://vs.tscn")
