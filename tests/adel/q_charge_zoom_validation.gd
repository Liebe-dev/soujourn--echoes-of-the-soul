extends SceneTree
const S = AdelStateMachine.State
const Debug = preload("res://scenes/enemy/enemy_debug_settings.gd")
var checks: int = 0
var failures: int = 0
var scene: Node2D
var player: CharacterBody2D
var skill: Node
var camera: Camera2D
var enemy: CharacterBody2D
var origin: Vector2
var base_zoom: Vector2
var capture_dir: String = ""
var time_effects: Node

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexQChargeZoom20261026"):
		push_error("Run only in an isolated QChargeZoom project/user directory.")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): capture_dir = arg.trim_prefix("--capture=")
	create_timer(45.0, true, false, true).timeout.connect(func():
		push_error("Q charge zoom suite timed out.")
		quit(1))
	if await _run() != true: check(false, "suite completes without a runtime error")
	print("Q CHARGE ZOOM RESULT checks=", checks, " failures=", failures)
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("Q CHARGE ZOOM ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 1) -> void:
	for i in count:
		await physics_frame
		await process_frame

func wait_real(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout

func until(condition: Callable, timeout: float = 3.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if condition.call(): return true
		await process_frame
	return false

func input(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames()

func capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join(label + ".png"))

func reset(hit: bool = false) -> void:
	paused = false
	time_effects.remove(scene)
	for action in [&"weapon_skill", &"attack", &"guard and deflect", &"move_left", &"move_right"]:
		Input.action_release(action)
	player.restore_checkpoint_state(origin, false)
	player.vitals.simulation_enabled = false
	player.hit_stop_enabled = false
	player.stagger_zoom_enabled = false
	player.stagger_slow_motion_enabled = false
	player.stats.heal_to_full()
	skill.charge_zoom_enabled = true
	skill.charge_level_1_zoom_multiplier = 1.12
	skill.charge_level_2_zoom_multiplier = 1.25
	skill.charge_zoom_in_duration = 0.12
	skill.charge_zoom_out_duration = 0.18
	enemy.position = origin + Vector2(155.0 if hit else 4000.0, 0.0)
	enemy.current_health = 1000
	await frames(4)

func begin_charge() -> void:
	await input(&"weapon_skill", true)
	check(await until(func(): return skill.is_active()), "real Q input starts the charge")

func level_1() -> void:
	await begin_charge()
	check(await until(func(): return camera.zoom.is_equal_approx(base_zoom * 1.12)), "level 1 reaches its configured charge zoom")

func check_zoom_curve() -> void:
	for multiplier: float in [1.12, 1.25]:
		skill._charge_zoom.hold(camera, multiplier, 0.12)
		var previous: float = 1.0
		var previous_step: float = INF
		for step: int in range(1, 6):
			skill._charge_zoom._apply(float(step) / 5.0)
			var current: float = camera.zoom.x / base_zoom.x
			var advance: float = current - previous
			check(advance > 0.0 and advance < previous_step, "%.2fx zoom slows down across equal time interval %d" % [multiplier, step])
			if step == 1:
				check(advance > (multiplier - 1.0) * 0.6, "%.2fx zoom pulls in strongly during its first fifth" % multiplier)
			previous = current
			previous_step = advance
		check(camera.zoom.is_equal_approx(base_zoom * multiplier), "%.2fx ease-out reaches the exact target without overshoot" % multiplier)
		skill._charge_zoom.cancel()

func _run() -> bool:
	Engine.max_fps = 144
	time_effects = root.get_node("CombatTime")
	Debug.ai_disabled = true
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate() as Node2D
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("PlayableAdel") as CharacterBody2D
	skill = player.saber_skill
	camera = player.get_node("Camera2D") as Camera2D
	enemy = scene.get_node("Enemy") as CharacterBody2D
	for actor: Node in get_nodes_in_group("camera_lock_targets"):
		actor.set_physics_process(false)
		actor.position.x += 6000.0
	scene.get_node("Instructions").hide()
	player.vitals.simulation_enabled = false
	await frames(65)
	origin = player.position
	base_zoom = camera.zoom
	check(skill.charge_level_1_time == 0.7 and skill.charge_level_2_time == 1.5 and skill.lunge_speed == 2811.0, "authored charge times and lunge speed are preserved")
	check(skill.tap_cooldown == 4.0 and skill.charged_cooldown == 6.0 and skill.full_cooldown == 8.0, "authored cooldowns are preserved")
	check(skill.charged_impact_zoom_multiplier == 1.3 and skill.full_impact_zoom_multiplier == 1.5, "authored impact zooms are preserved")
	# Independent presentation scenarios do not wait for production cooldowns.
	skill.tap_cooldown = 0.0
	skill.charged_cooldown = 0.0
	skill.full_cooldown = 0.0
	await reset()
	check_zoom_curve()
	await capture("before-charge")
	await begin_charge()
	await wait_real(0.35)
	check(camera.zoom.is_equal_approx(base_zoom) and not camera.has_combat_zoom(&"skill_charge"), "tap and early charge do not zoom")
	check(await until(func(): return camera.zoom.is_equal_approx(base_zoom * 1.12)), "holding into level 1 zooms smoothly")
	check(player.state_machine.current == S.SKILL_CHARGE and not paused and Engine.time_scale == 1.0, "charge zoom does not change gameplay time or state")
	await capture("charge-level-1")
	check(await until(func(): return camera.zoom.is_equal_approx(base_zoom * 1.25)), "final level 2 pose adds the second zoom")
	check(player.state_machine.current == S.SKILL_CHARGE and player.spine_anim.assigned_animation == &"saber_skill_3", "level 2 zoom is visible before auto-lunge")
	await capture("charge-level-2")
	check(await until(func(): return player.state_machine.current != S.SKILL_CHARGE), "full charge still auto-releases")
	check(await until(func(): return not camera.has_combat_zoom(&"skill_charge")), "auto-release clears the charge source after its smooth return")
	check(camera.zoom.is_equal_approx(base_zoom) and not paused, "a full-charge miss returns to the original camera without a freeze")

	await reset()
	await level_1()
	await input(&"weapon_skill", false)
	check(await until(func(): return skill._charge_zoom._returning), "level 1 release starts the charge zoom return when lunging")
	check(camera.zoom.x > base_zoom.x, "release does not snap straight to base zoom")
	check(await until(func(): return not camera.has_combat_zoom(&"skill_charge")), "released level 1 returns fully")
	check(camera.zoom.is_equal_approx(base_zoom), "released level 1 restores the exact base")

	await reset()
	await begin_charge()
	await input(&"weapon_skill", false)
	await wait_real(0.4)
	check(camera.zoom.is_equal_approx(base_zoom) and not camera.has_combat_zoom(&"skill_charge"), "tap release never creates a charge zoom")

	await reset()
	await level_1()
	skill.charge_zoom_enabled = false
	await frames(2)
	check(not camera.has_combat_zoom(&"skill_charge") and camera.zoom.is_equal_approx(base_zoom), "disabling charge zoom during a hold clears it")
	skill.charge_zoom_enabled = true
	check(await until(func(): return camera.zoom.is_equal_approx(base_zoom * 1.12)), "reenabling resumes the current charge tier")

	await reset()
	skill.charge_level_1_zoom_multiplier = 1.0
	skill.charge_level_2_zoom_multiplier = 1.0
	await begin_charge()
	await wait_real(1.36)
	check(camera.zoom.is_equal_approx(base_zoom) and not camera.has_combat_zoom(&"skill_charge"), "multipliers of one leave no ineffective zoom source")

	await reset()
	skill.charge_zoom_in_duration = 0.0
	skill.charge_zoom_out_duration = 0.0
	await begin_charge()
	check(await until(func(): return camera.zoom.is_equal_approx(base_zoom * 1.12)), "zero rise duration applies the requested tier immediately")
	await input(&"weapon_skill", false)
	check(await until(func(): return player.state_machine.current == S.SKILL_DASH or player.state_machine.current == S.SKILL_RECOVERY), "zero-duration scenario reaches lunge")
	check(not camera.has_combat_zoom(&"skill_charge"), "zero return duration clears the source without an error")

	await reset()
	await begin_charge()
	check(await until(func(): return camera.has_combat_zoom(&"skill_charge")), "pause scenario reaches zoom transition")
	await wait_real(0.025)
	paused = true
	var paused_zoom := camera.zoom
	var paused_charge: float = skill.charge_time
	await wait_real(0.25)
	check(camera.zoom == paused_zoom and skill.charge_time == paused_charge, "pause freezes both the charge and its camera transition")
	paused = false
	check(await until(func(): return camera.zoom.is_equal_approx(base_zoom * 1.12)), "resume completes the zoom without counting paused time")

	await reset()
	await begin_charge()
	check(await until(func(): return camera.has_combat_zoom(&"skill_charge")), "slow-motion scenario reaches first tier")
	time_effects.request(scene, &"charge_zoom_test", 0.1, 0.5)
	await wait_real(0.17)
	check(camera.zoom.is_equal_approx(base_zoom * 1.12) and skill.charge_time < 0.9, "visual transition uses real time while charge follows game time")
	time_effects.remove(scene)

	await reset()
	await level_1()
	camera.set_combat_zoom(&"test_other_owner", 1.4)
	check(camera.zoom.is_equal_approx(base_zoom * 1.4), "camera takes the maximum source instead of multiplying zooms")
	player.clear_combat_input()
	check(not camera.has_combat_zoom(&"skill_charge") and camera.has_combat_zoom(&"test_other_owner"), "cancelling Q clears only its charge source")
	check(camera.zoom.is_equal_approx(base_zoom * 1.4), "Q cancellation preserves another effect's zoom")
	camera.clear_combat_zoom(&"test_other_owner")

	await reset()
	await level_1()
	player._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await frames(2)
	check(not skill.is_active() and not camera.has_combat_zoom(&"skill_charge"), "focus loss cleans charge zoom and input")
	await reset()
	await level_1()
	player.restore_checkpoint_state(origin, false)
	check(camera.zoom.is_equal_approx(base_zoom) and not camera.has_combat_zoom(&"skill_charge"), "checkpoint restoration cannot keep a stale charge zoom")

	for tier: int in [1, 2]:
		await reset(true)
		await level_1()
		if tier == 1: await input(&"weapon_skill", false)
		check(await until(func(): return skill._charged_finish.returning, 4.0), "charge %d hit still enters its existing impact return" % tier)
		check(not camera.has_combat_zoom(&"skill_charge") and paused, "charge %d does not leave a zoom floor during the frozen impact return" % tier)
		check(await until(func(): return not paused, 2.0), "impact return %d releases its own pause" % tier)
		check(camera.zoom.is_equal_approx(base_zoom) and not camera.has_combat_zoom(&"skill_impact"), "impact return %d reaches base without a stale source" % tier)

	await reset()
	await level_1()
	var alternate := Camera2D.new()
	scene.add_child(alternate)
	alternate.make_current()
	await frames(2)
	check(not camera.has_combat_zoom(&"skill_charge"), "losing the current camera clears the charge effect")
	alternate.queue_free()
	camera.make_current()
	await frames(2)
	await reset()
	await level_1()
	# Exercise the helper's exit cleanup independently of the active skill owner.
	player.clear_combat_input()
	var temporary_zoom := preload("res://scenes/adel/components/skill_charge_zoom.gd").new()
	scene.add_child(temporary_zoom)
	temporary_zoom.hold(camera, 1.12, 0.0)
	temporary_zoom.queue_free()
	await frames(2)
	check(camera.zoom.is_equal_approx(base_zoom) and not camera.has_combat_zoom(&"skill_charge"), "freeing the zoom owner clears its source")
	return true
