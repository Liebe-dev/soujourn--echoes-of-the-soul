extends EnemyPrototype

@onready var hurtbox: Area2D = $HurtBox
@onready var detection_area: Area2D = $DetectionArea

@export var chase_speed: float = 200.0
@export var lunge_speed: float = 400.0
@export var lunge_range: float = 120.0
@export var lunge_duration: float = 0.4
@export var chase_memory_time: float = 10.0

var target_player: Node2D = null
var memory_timer: float = 0.0
var lunge_timer: float = 0.0
var is_player_in_sight: bool = false
var lunge_cooldown: float = 0.0

func _ready() -> void:
	# Gọi hàm _ready() từ script gốc [cite: 1]
	super._ready()
	
	# Set sát thương gai nhím [cite: 1]
	hurt_damage = 20 
	
	# Kết nối tín hiệu
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	detection_area.body_entered.connect(_on_detection_entered)
	detection_area.body_exited.connect(_on_detection_exited)

func _physics_process(delta: float) -> void:
	# Trọng lực [cite: 2]
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Trừ thời gian hồi chiêu của đòn vồ
	if lunge_cooldown > 0:
		lunge_cooldown -= delta

	# Máy trạng thái AI
	match ai_state:
		"walk", "idle":
			_handle_patrol(delta)
		"chase":
			_handle_chase(delta)
		"lunge":
			_handle_lunge(delta)

	move_and_slide()

# ----------------- HÀM XỬ LÝ AI -----------------

func _handle_patrol(delta: float) -> void:
	ai_timer -= delta
	if ai_timer <= 0.0:
		if ai_state == "walk":
			ai_state = "idle"
			ai_timer = idle_duration # [cite: 1]
		else:
			ai_state = "walk"
			ai_timer = walk_duration # [cite: 1]
		_set_animation(ai_state)
	
	if ai_state == "walk":
		var target_x = start_position.x + patrol_direction * patrol_range # [cite: 1]
		if patrol_direction > 0 and global_position.x >= target_x: # [cite: 3]
			patrol_direction = -1 # [cite: 3]
		elif patrol_direction < 0 and global_position.x <= target_x: # [cite: 3]
			patrol_direction = 1 # [cite: 3]
		
		velocity.x = speed * patrol_direction # [cite: 3]
		_update_facing()
	elif ai_state == "idle":
		velocity.x = 0 # [cite: 3]

func _handle_chase(delta: float) -> void:
	if target_player == null:
		_return_to_patrol()
		return
		
	# Đếm ngược 10 giây nếu mất dấu
	if not is_player_in_sight:
		memory_timer -= delta
		if memory_timer <= 0.0:
			_return_to_patrol()
			return

	# Xoay mặt về phía người chơi
	var direction_to_player = sign(target_player.global_position.x - global_position.x)
	if direction_to_player != 0:
		patrol_direction = direction_to_player
		_update_facing()
	
	# Kiểm tra khoảng cách để vồ (lunge)
	var distance_to_player = abs(global_position.x - target_player.global_position.x)
	if distance_to_player <= lunge_range and lunge_cooldown <= 0:
		ai_state = "lunge"
		lunge_timer = lunge_duration
		_set_animation("lunge") 
	else:
		velocity.x = chase_speed * patrol_direction

func _handle_lunge(delta: float) -> void:
	lunge_timer -= delta
	velocity.x = lunge_speed * patrol_direction 
	
	if lunge_timer <= 0:
		velocity.x = 0
		lunge_cooldown = 1.5 
		ai_state = "chase"
		_set_animation("chase")

# ----------------- HÀM PHỤ TRỢ -----------------

func _return_to_patrol() -> void:
	target_player = null
	ai_state = "idle"
	ai_timer = idle_duration # [cite: 1]
	start_position = global_position 
	_set_animation("idle")

func _update_facing() -> void:
	if pivot != null:
		pivot.scale.x = -1 if patrol_direction > 0 else 1 
		
	if animated_sprite: 
		animated_sprite.flip_h = patrol_direction > 0
# ----------------- TÍN HIỆU (SIGNALS) -----------------

func _on_detection_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = body
		is_player_in_sight = true
		ai_state = "chase"
		_set_animation("chase")

func _on_detection_exited(body: Node2D) -> void:
	if body == target_player:
		is_player_in_sight = false
		memory_timer = chase_memory_time

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(hurt_damage, global_position)

# ----------------- GHI ĐÈ ANIMATION -----------------
# Chuyển đổi logic AI sang đúng 3 animation bạn đang có
func _set_animation(state: String) -> void:
	if animated_sprite:
		# Reset lại tốc độ phát hình mặc định
		animated_sprite.speed_scale = 1.0 
		
		match state:
			"idle":
				animated_sprite.play("idle")
			"walk":
				animated_sprite.play("walking")
			"chase":
				animated_sprite.play("walking") # Đuổi cũng dùng dáng đi bộ
				animated_sprite.speed_scale = 1.5 # Tăng tốc độ phát hình lên gấp rưỡi cho có cảm giác vội vàng
			"lunge":
				animated_sprite.play("attack") # Khi vồ thì dùng animation tấn công
