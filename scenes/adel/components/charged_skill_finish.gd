extends Node
## Owns only charged-Q held zoom, its paused return and one fresh buffered action.
signal returned(action: StringName, direction: float)
static var _pause_owner: WeakRef
var holding := false
var returning := false
var _camera: Camera2D
var _zoom_enabled := false
var _multiplier := 1.0
var _current_multiplier := 1.0
var _rise := 0.09
var _return_duration := 0.6
var _elapsed := 0.0
var _last_usec := 0
var _action: StringName = &""
var _direction := 0.0
const ACTIONS: Array[StringName] = [&"attack", &"weapon_skill", &"guard and deflect", &"dodge", &"jump", &"soul_heal"]

static func is_freezing() -> bool:
	return _pause_owner != null and is_instance_valid(_pause_owner.get_ref()) and _pause_owner.get_ref().returning

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_process_input(false)

func start(camera: Camera2D, enabled: bool, multiplier: float, rise: float, duration: float) -> void:
	cancel()
	_camera = camera
	holding = true
	_zoom_enabled = enabled and is_instance_valid(camera) and camera.is_current()
	_multiplier = maxf(multiplier, 1.0)
	_current_multiplier = 1.0
	_rise = maxf(rise, 0.0)
	_return_duration = maxf(duration, 0.0)
	_elapsed = 0.0
	_last_usec = Time.get_ticks_usec()
	if _zoom_enabled: _camera.set_combat_zoom(&"skill_impact", 1.0)
	set_process(true)

func begin_return() -> void:
	if not holding or returning: return
	if not _zoom_enabled or _return_duration <= 0.0 or _multiplier <= 1.0:
		cancel()
		returned.emit(&"", 0.0)
		return
	# The skill reaches this point from unpaused physics after its final recovery pose.
	if get_tree().paused or is_freezing():
		cancel()
		returned.emit(&"", 0.0)
		return
	returning = true
	_elapsed = 0.0
	_last_usec = Time.get_ticks_usec()
	_multiplier = _current_multiplier
	_pause_owner = weakref(self)
	get_tree().paused = true
	set_process_input(true)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var elapsed := maxf(float(now - _last_usec) / 1000000.0, 0.0)
	_last_usec = now
	if not holding: return
	if not is_instance_valid(_camera) or not _camera.is_current():
		var was_returning := returning
		cancel()
		if was_returning: returned.emit(&"", 0.0)
		return
	if get_tree().paused and not returning: return
	_elapsed += elapsed
	if not _zoom_enabled: return
	if returning:
		var progress := clampf(_elapsed / maxf(_return_duration, 0.000001), 0.0, 1.0)
		_current_multiplier = lerpf(_multiplier, 1.0, smoothstep(0.0, 1.0, progress))
		_camera.set_combat_zoom(&"skill_impact", _current_multiplier)
		if progress >= 1.0:
			var action := _action
			var direction := _direction
			cancel()
			returned.emit(action, direction)
	else:
		var weight := 1.0 if _rise <= 0.0 else 1.0 - pow(1.0 - clampf(_elapsed / _rise, 0.0, 1.0), 3.0)
		_current_multiplier = lerpf(1.0, _multiplier, weight)
		_camera.set_combat_zoom(&"skill_impact", _current_multiplier)

func _input(event: InputEvent) -> void:
	if not returning: return
	for action in ACTIONS:
		if event.is_action_pressed(action) and not event.is_echo():
			_action = action
			_direction = Input.get_axis("move_left", "move_right")
			get_viewport().set_input_as_handled()
			return
		if event.is_action_released(action):
			# A released defensive hold is not a request to enter defense later.
			if action == &"guard and deflect" and _action == action: _action = &""
			get_viewport().set_input_as_handled()
			return
	if event.is_action("ui_cancel") or event.is_action("toggle_master_menu") or event.is_action("interact"):
		get_viewport().set_input_as_handled()

func cancel() -> void:
	if is_instance_valid(_camera) and _zoom_enabled: _camera.clear_combat_zoom(&"skill_impact")
	if _pause_owner != null and _pause_owner.get_ref() == self:
		_pause_owner = null
		if is_inside_tree(): get_tree().paused = false
	holding = false
	returning = false
	_action = &""
	set_process(false)
	set_process_input(false)

func _exit_tree() -> void:
	cancel()
