extends CharacterBody2D
class_name EnemyPrototype

@onready var pivot = $WeaponPivot

@export var max_health: int = 100
@export var attack_damage: int = 20
@export var speed : float = 300.0
@export var hurt_damage: int = 20
@export var patrol_range: float = 200.0
@export var walk_duration: float = 5.0
@export var idle_duration: float = 5.0

const JUMP_VELOCITY = -400.0
var current_health: int = max_health
var patrol_direction: int = 1
var start_position: Vector2 = Vector2.ZERO
var ai_state: String = "walk"
var ai_timer: float = walk_duration
var animated_sprite: AnimatedSprite2D = null

func _ready() -> void:
	current_health = max_health
	start_position = global_position
	ai_state = "walk"
	ai_timer = walk_duration
	if has_node("AnimatedSprite2D"):
		animated_sprite = $AnimatedSprite2D
	_set_animation(ai_state)

func take_damage(dmg: int, hit_from_global: Vector2 = Vector2.INF) -> void:
	current_health = max(current_health - dmg, 0)
	print("Enemy took %d damage (%d/%d)" % [dmg, current_health, max_health])
	if current_health <= 0:
		die()

func die() -> void:
	queue_free()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	ai_timer -= delta
	if ai_timer <= 0.0:
		if ai_state == "walk":
			ai_state = "idle"
			ai_timer = idle_duration
		else:
			ai_state = "walk"
			ai_timer = walk_duration
		_set_animation(ai_state)
	
	if ai_state == "walk":
		var target_x = start_position.x + patrol_direction * patrol_range
		if patrol_direction > 0 and global_position.x >= target_x:
			patrol_direction = -1
		elif patrol_direction < 0 and global_position.x <= target_x:
			patrol_direction = 1
		velocity.x = speed * patrol_direction
		pivot.scale.x = -1 if patrol_direction > 0 else 1
		if animated_sprite:
			animated_sprite.flip_h = patrol_direction > 0
	elif ai_state == "idle":
		velocity.x = 0
	
	move_and_slide()

func _set_animation(state: String) -> void:
	if animated_sprite:
		match state:
			"walk":
				animated_sprite.play("walking")
			"idle":
				animated_sprite.play("idle")
