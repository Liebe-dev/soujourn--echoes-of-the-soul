extends Node
## Short visual pulse, measured in unpaused real time rather than hit-stop time.
var _camera: Camera2D
var active := false
var _elapsed := 0.0
var _last_usec := 0
var _start_multiplier := 1.0
var _current_multiplier := 1.0

func _ready() -> void:
	_camera = get_parent() as Camera2D
	set_process(false)

func _allowed() -> bool:
	if not is_instance_valid(_camera) or not _camera.is_current() or not _camera.hit_stop_zoom_enabled: return false
	if get_tree().paused or not is_instance_valid(_camera.target) or _camera.target.is_queued_for_deletion(): return false
	if _camera.has_combat_zoom(&"stagger"): return false
	var actor: CharacterBody2D = _camera.target
	if "damage" in actor and actor.damage != null and actor.damage.is_stunned: return false
	if actor.has_method("is_campfire_ui_active") and actor.is_campfire_ui_active(): return false
	return not ("is_resting" in actor and actor.is_resting)

func start() -> void:
	if not _allowed(): return
	_start_multiplier = _current_multiplier if active else 1.0
	_elapsed = 0.0
	_last_usec = Time.get_ticks_usec()
	active = true
	_camera.set_combat_zoom(&"hit_stop", _start_multiplier)
	set_process(true)

func _process(_delta: float) -> void:
	if not _allowed():
		cancel()
		return
	var now := Time.get_ticks_usec()
	_elapsed += maxf(float(now - _last_usec) / 1000000.0, 0.0)
	_last_usec = now
	var rise: float = maxf(_camera.hit_stop_zoom_in_duration, 0.0)
	var fall: float = maxf(_camera.hit_stop_zoom_out_duration, 0.0)
	if _elapsed >= rise + fall:
		cancel()
		return
	var peak: float = clampf(_camera.hit_stop_zoom_multiplier, 1.1, 1.2)
	if _elapsed < rise:
		var progress := clampf(_elapsed / maxf(rise, 0.000001), 0.0, 1.0)
		_current_multiplier = lerpf(_start_multiplier, peak, 1.0 - pow(1.0 - progress, 3.0))
	else:
		var progress := clampf((_elapsed - rise) / maxf(fall, 0.000001), 0.0, 1.0)
		_current_multiplier = lerpf(peak, 1.0, smoothstep(0.0, 1.0, progress))
	_camera.set_combat_zoom(&"hit_stop", _current_multiplier)

func cancel() -> void:
	active = false
	_current_multiplier = 1.0
	if is_instance_valid(_camera): _camera.clear_combat_zoom(&"hit_stop")
	set_process(false)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED]: _last_usec = Time.get_ticks_usec()

func _exit_tree() -> void:
	cancel()
