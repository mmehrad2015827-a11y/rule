extends Control

func _ready():
	# ۱. وقتی توی منو هستیم، موس باید آزاد و قابل مشاهده باشه
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_button_pressed():
	# ۲. رفتن به صحنه بازی اصلی
	# ⚠️ نکته مهم: اگر اسم فایل بازی اصلیت (همون Node3D) چیز دیگه‌ایه، 
	# حتماً اینجا اسمش رو دقیق بنویس. مثلاً: "res://Main.tscn"
	get_tree().change_scene_to_file("res://vs.tscn") 
