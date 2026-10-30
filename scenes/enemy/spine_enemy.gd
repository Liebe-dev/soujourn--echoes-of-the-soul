extends EnemyBase
## Uses EnemyBase's health/death contract; this enemy owns its combat decisions.

const Sight = preload("res://scenes/enemy/enemy_sight.gd")
const UtilityAI = preload("res://scenes/enemy/enemy_utility_ai.gd")
const UtilityProfile = preload("res://scenes/enemy/enemy_utility_profile.gd")
enum DecisionMode { FSM, UTILITY }
# WALK = Patrol, RUN = Chase; attack phases remain explicit states.
enum State { WALK, RUN, WINDUP, LEAP, LAND, MELEE, RECOVERY, DETECT, DEAD, IDLE, FLEE, STUNNED }
signal state_changed(previous: State, current: State)
signal utility_decided(action: StringName, scores: Dictionary)

@export_group("AI Decisions")
@export var decision_mode: DecisionMode = DecisionMode.FSM
@export var utility_profile: UtilityProfile = UtilityProfile.new()
@export_range(0.05, 2.0, 0.05) var utility_think_interval := 0.2
@export var utility_weighted_selection := false
@export_range(0.0, 1.0) var utility_top_ratio := 0.85
@export_range(0.0, 0.5) var utility_switch_margin := 0.08
@export_range(1.0, 2000.0) var utility_ally_radius := 500.0

@export_group("Detection")
@export_range(1.0, 2000.0) var detection_distance: float = 500.0
@export_range(1.0, 2500.0) var disengage_distance: float = 650.0
@export_range(0.0, 10.0) var chase_memory: float = 1.5
@export var reset_opener_on_disengage: bool = true
@export_range(0.0, 1000.0) var run_speed: float = 240.0
@export_flags_2d_physics var sight_obstacle_mask: int = 1

@export_group("Survival")
## Set to zero to disable fleeing for this enemy type.
@export_range(0.0, 1.0) var flee_health_ratio: float = 0.2
@export_range(0.0, 1.0) var flee_recover_ratio: float = 0.35
@export_range(1.0, 2000.0) var flee_safe_distance: float = 600.0
@export_range(0.1, 10.0, 0.1) var flee_max_duration := 3.0
@export_range(0.0, 1.0) var counterattack_threat_threshold := 0.5
@export_range(0.1, 10.0, 0.1) var counterattack_pressure_duration := 3.0

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

@export_group("Death Terrain")
## World geometry only. Combat layers/hurtboxes remain disabled after death.
@export_flags_2d_physics var corpse_terrain_mask: int = 1

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
var target_visible := false
var last_seen_position := Vector2.ZERO
var _stun_remaining := 0.0
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
var _corpse_locomotion: LocomotionComponent
## Readable in the remote inspector and by the comparison scene overlay.
var utility_action: StringName = &""
var utility_scores: Dictionary = {}
var utility_considerations: Dictionary = {}
var _utility := UtilityAI.new()
var _utility_think_left := 0.0
var _utility_detected_target_id := 0
var _known_player_health := 1.0
var _previous_decision_mode := DecisionMode.FSM
var flee_time := 0.0
var flee_pressure_time := 0.0
var flee_exhausted := false
var counterattack_active := false
var _flee_target_id := 0


func _ready() -> void:
	if rig != null:
		_rig_origin = rig.position
	super._ready()
	_rng.randomize()
	if animation_player == null or visual_pivot == null or weapon_pivot == null or hitbox_shape == null or hitbox == null or leap_hitbox == null or leap_hitbox_shape == null or leap_hitbox_shape.shape == null:
		push_warning("SpineEnemy needs its rig, WeaponPivot/Hitbox and LeapHitbox with collision shapes.")
		set_physics_process(false)
		return
	for clip in [&"walk", &"detect player", &"run", &"attack1_1", &"attack1_2", &"attack1_3", &"attack2", &"attack3"]:
		if not animation_player.has_animation(clip):
			push_warning("SpineEnemy is missing animation: " + clip)
			set_physics_process(false)
			return
	animation_player.animation_finished.connect(_on_animation_finished)
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
	add_to_group(&"enemy_ai_agents")
	_enter_state(State.WALK)


