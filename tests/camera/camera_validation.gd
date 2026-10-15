extends Node
var checks := 0
var failures := 0
var scene: Node2D
var p
var cam
var enemy
var home := Vector2.ZERO
var events: Array[StringName] = []
var render_fps := 120

class LegacyEffects:
	extends Node
	var calls := 0
	func trigger_impact_shake(_strength: float) -> void:
		calls += 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not String(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("CodexCamera"):
		get_tree().quit(2)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--camera-fps="): render_fps = int(argument.get_slice("=", 1))
	Engine.max_fps = render_fps
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("CAMERA ", "PASS " if ok else "FAIL ", label)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://camera-" + label + ".png")

func fixture() -> void:
	if is_instance_valid(scene):
		scene.queue_free()
		await frames(2)
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	await frames(45)
	home = p.global_position
	cam = p.get_node("Camera2D")
	p.camera_feedback.connect(func(event: StringName, _dir: Vector2): events.append(event))
	p.get_node("Camera2D/hud").set_process(false)
	p.vitals.simulation_enabled = false

func manual_reset() -> void:
	CombatTime.remove(self)
	CombatTime.set_actor_exempt(p, false)
	Engine.time_scale = 1.0
	p.global_position = home
	p.velocity = Vector2.ZERO
	cam.reset_camera()
	cam._was_current = true

func advance(count: int, dt: float) -> void:
	for i in count: cam._process(dt)

func root_in_safe_frame() -> bool:
	var distance: Vector2 = (p.global_position - cam.get_screen_center_position()) * cam.zoom
	var half: Vector2 = cam.get_viewport_rect().size * (0.5 - cam.safe_screen_margin)
	return absf(distance.x) <= half.x + 0.5 and absf(distance.y) <= half.y + 0.5

func frame_inside(bounds: Rect2) -> bool:
	var half: Vector2 = cam._view_size() * 0.5
	var center: Vector2 = cam.get_screen_center_position()
	return bounds.grow(0.5).encloses(Rect2(center - half, half * 2.0))

func response_at(fps: int) -> Vector2:
	manual_reset()
	p.position.x += 400.0
	advance(fps, 1.0 / fps)
	return cam.global_position

func _run() -> void:
	await fixture()
	check(cam.get_script().resource_path == "res://scenes/camera_2d.gd", "real player loads upgraded camera")
	check(cam.zoom.is_equal_approx(Vector2(1.05, 1.05)), "authored base zoom retained")
	check(cam._base_offset.is_equal_approx(Vector2(0, -234.71)), "authored vertical framing retained")
	await capture("baseline")
	for room in get_tree().get_nodes_in_group(&"camera_rooms"): room.queue_free()
	await frames(2)
	p.set_physics_process(false)
	cam.set_process(false)
	manual_reset()
	var initial: Vector2 = cam.global_position
	p._set_facing_direction(-1)
	advance(60, 1.0 / 60.0)
	check(cam.global_position.is_equal_approx(initial), "turning at rest does not pan camera")
	p.velocity.x = 400.0
	for i in 60:
		p.position.x += 400.0 / 60.0
		cam._process(1.0 / 60.0)
	check(cam._look_direction == 1 and cam._lookahead > 0.0, "walking establishes forward focus")
	check(root_in_safe_frame(), "walking remains within safe frame")
	p.velocity.x = -400.0
	advance(3, 1.0 / 60.0)
	check(cam._look_direction == 1, "brief reversal does not immediately flip focus")
	advance(12, 1.0 / 60.0)
	check(cam._look_direction == -1, "sustained reversal changes focus")
	manual_reset()
	p.velocity.x = 400.0
	advance(15, 1.0 / 60.0)
	p.state_machine.transition(AdelStateMachine.State.KNOCKBACK)
	p.velocity.x = -400.0
	advance(20, 1.0 / 60.0)
	check(cam._look_direction == 1, "knockback does not reverse lookahead away from attacker")
	p.state_machine.resume_locomotion()
	manual_reset()
	p.velocity.x = 2811.0
	var always_safe := true
	for i in 30:
		p.position.x += p.velocity.x / 60.0
		cam._process(1.0 / 60.0)
		always_safe = always_safe and root_in_safe_frame()
	check(always_safe, "2811px/s lunge remains readable through acceleration")
	var at_30 := response_at(30)
	var at_60 := response_at(60)
	var at_120 := response_at(120)
	check(at_30.distance_to(at_60) < 0.02 and at_60.distance_to(at_120) < 0.02, "static-target damping is consistent at 30/60/120 steps")
	manual_reset()
	p.velocity = Vector2(0, -500)
	p.move_and_slide()
	p.position = home
	cam.reset_camera()
	var ground_y: float = cam.global_position.y
	p.position.y -= 60.0
	advance(12, 1.0 / 60.0)
	check(absf(cam.global_position.y - ground_y) < 1.0, "small airborne jump retains platform height")
	p.velocity.y = 900.0
	for i in 40:
		p.position.y += 15.0
		cam._process(1.0 / 60.0)
	check(cam.global_position.y > ground_y + 200.0 and root_in_safe_frame(), "long fall catches up and keeps player in frame")
	var fall_screen_y: float = 0.5 + (p.global_position.y - cam.get_screen_center_position().y) / cam._view_size().y
	check(fall_screen_y < 0.74, "long fall opens landing view beyond ordinary framing")
	manual_reset()
	var expected: Vector2 = response_at(60)
	manual_reset()
	p.position.x += 400.0
	CombatTime.set_actor_exempt(p, true)
	CombatTime.request(self, &"skill_recovery", 0.5, 2.0)
	advance(60, 1.0 / 120.0)
	check(cam.global_position.distance_to(expected) < 0.02, "actor-exempt follow keeps normal response in world slow motion")
	manual_reset()
	var before_stop: Vector2 = cam.global_position
	p.position.x += 80.0
	CombatTime.request(self, &"hit_stop", 0.05, 1.0)
	cam.feedback(&"deflect", Vector2.RIGHT)
	advance(12, 0.05 / 60.0)
	check(cam.global_position.is_equal_approx(before_stop), "hitstop holds base camera framing")
	check(cam.impulses.shake_pixels == Vector2.ZERO, "impact shake expires in real time during hitstop")
	manual_reset()
	for i in 32: cam.feedback(&"stagger", Vector2.RIGHT)
	cam._process(1.0 / 120.0)
	check(cam.impulses._impulses.size() <= 8 and cam.impulses.shake_pixels.length() <= cam.feedback_profile.maximum_shake_pixels + 0.0001, "repeated impacts have bounded memory and amplitude")
	advance(60, 1.0 / 60.0)
	check(cam.impulses._impulses.is_empty() and cam.offset.is_equal_approx(cam._base_offset), "shake returns exactly to authored offset")
	cam.feedback(&"stagger")
	cam._process(0.30)
	check(cam.impulses._impulses.is_empty(), "a slow render frame does not prolong impact feedback")
	cam.feedback(&"deflect")
	advance(4, 1.0 / 60.0)
	check(cam.zoom.x > 1.05, "successful deflect produces subtle zoom accent")
	advance(90, 1.0 / 60.0)
	check(absf(cam.zoom.x - 1.05) < 0.0001, "zoom settles to baseline without drift")
	cam.feedback(&"deflect")
	cam.reset_camera()
	check(cam.impulses._impulses.is_empty() and cam.zoom.is_equal_approx(Vector2(1.05, 1.05)), "reset clears all transient effects")
	var room := CameraRoom.new()
	room.activation_rect = Rect2(-5000, -5000, 10000, 10000)
	room.view_bounds = Rect2(-1200, -1400, 3200, 2400)
	scene.add_child(room)
	cam.reset_camera()
	check(cam.active_room == room, "camera acquires explicit room")
	p.position = room.view_bounds.end - Vector2(15, 15)
	cam.reset_camera()
	cam.feedback(&"stagger", Vector2.ONE)
	var contained := true
	for i in 24:
		cam._process(1.0 / 60.0)
		contained = contained and frame_inside(room.world_bounds())
	check(contained, "room containment includes shake at both edges")
	room.view_bounds = Rect2(home - Vector2(400, 300), Vector2(800, 600))
	p.position = home
	cam.reset_camera()
	check(frame_inside(room.world_bounds()) and cam.zoom.x > 2.0, "small room fits viewport instead of exposing outside bounds")
	var priority_room := CameraRoom.new()
	priority_room.room_priority = 2
	priority_room.activation_rect = Rect2(home - Vector2(80, 80), Vector2(160, 160))
	priority_room.view_bounds = Rect2(-1400, -1500, 3600, 3000)
	scene.add_child(priority_room)
	cam._process(1.0 / 60.0)
	check(cam.active_room == priority_room, "higher-priority room wins overlap")
	p.position.x += 100.0
	advance(30, 1.0 / 60.0)
	check(cam.active_room == priority_room, "room exit hysteresis prevents border oscillation")
	priority_room.queue_free()
	room.queue_free()
	await frames(2)
	manual_reset()
	CameraMotionPreferences.shake_strength = 0.0
	CameraMotionPreferences.dynamic_zoom = false
	cam.feedback(&"deflect", Vector2.RIGHT)
	advance(3, 1.0 / 60.0)
	check(cam.offset.is_equal_approx(cam._base_offset) and cam.zoom.is_equal_approx(Vector2(1.05, 1.05)), "motion settings disable shake and dynamic zoom")
	CameraMotionPreferences.shake_strength = 1.0
	CameraMotionPreferences.dynamic_zoom = true
	CameraMotionPreferences.reduced_motion = true
	cam.reset_camera()
	cam.feedback(&"deflect", Vector2.RIGHT)
	advance(3, 1.0 / 60.0)
	check(cam.zoom.is_equal_approx(Vector2(1.05, 1.05)), "reduced motion suppresses combat zoom")
	CameraMotionPreferences.reduced_motion = false
	await fixture()
	var hud: Node = p.get_node("Camera2D/hud")
	var hud_position: Vector2 = hud.get_node("ScreenSpace/bar").get_global_transform_with_canvas().origin
	cam.feedback(&"stagger", Vector2.RIGHT)
	await frames(2)
	check(hud.get_node("ScreenSpace/bar").get_global_transform_with_canvas().origin.is_equal_approx(hud_position), "world shake does not move HUD")
	get_tree().paused = true
	var paused_position: Vector2 = cam.global_position
	var paused_zoom: Vector2 = cam.zoom
	var paused_shake: Vector2 = cam.impulses.shake_pixels
	await wait(0.2)
	check(cam.global_position == paused_position and cam.zoom == paused_zoom and cam.impulses.shake_pixels == paused_shake, "pause freezes camera and effects")
	get_tree().paused = false
	await frames(20)
	check(cam.impulses._impulses.is_empty(), "effects resume and finish after unpause")
	var options: Node = p.get_node("Camera2D/UI_Layer/PauseMenu/VBoxContainer/CameraOptions")
	check(options.get_node("DynamicZoom").button_pressed and options.get_node("Shake/Strength").value == 100.0, "pause controls reflect default preferences")
	options.get_node("Shake/Strength").value = 35.0
	options.get_node("DynamicZoom").button_pressed = false
	check(CameraMotionPreferences.shake_strength == 0.35 and not CameraMotionPreferences.dynamic_zoom, "pause controls update shared camera preferences")
	var second_options = load("res://scenes/camera/camera_options.tscn").instantiate()
	scene.add_child(second_options)
	check(second_options.get_node("Shake/Strength").value == 35.0 and not second_options.get_node("DynamicZoom").button_pressed, "new menu instances reflect saved values")
	second_options.queue_free()
	var config := ConfigFile.new()
	check(config.load(CameraMotionPreferences.PATH) == OK and config.get_value("camera", "shake_strength") == 0.35, "camera preferences persist separately from checkpoints")
	CameraMotionPreferences.store(1.0, true, false)
	p.get_node("Camera2D/UI_Layer/PauseMenu").pause_and_unpause()
	await frames(2)
	await capture("pause-options")
	p.get_node("Camera2D/UI_Layer/PauseMenu").pause_and_unpause()
	await frames(2)
	var legacy_fx := LegacyEffects.new()
	legacy_fx.name = "ScreenEffects"
	scene.add_child(legacy_fx)
	cam.reset_camera()
	hud._trigger_impact_feedback(hud.SCREEN_SHAKE_STAGGER)
	check(legacy_fx.calls == 0 and cam.impulses._impulses.is_empty(), "HUD avoids duplicate world stagger shake")
	hud._trigger_impact_feedback(hud.SCREEN_SHAKE_FLASK)
	check(legacy_fx.calls == 0 and cam.impulses._impulses.size() == 1, "flask uses camera feedback without legacy double shake")
	events.clear()
	enemy.position = p.position + Vector2(70, 0)
	enemy.current_health = 1000
	p._set_facing_direction(1)
	p.combat.combo_step = 1
	p._play_combo_step()
	await wait(0.8)
	check(events.count(&"attack") == 1 and enemy.current_health < 1000, "normal attack emits one camera impact on real damage")
	await wait(0.5)
	p.restore_checkpoint_state(home, false)
	hud.restore_stamina_full()
	await frames(3)
	events.clear()
	p.defense.begin_guard(0.15)
	p.take_damage(20, p.position + Vector2(80, 0))
	check(events.count(&"deflect") == 1, "accepted deflect reaches camera feedback")
	await frames(4)
	await capture("deflect")
	await wait(0.6)
	p.restore_checkpoint_state(home, false)
	await frames(3)
	events.clear()
	enemy.position = p.position + Vector2(230, 0)
	enemy.current_health = 1000
	Input.action_press("weapon_skill")
	check(p.saber_skill.begin(), "charged Q starts in real player state machine")
	await wait(p.saber_skill.charge_level_1_time + 0.12)
	check(cam.zoom.x < 1.05, "charged skill opens view before lunge")
	await capture("charge")
	Input.action_release("weapon_skill")
	p.saber_skill.release()
	await wait(1.0)
	check(events.count(&"skill_charged") == 1 and enemy.current_health < 1000, "charged Q emits one impact after real collision")
	check(not p.saber_skill.is_active() and Engine.time_scale == 1.0, "skill and slow motion finish without camera changing combat clock")
	cam.feedback(&"stagger")
	p.restore_checkpoint_state(home + Vector2(220, 0), false)
	check(cam.impulses._impulses.is_empty() and cam.zoom.is_equal_approx(Vector2(1.05, 1.05)), "checkpoint relocation resets camera immediately")
	await aspect_checks()
	await playground_checks()
	await frames(10)
	await wait(1.2)
	print("CAMERA RENDER display=", DisplayServer.get_name(), " requested_fps=", render_fps, " observed_recent_fps=", Engine.get_frames_per_second(), " viewport=", get_viewport().get_visible_rect().size)
	print("CAMERA RESULT checks=", checks, " failures=", failures)
	get_tree().quit(1 if failures else 0)

func aspect_checks() -> void:
	for size in [Vector2i(1920, 1080), Vector2i(1920, 1200), Vector2i(2560, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = size
		add_child(viewport)
		var actor := CharacterBody2D.new()
		actor.position = Vector2(1450, 900)
		viewport.add_child(actor)
		var camera = load("res://scenes/camera_2d.gd").new()
		camera.zoom = Vector2(1.05, 1.05)
		camera.offset = Vector2(0, -234.71)
		camera.room_bounds_enabled = true
		camera.room_bounds = Rect2(-1600, -1400, 6000, 4000)
		actor.add_child(camera)
		camera.make_current()
		camera.set_process(false)
		camera.reset_camera()
		camera.feedback(&"stagger", Vector2.ONE)
		var contained := true
		for i in 20:
			camera._process(1.0 / 60.0)
			var half: Vector2 = camera._view_size() * 0.5
			contained = contained and camera.room_bounds.grow(0.5).encloses(Rect2(camera.get_screen_center_position() - half, half * 2.0))
		check(contained, "bounds honor viewport aspect " + str(size))
		viewport.queue_free()
		await frames(1)

func playground_checks() -> void:
	scene.queue_free()
	await frames(2)
	scene = load("res://scenes/camera/camera_playground.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	await frames(45)
	cam = p.get_node("Camera2D")
	check(cam.is_current() and cam.active_room != null, "playground loads real actor and camera room")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F1
	key.pressed = true
	scene._unhandled_key_input(key)
	check(cam.show_debug_zones, "playground F1 toggles debugging zones")
	scene._unhandled_key_input(key)
	enemy.queue_free()
	await frames(2)
	key.physical_keycode = KEY_R
	var save_path := SaveManager.get_save_path(1)
	var save_before := FileAccess.get_file_as_string(save_path) if FileAccess.file_exists(save_path) else "<absent>"
	scene._unhandled_key_input(key)
	check(is_instance_valid(scene.enemy) and scene.enemy.current_health > 0, "playground R recreates a defeated enemy")
	scene.enemy.set_physics_process(false)
	var shape: CollisionShape2D = p.get_node("CollisionShape2D")
	var feet_y: float = shape.global_position.y + p._capsule_half_height(shape)
	var save_after := FileAccess.get_file_as_string(save_path) if FileAccess.file_exists(save_path) else "<absent>"
	check(absf(p.global_position.x - 300.0) < 0.1 and absf(feet_y - 600.0) < 0.1 and save_before == save_after, "playground R restores grounded player without writing save")
	await frames(10)
	await capture("playground")
