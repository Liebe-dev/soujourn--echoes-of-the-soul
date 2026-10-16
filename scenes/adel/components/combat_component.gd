class_name CombatComponent
extends RefCounted
## A15.2 — Combat (combo + jump attack) extracted from scenes/adel/playable_adel.gd.
##
## Owns the combo/jump-attack STATE and the pure flow/decision logic (combo
## progression, attack queuing, jump-attack hang/fall/land). It holds a reference
## to the owning CharacterBody2D (single source of truth for `velocity`) and to the
## LocomotionComponent (for the jump-attack fall speed cap).
##
## Does NOT own: animation, FSM flags (can_move / is_doing_action / is_locked),
## damage/stagger/invulnerability, dash, or rest. Those effects are applied by the
## coordinator in reaction to the enum outcomes returned by the methods below.

enum AttackAction {
	NONE,
	START_COMBO,
	QUEUE_COMBO,
	START_JUMP_ATTACK,
	FINISH_COMBO,
}

# --- Combat tuning ---
const JUMP_ATTACK_HANG_TIME := 0.15
const JUMP_ATTACK_FALL_SPEED := 1500.0
const JUMP_ATTACK_LAND_UNLOCK := 0.3

# --- Combat state owned by CombatComponent ---

var combo_step: int = 0
var attack_queued: bool = false
var attack_buffer_duration := 0.18
var _attack_buffer_left := 0.0
var has_air_comboed: bool = false
# Normal-fall reference survives combo steps; displayed fall speed is scaled.
var _air_combo_fall_speed := -1.0
var _air_attack_pause_at := -1.0
var _air_attack_pause_duration := 0.0
var _air_attack_pause_left := 0.0
var is_jump_attacking: bool = false
var is_jump_attack_hanging: bool = false
var jump_attack_hang_timer: float = 0.0
var _jump_attack_waits_for_animation := false
var is_jump_attack_landing: bool = false
var jump_attack_land_timer: float = 0.0

var _body: CharacterBody2D
var _locomotion: LocomotionComponent
var _attack_hitbox: Area2D
var equipped_weapon: WeaponData


func _init(
	body: CharacterBody2D,
	locomotion: LocomotionComponent,
	weapon: WeaponData,
	attack_hitbox: Area2D
) -> void:
	_body = body
	_locomotion = locomotion
	equipped_weapon = weapon
	_attack_hitbox = attack_hitbox
	_attack_hitbox.monitoring = false
# --- Weapon ---
func change_weapon(new_weapon: WeaponData) -> void:
	equipped_weapon = new_weapon
	combo_step = 0

# --- Animation name helper ---
func get_attack_anim_name() -> String:
	return equipped_weapon.animation_prefix + "_attack_" + str(combo_step)

func get_combo_damage() -> int:
	var multiplier := equipped_weapon.combo_finisher_multiplier if combo_step == 4 else 1.0
	return maxi(0, int(round(float(equipped_weapon.damage) * maxf(multiplier, 0.0))))

# --- Attack input (was inline in _unhandled_input) ---
func handle_attack_input(is_doing_action: bool) -> AttackAction:
	if not _body.is_on_floor() and (has_air_comboed or combo_step >= 4 or Input.is_action_pressed("move_down")):
		if not is_jump_attacking:
			return AttackAction.START_JUMP_ATTACK
		return AttackAction.NONE

	if not is_doing_action:
		if combo_step == 0 or combo_step >= 4:
			combo_step = 1
		else:
			combo_step += 1
		attack_queued = false
		return AttackAction.START_COMBO
	elif combo_step > 0 and combo_step < 4:
		attack_queued = attack_buffer_duration > 0.0
		_attack_buffer_left = attack_buffer_duration
		return AttackAction.QUEUE_COMBO
	return AttackAction.NONE

func tick_input_buffer(delta: float) -> void:
	if not attack_queued: return
	_attack_buffer_left = maxf(_attack_buffer_left - delta, 0.0)
	if _attack_buffer_left <= 0.0: clear_attack_buffer()

func clear_attack_buffer() -> void:
	attack_queued = false
	_attack_buffer_left = 0.0

# --- Combo progression on attack animation finish (was inline in _on_spine_anim_finished) ---
func on_attack_anim_finished() -> AttackAction:
	if attack_queued and combo_step < 4:
		combo_step += 1
		attack_queued = false
		return AttackAction.START_COMBO

	attack_queued = false
	return AttackAction.FINISH_COMBO
# --- Jump attack state transitions ---
func start_jump_attack(hang_duration: float = JUMP_ATTACK_HANG_TIME, wait_for_animation: bool = false) -> void:
	_jump_attack_waits_for_animation = wait_for_animation
	cancel_air_attack_pause()
	_air_combo_fall_speed = -1.0
	attack_queued = false
	is_jump_attacking = true
	is_jump_attack_hanging = true
	jump_attack_hang_timer = maxf(hang_duration, 0.0)
	combo_step = 0

