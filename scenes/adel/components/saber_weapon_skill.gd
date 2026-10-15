class_name SaberWeaponSkill
extends Node
## Q skill: charge, committed release, swept lunge, impact and recovery.
const STUN = preload("res://scenes/adel/components/enemy_skill_stun.gd")
const S = AdelStateMachine.State

@export_group("Charge")
@export_range(0.01, 2.0, 0.01) var tap_windup: float = 0.2
@export_range(0.1, 5.0, 0.05) var charge_level_1_time: float = 1.0
@export_range(0.2, 8.0, 0.05) var charge_level_2_time: float = 2.0
@export_range(0.01, 1.0, 0.01) var charged_release_windup: float = 0.1
@export_range(0.01, 1.0, 0.01) var full_charge_final_pose: float = 0.2
@export var allow_airborne: bool = false

@export_group("Lunge")
@export_range(0.0, 2000.0, 1.0, "or_greater") var lunge_distance: float = 180.0
@export_range(1.0, 5000.0, 10.0, "or_greater") var lunge_speed: float = 900.0
@export_range(0.0, 5.0, 0.05) var charged_distance_multiplier: float = 1.5
@export_range(0.0, 5.0, 0.05) var full_distance_multiplier: float = 2.0
@export_flags_2d_physics var enemy_detection_mask: int = 5

@export_group("Damage And Stun")
@export_range(0, 10000, 1, "or_greater") var damage: int = 20
@export_range(0.0, 5.0, 0.05) var charged_damage_multiplier: float = 1.2
@export_range(0.0, 5.0, 0.05) var full_damage_multiplier: float = 1.6
@export_range(0.0, 3.0, 0.01) var charged_stun_duration: float = 0.25
@export_range(0.0, 3.0, 0.01) var full_stun_duration: float = 0.4
@export_range(0.01, 1.0, 0.01) var impact_pose_duration: float = 0.05

@export_group("Impact Timing")
@export_range(0.0, 0.5, 0.005) var tap_hit_stop_duration: float = 0.065
@export_range(0.0, 0.5, 0.005) var charged_hit_stop_duration: float = 0.075
@export_range(0.0, 0.5, 0.005) var full_hit_stop_duration: float = 0.1
@export_range(0.01, 1.0, 0.01) var recovery_slow_motion_scale: float = 0.5
@export_range(0.01, 1.0, 0.01) var charged_recovery_duration: float = 0.3
@export_range(0.01, 1.0, 0.01) var tap_recovery_duration: float = 0.15

var tier := 0
var charge_time := 0.0
var distance_travelled := 0.0
var contact_target: Node2D
var _body: CharacterBody2D
var _active := false
var _elapsed := 0.0
var _remaining_distance := 0.0
var _direction := 1
var _released := false
var _confirmed := false
var _manual_animation := false
var _old_animation_mode := 1
var _query := PhysicsShapeQueryParameters2D.new()

func setup(body: CharacterBody2D) -> void:
	_body = body
	_body.saber_hitbox.target_hit.connect(_on_target_hit)
	CombatTime.effect_finished.connect(_on_effect_finished)

func is_active() -> bool: return _active
func is_dashing() -> bool: return _active and _body.state_machine.current == S.SKILL_DASH

func begin() -> bool:
	if _active or not _body.state_machine.can_begin_action() or (not allow_airborne and not _body.is_on_floor()): return false
	for clip in [&"saber_skill_1", &"saber_skill_2", &"saber_skill_3", &"saber_skill_4", &"saber_skill_5", &"saber_skill_6"]:
		if not _body.spine_anim.has_animation(clip): return false
	_body.clear_combat_input()
	_active = true
	_released = false
	_confirmed = false
	charge_time = 0.0
	distance_travelled = 0.0
	contact_target = null
	tier = 0
	_update_charge_facing()
	_body.combat.combo_step = 0
	_body.velocity.x = 0.0
	_enter(S.SKILL_CHARGE, &"saber_skill_1")
	return true

