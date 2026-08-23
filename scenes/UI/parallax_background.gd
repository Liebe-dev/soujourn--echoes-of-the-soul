extends ParallaxBackground

# Tốc độ cuộn (thay đổi số này để nhanh/chậm hoặc đổi dấu - để chạy ngược lại)
var scroll_speed = 50

func _process(delta):
	# Tự động cộng dồn tọa độ cuộn theo thời gian thực
	scroll_base_offset.x -= scroll_speed * delta
