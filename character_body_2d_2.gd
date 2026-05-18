extends CharacterBody2D
@onready var anim = $AnimatedSprite2D
@onready var Shadow =$Shadow
const SPEED = 72.0
const JUMP_VELOCITY = 0.0
const SLIDE_SPEED = 300.0

var is_sliding = false
var can_move: bool = true
var is_locked: bool = false

func _physics_process(delta: float) -> void:
	if is_locked or can_move == false:
		velocity.x = 0
		move_and_slide()
		return
	Shadow.modulate.a = 1.0
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
		Shadow.modulate.a = 0
		if velocity.x < 0:
			anim.flip_h = true
		else:
			anim.flip_h = false
	else:
		#Moving action
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