func release() -> void:
	if not _active or _released or _body.state_machine.current != S.SKILL_CHARGE: return
	# Capture same-frame directional input before release commits the lunge.
	_update_charge_facing()
	_released = true
	if charge_time + 0.000001 >= _full_charge_time():
		tier = 2
		_start_lunge()
	elif charge_time + 0.000001 >= charge_level_1_time:
		tier = 1
		_enter(S.SKILL_RELEASE, &"saber_skill_2")
	elif charge_time + 0.000001 >= tap_windup:
		tier = 0
		_start_lunge()

func physics_update(delta: float) -> void:
	if not _active: return
	var phase: int = _body.state_machine.current
	_elapsed += delta
	match phase:
		S.SKILL_CHARGE:
			if not _released: _update_charge_facing()
			charge_time += delta
			if _released:
				if charge_time + 0.000001 >= tap_windup: _start_lunge()
			elif charge_time + 0.000001 >= _full_charge_time():
				tier = 2
				_start_lunge()
			else:
				var clip: StringName = &"saber_skill_1"
				if charge_time >= _full_charge_time() - full_charge_final_pose: clip = &"saber_skill_3"
				elif charge_time >= charge_level_1_time: clip = &"saber_skill_2"
				if _body.spine_anim.assigned_animation != clip: _body.presentation.hold(clip)
				# Poll release if another Control consumed the physical release event.
				if not Input.is_action_pressed("weapon_skill"): release()
		S.SKILL_RELEASE:
			if _elapsed + 0.000001 >= charged_release_windup: _start_lunge()
		S.SKILL_DASH:
			_lunge(delta)
			return
		S.SKILL_IMPACT:
			_body.saber_hitbox.sample_skill_damage()
			if _elapsed >= impact_pose_duration: _start_recovery()
		S.SKILL_RECOVERY:
			_body.spine_anim.advance(delta)
			if (tier == 0 or not _confirmed) and _elapsed + 0.000001 >= _recovery_duration(): _finish()
	if _active and _body.state_machine.current != S.SKILL_DASH:
		_body.velocity.x = 0.0
		_body.locomotion.apply_vertical_physics(delta)
		_body.move_and_slide()

func _update_charge_facing() -> void:
	_body._update_facing(Input.get_axis("move_left", "move_right"))
	_direction = _body.facing_direction

func _full_charge_time() -> float:
	return maxf(charge_level_2_time, charge_level_1_time + full_charge_final_pose)

func _enter(phase: int, clip: StringName) -> void:
	_elapsed = 0.0
	_body.state_machine.transition(phase)
	_body.presentation.hold(clip)

func _start_lunge() -> void:
	_remaining_distance = lunge_distance * ([1.0, charged_distance_multiplier, full_distance_multiplier][tier])
	_body.velocity = Vector2.ZERO
	_enter(S.SKILL_DASH, &"saber_skill_4")

func _lunge(delta: float) -> void:
	var step := minf(_remaining_distance, lunge_speed * delta)
	var motion := Vector2(_direction * step, 0.0)
	var contact := _first_enemy_contact(motion)
	var fraction: float = contact.get("fraction", 1.0)
	var intended := motion * fraction
	var origin: Vector2 = _body.global_position
	_body.velocity = Vector2(_direction * lunge_speed, 0.0)
	var wall := _body.move_and_collide(intended)
	var travelled := absf(_body.global_position.x - origin.x)
	distance_travelled += travelled
	_remaining_distance = maxf(_remaining_distance - travelled, 0.0)
	if contact.has("body") and travelled + 0.1 >= absf(intended.x):
		var target = contact.body
		if _valid_enemy(target):
			contact_target = target
			_impact()
			return
	if wall != null or _remaining_distance <= 0.01 or step <= 0.0:
		_start_recovery()

func _valid_enemy(node) -> bool:
	if not is_instance_valid(node) or node == _body or node.is_queued_for_deletion() or node.is_in_group("Player") or not node.has_method("take_damage"): return false
	if "is_dead" in node and node.is_dead: return false
	return not ("current_health" in node and node.current_health <= 0)

