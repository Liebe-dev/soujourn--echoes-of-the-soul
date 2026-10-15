extends Node
## Presentation only. CombatTime remains the only writer of Engine.time_scale.
var _camera: Camera2D
var _base_zoom := Vector2.ONE
var _active := false
var _zoom_active := false
var _generation := 0
var _game_elapsed := 0.0
var _real_elapsed := 0.0
var _last_usec := 0
var _peak_game_time := -1.0
var _restore_at := 0.0
var _zoom_in_duration := 0.06
var _multiplier := 1.5

func _ready() -> void:
	set_process(false)

func start(camera: Camera2D, stagger_duration: float, settings: Dictionary) -> void:
	cancel()
	_camera = camera
	if is_instance_valid(camera) and camera.has_method("cancel_hit_stop_zoom"): camera.cancel_hit_stop_zoom()
	_generation += 1
	_active = true
	_game_elapsed = 0.0
	_real_elapsed = 0.0
	_last_usec = Time.get_ticks_usec()
	_peak_game_time = -1.0
	_restore_at = maxf(stagger_duration - float(settings.get("return_lead", 0.2)), 0.0)
	_zoom_in_duration = maxf(float(settings.get("zoom_in_duration", 0.06)), 0.0)
	_multiplier = maxf(float(settings.get("zoom_multiplier", 1.5)), 1.0)
	_zoom_active = bool(settings.get("zoom_enabled", true)) and is_instance_valid(camera) and camera.is_current() and _restore_at > 0.0
	if _zoom_active:
		if camera.has_method("set_combat_zoom"): camera.set_combat_zoom(&"stagger", 1.0)
		_base_zoom = camera.zoom
		var token := _generation
		CombatTime.actor_timeout(get_parent(), _restore_at, func():
			if token == _generation: _restore_zoom()
		)
	if bool(settings.get("slow_motion_enabled", true)):
		CombatTime.request(self, &"stagger_impact", float(settings.get("slow_motion_scale", 0.35)), maxf(float(settings.get("slow_motion_duration", 0.18)), 0.0))
	set_process(true)

func _process(delta: float) -> void:
	if not _active: return
	if not is_instance_valid(_camera) or not _camera.is_current():
		cancel()
		return
	var now := Time.get_ticks_usec()
	_real_elapsed += maxf(float(now - _last_usec) / 1000000.0, 0.0)
	_last_usec = now
	_game_elapsed += CombatTime.actor_delta(get_parent(), delta)
	if not _zoom_active: return
	if _game_elapsed >= _restore_at:
		_restore_zoom()
		return
	var weight := 1.0
	if _real_elapsed < _zoom_in_duration:
		weight = 1.0 - pow(1.0 - _real_elapsed / maxf(_zoom_in_duration, 0.000001), 3.0)
	else:
		if _peak_game_time < 0.0: _peak_game_time = _game_elapsed
		var progress := clampf((_game_elapsed - _peak_game_time) / maxf(_restore_at - _peak_game_time, 0.000001), 0.0, 1.0)
		weight = 1.0 - smoothstep(0.0, 1.0, progress)
	var multiplier := lerpf(1.0, _multiplier, weight)
	if _camera.has_method("set_combat_zoom"): _camera.set_combat_zoom(&"stagger", multiplier)
	else: _camera.zoom = _base_zoom * multiplier

func _restore_zoom() -> void:
	if not _zoom_active: return
	_zoom_active = false
	if is_instance_valid(_camera):
		if _camera.has_method("clear_combat_zoom"): _camera.clear_combat_zoom(&"stagger")
		else: _camera.zoom = _base_zoom

func cancel() -> void:
	_generation += 1
	_active = false
	_restore_zoom()
	CombatTime.remove(self, &"stagger_impact")
	set_process(false)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED]: _last_usec = Time.get_ticks_usec()

func _exit_tree() -> void:
	cancel()
