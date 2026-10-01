class_name SaberHitbox
extends Node2D

@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hitbox_animation: AnimationPlayer = $AnimationPlayer

var _attack_active := false
var _active_attack_name: StringName
var _hit_targets: Dictionary = {}
var _shutdown_queued := false

func _ready() -> void:
	hitbox_shape.disabled = true
	hitbox_animation.animation_finished.connect(_on_hitbox_animation_finished)

func play_attack_window(attack_name: StringName) -> void:
	if _attack_active and _active_attack_name == attack_name:
		return
	_hit_targets.clear()
	_attack_active = true
	_active_attack_name = attack_name
	_shutdown_queued = false
	hitbox_animation.play(attack_name)

func stop_attack_window() -> void:
	_attack_active = false
	if _shutdown_queued:
		return
	_shutdown_queued = true
	call_deferred("_apply_stop_attack_window")

func _apply_stop_attack_window() -> void:
	_shutdown_queued = false
	hitbox_animation.stop()
	hitbox_shape.set_deferred("disabled", true)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not _attack_active or not body.has_method("take_damage"):
		return
	var target_id := body.get_instance_id()
	if _hit_targets.has(target_id):
		return

	_hit_targets[target_id] = true
	body.take_damage(20, global_position)

func _on_hitbox_animation_finished(_animation_name: StringName) -> void:
	_attack_active = false
	hitbox_shape.set_deferred("disabled", true)
