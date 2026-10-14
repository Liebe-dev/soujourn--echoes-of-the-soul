extends EnemyBase
## Uses EnemyBase's health/death contract; this enemy owns its combat decisions.

enum State { WALK, RUN, WINDUP, LEAP, LAND, MELEE, RECOVERY }

@export_group("Detection")
@export_range(1.0, 2000.0) var detection_distance: float = 500.0
@export_range(1.0, 2500.0) var disengage_distance: float = 650.0
@export_range(0.0, 10.0) var chase_memory: float = 1.5
@export var reset_opener_on_disengage: bool = true
@export_range(0.0, 1000.0) var run_speed: float = 240.0

@export_group("Opening Leap")
@export_range(1.0, 1000.0) var leap_range: float = 280.0
@export_range(0.01, 3.0) var windup_time: float = 0.4
@export_range(1.0, 1500.0) var jump_speed: float = 420.0
@export_range(1.0, 1500.0) var max_leap_speed: float = 520.0
@export_range(0.01, 3.0) var landing_time: float = 0.35
@export_range(0, 1000) var leap_damage: int = 20

@export_group("Follow-up Attacks")
@export_range(1.0, 500.0) var melee_range: float = 110.0
@export_range(1.0, 500.0) var attack_height_tolerance: float = 100.0
@export_range(0.0, 1.0) var attack3_chance: float = 0.2
@export_range(0.01, 10.0) var recovery_time: float = 0.7
@export_range(0, 1000) var attack2_damage: int = 12
@export_range(0, 1000) var attack3_damage: int = 18
## Seconds in the source clips (attack2: 0.7s, attack3: 0.9s).
@export var attack2_window: Vector2 = Vector2(0.3, 0.45)
@export var attack3_window: Vector2 = Vector2(0.4, 0.65)

@export_group("Rig Alignment")
## Per-clip offsets compensate the source rig's different pose origins.
@export var animation_offsets: Dictionary[StringName, Vector2] = {
	&"walk": Vector2(0, 22), &"run": Vector2(0, 42),
	&"attack1_1": Vector2(0, 20), &"attack1_3": Vector2(0, 18.45),
	&"attack2": Vector2(0, 20), &"attack3": Vector2(0, 24.6),
}

@onready var visual_pivot: Node2D = get_node_or_null("VisualPivot")
@onready var rig: Node2D = get_node_or_null("VisualPivot/EnemyRig")
@onready var animation_player: AnimationPlayer = get_node_or_null("VisualPivot/EnemyRig/AnimationPlayer")
@onready var weapon_pivot: Node2D = get_node_or_null("WeaponPivot")
@onready var hitbox: Area2D = get_node_or_null("WeaponPivot/Hitbox")
@onready var hitbox_shape: CollisionShape2D = get_node_or_null("WeaponPivot/Hitbox/CollisionShape2D")

@onready var leap_hitbox: Area2D = get_node_or_null("LeapHitbox")
@onready var leap_hitbox_shape: CollisionShape2D = get_node_or_null("LeapHitbox/CollisionShape2D")

var state: State = State.WALK
var attack_animation: StringName = &""
var target: Node2D
var opener_available: bool = true
var _elapsed: float = 0.0
var _lost_time: float = 0.0
var _leap_velocity_x: float = 0.0
var _has_left_floor: bool = false
var _window_open: bool = false
var _active_hitbox: Area2D
var _leap_opening_check_pending := false
var _leap_query := PhysicsShapeQueryParameters2D.new()
var _swing_damage: int = 0
var _hit_targets: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _rig_origin := Vector2.ZERO


func _ready() -> void:
	if rig != null:
		_rig_origin = rig.position
	super._ready()
	_rng.randomize()
	if animation_player == null or visual_pivot == null or weapon_pivot == null or hitbox_shape == null or hitbox == null or leap_hitbox == null or leap_hitbox_shape == null or leap_hitbox_shape.shape == null:
		push_warning("SpineEnemy needs its rig, WeaponPivot/Hitbox and LeapHitbox with collision shapes.")
		set_physics_process(false)
		return
	for clip in [&"walk", &"run", &"attack1_1", &"attack1_2", &"attack1_3", &"attack2", &"attack3"]:
		if not animation_player.has_animation(clip):
			push_warning("SpineEnemy is missing animation: " + clip)
			set_physics_process(false)
			return
	# Authoring helpers in the source rig are not part of the character.
	for helper in ["Sprite2D", "Sprite2D2"]:
		var node := get_node_or_null("VisualPivot/EnemyRig/" + helper) as CanvasItem
		if node != null:
			node.hide()
	hitbox_shape.disabled = true
	leap_hitbox_shape.disabled = true
	_leap_query.collide_with_areas = false
	_leap_query.collide_with_bodies = true
	_leap_query.exclude = [get_rid()]
	_enter_state(State.WALK)