func _physics_process(delta: float) -> void:
	if delta <= 0.0: return
	if is_dead:
		_physics_corpse(delta)
		return
	if EnemyDebugSettings.is_ai_disabled():
		_debug_idle(delta)
		return
	if _debug_ai_was_disabled:
		_debug_ai_was_disabled = false
		_enter_state(State.WALK)
	_elapsed += delta
	_utility_think_left = maxf(_utility_think_left - delta, 0.0)
	_refresh_target(delta)
	_tick_flee_response(delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity.x = 0.0
	var next := _evaluate_transition()
	if next != state:
		if next == State.LEAP: _launch()
		elif next == State.MELEE: _begin_melee()
		else: _enter_state(next)
	_update_state(delta)
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


func _debug_idle(delta: float) -> void:
	if not _debug_ai_was_disabled:
		_reset_flee_response()
		target = null
		_lost_time = 0.0
		opener_available = true
		attack_animation = &""
		_swing_damage = 0
		_hit_targets.clear()
		_enter_state(State.WALK)
		if animation_player != null: animation_player.pause()
	_debug_ai_was_disabled = true
	_set_damage_window(false)
	velocity.x = 0.0
	if not is_on_floor(): velocity += get_gravity() * delta
	move_and_slide()


func _refresh_target(delta: float) -> void:
	var was_visible := target_visible
	var previous_id := target.get_instance_id() if is_instance_valid(target) else 0
	target_visible = false
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		target_visible = global_position.distance_to(target.global_position) <= maxf(disengage_distance, detection_distance) and Sight.can_see(self, target, sight_obstacle_mask)
		if target_visible:
			last_seen_position = target.global_position
			_lost_time = 0.0
		else:
			_lost_time += delta
			if _lost_time >= chase_memory: target = null
	else:
		target = null
	if target != null:
		if target_visible != was_visible: _utility_think_left = 0.0
		return
	_utility_detected_target_id = 0
	_known_player_health = 1.0
	if reset_opener_on_disengage: opener_available = true
	var nearest := detection_distance
	for candidate in get_tree().get_nodes_in_group("Player"):
		if not candidate is Node2D or candidate.is_queued_for_deletion(): continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= nearest and Sight.can_see(self, candidate, sight_obstacle_mask):
			nearest = distance
			target = candidate
			target_visible = true
			last_seen_position = candidate.global_position
			_lost_time = 0.0
	var current_id := target.get_instance_id() if is_instance_valid(target) else 0
	if current_id != previous_id or target_visible != was_visible: _utility_think_left = 0.0


## Transition rules are separate from per-state motion and effects.
func _evaluate_transition() -> State:
	if decision_mode != _previous_decision_mode:
		_previous_decision_mode = decision_mode
		_utility_think_left = 0.0
		utility_action = &""
	if _stun_remaining > 0.0: return State.STUNNED
	if decision_mode == DecisionMode.UTILITY: return _evaluate_utility_transition()
	if state == State.STUNNED: return State.RUN if is_instance_valid(target) else State.WALK
	if state == State.LEAP: return state # Finish flight before choosing a ground action.
	var has_target := is_instance_valid(target)
	var health_ratio := float(current_health) / maxi(max_health, 1)
	if counterattack_active:
		if state not in [State.DETECT, State.WINDUP, State.LAND, State.MELEE, State.RECOVERY]:
			return _counterattack_transition()
	elif flee_exhausted and state in [State.FLEE, State.RUN, State.WALK, State.IDLE]:
		return State.IDLE
	if state == State.FLEE and not counterattack_active:
		if not has_target or global_position.distance_to(last_seen_position) >= flee_safe_distance: return State.IDLE
		if health_ratio >= maxf(flee_recover_ratio, flee_health_ratio): return State.RUN
		return state
	if not counterattack_active and has_target and flee_health_ratio > 0.0 and health_ratio <= flee_health_ratio and global_position.distance_to(last_seen_position) < flee_safe_distance:
		return State.FLEE
	# Wait at safety instead of immediately chasing back into flee range.
	if not counterattack_active and has_target and flee_health_ratio > 0.0 and health_ratio <= flee_health_ratio and global_position.distance_to(last_seen_position) >= flee_safe_distance:
		return State.IDLE
	match state:
		State.WALK, State.IDLE:
			if has_target: return State.DETECT
			if _elapsed >= maxf(walk_duration if state == State.WALK else idle_duration, 0.01):
				return State.IDLE if state == State.WALK else State.WALK
		State.DETECT, State.RUN, State.WINDUP:
			if not has_target: return State.WALK
			if state == State.RUN and target_visible and is_on_floor():
				var distance := absf(last_seen_position.x - global_position.x)
				var reachable := absf(last_seen_position.y - global_position.y) <= attack_height_tolerance
				if reachable and opener_available and distance <= leap_range: return State.WINDUP
				if reachable and not opener_available and distance <= melee_range: return State.MELEE
			if state == State.WINDUP:
				if not target_visible: return State.RUN
				if _elapsed >= maxf(windup_time, 0.01) and is_on_floor(): return State.LEAP
		State.LAND:
			if _elapsed >= maxf(landing_time, 0.01): return State.RECOVERY
		State.MELEE:
			if not has_target or not target_visible or _elapsed >= animation_player.get_animation(attack_animation).length: return State.RECOVERY
		State.RECOVERY:
			if _elapsed >= maxf(recovery_time, 0.01): return State.RUN if has_target else State.WALK
	return state


## Retreat is a limited budget per encounter; brief utility switches cannot refill it.
func _reset_flee_response() -> void:
	flee_time = 0.0
	flee_pressure_time = 0.0
	flee_exhausted = false
	counterattack_active = false
	_flee_target_id = 0


func get_flee_threat() -> float:
	if not is_instance_valid(target) or not target_visible: return 0.0
	var normalized := absf(last_seen_position.x - global_position.x) / maxf(flee_safe_distance, 1.0)
	if decision_mode == DecisionMode.UTILITY and utility_profile != null:
		return UtilityProfile.response(utility_profile.threat_distance, normalized)
	return clampf(1.0 - normalized, 0.0, 1.0)


func _tick_flee_response(delta: float) -> void:
	if delta <= 0.0: return
	var health := float(current_health) / maxi(max_health, 1)
	var recovered := health >= maxf(flee_recover_ratio, flee_health_ratio)
	if decision_mode == DecisionMode.UTILITY:
		recovered = UtilityProfile.response(utility_profile.flee_need, health) <= 0.0 if utility_profile != null else health >= 0.6
	if is_dead or not is_instance_valid(target) or target.is_queued_for_deletion() or flee_health_ratio <= 0.0 or recovered:
		_reset_flee_response()
		return
	var target_id := target.get_instance_id()
	if target_id != _flee_target_id:
		_reset_flee_response()
		_flee_target_id = target_id
	if counterattack_active: return
	if state == State.FLEE:
		flee_time += delta
		if flee_time >= maxf(flee_max_duration, 0.1) and not flee_exhausted:
			flee_exhausted = true
			_utility_think_left = 0.0
	# Breaks in sight/pressure reset the consecutive timer, rather than adding up bursts.
	if (state == State.FLEE or flee_time > 0.0) and state in [State.FLEE, State.IDLE, State.RUN, State.WALK] and get_flee_threat() > counterattack_threat_threshold:
		flee_pressure_time += delta
	else:
		flee_pressure_time = 0.0
	if flee_pressure_time >= maxf(counterattack_pressure_duration, 0.1):
		counterattack_active = true
		flee_exhausted = true
		opener_available = true # One fresh leap, followed by normal melee attacks.
		_utility_think_left = 0.0


func _counterattack_transition() -> State:
	if not is_instance_valid(target): return State.WALK
	if target_visible and is_on_floor() and absf(last_seen_position.y - global_position.y) <= attack_height_tolerance:
		var distance := absf(last_seen_position.x - global_position.x)
		if opener_available and distance <= leap_range: return State.WINDUP
		if not opener_available and distance <= melee_range: return State.MELEE
	return State.RUN


func _evaluate_utility_transition() -> State:
	var has_target := is_instance_valid(target)
	# Committed actions retain their animation, damage windows and recovery.
	match state:
		State.DEAD, State.LEAP: return state
		State.DETECT: return state if has_target else State.WALK
		State.WINDUP:
			if not has_target or not target_visible: return State.RUN if has_target else State.WALK
			return State.LEAP if _elapsed >= maxf(windup_time, 0.01) and is_on_floor() else state
		State.LAND: return State.RECOVERY if _elapsed >= maxf(landing_time, 0.01) else state
		State.MELEE:
			if not has_target or not target_visible or _elapsed >= animation_player.get_animation(attack_animation).length: return State.RECOVERY
			return state
		State.RECOVERY:
			if _elapsed < maxf(recovery_time, 0.01): return state
		State.STUNNED: _utility_think_left = 0.0
	if has_target and _utility_detected_target_id != target.get_instance_id(): return State.DETECT
	if _utility_think_left <= 0.0 or utility_action == &"":
		if utility_profile == null: utility_profile = UtilityProfile.new()
		utility_scores = _utility.evaluate(_utility_context(), utility_profile)
		utility_considerations = _utility.considerations.duplicate()
		utility_action = _utility.choose(utility_action, _rng, utility_weighted_selection, utility_top_ratio, utility_switch_margin)
		_utility_think_left = maxf(utility_think_interval, 0.05)
		utility_decided.emit(utility_action, utility_scores.duplicate())
	match utility_action:
		&"patrol": return State.WALK
		&"chase": return State.RUN
		&"leap": return State.WINDUP
		&"melee": return State.MELEE
		&"flee": return State.FLEE
	return State.IDLE


func _utility_context() -> Dictionary:
	var has_target := is_instance_valid(target)
	if has_target and target_visible:
		if target.has_method("get_ai_health_ratio"):
			_known_player_health = clampf(float(target.get_ai_health_ratio()), 0.0, 1.0)
		elif "current_health" in target and "max_health" in target:
			_known_player_health = clampf(float(target.current_health) / maxf(float(target.max_health), 1.0), 0.0, 1.0)
	var allies := 0
	for candidate in get_tree().get_nodes_in_group(&"enemy_ai_agents"):
		if candidate == self or not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or candidate.is_dead: continue
		if global_position.distance_to(candidate.global_position) <= utility_ally_radius and Sight.can_see(self, candidate, sight_obstacle_mask): allies += 1
	var memory := 1.0 if target_visible else clampf(1.0 - _lost_time / maxf(chase_memory, 0.001), 0.0, 1.0)
	return {
		&"has_target": has_target, &"visible": target_visible, &"grounded": is_on_floor(),
		&"reachable": absf(last_seen_position.y - global_position.y) <= attack_height_tolerance,
		&"distance": absf(last_seen_position.x - global_position.x),
		&"health": clampf(float(current_health) / maxi(max_health, 1), 0.0, 1.0),
		&"player_health": _known_player_health, &"allies": allies, &"memory": memory,
		&"opener": opener_available, &"leap_range": leap_range, &"melee_range": melee_range,
		&"safe_distance": flee_safe_distance, &"flee_enabled": flee_health_ratio > 0.0,
		&"flee_exhausted": flee_exhausted, &"counterattack": counterattack_active,
		&"resting": state == State.IDLE,
		&"phase_progress": _elapsed / maxf(idle_duration if state == State.IDLE else walk_duration, 0.01),
	}


func take_damage(dmg: int, hit_from_global: Vector2 = Vector2.INF) -> bool:
	var accepted := super.take_damage(dmg, hit_from_global)
	if accepted: _utility_think_left = 0.0
	return accepted


func _update_state(delta: float) -> void:
	match state:
		State.WALK: _walk_patrol(delta)
		State.RUN:
			var dx := last_seen_position.x - global_position.x
			if not is_zero_approx(dx): _direction = 1 if dx > 0.0 else -1
			_update_facing()
			velocity.x = minf(run_speed, absf(dx) / delta) * signf(dx)
		State.LEAP:
			velocity.x = _leap_velocity_x
			_set_damage_window(is_instance_valid(target) and target_visible)
		State.MELEE:
			var window := attack3_window if attack_animation == &"attack3" else attack2_window
			_set_damage_window(target_visible and _elapsed >= maxf(window.x, 0.0) and _elapsed < window.y)
		State.FLEE:
			var dx := global_position.x - last_seen_position.x
			if not is_zero_approx(dx): _direction = 1 if dx > 0.0 else -1
			velocity.x = run_speed * _direction
			_update_facing()
		State.STUNNED: _stun_remaining = maxf(_stun_remaining - delta, 0.0)


func apply_ai_stun(duration: float) -> void:
	if is_dead or duration <= 0.0: return
	_stun_remaining = maxf(_stun_remaining, duration)
	if state != State.STUNNED: _enter_state(State.STUNNED)


func is_ai_stunned() -> bool:
	return not is_dead and state == State.STUNNED


func get_ai_stun_remaining() -> float:
	return _stun_remaining


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
		var dx := last_seen_position.x - global_position.x
		if not is_zero_approx(dx):
			_direction = 1 if dx > 0.0 else -1
			_update_facing()


func _launch() -> void:
	if is_dead: return
	_face_target()
	opener_available = false
	var flight_time := 2.0 * jump_speed / maxf(get_gravity().y, 1.0)
	_leap_velocity_x = clampf((last_seen_position.x - global_position.x) / flight_time, -max_leap_speed, max_leap_speed)
	velocity = Vector2(_leap_velocity_x, -jump_speed)
	_has_left_floor = false
	_hit_targets.clear()
	_swing_damage = leap_damage
	_enter_state(State.LEAP)


func _begin_melee() -> void:
	if is_dead: return
	_face_target()
	attack_animation = &"attack3" if _rng.randf() < clampf(attack3_chance, 0.0, 1.0) else &"attack2"
	_swing_damage = attack3_damage if attack_animation == &"attack3" else attack2_damage
	_hit_targets.clear()
	_enter_state(State.MELEE)


func _enter_state(next: State) -> void:
	if is_dead: return
	var previous := state
	_exit_state(previous)
	state = next
	_elapsed = 0.0
	_utility_think_left = 0.0
	match state:
		State.WALK: _set_animation(&"walk")
		State.DETECT:
			_face_target()
			_set_animation(&"detect player")
		State.RUN: _set_animation(&"run")
		State.WINDUP:
			_face_target()
			_set_animation(&"attack1_1")
		State.LEAP:
			_set_animation(&"attack1_2")
			_set_damage_window(is_instance_valid(target))
		State.LAND: _set_animation(&"attack1_3")
		State.MELEE:
			_set_animation(attack_animation)
		State.IDLE:
			_set_animation(&"walk")
			animation_player.pause()
		State.FLEE: _set_animation(&"run")
		State.STUNNED: animation_player.pause()
		State.RECOVERY: pass
	state_changed.emit(previous, state)


func _exit_state(previous: State) -> void:
	_set_damage_window(false)
	if previous == State.STUNNED:
		_stun_remaining = 0.0
		_leap_velocity_x = 0.0
		velocity.x = 0.0


func _on_animation_finished(clip: StringName) -> void:
	if is_dead:
		if clip == &"death": queue_free()
		return
	if EnemyDebugSettings.is_ai_disabled(): return
	# Only the live detection transition owns this completion signal.
	if clip != &"detect player" or state != State.DETECT:
		return
	if is_dead or not is_inside_tree() or is_queued_for_deletion():
		return
	var has_target := is_instance_valid(target) and not target.is_queued_for_deletion()
	if has_target: _utility_detected_target_id = target.get_instance_id()
	_enter_state(State.RUN if has_target else State.WALK)


func _set_damage_window(active: bool) -> void:
	active = active and not is_dead and not EnemyDebugSettings.is_ai_disabled()
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
	if is_dead or EnemyDebugSettings.is_ai_disabled() or not _window_open or not is_inside_tree():
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


func _finish_death() -> void:
	if not is_inside_tree() or is_queued_for_deletion(): return
	_reset_flee_response()
	_exit_state(state)
	var previous := state
	state = State.DEAD
	utility_action = &""
	utility_scores.clear()
	utility_considerations.clear()
	_stun_remaining = 0.0
	state_changed.emit(previous, state)
	target = null
	attack_animation = &""
	_swing_damage = 0
	_hit_targets.clear()
	_set_damage_window(false)
	set_process(false)
	remove_from_group(&"camera_lock_targets")
	remove_from_group(&"Enemy")
	remove_from_group(&"enemy_ai_agents")
	# A pre-existing Q stun must never move or re-enable this corpse.
	var stun := get_node_or_null("WeaponSkillStun")
	if stun != null:
		stun.set_physics_process(false)
		stun.queue_free()
	var colliders: Array[Node] = [self]
	colliders.append_array(find_children("*", "CollisionObject2D", true, false))
	for collider in colliders:
		collider.set_deferred("collision_layer", 0)
		collider.set_deferred("collision_mask", 0)
		if collider is Area2D:
			collider.set_deferred("monitoring", false)
			collider.set_deferred("monitorable", false)
	for shape in find_children("*", "CollisionShape2D", true, false): shape.set_deferred("disabled", true)
	for shape in find_children("*", "CollisionPolygon2D", true, false): shape.set_deferred("disabled", true)
	if animation_player == null or not animation_player.has_animation(&"death"):
		push_warning("SpineEnemy is missing death animation; removing immediately.")
		queue_free()
		return
	# Keep the authored 10-second clip and its fading; no extra fade or wall-time timer.
	animation_player.speed_scale = 1.0
	_set_animation(&"death")
	# Lethal hits can occur while physics queries are flushing.
	_enable_corpse_fall.call_deferred()


func _enable_corpse_fall() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not is_dead: return
	var source := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if source == null or source.shape == null: return
	var terrain_shape := CollisionShape2D.new()
	terrain_shape.name = "CorpseTerrainCollider"
	terrain_shape.shape = source.shape.duplicate() as Shape2D
	terrain_shape.transform = source.transform
	add_child(terrain_shape)
	collision_layer = 0
	collision_mask = corpse_terrain_mask
	_ignore_corpse_characters(get_tree().root)
	_corpse_locomotion = LocomotionComponent.new(self)
	set_physics_process(true)


func _ignore_corpse_characters(node: Node) -> void:
	if node is CharacterBody2D and node != self:
		add_collision_exception_with(node)
	for child in node.get_children(): _ignore_corpse_characters(child)


func _physics_corpse(delta: float) -> void:
	if _corpse_locomotion == null: return
	velocity.x = 0.0
	# Reuse Player gravity multipliers and terminal speed; no duplicate tuning.
	_corpse_locomotion.apply_vertical_physics(delta)
	move_and_slide()


func _update_facing() -> void:
	if visual_pivot != null:
		visual_pivot.scale.x = -1.0 if _direction > 0 else 1.0
	if weapon_pivot != null:
		# The source rig and authored attack box face left; mirror both together.
		weapon_pivot.scale.x = -1.0 if _direction > 0 else 1.0


func _set_animation(requested: StringName) -> void:
	if is_dead and requested != &"death": return
	if animation_player == null:
		return
	var clip := requested if animation_player.has_animation(requested) else &"walk"
	if animation_player.has_animation(clip):
		if rig != null:
			rig.position = _rig_origin + animation_offsets.get(clip, Vector2.ZERO)
		animation_player.play(clip)
		animation_player.advance(0.0)
