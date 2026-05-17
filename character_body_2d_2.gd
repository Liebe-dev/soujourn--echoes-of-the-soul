extends CharacterBody2D
@onready var anim = $AnimatedSprite2D
#@onready var Shadow =$Shadow
const SPEED = 300.0 #72.0
const JUMP_VELOCITY = 0.0
const SLIDE_SPEED = 300.0

var is_sliding = false
var can_move: bool = true
var is_locked: bool = false
var is_resting: bool = false
var _position_before_rest: Vector2 = Vector2.ZERO

func enter_rest(_world_position: Vector2, face_left: bool) -> void:
	_position_before_rest = global_position
	is_resting = true
	is_locked = true
	can_move = false
	velocity = Vector2.ZERO
	anim.flip_h = face_left
	anim.play("idle")

func exit_rest() -> void:
	is_resting = false
	is_locked = false
	can_move = true
	velocity = Vector2.ZERO
	global_position = _position_before_rest
	snap_feet_to_floor()

func snap_feet_to_floor(max_drop: float = 96.0) -> void:
	var col := $CollisionShape2D as CollisionShape2D
	if col == null or col.shape == null:
		return
	var half_h := _capsule_half_height(col)
	var feet := Vector2(col.global_position.x, col.global_position.y + half_h)
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		feet + Vector2(0, -4.0),
		feet + Vector2(0, max_drop)
	)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	global_position.y += hit.position.y - feet.y

func _capsule_half_height(col: CollisionShape2D) -> float:
	var capsule := col.shape as CapsuleShape2D
	if capsule == null:
		return 32.0
	var scale_y := col.global_transform.get_scale().y
	return capsule.height * 0.5 * scale_y

func _physics_process(delta: float) -> void:
	if is_resting:
		velocity = Vector2.ZERO
		return
	if is_locked or can_move == false:
		velocity.x = 0
		move_and_slide()
		return
	#Shadow.modulate.a = 1.0
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor():
		var floor_angle = get_floor_angle()
		if floor_angle > deg_to_rad(20.0):
			is_sliding = true
		else:
			is_sliding = false
	else:
		is_sliding = false

	if is_sliding:
		var slope_normal = get_floor_normal()
		
		velocity.x = slope_normal.x * 2 * SLIDE_SPEED
		
		anim.play("Slide")
		#Shadow.modulate.a = 0
		if velocity.x < 0:
			anim.flip_h = true
		else:
			anim.flip_h = false
	else:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			
		var direction := Input.get_axis("move_left", "move_right")
		
		if direction:
			if is_on_floor():
				anim.play("walk")
			velocity.x = direction * SPEED
			
			if direction < 0:
				anim.flip_h = true  
			else:
				anim.flip_h = false 
				
		else:
			if is_on_floor():
				if abs(velocity.x) > 100: 
					anim.play("Slide")
				else:
					anim.play("idle")
					
			velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
