extends Camera2D

const HitStopCameraZoom = preload("res://scenes/camera/hit_stop_camera_zoom.gd")
const CameraPreferences = preload("res://scenes/camera/camera_preferences.gd")
const CameraTargetLock = preload("res://scenes/camera/camera_target_lock.gd")

@export_category("Camera Settings")
@export_range(0.1, 30.0, 0.1, "or_greater") var follow_speed_x: float = 8.0
@export var follow_speed_y: float = 5.0

@export_category("Horizontal Follow")
@export_range(0.0, 1.0, 0.01, "or_greater") var horizontal_follow_delay: float = 0.1
@export_range(0.0, 5.0, 0.01) var horizontal_center_snap_distance: float = 0.1

@export_category("Deadzone (Vùng chết)")
@export var vertical_deadzone: float = 60.0

@export_category("Mouse Pan")
@export var mouse_pan_enabled: bool = true
@export var mouse_pan_max_distance: Vector2 = Vector2(90.0, 55.0)
@export_range(0.0, 0.9, 0.01) var mouse_pan_deadzone: float = 0.18
@export_range(0.1, 30.0, 0.1, "or_greater") var mouse_pan_follow_speed: float = 5.0

@export_category("Mouse Auto Reset")
@export var mouse_pan_auto_reset_enabled: bool = true
@export_range(0.5, 30.0, 0.1) var mouse_pan_auto_reset_delay: float = 3.0

@export_category("Target Lock")
@export var lock_on_enabled: bool = true
@export_range(0.1, 1.0, 0.01) var lock_switch_hold_time: float = 0.2
@export_range(4.0, 200.0, 1.0) var lock_switch_drag_distance: float = 24.0
@export_range(5.0, 89.0, 1.0) var lock_switch_half_angle: float = 65.0

@export_category("Hit Stop Zoom")
@export var hit_stop_zoom_enabled: bool = true
@export_range(1.0, 1.2, 0.01) var hit_stop_zoom_multiplier: float = 1.05
@export_range(0.0, 0.2, 0.005) var hit_stop_zoom_in_duration: float = 0.025
@export_range(0.0, 0.3, 0.005) var hit_stop_zoom_out_duration: float = 0.09

var hit_stop_zoom: Node
var _combat_zoom_base: Vector2 = Vector2.ONE
var _combat_zoom_sources: Dictionary = {}
var target_lock: Node
var _stagger_focus_weight: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO
var _mouse_pan: Vector2 = Vector2.ZERO

var target: CharacterBody2D
var _target_y: float = 0.0
var _last_target_x: float = 0.0
var _horizontal_direction: int = 0
var _horizontal_delay_left: float = 0.0

func _ready() -> void:
	top_level = true
	enabled = true
	_base_offset = offset
	if get_parent() is CharacterBody2D:
		target = get_parent()
		global_position = target.global_position
		_target_y = global_position.y
		_last_target_x = target.global_position.x
	var settings := CameraPreferences.read_defaults(mouse_pan_deadzone, mouse_pan_auto_reset_enabled, mouse_pan_auto_reset_delay)
	apply_camera_preferences(settings, false)
	target_lock = CameraTargetLock.new()
	target_lock.name = "TargetLock"
	add_child(target_lock)
	hit_stop_zoom = HitStopCameraZoom.new()
	hit_stop_zoom.name = "HitStopZoom"
	add_child(hit_stop_zoom)

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var target_pos = target.global_position
	var ideal_center_y = target_pos.y - 30.0

	if target.has_method("is_on_floor") and target.is_on_floor():
		_target_y = lerp(_target_y, ideal_center_y, follow_speed_y * 0.5 * delta)
	else:
		var diff_y = target_pos.y - _target_y

		if diff_y < -vertical_deadzone:
			_target_y = target_pos.y + vertical_deadzone
		elif diff_y > vertical_deadzone:
			_target_y = target_pos.y - vertical_deadzone
	var new_x = _follow_horizontal(target_pos.x, delta)
	var new_y = lerp(global_position.y, _target_y, follow_speed_y * delta)

	global_position = Vector2(new_x, new_y)
	_update_mouse_pan(delta)

