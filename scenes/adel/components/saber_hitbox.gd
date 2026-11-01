class_name SaberHitbox
extends Node2D
signal hit_confirmed(attack_name: StringName)
signal target_hit(body: Node2D)
var _impact_reported := false

@onready var hitbox_area: Area2D = $"../../AttackHitbox"
@onready var hitbox_shape: CollisionShape2D = $"../../AttackHitbox/CollisionShape2D"
@onready var hitbox_animation: AnimationPlayer = $AnimationPlayer
@onready var source_body: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

var _attack_active := false
var _combo_window_open := false
var _active_attack_name: StringName
var _hit_targets: Dictionary = {}
var _swing_damage := 20
var _generation := 0

func get_active_attack_name() -> StringName:
	return _active_attack_name

func get_attack_generation() -> int:
	return _generation

func _ready() -> void:
	hitbox_shape.disabled = true
	# Opening must run before closing/finish even when one update crosses all keys.
	hitbox_animation.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	hitbox_animation.animation_finished.connect(_on_hitbox_animation_finished)

func play_attack_window(attack_name: StringName, amount: int = 20) -> void:
	if _attack_active and _active_attack_name == attack_name:
		return
	_hit_targets.clear()
	_impact_reported = false
	_attack_active = true
	_active_attack_name = attack_name
	_generation += 1
	_swing_damage = maxi(amount, 0)
	_combo_window_open = false
	hitbox_shape.set_deferred("disabled", true)
	hitbox_area.set_deferred("monitoring", true)
	hitbox_animation.play(attack_name)

func stop_attack_window() -> void:
	_attack_active = false
	_combo_window_open = false
	_generation += 1
	_apply_stop_attack_window.call_deferred(_generation)

func _apply_stop_attack_window(generation: int) -> void:
	if generation != _generation: return
	hitbox_animation.stop()
	hitbox_shape.set_deferred("disabled", true)

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if _combo_window_open or _active_attack_name == &"saber_skill":
		_on_hitbox_body_entered(body)

func _set_combo_window_enabled(enabled: bool) -> void:
	if not _attack_active or _active_attack_name == &"saber_skill": return
	_combo_window_open = enabled
	hitbox_shape.set_deferred("disabled", not enabled)
	if enabled:
		_sample_shape_damage(hitbox_shape, hitbox_area.collision_mask)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not _attack_active or not body.has_method("take_damage"):
		return
	var target_id := body.get_instance_id()
	if _hit_targets.has(target_id):
		return

	_hit_targets[target_id] = true
	var old_health = _read_health(body)
	var amount: int = source_body.scale_attack_damage(_swing_damage)
	var accepted = body.take_damage(amount, global_position)
	if accepted == null and old_health != null and is_instance_valid(body):
		var new_health = _read_health(body)
		accepted = new_health != null and new_health < old_health
	if accepted == true and amount > 0: target_hit.emit(body)
	if accepted == true and amount > 0 and not _impact_reported:
		_impact_reported = true
		hit_confirmed.emit(_active_attack_name)

func _read_health(body: Node):
	for info in body.get_property_list():
		if info.name == &"current_health": return body.get(&"current_health")
	return null

func _on_hitbox_animation_finished(_animation_name: StringName) -> void:
	_attack_active = false
	_combo_window_open = false
	hitbox_shape.set_deferred("disabled", true)

func begin_skill_window(amount: int) -> void:
	stop_attack_window()
	_generation += 1
	_attack_active = true
	_active_attack_name = &"saber_skill"
	_impact_reported = false
	_swing_damage = maxi(amount, 0)
	_hit_targets.clear()
	hitbox_animation.stop()
	hitbox_area.set_deferred("monitoring", true)
	hitbox_shape.set_deferred("disabled", false)

func sample_skill_damage() -> void:
	if not _attack_active or _active_attack_name != &"saber_skill": return
	_sample_shape_damage(hitbox_shape, hitbox_area.collision_mask)

func _sample_shape_damage(shape_node: CollisionShape2D, mask: int) -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.transform = shape_node.global_transform
	query.collision_mask = mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var source := get_parent().get_parent() as CollisionObject2D
	if source != null: query.exclude = [source.get_rid()]
	for contact in get_world_2d().direct_space_state.intersect_shape(query, 64):
		_on_hitbox_body_entered(contact.collider)
