class_name SaberHitbox
extends Node2D
signal hit_confirmed(attack_name: StringName)
signal target_hit(body: Node2D)
var _impact_reported := false

@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hitbox_animation: AnimationPlayer = $AnimationPlayer
@onready var source_body: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

var _attack_active := false
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
	hitbox_animation.play(attack_name)

func stop_attack_window() -> void:
	_attack_active = false
	_generation += 1
	_apply_stop_attack_window.call_deferred(_generation)

func _apply_stop_attack_window(generation: int) -> void:
	if generation != _generation: return
	hitbox_animation.stop()
	hitbox_shape.set_deferred("disabled", true)

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
	# Apply the exact same authored shape transform as a normal Saber attack.
	var clip := hitbox_animation.get_animation(&"saber_attack_1")
	for track in clip.get_track_count():
		var path := String(clip.track_get_path(track))
		if path.ends_with(":position"): hitbox_shape.position = clip.track_get_key_value(track, 0)
		elif path.ends_with(":rotation"): hitbox_shape.rotation = clip.track_get_key_value(track, 0)
	hitbox_shape.set_deferred("disabled", false)

func sample_skill_damage() -> void:
	if not _attack_active or _active_attack_name != &"saber_skill": return
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hitbox_shape.shape
	query.transform = hitbox_shape.global_transform
	query.collision_mask = $Hitbox.collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var source := get_parent().get_parent() as CollisionObject2D
	if source != null: query.exclude = [source.get_rid()]
	for contact in get_world_2d().direct_space_state.intersect_shape(query, 64):
		_on_hitbox_body_entered(contact.collider)
