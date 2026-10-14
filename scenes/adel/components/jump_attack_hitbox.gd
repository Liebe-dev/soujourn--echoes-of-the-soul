class_name JumpAttackHitbox
extends Area2D
## One swing spans falling and landing; the coordinator controls its damage window.

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var source_body: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
var _attack_active := false
var _window_open := false
var _opening_query_pending := false
var _swing_damage := 0
var _hit_targets: Dictionary = {}
var _query := PhysicsShapeQueryParameters2D.new()

func _ready() -> void:
	_query.collide_with_areas = false
	_query.collide_with_bodies = true
	if source_body != null: _query.exclude = [source_body.get_rid()]
	collision_shape.disabled = true

func begin_attack(amount: int) -> void:
	end_attack()
	_hit_targets.clear()
	_swing_damage = maxi(amount, 0)
	_attack_active = true

func end_attack() -> void:
	_attack_active = false
	set_damage_window(false)

func set_damage_window(active: bool) -> void:
	active = active and _attack_active and _swing_damage > 0
	if _window_open == active: return
	_window_open = active
	_opening_query_pending = active
	set_deferred("monitoring", active)
	collision_shape.set_deferred("disabled", not active)

func sample_damage(force_query: bool = false) -> void:
	if not _attack_active or not _window_open or not _has_live_source(): return
	if monitoring:
		for body in get_overlapping_bodies():
			_try_hit_body(body)
	if not _window_open or not _has_live_source(): return
	# Area overlap caches can miss activation or the last movement before landing.
	if force_query or _opening_query_pending:
		_opening_query_pending = false
		_query.shape = collision_shape.shape
		_query.transform = collision_shape.global_transform
		_query.collision_mask = collision_mask
		for contact in get_world_2d().direct_space_state.intersect_shape(_query):
			_try_hit_body(contact.get("collider") as Node2D)

func _try_hit_body(body: Node2D) -> void:
	if not _attack_active or not _window_open or not _has_live_source(): return
	if not is_instance_valid(body) or body.is_queued_for_deletion(): return
	if body.is_in_group("Player") or not body.has_method("take_damage"): return
	var id := body.get_instance_id()
	if _hit_targets.has(id): return
	_hit_targets[id] = true
	body.take_damage(_swing_damage, source_body.global_position)

func _has_live_source() -> bool:
	return is_inside_tree() and not is_queued_for_deletion() and is_instance_valid(source_body) and source_body.is_inside_tree() and not source_body.is_queued_for_deletion()
