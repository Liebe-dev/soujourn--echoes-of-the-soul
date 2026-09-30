class_name LocomotionComponent
extends RefCounted
## A15.1 — Locomotion extracted from scenes/adel/playable_adel.gd.
##
## Owns horizontal movement, vertical physics (gravity), and jump for the
## playable CharacterBody2D. Holds a reference to the owning body so there is a
## single source of truth for `velocity` (still owned by the body itself).
##
## Does NOT own: animation, dash, combat, stagger, rest, or the FSM flow.
## Jump/landing transitions are exposed via the `jumped`/`landed` signals so the
## coordinator can react without the component depending on the player script.

signal jumped
signal landed

# --- Movement tuning (single source of truth) ---
const WALK_SPEED := 140.0
const RUN_SPEED := 450.0
const RUN_BOOST_SPEED := 520.0
const RUN_BOOST_TIME := 0.22
const GROUND_ACCEL := 1400.0
const GROUND_FRICTION := 1600.0
const TURN_ACCEL := 3200.0
const AIR_ACCEL_STAND := 320.0
const AIR_ACCEL_RUN := 980.0
const AIR_SPEED_CAP_STAND := 95.0
const AIR_SPEED_CAP_RUN := RUN_SPEED
const WALK_JUMP_VELOCITY := -480.0
const RUN_JUMP_VELOCITY := -720.0
const DOUBLE_JUMP_VELOCITY := -700.0
const JUMP_RISE_GRAVITY_MULT := 1.6
const JUMP_CUT_GRAVITY_MULT := 3.2
const FALL_GRAVITY_MULT := 2
const MAX_FALL_SPEED := 920.0
const MAX_JUMPS := 2

# --- State owned by Locomotion ---
var is_running: bool = false
var _jumps_remaining := MAX_JUMPS
var _was_on_floor := true
var _run_boost_timer := 0.0
var _was_running := false
var _air_accel := AIR_ACCEL_STAND
var _air_speed_cap := AIR_SPEED_CAP_STAND

var _body: CharacterBody2D

func _init(body: CharacterBody2D) -> void:
	_body = body

# --- Run toggle / boost (was inline in _physics_process) ---
func update_run_state(delta: float) -> void:
	if Input.is_action_just_pressed("run") and _body.is_on_floor():
		is_running = not is_running
	if is_running and not _was_running and _body.is_on_floor():
		_run_boost_timer = RUN_BOOST_TIME
	_was_running = is_running
	if _run_boost_timer > 0.0:
		_run_boost_timer = maxf(_run_boost_timer - delta, 0.0)

# --- Horizontal movement ---
func apply_horizontal_movement(direction: float, delta: float) -> void:
	if not _body.is_on_floor():
		if direction != 0.0:
			var target_x := direction * _air_speed_cap
			_body.velocity.x = move_toward(_body.velocity.x, target_x, _air_accel * delta)
			_body.velocity.x = clampf(_body.velocity.x, -_air_speed_cap, _air_speed_cap)
		return

	var target_speed := _get_ground_target_speed()
	if direction != 0.0:
		var target_x := direction * target_speed
		var accel := GROUND_ACCEL
		if signf(_body.velocity.x) != 0.0 and signf(direction) != signf(_body.velocity.x):
			accel = TURN_ACCEL
		_body.velocity.x = move_toward(_body.velocity.x, target_x, accel * delta)
	else:
		_body.velocity.x = move_toward(_body.velocity.x, 0.0, GROUND_FRICTION * delta)

# --- Vertical physics (gravity + terminal velocity) ---
func apply_vertical_physics(delta: float) -> void:
	if _body.is_on_floor():
		return

	var gravity := _body.get_gravity() * delta

	if _body.velocity.y < 0.0:
		gravity *= JUMP_RISE_GRAVITY_MULT
	elif _body.velocity.y > 0.0:
		gravity *= FALL_GRAVITY_MULT

	_body.velocity += gravity
	_body.velocity.y = minf(_body.velocity.y, MAX_FALL_SPEED)

# --- Jump ---
func handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return
	if _body.is_on_floor():
		_begin_air_movement()
		_body.velocity.y = _get_ground_jump_velocity()
		_jumps_remaining = MAX_JUMPS - 1
		jumped.emit()
	elif _jumps_remaining > 0:
		_body.velocity.y = DOUBLE_JUMP_VELOCITY
		_jumps_remaining -= 1
		jumped.emit()

# --- Floor/air transition bookkeeping (was inline in _physics_process) ---
func update_ground_state() -> void:
	if _body.is_on_floor():
		_jumps_remaining = MAX_JUMPS
		if not _was_on_floor:
			landed.emit()
	elif _was_on_floor:
		_begin_air_movement()
	_was_on_floor = _body.is_on_floor()

func _get_ground_target_speed() -> float:
	if is_running:
		if _run_boost_timer > 0.0:
			return RUN_BOOST_SPEED
		return RUN_SPEED
	return WALK_SPEED

func _uses_run_jump() -> bool:
	return is_running or absf(_body.velocity.x) >= WALK_SPEED * 0.7

func _get_ground_jump_velocity() -> float:
	if _uses_run_jump():
		return RUN_JUMP_VELOCITY
	return WALK_JUMP_VELOCITY

func _begin_air_movement() -> void:
	if _uses_run_jump():
		_air_accel = AIR_ACCEL_RUN
		_air_speed_cap = AIR_SPEED_CAP_RUN
	else:
		_air_accel = AIR_ACCEL_STAND
		_air_speed_cap = AIR_SPEED_CAP_STAND
