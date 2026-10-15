class_name DefenseComponent
extends RefCounted
## Owns guard timing and directional hit classification, without scene side effects.

enum HitResult { NONE, DEFLECT, GUARD }
const DEFAULT_DEFLECT_WINDOW := 0.2
const DEFAULT_DEFLECT_DELAY := 0.1

var deflect_window: float
var deflect_delay: float
var _guarding := false
var _holding_duration := 0.0
var _guard_push_left := 0.0
var _guard_push_speed := 0.0
var _guard_push_direction := 0.0
var guard_push_active: bool:
	get: return _guard_push_left > 0.0

var is_guarding: bool:
	get:
		return _guarding

var holding_duration: float:
	get:
		return _holding_duration

func _init(window: float = DEFAULT_DEFLECT_WINDOW, delay: float = DEFAULT_DEFLECT_DELAY) -> void:
	deflect_window = maxf(window, 0.0)
	deflect_delay = maxf(delay, 0.0)

func begin_guard(press_age: float = 0.0) -> void:
	_guarding = true
	_holding_duration = maxf(press_age, 0.0)

func end_guard(cancel_push: bool = true) -> void:
	if cancel_push: _guard_push_left = 0.0
	_guarding = false
	_holding_duration = 0.0

func sync_press_age(age: float) -> void:
	if _guarding: _holding_duration = maxf(age, 0.0)

func tick(delta: float) -> void:
	if _guarding:
		_holding_duration += maxf(delta, 0.0)

func is_in_deflect_window() -> bool:
	return _guarding and deflect_window > 0.0 and _holding_duration >= deflect_delay and _holding_duration < deflect_delay + deflect_window - 0.000001

func classify_hit(body_position: Vector2, facing_direction: int, hit_from: Vector2) -> HitResult:
	# Unknown or vertically aligned origins cannot establish a frontal attack.
	if not _guarding or not hit_from.is_finite():
		return HitResult.NONE
	if (hit_from.x - body_position.x) * facing_direction <= 0.0:
		return HitResult.NONE
	return HitResult.DEFLECT if is_in_deflect_window() else HitResult.GUARD


func start_guard_push(distance: float, duration: float, direction: float) -> void:
	_guard_push_left = maxf(distance, 0.0)
	_guard_push_speed = _guard_push_left / maxf(duration, 0.01)
	_guard_push_direction = signf(direction)

func consume_guard_push(delta: float) -> float:
	if not guard_push_active or delta <= 0.0:
		return 0.0
	var travel := minf(_guard_push_left, _guard_push_speed * delta)
	_guard_push_left = maxf(_guard_push_left - travel, 0.0)
	return _guard_push_direction * travel / delta
