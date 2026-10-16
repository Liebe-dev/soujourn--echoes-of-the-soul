class_name EnemyBase
extends CharacterBody2D
const ChargedFinish = preload("res://scenes/adel/components/charged_skill_finish.gd")
const EnemyDebugSettings = preload("res://scenes/enemy/enemy_debug_settings.gd")
## M1: patrol, world physics, receiving damage, and one death/EXP reward.
## Add the Enemy group in the scene only when player contact damage is wanted.

@export_group("Health")
@export_range(1, 10000, 1, "or_greater") var max_health: int = 20
@export_range(0, 10000, 1, "or_greater") var exp_reward: int = 30

@export_group("Patrol")
@export_range(0.0, 1000.0, 1.0, "or_greater") var speed: float = 150.0
@export_range(0.0, 2000.0, 1.0, "or_greater") var patrol_range: float = 200.0
@export_range(0.01, 60.0, 0.01, "or_greater") var walk_duration: float = 5.0
@export_range(0.01, 60.0, 0.01, "or_greater") var idle_duration: float = 5.0
@export_enum("Left:-1", "Right:1") var initial_direction: int = 1

@export_group("Animation")
@export var animation_idle: StringName = &"idle"
@export var animation_walk: StringName = &"walking"
@export var sprite_faces_left: bool = true

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var current_health: int = 0
var is_dead: bool = false
var _debug_ai_was_disabled := false
var _anchor_x: float = 0.0
var _direction: int = 1
var _walking: bool = true
var _state_time_left: float = 0.0


func _ready() -> void:
	add_to_group(&"camera_lock_targets")
	current_health = maxi(max_health, 1)
	_anchor_x = global_position.x
	_direction = -1 if initial_direction < 0 else 1
	_state_time_left = maxf(walk_duration, 0.01)
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape == null or body_shape.shape == null or body_shape.disabled:
		push_warning("EnemyBase needs an enabled CollisionShape2D; movement disabled.")
		set_physics_process(false)
	_update_facing()
	_set_animation(animation_walk)


func _debug_idle(delta: float) -> void:
	_debug_ai_was_disabled = true
	velocity.x = 0.0
	if not is_on_floor(): velocity += get_gravity() * delta
	_set_animation(animation_idle)
	move_and_slide()


## The body collider is the hurtbox; offensive Areas must never be lock points.
func get_lock_on_point() -> Vector2:
	var hurtbox := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if is_dead or current_health <= 0 or hurtbox == null or hurtbox.disabled or hurtbox.shape == null:
		return Vector2.INF
	return hurtbox.global_transform * hurtbox.shape.get_rect().get_center()


func _physics_process(delta: float) -> void:
	if is_dead or delta <= 0.0:
		return
	if EnemyDebugSettings.is_ai_disabled():
		_debug_idle(delta)
		return
	if _debug_ai_was_disabled:
		_debug_ai_was_disabled = false
		_set_animation(animation_walk if _walking else animation_idle)
	if not is_on_floor():
		velocity += get_gravity() * delta

	_state_time_left -= delta
	if _state_time_left <= 0.0:
		_walking = not _walking
		_state_time_left = maxf(walk_duration if _walking else idle_duration, 0.01)
		_set_animation(animation_walk if _walking else animation_idle)

	velocity.x = 0.0
	var distance_from_anchor := maxf(patrol_range, 0.0)
	if _walking and distance_from_anchor > 0.0:
		var left_edge := _anchor_x - distance_from_anchor
		var right_edge := _anchor_x + distance_from_anchor
		if global_position.x >= right_edge:
			_direction = -1
		elif global_position.x <= left_edge:
			_direction = 1
		var target_x := right_edge if _direction > 0 else left_edge
		# Limit this frame's travel so even a large physics step cannot overshoot.
		var step_speed := minf(maxf(speed, 0.0), absf(target_x - global_position.x) / delta)
		velocity.x = step_speed * _direction
		_update_facing()

	move_and_slide()
	if _walking and is_on_wall():
		_direction *= -1
		_update_facing()


@warning_ignore("unused_parameter")
func take_damage(dmg: int, hit_from_global: Vector2 = Vector2.INF) -> bool:
	# Kept for the SaberHitbox API; knockback belongs to a later milestone.
	if ChargedFinish.is_freezing() or is_dead or dmg <= 0:
		return false
	# Accept the hit for feedback/stun while leaving HP and EXP untouched.
	if EnemyDebugSettings.is_immortal(): return true
	current_health = maxi(current_health - dmg, 0)
	if current_health == 0:
		die()
	return true


func die() -> void:
	if ChargedFinish.is_freezing() or is_dead or EnemyDebugSettings.is_immortal():
		return
	# queue_free is deferred; set the guard before signals or another hit can run.
	is_dead = true
	current_health = 0
	velocity = Vector2.ZERO
	set_physics_process(false)
	PlayerProgress.add_exp(exp_reward)
	_finish_death()


func _finish_death() -> void:
	# Animated enemies override this final step; prototypes keep immediate removal.
	queue_free()


func _update_facing() -> void:
	if animated_sprite != null:
		animated_sprite.flip_h = (_direction > 0) if sprite_faces_left else (_direction < 0)


func _set_animation(requested: StringName) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var frames := animated_sprite.sprite_frames
	var chosen := requested
	if not frames.has_animation(chosen) or frames.get_frame_count(chosen) == 0:
		chosen = &""
		for candidate in frames.get_animation_names():
			if frames.get_frame_count(candidate) > 0:
				chosen = StringName(candidate)
				break
		if chosen == &"":
			animated_sprite.stop()
			return
	if animated_sprite.animation != chosen or not animated_sprite.is_playing():
		animated_sprite.play(chosen)
