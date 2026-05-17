extends Control

# ======================
#      STATS
# ======================
var max_hp := 100
var hp := 100

# ======================
#      NODES
# ======================
@onready var hp_main = $bar/hp/hp_main
@onready var hp_delay = $bar/hp/hp_delay

# ======================
#   AUTO HIDE SYSTEM
# ======================
var in_combat := false
var hide_delay := 3.0
var hide_timer := 0.0
var is_hidden := false
var fade_tween: Tween

# ======================
#      READY
# ======================
func _ready():
	# Khởi tạo giá trị ban đầu
	update_shader_value(hp_main, float(hp) / max_hp)
	update_shader_value(hp_delay, float(hp) / max_hp)
	
	# Mới vào thì ẩn HUD đi
	modulate.a = 0.0
	is_hidden = true

# ======================
#      PROCESS
# ======================
func _process(delta):
	if in_combat:
		hide_timer += delta
		
		if hide_timer >= hide_delay:
			fade_out()
			in_combat = false
			hide_timer = 0.0

# ======================
#      HP SYSTEM
# ======================
func heal_to_full() -> void:
	hp = max_hp
	sync_hp_display()
	fade_in()

func sync_hp_display() -> void:
	var percent := float(hp) / float(max_hp)
	update_shader_value(hp_main, percent)
	update_shader_value(hp_delay, percent)

func damage(dmg: int):
	hp = clamp(hp - dmg, 0, max_hp)
	var percent = float(hp) / max_hp
	
	# Cập nhật thanh chính ngay lập tức
	update_shader_value(hp_main, percent)
	
	# Tween cho thanh delay (màu trắng/vàng chạy sau)
	var t = create_tween()
	t.tween_method(
		func(v): update_shader_value(hp_delay, v),
		hp_delay.material.get_shader_parameter("hp"),
		percent,
		0.6
	)
	
	flash_red()
	
	# Kích hoạt hiện HUD
	hide_timer = 0.0
	in_combat = true
	fade_in()

	if hp <= 0:
		SaveManager.respawn_at_checkpoint()

func update_shader_value(node: CanvasItem, value: float):
	if node and node.material:
		node.material.set_shader_parameter("hp", value)

# ======================
#      EFFECTS
# ======================
func flash_red():
	var t = create_tween()
	t.tween_property(self, "modulate", Color(1, 0.5, 0.5, 1), 0.05)
	t.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)

func fade_in():
	if not is_hidden:
		return
		
	is_hidden = false
	
	if fade_tween:
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.4)
func fade_out():
	if is_hidden:
		return
		
	is_hidden = true
	
	if fade_tween:
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.6)
# ======================
#      INPUT TEST
# ======================
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			damage(10)   
