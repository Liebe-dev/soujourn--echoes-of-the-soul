extends Node
var checks := 0
var failures := 0
var p
var cam
var scene: Node
var rendered := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not String(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("CodexMouseCamera"):
		get_tree().quit(2)
		return
	Engine.max_fps = 60
	rendered = DisplayServer.get_name() != "headless"
	_run.call_deferred()

func frames(count: int = 2) -> void:
	for i in count: await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("MOUSE CAMERA ", "PASS " if ok else "FAIL ", label)

func action(name: StringName) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventAction.new()
	event.action = name
	Input.parse_input_event(event)
	await frames(3)

func pointer_at(fraction: Vector2) -> void:
	if not rendered: return
	var rect := get_viewport().get_visible_rect()
	get_viewport().warp_mouse(rect.position + rect.size * fraction)
	await frames(3)

func centered(label: String) -> void:
	if not rendered: return
	await frames(3)
	var pos := get_viewport().get_mouse_position()
	var center := get_viewport().get_visible_rect().get_center()
	check(pos.distance_to(center) <= 2.0, label + " native cursor centered: " + str(pos))

func mode(expected: int, label: String) -> void:
	if rendered: check(Input.mouse_mode == expected, label)

func capture(label: String) -> void:
	if not rendered: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://mouse-camera-" + label + ".png")

func _run() -> void:
	if rendered:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1280, 720)
		get_window().position = Vector2i(40, 40)
		get_window().grab_focus()
		await wait(0.2)
		check(get_window().has_focus(), "native game window has focus")
	SaveManager.delete_save()
	SaveManager._data = SaveManager._default_data()
	scene = load("res://scenes/Map 1/map_1_scene_2.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	await wait(0.35)
	p = get_tree().get_first_node_in_group("Player")
	cam = p.get_node("Camera2D")
	p.set_physics_process(false)
	var rect: Rect2 = cam.get_viewport_rect()
	var center := rect.get_center()
	check(cam._pan_for_pointer(center, rect) == Vector2.ZERO, "center pointer is neutral")
	check(cam._pan_for_pointer(center + rect.size * Vector2(0.04, 0.02), rect) == Vector2.ZERO, "inner deadzone prevents minor pointer drift")
	var right: Vector2 = cam._pan_for_pointer(center + Vector2(rect.size.x * 0.45, 0), rect)
	var left: Vector2 = cam._pan_for_pointer(center - Vector2(rect.size.x * 0.45, 0), rect)
	var up: Vector2 = cam._pan_for_pointer(center - Vector2(0, rect.size.y * 0.45), rect)
	var down: Vector2 = cam._pan_for_pointer(center + Vector2(0, rect.size.y * 0.45), rect)
	check(right.x > 0.0 and right.y == 0.0 and right.is_equal_approx(-left), "horizontal pan is directional and symmetric")
	check(up.y < 0.0 and up.x == 0.0 and up.is_equal_approx(-down), "vertical pan is directional and symmetric")
	var diagonal: Vector2 = cam._pan_for_pointer(rect.end - Vector2.ONE, rect)
	check(diagonal.x > 0.0 and diagonal.y > 0.0 and (diagonal / cam.mouse_pan_max_distance).length() <= 1.0001, "diagonal pan stays within configured ellipse")
	check(cam._pan_for_pointer(rect.end + Vector2(10, 10), rect) == Vector2.ZERO, "pointer outside game viewport cannot drag camera")
	for size in [Vector2(1920, 1080), Vector2(1920, 1200), Vector2(2560, 1080)]:
		var sample: Vector2 = cam._pan_for_pointer(size * Vector2(0.9, 0.5), Rect2(Vector2.ZERO, size))
		check(sample.is_equal_approx(cam._pan_for_pointer(Vector2(1920, 1080) * Vector2(0.9, 0.5), Rect2(0, 0, 1920, 1080))), "normalized pan agrees across viewport " + str(size))
	mode(Input.MOUSE_MODE_HIDDEN, "gameplay keeps cursor hidden")
	await pointer_at(Vector2(0.9, 0.2))
	await wait(0.6)
	if rendered:
		check(cam._mouse_pan.x > 15.0 and cam._mouse_pan.y < -5.0, "real hidden pointer pans camera up and right")
		var desired: Vector2 = cam._pan_for_pointer(get_viewport().get_mouse_position(), rect)
		p.position.x += 200.0
		await wait(0.8)
		check(cam._mouse_pan.distance_to(desired) < 1.0, "camera movement does not amplify mouse offset")
		check((cam.offset - cam._base_offset).is_equal_approx(cam._mouse_pan), "mouse offset is additive to original camera framing")
		await capture("pan-right-up")
	var master = p.get_node("Camera2D/UI_Layer/master_menu")
	var pause = p.get_node("Camera2D/UI_Layer/PauseMenu")
	await action(&"toggle_master_menu")
	check(master.visible and get_tree().paused, "real B input opens and pauses inventory")
	mode(Input.MOUSE_MODE_VISIBLE, "B menu shows cursor")
	await centered("B menu")
	await wait(0.3)
	await pointer_at(Vector2(0.72, 0.62))
	var moved_pointer := get_viewport().get_mouse_position()
	p.refresh_gameplay_cursor()
	await frames(3)
	if rendered: check(get_viewport().get_mouse_position().distance_to(moved_pointer) <= 2.0, "ordinary cursor refresh does not pin an open menu pointer")
	await action(&"toggle_master_menu")
	await wait(0.3)
	check(not master.visible and not get_tree().paused, "B closes inventory")
	mode(Input.MOUSE_MODE_HIDDEN, "closing B hides cursor")
	await centered("closing B neutralizes pan")
	await wait(0.7)
	check(cam._mouse_pan.length() < 1.0, "menu exit returns mouse pan to neutral")
	await pointer_at(Vector2(0.15, 0.8))
	await action(&"ui_cancel")
	check(pause.visible and get_tree().paused, "real Esc opens pause")
	mode(Input.MOUSE_MODE_VISIBLE, "pause shows cursor")
	await centered("pause")
	var paused_pan: Vector2 = cam._mouse_pan
	await pointer_at(Vector2(0.88, 0.13))
	await wait(0.15)
	check(cam._mouse_pan == paused_pan, "moving mouse in pause cannot move camera")
	await capture("pause-centered")
	await action(&"ui_cancel")
	check(not pause.visible and not get_tree().paused, "Esc resumes game")
	await centered("pause exit neutralizes pan")
	await pointer_at(Vector2(0.2, 0.15))
	var camp = scene.get_node("Campfire")
	p.position = Vector2(369, 836)
	p.set_physics_process(true)
	await wait(0.15)
	camp._player = p
	camp._player_in_range = true
	camp._rest_cooldown = 0.0
	camp.enter_fade_out_duration = 0.04
	camp.enter_fade_in_duration = 0.12
	camp.leave_fade_duration = 0.06
	await action(&"interact")
	check(camp._phase == camp.Phase.ENTERING and not p._campfire_cursor_ready, "campfire entry keeps cursor gated during fade")
	mode(Input.MOUSE_MODE_HIDDEN, "campfire fade keeps cursor hidden")
	await wait(0.22)
	check(camp.is_menu_ready() and p._campfire_cursor_ready, "campfire reveals UI after fade")
	mode(Input.MOUSE_MODE_VISIBLE, "ready campfire shows cursor")
	await centered("campfire ready")
	check(get_viewport().get_camera_2d() != cam, "campfire retains its cinematic camera")
	await pointer_at(Vector2(0.85, 0.85))
	await wait(0.3)
	check(cam._mouse_pan.length() < 3.0, "campfire disables gameplay mouse pan")
	camp.btn_leave.pressed.emit()
	await wait(0.18)
	check(not camp.is_ui_active() and not p.is_resting, "leave restores gameplay")
	mode(Input.MOUSE_MODE_HIDDEN, "leaving campfire hides cursor")
	await centered("campfire exit neutralizes pan")
	await pointer_at(Vector2(0.87, 0.17))
	check(SaveManager.return_to_title(), "return-to-title transition succeeds")
	await wait(0.3)
	mode(Input.MOUSE_MODE_VISIBLE, "title shows cursor")
	await centered("title screen")
	print("MOUSE CAMERA RESULT checks=", checks, " failures=", failures, " display=", DisplayServer.get_name())
	get_tree().quit(1 if failures else 0)
