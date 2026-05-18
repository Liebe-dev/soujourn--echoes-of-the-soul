extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func take_damage():
	pass

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

func _on_head_area_body_entered(body: Node2D) -> void:
	if body.has_method("SET_ON_NPC_HEAD"):
		body.SET_ON_NPC_HEAD(true, global_position)

func _on_head_area_body_exited(body: Node2D) -> void:
	if body.has_method("SET_ON_NPC_HEAD"):
		body.SET_ON_NPC_HEAD(false, global_position)
