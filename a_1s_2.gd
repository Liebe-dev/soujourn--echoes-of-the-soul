extends Node2D # (Hoặc Node tuỳ thuộc vào gốc scene của bạn)

# Nắm kéo ColorRect của cảnh mới vào đây (giống như bạn làm với bush_overlay)
@onready var fade_in_overlay =$UI_OverLay/ColorOverLay
@onready var fade_in_overlay2 =$CanvasLayer/ColorOverLay2

func _ready() -> void:
	fade_in_overlay2.modulate.a = 1.0
	fade_in_overlay.modulate.a = 1.0
	
	# 2. Tạo hiệu ứng sáng dần (Fade-in)
	var tween = create_tween()
	# Giảm độ mờ (Alpha) từ 1.0 xuống 0.0 trong thời gian 1 giây
	tween.tween_property(fade_in_overlay, "modulate:a", 0.0, 0.8)
	# 1. Đảm bảo ngay khi vừa vào cảnh, màn hình phải đen thui (Alpha = 1.0)
	fade_in_overlay.modulate.a = 1.0
	
	# 2. Tạo hiệu ứng sáng dần (Fade-in)
	# Giảm độ mờ (Alpha) từ 1.0 xuống 0.0 trong thời gian 1 giây
	tween.tween_property(fade_in_overlay2, "modulate:a", 0.0, 4.5)
