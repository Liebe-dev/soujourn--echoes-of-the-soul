extends CharacterBody2D

@export var max_health: int = 100
@export var attack_damage: int = 20

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var current_health: int = max_health

func _ready() -> void:
	current_health = max_health

func take_damage(dmg: int, hit_from_global: Vector2 = Vector2.INF) -> void:
	current_health = max(current_health - dmg, 0)
	if current_health <= 0:
		die()

func die() -> void:
	queue_free()

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
