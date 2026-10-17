extends Node
## Camera-only targeting; never changes facing, attacks, damage or collision.
const TARGET_GROUP := &"camera_lock_targets"

class Reticle extends Node2D:
	var preview := false
	func _draw() -> void:
		var color := Color(1.0, 0.8, 0.25) if preview else Color(0.9, 0.96, 1.0)
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 32, Color(0.03, 0.04, 0.06, 0.9), 4.0, true)
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 32, color, 2.0, true)
		draw_circle(Vector2.ZERO, 2.0, color)

var camera: Camera2D
var locked: Node2D
var preview: Node2D
var _anchor: Node2D
var _holding := false
var _started_locked := false
var _press_time := 0
var _drag := Vector2.ZERO
var _dragged := false
var _was_active := false
var _pointer := Vector2.INF
var _last_motion_time := 0
var _pan_suppressed := false
var _layer: CanvasLayer
var _reticle: Reticle

func _ready() -> void:
	camera = get_parent() as Camera2D
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.name = "LockReticle"
	_layer.layer = 0
	add_child(_layer)
	_reticle = Reticle.new()
	_reticle.hide()
	_layer.add_child(_reticle)
	_last_motion_time = Time.get_ticks_msec()

func gameplay_active() -> bool:
	if camera == null or not is_instance_valid(camera.target): return false
	if not camera.is_current() or get_tree().paused: return false
	if Input.mouse_mode not in [Input.MOUSE_MODE_HIDDEN, Input.MOUSE_MODE_CONFINED_HIDDEN]: return false
	if camera.target.has_method("is_campfire_ui_active") and camera.target.is_campfire_ui_active(): return false
	return get_window() != null and get_window().has_focus()

func _process(_delta: float) -> void:
	var active := gameplay_active()
	if not active:
		cancel_gesture()
		_reticle.hide()
		_was_active = false
		return
	if not _was_active:
		reset_pointer()
	_was_active = true
	sample_pointer(get_viewport().get_mouse_position(), Time.get_ticks_msec())
	validate_lock()
	var shown := preview if _holding and valid_target(preview) else locked
	_reticle.visible = valid_target(shown)
	if _reticle.visible:
		_reticle.position = screen_point(shown)
		_reticle.preview = _holding and shown != locked
		_reticle.queue_redraw()

func _input(event: InputEvent) -> void:
	if not gameplay_active():
		cancel_gesture()
		return
	if event.is_action("target_lock") and not event.is_echo():
		if event.is_pressed(): begin_gesture(Time.get_ticks_msec())
		else: finish_gesture(Time.get_ticks_msec())
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _holding:
		update_gesture(event.relative)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_gesture()
		reset_pointer(true)

func reset_pointer(suppress: bool = false) -> void:
	_pointer = get_viewport().get_mouse_position()
	_last_motion_time = Time.get_ticks_msec()
	_pan_suppressed = suppress

func sample_pointer(pointer: Vector2, now: int) -> void:
	if _pointer == Vector2.INF or pointer.distance_squared_to(_pointer) > 0.01:
		_pointer = pointer
		_last_motion_time = now
		_pan_suppressed = false
	if camera.mouse_pan_auto_reset_enabled and now - _last_motion_time >= camera.mouse_pan_auto_reset_delay * 1000.0:
		_pan_suppressed = true

func mouse_pan_allowed() -> bool:
	return not _pan_suppressed and not _holding

func valid_target(enemy: Variant) -> bool:
	if not is_instance_valid(enemy) or not enemy.is_inside_tree() or enemy.is_queued_for_deletion(): return false
	if not enemy.is_visible_in_tree() or not enemy.has_method("get_lock_on_point"): return false
	var point: Vector2 = enemy.get_lock_on_point()
	return point.is_finite()

func screen_point(enemy: Node2D) -> Vector2:
	return get_viewport().get_canvas_transform() * Vector2(enemy.get_lock_on_point())

func in_view(enemy: Variant) -> bool:
	return valid_target(enemy) and get_viewport().get_visible_rect().has_point(screen_point(enemy))

func candidates() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(TARGET_GROUP):
		if node is Node2D and node != camera.target and in_view(node): result.append(node)
	return result

func nearest() -> Node2D:
	var best: Node2D
	var best_distance := INF
	var origin := actor_point()
	for enemy in candidates():
		var distance := origin.distance_squared_to(Vector2(enemy.get_lock_on_point()))
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best

func directional(origin: Variant, direction: Vector2) -> Node2D:
	if not in_view(origin): return null
	if direction.is_zero_approx(): return origin
	var best: Node2D = origin
	var best_angle := INF
	var best_distance := INF
	var center := screen_point(origin)
	var minimum_dot := cos(deg_to_rad(camera.lock_switch_half_angle))
	for enemy in candidates():
		if enemy == origin: continue
		var displacement := screen_point(enemy) - center
		if displacement.length_squared() < 1.0: continue
		var dot := direction.normalized().dot(displacement.normalized())
		if dot < minimum_dot: continue
		var angle := acos(clampf(dot, -1.0, 1.0))
		var distance := displacement.length_squared()
		if angle < best_angle - 0.01 or (absf(angle - best_angle) <= 0.01 and distance < best_distance):
			best_angle = angle
			best_distance = distance
			best = enemy
	return best

func begin_gesture(now: int) -> void:
	if not camera.lock_on_enabled: return
	validate_lock()
	_holding = true
	_started_locked = valid_target(locked)
	_anchor = locked if _started_locked else nearest()
	preview = _anchor
	_press_time = now
	_drag = Vector2.ZERO
	_dragged = false

func update_gesture(relative: Vector2) -> void:
	if not _holding: return
	_drag += relative
	if _drag.length() >= camera.lock_switch_drag_distance:
		_dragged = true
		preview = directional(_anchor, _drag)

func finish_gesture(now: int) -> void:
	if not _holding: return
	var tap: bool = not _dragged and now - _press_time < camera.lock_switch_hold_time * 1000.0
	if _started_locked and tap:
		clear_lock()
	else:
		locked = preview if in_view(preview) else null
		if locked == null: reset_pointer(true)
	_had_lock = is_instance_valid(locked)
	cancel_gesture()

func cancel_gesture() -> void:
	_holding = false
	preview = null
	_anchor = null
	_drag = Vector2.ZERO
	_dragged = false

func clear_lock() -> void:
	locked = null
	_had_lock = false
	cancel_gesture()
	reset_pointer(true)
	if is_instance_valid(_reticle): _reticle.hide()

func validate_lock() -> void:
	if not is_instance_valid(locked):
		if _had_lock: clear_lock()
	elif not camera.lock_on_enabled or not in_view(locked): clear_lock()
	_had_lock = is_instance_valid(locked)

var _had_lock := false

func actor_point() -> Vector2:
	var shape := camera.target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	return shape.global_position if shape != null else camera.target.global_position

func pan_for_lock() -> Vector2:
	var point: Vector2 = locked.get_lock_on_point()
	var half_view := get_viewport().get_visible_rect().size * 0.5
	if half_view.x <= 0.0 or half_view.y <= 0.0: return Vector2.ZERO
	var normalized := ((point - actor_point()) * camera.zoom / half_view).limit_length(1.0)
	return normalized * camera.mouse_pan_max_distance.abs()
