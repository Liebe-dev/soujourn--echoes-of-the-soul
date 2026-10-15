class_name DashComponent
extends RefCounted
## Owns eligibility, phase timing, integrated motion, dash immunity and cooldown.
enum Phase { IDLE, ACTIVE, SKID }
const DASH_TWEEN_DURATION := 0.3 # Legacy default name; movement no longer uses Tween.
const DASH_SKID_DURATION := 0.2
var phase := Phase.IDLE
var is_dodging: bool:
	get: return phase != Phase.IDLE
var able_to_dodge := true
var has_air_dashed := false
var is_air := false
var _body: CharacterBody2D
var _cooldown: Timer
var _elapsed := 0.0
var _direction := 1.0
var _duration := 0.3
var _skid_duration := 0.2
var _initial_speed := 2800.0
var _target_speed := 140.0
var _iframe_window := Vector2(0.0, 0.3)
var _iframe_token := 0

func _init(body: CharacterBody2D, cooldown: Timer) -> void:
	_body = body
	_cooldown = cooldown

func can_dash(direction: float, on_floor: bool) -> bool:
	return Input.is_action_just_pressed("dodge") and can_start(direction, on_floor)

func can_start(direction: float, on_floor: bool) -> bool:
	return not is_dodging and able_to_dodge and (direction != 0.0 if on_floor else not has_air_dashed)

func start_dash(direction: float, on_floor: bool, facing: int) -> bool:
	if not can_start(direction, on_floor) or not _body.has_action_stamina() or _body.is_sentinel_exit_pending(): return false
	_body.vitals.spend_stamina("dash", true)
	is_air = not on_floor
	if is_air: has_air_dashed = true
	_direction = direction if direction != 0.0 else float(facing)
	_duration = maxf(_body.dash_active_duration, 0.001)
	_skid_duration = maxf(_body.dash_skid_duration, 0.0)
	_initial_speed = maxf(_body.dash_speed, 0.0)
	_target_speed = maxf(_body.dash_end_speed, 0.0)
	_iframe_window = Vector2(clampf(_body.dash_iframe_window.x, 0.0, _duration), clampf(_body.dash_iframe_window.y, 0.0, _duration))
	_elapsed = 0.0
	phase = Phase.ACTIVE
	_body.state_machine.transition(AdelStateMachine.State.DASH_ACTIVE)
	_body.presentation.play(&"dash_air" if is_air else &"dash")
	_body.ghost_trail.start()
	_body.velocity = Vector2(_direction * _initial_speed, 0.0)
	_update_immunity()
	return true

func physics_update(delta: float) -> void:
	if not is_dodging or delta <= 0.0: return
	_body.velocity.y = 0.0
	if phase == Phase.ACTIVE:
		var previous := _elapsed
		_elapsed = minf(_elapsed + delta, _duration)
		# Exact area of the original QUAD/EASE_OUT velocity curve.
		var distance := _motion_area(_elapsed) - _motion_area(previous)
		_body.velocity.x = _direction * distance / delta
	else:
		_elapsed += delta
		_body.velocity.x = 0.0
	_body.move_and_slide()
	_body.locomotion.update_ground_state()
	_update_immunity()
	if phase == Phase.ACTIVE and _elapsed + 0.000001 >= _duration:
		_body.velocity.x = 0.0
		if is_air or _skid_duration <= 0.0:
			_finish()
		else:
			phase = Phase.SKID
			_update_immunity()
			_elapsed = 0.0
			_body.state_machine.transition(AdelStateMachine.State.DASH_SKID)
			_body.presentation.play(&"dash skid")
	elif phase == Phase.SKID and _elapsed + 0.000001 >= _skid_duration:
		_finish()

func _motion_area(time: float) -> float:
	return _target_speed * time + (_initial_speed - _target_speed) * _duration * (1.0 - pow(1.0 - time / _duration, 3.0)) / 3.0

func _update_immunity() -> void:
	var in_window := phase == Phase.ACTIVE and _elapsed >= _iframe_window.x and _elapsed < _iframe_window.y
	if in_window and _iframe_token == 0:
		_iframe_token = _body.damage.grant_invulnerability(&"dash")
	elif not in_window and _iframe_token != 0:
		_body.damage.release_invulnerability(&"dash", _iframe_token)
		_iframe_token = 0

func _finish() -> void:
	_body.state_machine.resume_locomotion() # Parent exit calls end_dash exactly once.
	_body._try_consume_guard() # Held defense starts now, even during dash cooldown.

func end_dash() -> void:
	if not is_dodging: return
	phase = Phase.IDLE
	_body.velocity.x = 0.0
	_body.ghost_trail.stop()
	if _iframe_token != 0:
		_body.damage.release_invulnerability(&"dash", _iframe_token)
		_iframe_token = 0
	able_to_dodge = false
	_cooldown.start()

func reset_air_dash() -> void:
	has_air_dashed = false

func on_cooldown_timeout() -> void:
	able_to_dodge = true
