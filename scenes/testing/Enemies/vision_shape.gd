@tool
extends ShapeCast2D

@export_category("Tầm nhìn AI (Vision Cone)")

# Bán kính tầm nhìn (độ dài tia)
@export var view_radius: float = 300.0:
	set(value):
		view_radius = max(1.0, value) # Không cho phép giá trị âm
		_update_shape()

# Góc mở tầm nhìn (tính bằng độ)
@export_range(10.0, 360.0) var view_angle_degrees: float = 90.0:
	set(value):
		view_angle_degrees = value
		_update_shape()

# Độ mượt của cung tròn (càng cao càng tròn, nhưng nặng hơn)
@export_range(5, 64) var curve_quality: int = 16:
	set(value):
		curve_quality = value
		_update_shape()

func _ready():
	# Quan trọng: Đặt target_position về 0 vì ta chỉ muốn check ngay tại chỗ, không quét dọc đường
	target_position = Vector2.ZERO
	_update_shape()

# Hàm tự động vẽ hình đa giác
func _update_shape():
	var cone_shape = ConvexPolygonShape2D.new()
	var points = PackedVector2Array()
	
	# 1. Điểm đầu tiên là tâm (mắt kẻ địch, toạ độ 0,0)
	points.append(Vector2.ZERO)
	
	# 2. Đổi từ độ sang Radian để tính toán lượng giác
	var start_angle = -deg_to_rad(view_angle_degrees / 2.0)
	var end_angle = deg_to_rad(view_angle_degrees / 2.0)
	var angle_step = (end_angle - start_angle) / (curve_quality - 1)
	
	# 3. Vẽ các điểm cong trên cung tròn
	for i in range(curve_quality):
		var current_angle = start_angle + (i * angle_step)
		
		# Mặc định hình nón sẽ hướng sang phải (trục X dương)
		var point = Vector2(-cos(current_angle), sin(current_angle)) * view_radius
		points.append(point)
		
	# 4. Gắn các điểm vừa vẽ vào Shape và cập nhật cho ShapeCast2D
	cone_shape.points = points
	self.shape = cone_shape