func finish_jump_attack_hang() -> void:
	is_jump_attack_hanging = false
	jump_attack_hang_timer = 0.0
	_jump_attack_waits_for_animation = false

func begin_jump_attack_land() -> void:
	_jump_attack_waits_for_animation = false
	is_jump_attacking = false
	is_jump_attack_hanging = false
	jump_attack_hang_timer = 0.0
	is_jump_attack_landing = true
	jump_attack_land_timer = 0.0

func cancel_jump_attack_land() -> void:
	is_jump_attack_landing = false

func is_jump_attack_land_unlocked() -> bool:
	return is_jump_attack_landing and jump_attack_land_timer >= JUMP_ATTACK_LAND_UNLOCK

func should_cancel_jump_attack_land() -> bool:
	return is_jump_attack_land_unlocked()

# --- Interruption boundary ---
# Clears transient attack state when an external interruption (e.g. stagger)
# cancels an in-progress attack. Does NOT reset combo_step — combo progression
# is deliberately preserved.
func interrupt() -> void:
	_jump_attack_waits_for_animation = false
	cancel_air_attack_pause()
	_air_combo_fall_speed = -1.0
	clear_attack_buffer()
	is_jump_attacking = false
	is_jump_attack_hanging = false
	is_jump_attack_landing = false

# --- Combo reset ---
func reset_combo_if_idle(is_doing_action: bool) -> void:
	if not is_doing_action:
		combo_step = 0

# --- One frame-marker pause per combo swing. Animation keeps playing.
func arm_air_attack_pause(frame_time: float, duration: float) -> void:
	_air_attack_pause_at = frame_time
	_air_attack_pause_duration = maxf(duration, 0.0)
	_air_attack_pause_left = 0.0

func cancel_air_attack_pause() -> void:
	_air_attack_pause_at = -1.0
	_air_attack_pause_left = 0.0

func tick_air_attack_pause(animation_position: float, delta: float) -> bool:
	if _air_attack_pause_at >= 0.0 and animation_position + 0.00001 >= _air_attack_pause_at:
		_air_attack_pause_at = -1.0
		if not _body.is_on_floor(): _air_attack_pause_left = _air_attack_pause_duration
	if _body.is_on_floor(): _air_attack_pause_left = 0.0
	if _air_attack_pause_left <= 0.0: return false
	_air_attack_pause_left = maxf(_air_attack_pause_left - delta, 0.0)
	return true

# --- Combat air physics (slow combo fall + jump-attack hang/fall).
# Returns true when combat handled gravity this frame; false means the caller
# should run normal locomotion gravity instead.
func apply_combat_air_physics(delta: float, air_fall_multiplier: float = 0.3) -> bool:
	if combo_step > 0 and not _body.is_on_floor():
		if _air_combo_fall_speed < 0.0:
			_air_combo_fall_speed = maxf(_body.velocity.y, 0.0)
		var gravity_multiplier: float = LocomotionComponent.FALL_GRAVITY_MULT if _air_combo_fall_speed > 0.0 else 1.0
		_air_combo_fall_speed = minf(_air_combo_fall_speed + _body.get_gravity().y * gravity_multiplier * delta, LocomotionComponent.MAX_FALL_SPEED)
		_body.velocity.y = _air_combo_fall_speed * clampf(air_fall_multiplier, 0.01, 1.0)
		return true

	_air_combo_fall_speed = -1.0

	if is_jump_attacking and not _body.is_on_floor():
		if is_jump_attack_hanging:
			if not _jump_attack_waits_for_animation:
				jump_attack_hang_timer = maxf(jump_attack_hang_timer - delta, 0.0)
			_body.velocity.y = 0.0
			if jump_attack_hang_timer <= 0.0:
				is_jump_attack_hanging = false
		else:
			_body.velocity.y = JUMP_ATTACK_FALL_SPEED
		return true

	return false

func enable_attack_hitbox() -> void:
	_attack_hitbox.monitoring = true


func disable_attack_hitbox() -> void:
	_attack_hitbox.monitoring = false

func start_attack_hitbox_window() -> void:
	var attack_index := combo_step - 1

	if attack_index < 0:
		return

	if attack_index >= equipped_weapon.attack_active_start.size():
		return

	if attack_index >= equipped_weapon.attack_active_end.size():
		return

	var active_start: float = equipped_weapon.attack_active_start[attack_index]
	var active_end: float = equipped_weapon.attack_active_end[attack_index]

	await _body.get_tree().create_timer(active_start).timeout

	enable_attack_hitbox()

	await _body.get_tree().create_timer(active_end - active_start).timeout

	disable_attack_hitbox()