func _follow_horizontal(target_x: float, delta: float) -> float:
	var motion := target_x - _last_target_x
	_last_target_x = target_x
	var direction := int(signf(motion)) if absf(motion) > 0.001 else 0
	if direction != _horizontal_direction:
		_horizontal_direction = direction
		_horizontal_delay_left = maxf(horizontal_follow_delay, 0.0) if direction != 0 else 0.0

	# Hold for the requested start delay, then smoothly catch up to the root.
	var held_time := minf(maxf(delta, 0.0), _horizontal_delay_left)
	_horizontal_delay_left = maxf(_horizontal_delay_left - held_time, 0.0)
	var follow_delta := maxf(delta - held_time, 0.0)
	var weight := 1.0 - exp(-maxf(follow_speed_x, 0.0) * follow_delta)
	var next_x := lerpf(global_position.x, target_x, weight)
	if direction == 0 and absf(target_x - next_x) <= horizontal_center_snap_distance:
		return target_x
	return next_x


func play_hit_stop_zoom() -> void:
	if is_instance_valid(hit_stop_zoom): hit_stop_zoom.start()

func cancel_hit_stop_zoom() -> void:
	if is_instance_valid(hit_stop_zoom): hit_stop_zoom.cancel()

func has_combat_zoom(source: StringName) -> bool:
	return _combat_zoom_sources.has(source)

func set_combat_zoom(source: StringName, multiplier: float) -> void:
	if _combat_zoom_sources.is_empty(): _combat_zoom_base = zoom
	_combat_zoom_sources[source] = maxf(multiplier, 1.0)
	_apply_combat_zoom()

func clear_combat_zoom(source: StringName) -> void:
	if not _combat_zoom_sources.has(source): return
	_combat_zoom_sources.erase(source)
	_apply_combat_zoom()

func _apply_combat_zoom() -> void:
	# Shared base and a maximum, never multiply one impact zoom by another.
	var multiplier := 1.0
	for value in _combat_zoom_sources.values(): multiplier = maxf(multiplier, float(value))
	zoom = _combat_zoom_base * multiplier

func camera_preferences() -> Dictionary:
	return {"deadzone": mouse_pan_deadzone, "reset_enabled": mouse_pan_auto_reset_enabled, "reset_delay": mouse_pan_auto_reset_delay}

func apply_camera_preferences(settings: Dictionary, persist: bool = true) -> Error:
	mouse_pan_deadzone = clampf(float(settings.get("deadzone", mouse_pan_deadzone)), 0.0, 0.9)
	mouse_pan_auto_reset_enabled = bool(settings.get("reset_enabled", mouse_pan_auto_reset_enabled))
	mouse_pan_auto_reset_delay = clampf(float(settings.get("reset_delay", mouse_pan_auto_reset_delay)), 0.5, 30.0)
	if is_instance_valid(target_lock): target_lock.reset_pointer()
	if persist: return CameraPreferences.store(mouse_pan_deadzone, mouse_pan_auto_reset_enabled, mouse_pan_auto_reset_delay)
	return OK

func _update_mouse_pan(delta: float) -> void:
	var desired := Vector2.ZERO
	if is_instance_valid(target_lock):
		target_lock.validate_lock()
		if target_lock.gameplay_active():
			if target_lock.valid_target(target_lock.locked):
				desired = target_lock.pan_for_lock()
			elif mouse_pan_enabled and target_lock.mouse_pan_allowed():
				desired = _pan_for_pointer(get_viewport().get_mouse_position(), get_viewport_rect())
	var weight := 1.0 - exp(-maxf(mouse_pan_follow_speed, 0.0) * maxf(delta, 0.0))
	_mouse_pan = _mouse_pan.lerp(desired, weight)
	if _mouse_pan.distance_to(desired) < 0.01: _mouse_pan = desired
	_apply_camera_offset()

func set_stagger_focus(weight: float) -> void:
	_stagger_focus_weight = clampf(weight, 0.0, 1.0)
	_apply_camera_offset()

func _apply_camera_offset() -> void:
	var normal_offset := _base_offset + _mouse_pan
	if _stagger_focus_weight <= 0.0 or not is_instance_valid(target):
		offset = normal_offset
		return
	var hurtbox := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var focus := hurtbox.global_position if hurtbox != null else target.global_position
	offset = normal_offset.lerp(focus - global_position, _stagger_focus_weight)

func _pan_for_pointer(pointer: Vector2, viewport_rect: Rect2) -> Vector2:
	if not viewport_rect.has_area() or not viewport_rect.has_point(pointer): return Vector2.ZERO
	# Screen coordinates avoid feedback from the camera's world-space movement.
	var normalized := ((pointer - viewport_rect.get_center()) / (viewport_rect.size * 0.5)).limit_length(1.0)
	var radius := normalized.length()
	var deadzone := clampf(mouse_pan_deadzone, 0.0, 0.9)
	if radius <= deadzone: return Vector2.ZERO
	var amount := clampf((radius - deadzone) / (1.0 - deadzone), 0.0, 1.0)
	return normalized.normalized() * amount * mouse_pan_max_distance.abs()
