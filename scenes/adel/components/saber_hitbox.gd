class_name SaberHitbox
extends Node2D

@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hitbox_animation: AnimationPlayer = $AnimationPlayer

var _attack_active := false
var _hit_targets: Dictionary = {}

func _ready() -> void:
	hitbox_shape.disabled = true
	hitbox_animation.animation_finished.connect(_on_hitbox_animation_finished)

func play_attack_window(attack_name: StringName) -> void:
	_hit_targets.clear()
	_attack_active = true
	hitbox_animation.play(attack_name)

func stop_attack_window() -> void:
	_attack_active = false
	_hit_targets.clear()
	hitbox_animation.stop()
	hitbox_shape.disabled = true

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not _attack_active or not body.has_method("take_damage"):
		return
	if _hit_targets.has(body):
		return

	_hit_targets[body] = true
	body.take_damage(20, global_position)

func _on_hitbox_animation_finished(_animation_name: StringName) -> void:
	_attack_active = false
	_hit_targets.clear()
	hitbox_shape.disabled = true
