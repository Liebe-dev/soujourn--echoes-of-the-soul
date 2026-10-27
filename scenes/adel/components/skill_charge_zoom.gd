extends Node
## Presentation in real time, paused with gameplay; owns only its camera source.
const SOURCE: StringName = &"skill_charge"
var _camera: Camera2D
var _current: float = 1.0
var _from: float = 1.0
var _target: float = 1.0
var _duration: float = 0.0
var _elapsed: float = 0.0
var _last_usec: int = 0
var _returning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)

func hold(camera: Camera2D, multiplier: float, duration: float) -> void:
	if multiplier <= 1.0:
		release(duration)
		return
	if not is_instance_valid(camera) or not camera.is_current() or not camera.has_method("set_combat_zoom"):
		cancel()
		return
	if _camera != camera:
		cancel()
		_camera = camera
		_camera.set_combat_zoom(SOURCE, 1.0)
	var target := maxf(multiplier, 1.0)
	if not _returning and is_equal_approx(_target, target): return
	_returning = false
	_transition(target, duration)

func release(duration: float) -> void:
	if not is_instance_valid(_camera) or _returning: return
	_returning = true
	_transition(1.0, duration)

func _transition(target: float, duration: float) -> void:
	_from = _current
	_target = target
	_duration = maxf(duration, 0.0)
	_elapsed = 0.0
	_last_usec = Time.get_ticks_usec()
	set_process(true)
	if _duration <= 0.0: _apply(1.0)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var delta := maxf(float(now - _last_usec) / 1000000.0, 0.0)
	_last_usec = now
	if not is_instance_valid(_camera) or not _camera.is_current():
		cancel()
		return
	if get_tree().paused: return
	if not _returning and is_equal_approx(_current, _target): return
	_elapsed += delta
	_apply(clampf(_elapsed / maxf(_duration, 0.000001), 0.0, 1.0))

func _apply(progress: float) -> void:
	# Quintic ease-out: pull in hard immediately, then lose speed toward the target.
	var weight := smoothstep(0.0, 1.0, progress) if _returning else 1.0 - pow(1.0 - progress, 5.0)
	_current = lerpf(_from, _target, weight)
	_camera.set_combat_zoom(SOURCE, _current)
	if progress >= 1.0:
		if _returning: cancel()

func cancel() -> void:
	if is_instance_valid(_camera): _camera.clear_combat_zoom(SOURCE)
	_camera = null
	_current = 1.0
	_target = 1.0
	_returning = false
	set_process(false)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED]: _last_usec = Time.get_ticks_usec()

func _exit_tree() -> void:
	cancel()