func _physics_process(delta: float) -> void:
	if is_dead or delta <= 0.0:
		return
	_elapsed += delta
	_refresh_target(delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity.x = 0.0
	match state:
		State.WALK:
			if is_instance_valid(target):
				_enter_state(State.RUN)
			else:
				_walk_patrol(delta)
		State.RUN:
			if not is_instance_valid(target):
				_enter_state(State.WALK)
			else:
				_face_target()
				var distance := absf(target.global_position.x - global_position.x)
				var reachable := absf(target.global_position.y - global_position.y) <= attack_height_tolerance
				if is_on_floor() and reachable and opener_available and distance <= leap_range:
					_enter_state(State.WINDUP)
				elif is_on_floor() and reachable and not opener_available and distance <= melee_range:
					_begin_melee()
				else:
					velocity.x = minf(run_speed, distance / delta) * _direction
		State.WINDUP:
			if not is_instance_valid(target):
				_enter_state(State.WALK)
			elif _elapsed >= maxf(windup_time, 0.01) and is_on_floor():
				_launch()
		State.LEAP:
			velocity.x = _leap_velocity_x
			_set_damage_window(is_instance_valid(target))
		State.LAND:
			if _elapsed >= maxf(landing_time, 0.01):
				_enter_state(State.RECOVERY)
		State.MELEE:
			var window := attack3_window if attack_animation == &"attack3" else attack2_window
			_set_damage_window(is_instance_valid(target) and _elapsed >= maxf(window.x, 0.0) and _elapsed < window.y)
			if not is_instance_valid(target) or _elapsed >= animation_player.get_animation(attack_animation).length:
				_enter_state(State.RECOVERY)
		State.RECOVERY:
			if _elapsed >= maxf(recovery_time, 0.01):
				_enter_state(State.RUN if is_instance_valid(target) else State.WALK)
	move_and_slide()
	# Resolve this frame's active swing before LAND closes its window.
	_apply_swing_damage()
	if state == State.LEAP and _window_open:
		# Area overlap lists update on physics ticks. Query only at opening/landing
		# to include an existing overlap and contact on the final flight frame.
		if _leap_opening_check_pending or (_has_left_floor and is_on_floor()):
			_apply_leap_contact_damage()
		_leap_opening_check_pending = false
	if not is_inside_tree() or is_queued_for_deletion() or is_dead:
		return
	if state == State.LEAP:
		if not is_on_floor():
			_has_left_floor = true
		elif _has_left_floor:
			_enter_state(State.LAND)
		elif _elapsed > 0.2:
			# A low ceiling/obstruction can prevent takeoff; never remain in LEAP forever.
			_enter_state(State.RECOVERY)
	elif state == State.WALK and is_on_wall():
		_direction *= -1
		_update_facing()


func _refresh_target(delta: float) -> void:
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		if global_position.distance_to(target.global_position) <= maxf(disengage_distance, detection_distance):
			_lost_time = 0.0
		else:
			_lost_time += delta
			if _lost_time >= chase_memory:
				target = null
	else:
		target = null
	if target != null:
		return
	if reset_opener_on_disengage:
		opener_available = true
	var nearest := detection_distance
	for candidate in get_tree().get_nodes_in_group("Player"):
		if not candidate is Node2D or candidate.is_queued_for_deletion():
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= nearest:
			nearest = distance
			target = candidate
			_lost_time = 0.0


func _walk_patrol(delta: float) -> void:
	if patrol_range <= 0.0:
		return
	if global_position.x >= _anchor_x + patrol_range:
		_direction = -1
	elif global_position.x <= _anchor_x - patrol_range:
		_direction = 1
	var endpoint := _anchor_x + _direction * patrol_range
	velocity.x = minf(maxf(speed, 0.0), absf(endpoint - global_position.x) / delta) * _direction
	_update_facing()


func _face_target() -> void:
	if is_instance_valid(target):
		var dx := target.global_position.x - global_position.x
		if not is_zero_approx(dx):
			_direction = 1 if dx > 0.0 else -1
			_update_facing()


func _launch() -> void:
	_face_target()
	opener_available = false
	var flight_time := 2.0 * jump_speed / maxf(get_gravity().y, 1.0)
	_leap_velocity_x = clampf((target.global_position.x - global_position.x) / flight_time, -max_leap_speed, max_leap_speed)
	velocity = Vector2(_leap_velocity_x, -jump_speed)
	_has_left_floor = false
	_hit_targets.clear()
	_swing_damage = leap_damage
	_enter_state(State.LEAP)


func _begin_melee() -> void:
	attack_animation = &"attack3" if _rng.randf() < clampf(attack3_chance, 0.0, 1.0) else &"attack2"
	_swing_damage = attack3_damage if attack_animation == &"attack3" else attack2_damage
	_hit_targets.clear()
	_enter_state(State.MELEE)


func _enter_state(next: State) -> void:
	_set_damage_window(false)
	state = next
	_elapsed = 0.0
	match state:
		State.WALK: _set_animation(&"walk")
		State.RUN: _set_animation(&"run")
		State.WINDUP: _set_animation(&"attack1_1")
		State.LEAP:
			_set_animation(&"attack1_2")
			_set_damage_window(is_instance_valid(target))
		State.LAND: _set_animation(&"attack1_3")
		State.MELEE: _set_animation(attack_animation)
		State.RECOVERY: pass


func _set_damage_window(active: bool) -> void:
	var selected: Area2D = null
	if active:
		if state == State.LEAP: selected = leap_hitbox
		elif state == State.MELEE: selected = hitbox
	active = active and selected != null
	if _window_open == active and _active_hitbox == selected:
		return
	_window_open = active
	_active_hitbox = selected
	_leap_opening_check_pending = active and selected == leap_hitbox
	if hitbox_shape != null:
		hitbox_shape.set_deferred("disabled", not active or selected != hitbox)
	if leap_hitbox_shape != null:
		leap_hitbox_shape.set_deferred("disabled", not active or selected != leap_hitbox)


func _apply_swing_damage() -> void:
	if is_dead or not _window_open or _active_hitbox == null or not is_inside_tree():
		return
	for body in _active_hitbox.get_overlapping_bodies():
		_try_hit_body(body)


func _apply_leap_contact_damage() -> void:
	if is_dead or not _window_open or _active_hitbox != leap_hitbox or not is_inside_tree():
		return
	_leap_query.shape = leap_hitbox_shape.shape
	_leap_query.transform = leap_hitbox_shape.global_transform
	_leap_query.collision_mask = leap_hitbox.collision_mask
	for contact in get_world_2d().direct_space_state.intersect_shape(_leap_query):
		_try_hit_body(contact.get("collider") as Node2D)


func _try_hit_body(body: Node2D) -> void:
	if is_dead or not _window_open or not is_inside_tree():
		return
	if not is_instance_valid(body) or body.is_queued_for_deletion():
		return
	if not body.is_in_group("Player") or not body.has_method("take_damage"):
		return
	var id := body.get_instance_id()
	if not _hit_targets.has(id):
		# Count the contact even if Guard/Deflect/dash rejects its HP damage.
		_hit_targets[id] = true
		body.take_damage(_swing_damage, global_position)


func die() -> void:
	_set_damage_window(false)
	super.die()


func _update_facing() -> void:
	if visual_pivot != null:
		visual_pivot.scale.x = -1.0 if _direction > 0 else 1.0
	if weapon_pivot != null:
		# The source rig and authored attack box face left; mirror both together.
		weapon_pivot.scale.x = -1.0 if _direction > 0 else 1.0


func _set_animation(requested: StringName) -> void:
	if animation_player == null:
		return
	var clip := requested if animation_player.has_animation(requested) else &"walk"
	if animation_player.has_animation(clip):
		if rig != null:
			rig.position = _rig_origin + animation_offsets.get(clip, Vector2.ZERO)
		animation_player.play(clip)
		animation_player.advance(0.0)
