extends Node
var checks := 0
var failures := 0
var rendered := false
var world: Node2D
var player
var camera
var lock
var near_enemy
var right_enemy
var up_enemy
var left_enemy

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not String(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("CodexLockCamera"):
		get_tree().quit(2)
		return
	rendered = DisplayServer.get_name() != "headless"
	Engine.max_fps = 60
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("LOCK CAMERA ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 3) -> void:
	for i in count: await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func spawn_enemy(pos: Vector2, spine: bool = false):
	var enemy
	if spine:
		enemy = load("res://scenes/enemy/spine_enemy.tscn").instantiate()
	else:
		enemy = load("res://scenes/enemy/enemy_base.gd").new()
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		shape.position = Vector2(-5, -25)
		var capsule := CapsuleShape2D.new()
		capsule.radius = 16
		capsule.height = 48
		shape.shape = capsule
		enemy.add_child(shape)
		var visual := Polygon2D.new()
		visual.polygon = PackedVector2Array([Vector2(-20, 0), Vector2(0, -45), Vector2(20, 0)])
		visual.color = Color(0.65, 0.3, 0.24)
		enemy.add_child(visual)
	enemy.position = pos
	enemy.exp_reward = 0
	world.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

func click_middle(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_MIDDLE
	event.pressed = pressed
	event.position = get_viewport().get_mouse_position()
	Input.parse_input_event(event)
	await frames()

func move_middle(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.position = get_viewport().get_mouse_position() + relative
	event.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	Input.parse_input_event(event)
	await frames()

func action(name: StringName) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventAction.new()
	event.action = name
	Input.parse_input_event(event)
	await frames()

func capture(label: String) -> void:
	if not rendered: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://lock-camera-" + label + ".png")

func run() -> void:
	if rendered:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1280, 720)
		get_window().position = Vector2i(40, 40)
		get_window().grab_focus()
		await wait(0.2)
		check(get_window().has_focus(), "native test window focused")
	var prefs = load("res://scenes/camera/camera_preferences.gd")
	if FileAccess.file_exists(prefs.PATH): DirAccess.remove_absolute(prefs.PATH)
	world = Node2D.new()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	player = load("res://scenes/adel/playable_adel.tscn").instantiate()
	player.position = Vector2(1000, 600)
	world.add_child(player)
	player.set_physics_process(false)
	camera = player.get_node("Camera2D")
	camera.set_physics_process(false)
	lock = camera.target_lock
	lock.set_process(false)
	camera.force_update_scroll()
	near_enemy = spawn_enemy(Vector2(1160, 600), true)
	right_enemy = spawn_enemy(Vector2(1440, 600))
	up_enemy = spawn_enemy(Vector2(1160, 320))
	left_enemy = spawn_enemy(Vector2(760, 600))
	var outside = spawn_enemy(Vector2(9000, 600))
	await frames()
	camera.force_update_scroll()
	check(near_enemy.is_in_group(&"camera_lock_targets"), "actual SpineEnemy registers dedicated camera group")
	check(not near_enemy.is_in_group(&"Enemy"), "registration does not enable contact damage")
	check(near_enemy.get_lock_on_point().is_equal_approx(near_enemy.get_node("CollisionShape2D").global_position), "actual enemy point is body hurtbox center")
	check(not near_enemy.get_lock_on_point().is_equal_approx(near_enemy.get_node("WeaponPivot/Hitbox/CollisionShape2D").global_position), "offensive hitbox is not used as lock point")
	check(lock.in_view(near_enemy) and not lock.in_view(outside), "only hurtbox centers inside camera are eligible")
	check(lock.nearest() == near_enemy, "nearest visible enemy measured from player hurtbox")
	near_enemy.get_node("CollisionShape2D").disabled = true
	check(not lock.valid_target(near_enemy), "disabled hurtbox cannot be targeted")
	near_enemy.get_node("CollisionShape2D").disabled = false
	near_enemy.is_dead = true
	check(not lock.valid_target(near_enemy), "dead enemy cannot be targeted")
	near_enemy.is_dead = false
	near_enemy.hide()
	check(not lock.valid_target(near_enemy), "hidden enemy cannot be targeted")
	near_enemy.show()
	check(lock.directional(near_enemy, Vector2.RIGHT) == right_enemy, "direction search uses current hurtbox as origin: right")
	check(lock.directional(near_enemy, Vector2.UP) == up_enemy, "direction search supports upper target")
	check(lock.directional(near_enemy, Vector2.DOWN) == near_enemy, "empty direction preserves existing target")
	lock.begin_gesture(1000)
	lock.finish_gesture(1050)
	check(lock.locked == near_enemy, "middle tap acquires nearest")
	lock.begin_gesture(2000)
	lock.update_gesture(Vector2(50, 0))
	check(lock.preview == right_enemy and lock.locked == near_enemy, "gesture previews without changing confirmed lock")
	lock.finish_gesture(2300)
	check(lock.locked == right_enemy, "release commits directional target")
	lock.begin_gesture(3000)
	lock.finish_gesture(3300)
	check(lock.locked == right_enemy, "hold without direction keeps target")
	lock.begin_gesture(4000)
	lock.finish_gesture(4050)
	check(lock.locked == null and not lock.mouse_pan_allowed(), "short click unlocks and suppresses stale mouse pan")
	lock.begin_gesture(5000)
	lock.update_gesture(Vector2(1, 0))
	lock.finish_gesture(5050)
	check(lock.locked == near_enemy, "tiny hand movement does not trigger switching")
	var saved_pos: Vector2 = near_enemy.position
	near_enemy.position.x = 9000
	lock.validate_lock()
	check(lock.locked == null and not lock.mouse_pan_allowed(), "leaving view clears lock and latches recenter")
	near_enemy.position = saved_pos
	lock.begin_gesture(6000)
	lock.finish_gesture(6050)
	near_enemy.current_health = 0
	lock.validate_lock()
	check(lock.locked == null, "zero HP releases lock immediately")
	near_enemy.current_health = near_enemy.max_health
	var temporary = spawn_enemy(Vector2(1020, 600))
	lock.begin_gesture(7000)
	lock.finish_gesture(7050)
	check(lock.locked == temporary, "temporary close enemy acquired")
	temporary.queue_free()
	await frames()
	lock.validate_lock()
	check(lock.locked == null and not lock.mouse_pan_allowed(), "freed target safely releases lock")
	temporary = spawn_enemy(Vector2(1020, 600))
	lock.begin_gesture(7100)
	temporary.queue_free()
	await frames()
	lock.update_gesture(Vector2(50, 0))
	lock.finish_gesture(7400)
	check(lock.locked == null, "enemy freed during selection cannot leave a stale gesture")
	camera.lock_on_enabled = false
	lock.begin_gesture(7500)
	check(not lock._holding and lock.locked == null, "Inspector can disable target lock")
	camera.lock_on_enabled = true
	lock.begin_gesture(8000)
	lock.finish_gesture(8050)
	var near_pan: Vector2 = lock.pan_for_lock()
	near_enemy.position.x += 350
	var far_pan: Vector2 = lock.pan_for_lock()
	check(far_pan.x > near_pan.x and near_pan.x > 0.0, "moving apart increases pull toward enemy")
	near_enemy.position = Vector2(10000, -10000)
	var maximum: Vector2 = lock.pan_for_lock()
	check((maximum / camera.mouse_pan_max_distance).length() <= 1.0001, "lock pull shares mouse pan maximum ellipse")
	near_enemy.position = saved_pos
	lock.clear_lock()
	camera.mouse_pan_auto_reset_enabled = true
	camera.mouse_pan_auto_reset_delay = 3.0
	var pointer := Vector2(1700, 400)
	lock._pointer = Vector2.INF
	lock.sample_pointer(pointer, 10000)
	lock.sample_pointer(pointer, 12999)
	check(lock.mouse_pan_allowed(), "stationary pointer keeps pan before 3 seconds")
	lock.sample_pointer(pointer, 13000)
	check(not lock.mouse_pan_allowed(), "stationary off-center pointer resets at 3 seconds")
	lock.sample_pointer(pointer, 15000)
	check(not lock.mouse_pan_allowed(), "idle pan stays centered until mouse moves")
	lock.sample_pointer(pointer + Vector2(1, 0), 15001)
	check(lock.mouse_pan_allowed(), "new movement re-enables mouse pan")
	camera.mouse_pan_auto_reset_enabled = false
	lock.sample_pointer(pointer, 16000)
	lock.sample_pointer(pointer, 100000)
	check(lock.mouse_pan_allowed(), "auto reset can be disabled")
	camera.apply_camera_preferences({"deadzone": 0.35, "reset_enabled": true, "reset_delay": 4.5})
	var reloaded: Dictionary = prefs.read_defaults(0.18, false, 3.0)
	check(is_equal_approx(reloaded.deadzone, 0.35) and reloaded.reset_enabled and is_equal_approx(reloaded.reset_delay, 4.5), "preferences persist independently of saves")
	var next_actor := CharacterBody2D.new()
	world.add_child(next_actor)
	var next_camera = load("res://scenes/camera_2d.gd").new()
	next_actor.add_child(next_camera)
	check(is_equal_approx(next_camera.mouse_pan_deadzone, 0.35) and is_equal_approx(next_camera.mouse_pan_auto_reset_delay, 4.5), "new player camera loads saved preferences")
	next_actor.queue_free()
	await frames()
	var rect: Rect2 = get_viewport().get_visible_rect()
	check(camera._pan_for_pointer(rect.get_center() + Vector2(rect.size.x * 0.15, 0), rect) == Vector2.ZERO, "changed deadzone updates camera mapping")
	var pause = player.get_node("Camera2D/UI_Layer/PauseMenu")
	pause.pause_and_unpause()
	check(pause.visible and get_tree().paused, "pause settings open in real pause menu")
	check(is_equal_approx(pause.get_node("VBoxContainer/CameraSettings/ResetRow/Delay").value, 4.5), "pause displays current idle duration")
	check(is_equal_approx(pause.get_node("VBoxContainer/CameraSettings/DeadzoneRow/Deadzone").value, 35.0), "pause displays current deadzone percentage")
	pause.get_node("VBoxContainer/CameraSettings/ResetRow/Delay").value = 2.0
	pause.get_node("VBoxContainer/CameraSettings/DeadzoneRow/Deadzone").value = 22.0
	pause.get_node("VBoxContainer/CameraSettings/AutoReset").button_pressed = false
	check(is_equal_approx(camera.mouse_pan_auto_reset_delay, 2.0) and is_equal_approx(camera.mouse_pan_deadzone, 0.22) and not camera.mouse_pan_auto_reset_enabled, "real pause control signals apply camera settings")
	check(not pause.get_node("VBoxContainer/CameraSettings/ResetRow/Delay").editable, "idle duration disabled when auto reset is off")
	await capture("pause-settings")
	pause.pause_and_unpause()
	if rendered: await native_input_tests(pause)
	if FileAccess.file_exists(prefs.PATH): DirAccess.remove_absolute(prefs.PATH)
	print("LOCK CAMERA RESULT checks=", checks, " failures=", failures, " display=", DisplayServer.get_name())
	get_tree().quit(1 if failures else 0)

func native_input_tests(pause) -> void:
	camera.apply_camera_preferences({"deadzone": 0.18, "reset_enabled": true, "reset_delay": 0.5}, false)
	lock.set_process(true)
	lock.clear_lock()
	await frames()
	await click_middle(true)
	await click_middle(false)
	check(lock.locked == near_enemy, "native middle input routed to acquire enemy")
	await click_middle(true)
	await move_middle(Vector2(65, 0))
	check(lock.preview == right_enemy and lock.locked == near_enemy, "native held-middle motion previews target")
	await click_middle(false)
	check(lock.locked == right_enemy, "native release confirms selected enemy")
	camera.set_physics_process(true)
	get_viewport().warp_mouse(get_viewport().get_visible_rect().size * Vector2(0.1, 0.2))
	await wait(0.4)
	check(camera._mouse_pan.x > 0.0, "locked camera pulls right despite mouse positioned left")
	await wait(0.6)
	check(lock.locked == right_enemy and camera._mouse_pan.x > 0.0, "idle reset does not cancel confirmed enemy pull")
	check(lock._reticle.visible and lock._reticle.position.distance_to(lock.screen_point(right_enemy)) < 0.1, "reticle tracks projected hurtbox center")
	await capture("locked-target")
	await click_middle(true)
	await click_middle(false)
	check(lock.locked == null, "native middle tap cancels lock")
	await wait(1.0)
	check(camera._mouse_pan.length() < 1.0, "manual unlock recenters instead of returning to stale pointer: " + str(camera._mouse_pan) + " pointer=" + str(get_viewport().get_mouse_position()) + " suppressed=" + str(lock._pan_suppressed))
	get_viewport().warp_mouse(get_viewport().get_visible_rect().size * Vector2(0.88, 0.5))
	await wait(0.25)
	check(camera._mouse_pan.x > 5.0, "moving pointer after unlock resumes panning: " + str(camera._mouse_pan) + " pointer=" + str(get_viewport().get_mouse_position()) + " focus=" + str(get_window().has_focus()))
	await wait(1.2)
	check(camera._mouse_pan.length() < 1.0, "native stationary pointer automatically recenters: " + str(camera._mouse_pan) + " pointer=" + str(get_viewport().get_mouse_position()) + " suppressed=" + str(lock._pan_suppressed))
	await click_middle(true)
	await move_middle(Vector2(60, 0))
	await action(&"ui_cancel")
	check(pause.visible and not lock._holding and not lock._reticle.visible, "pause cancels pending gesture and hides reticle")
	check(get_viewport().get_mouse_position().distance_to(get_viewport().get_visible_rect().get_center()) < 2.0, "pause cursor remains centered: " + str(get_viewport().get_mouse_position()))
	await click_middle(false)
	check(lock.locked == null, "release in UI cannot confirm stale selection")
	await action(&"ui_cancel")
	await frames()
	await click_middle(true)
	await click_middle(false)
	check(lock.locked == near_enemy, "middle lock works after pause")
	await action(&"toggle_master_menu")
	check(get_tree().paused and not lock._reticle.visible, "inventory hides reticle and disables lock input")
	await wait(0.3)
	await action(&"toggle_master_menu")
	await wait(0.3)
	check(lock.locked == near_enemy and lock._reticle.visible, "confirmed lock survives inventory pause: lock=" + str(lock.locked) + " visible=" + str(lock._reticle.visible) + " active=" + str(lock.gameplay_active()) + " mode=" + str(Input.mouse_mode))
	lock.clear_lock()