func _first_enemy_contact(motion: Vector2) -> Dictionary:
	var shape: CollisionShape2D = _body.get_node("CollisionShape2D")
	_query.shape = shape.shape
	_query.transform = shape.global_transform
	_query.collision_mask = enemy_detection_mask
	_query.collide_with_bodies = true
	_query.collide_with_areas = false
	_query.exclude = [_body.get_rid()]
	var space := _body.get_world_2d().direct_space_state
	# cast_motion ignores initial overlaps; inspect them explicitly first.
	_query.motion = Vector2.ZERO
	for item in space.intersect_shape(_query, 64):
		if _valid_enemy(item.collider): return {"body": item.collider, "fraction": 0.0}
	# World/legacy bodies share a layer; filter non-damage bodies from this query.
	for attempt in 32:
		_query.transform = shape.global_transform
		_query.motion = motion
		var cast := space.cast_motion(_query)
		if cast.size() < 2 or cast[0] >= 1.0: return {}
		_query.motion = Vector2.ZERO
		_query.transform.origin += motion * cast[1] + motion.normalized() * 0.05
		var overlaps := space.intersect_shape(_query, 64)
		var excluded := false
		for item in overlaps:
			if _valid_enemy(item.collider): return {"body": item.collider, "fraction": cast[0]}
			var exclusions: Array[RID] = _query.exclude
			if not item.rid in exclusions:
				exclusions.append(item.rid)
				_query.exclude = exclusions
				excluded = true
		if not excluded: return {}
	return {}

func _impact() -> void:
	_body.velocity = Vector2.ZERO
	_enter(S.SKILL_IMPACT, &"saber_skill_5")
	var multiplier: float = [1.0, charged_damage_multiplier, full_damage_multiplier][tier]
	_body.saber_hitbox.begin_skill_window(maxi(0, int(round(damage * multiplier))))
	_body.saber_hitbox.sample_skill_damage()

func _on_target_hit(target: Node2D) -> void:
	if not _active or _body.state_machine.current != S.SKILL_IMPACT: return
	if not _confirmed:
		_confirmed = true
		_body._request_hit_stop([tap_hit_stop_duration, charged_hit_stop_duration, full_hit_stop_duration][tier])
	if tier == 0 or not _valid_enemy(target): return
	var duration: float = charged_stun_duration if tier == 1 else full_stun_duration
	if duration <= 0.0: return
	var stun = target.get_node_or_null("WeaponSkillStun")
	if stun == null:
		stun = STUN.new()
		stun.name = "WeaponSkillStun"
		stun.remaining = duration
		target.add_child(stun)
	else:
		stun.extend(duration)

func _recovery_duration() -> float:
	return tap_recovery_duration if tier == 0 else charged_recovery_duration

func _start_recovery() -> void:
	_body.velocity = Vector2.ZERO
	_body.saber_hitbox.stop_attack_window()
	_elapsed = 0.0
	_body.state_machine.transition(S.SKILL_RECOVERY)
	_old_animation_mode = _body.spine_anim.callback_mode_process
	_body.spine_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_manual_animation = true
	var clip: StringName = &"saber_skill_6"
	var speed: float = _body.spine_anim.get_animation(clip).length / maxf(_recovery_duration(), 0.01)
	_body.spine_anim.play(clip, -1.0, speed)
	_body.spine_anim.advance(0.0)
	if tier > 0 and _confirmed:
		CombatTime.set_actor_exempt(_body, true)
		CombatTime.request(self, &"skill_recovery", recovery_slow_motion_scale, charged_recovery_duration)

func _on_effect_finished(owner: Object, lane: StringName) -> void:
	if owner == self and lane == &"skill_recovery" and _active and _body.state_machine.current == S.SKILL_RECOVERY: _finish()

func _finish() -> void:
	if not _active: return
	_body._play_ready(true)

func abort() -> void:
	if _active and is_instance_valid(_body) and _body.is_inside_tree(): _body._play_ready(true)

func cancel() -> void:
	if not _active: return
	_active = false
	if is_instance_valid(_body):
		_body.velocity = Vector2.ZERO
		_body.saber_hitbox.stop_attack_window()
		if _manual_animation: _body.spine_anim.callback_mode_process = _old_animation_mode
		CombatTime.set_actor_exempt(_body, false)
		CombatTime.remove(_body, &"hit_stop")
	_manual_animation = false
	CombatTime.remove(self)

func _exit_tree() -> void:
	cancel()
