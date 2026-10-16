extends Node
const S = AdelStateMachine.State
const Debug = preload("res://scenes/enemy/enemy_debug_settings.gd")
var checks := 0
var failures := 0
var scene
var p
var skill
var hud
var enemy
var origin: Vector2
var authored_cooldowns: Array[float] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not ProjectSettings.get_setting("application/config/use_custom_user_dir", false) or not OS.get_user_data_dir().contains("CodexQCooldown20261017"):
		get_tree().quit(2)
		return
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("Q COOLDOWN CONTEXT state=", p.state_machine.current, " clip=", p.spine_anim.assigned_animation, " velocity=", p.velocity, " active=", skill.is_active())
	print("Q COOLDOWN ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func button(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames()

func reset(hit: bool) -> void:
	for action in [&"weapon_skill", &"jump", &"move_right", &"move_left"]: await button(action, false)
	p.restore_checkpoint_state(origin, false)
	p.vitals.simulation_enabled = false
	enemy.position = origin + Vector2(155 if hit else 3000, 0)
	enemy.current_health = 1000
	p._set_facing_direction(1)
	await frames(5)

func reach_skill() -> bool:
	var deadline := Time.get_ticks_msec() + 4000
	while not skill.is_active() and Time.get_ticks_msec() < deadline: await frames()
	return skill.is_active()

func finish_skill() -> bool:
	var deadline := Time.get_ticks_msec() + 5000
	while skill.is_active() and Time.get_ticks_msec() < deadline: await frames()
	return not skill.is_active()

func launch(tier: int) -> void:
	await button(&"weapon_skill", true)
	check(skill.is_active(), "ready Q accepts fresh input tier %d" % tier)
	check(not skill.is_cooling_down(), "charging does not spend cooldown")
	var deadline := Time.get_ticks_msec() + 3000
	if tier > 0:
		while skill.charge_time < (skill.charge_level_1_time + 0.02 if tier == 1 else skill.charge_level_2_time + skill.full_charge_final_pose + 0.02) and p.state_machine.current == S.SKILL_CHARGE and Time.get_ticks_msec() < deadline: await frames()
	if tier < 2: await button(&"weapon_skill", false)
	while not skill.is_cooling_down() and skill.is_active() and Time.get_ticks_msec() < deadline: await frames()

func wait_real(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var loadout = hud.weapon_loadout
	var transform: Transform2D = loadout.get_global_transform_with_canvas()
	var rect := Rect2(transform.origin - Vector2(12, 12), loadout.REFERENCE_SIZE * transform.get_scale() + Vector2(24, 24))
	img.get_region(Rect2i(rect.intersection(Rect2(Vector2.ZERO, Vector2(img.get_size()))))).save_png("res://q-cooldown-" + label + ".png")

func cooldown_checks() -> void:
	var q = hud.weapon_loadout.get_node("Q")
	for tier in [0, 1, 2]:
		await reset(false)
		await launch(tier)
		var duration: float = [5.0, 8.0, 10.0][tier]
		check(skill.is_cooling_down() and is_equal_approx(skill.cooldown_total, duration) and skill.cooldown_remaining > duration - 0.1, "lunge commits %ss cooldown for tier %d" % [duration, tier])
		check(q.get_node("Cooldown").visible and q.get_node("Remaining").visible and q.get_node("Remaining").text != "", "actual gameplay publishes remaining time to Q HUD")
		check(q.get_node("Frame").get_theme_stylebox("panel").border_color == q.cooldown_border_color and is_equal_approx(q.get_node("Cooldown").material.get_shader_parameter("overlay_opacity"), 0.6), "cooldown uses gray border and black 60 percent overlay")
		await capture("tier-%d-start" % tier)
		check(await finish_skill(), "cooldown does not prevent current Q finishing")
		await button(&"weapon_skill", false)
		await button(&"weapon_skill", true)
		check(not skill.is_active() and not p._skill_requested and not skill.begin(), "cooldown rejects input and direct entry without buffering Q")
		var before: float = skill.cooldown_remaining
		get_tree().paused = true
		await wait_real(0.12)
		check(is_equal_approx(skill.cooldown_remaining, before) and is_equal_approx(q.remaining, before), "menu pause freezes gameplay cooldown and HUD together")
		get_tree().paused = false
		Engine.time_scale = 0.5
		var start := Time.get_ticks_usec()
		await wait_real(0.22)
		var elapsed := float(Time.get_ticks_usec() - start) / 1000000.0
		var consumed: float = before - skill.cooldown_remaining
		Engine.time_scale = 1.0
		check(absf(consumed - elapsed * 0.5) < 0.045, "cooldown follows game time during slow motion")
		hud.set_campfire_hidden(true)
		before = skill.cooldown_remaining
		await frames(5)
		check(skill.cooldown_remaining < before, "hiding HUD leaves gameplay cooldown running")
		hud.set_campfire_hidden(false)
		hud.set_sentinel_active(true)
		await frames(2)
		hud.set_sentinel_active(false)
		check(is_equal_approx(q.remaining, skill.cooldown_remaining), "normal HUD keeps cooldown when swapping Sentinel presentation")
		skill._physics_process(maxf(skill.cooldown_remaining - duration * 0.5, 0.0))
		check(is_equal_approx(q.get_node("Cooldown").material.get_shader_parameter("remaining_ratio"), 0.5), "half cooldown clears upper half and keeps lower overlay")
		await capture("tier-%d-half" % tier)
		skill._physics_process(skill.cooldown_remaining + 0.01)
		check(not skill.is_cooling_down() and not q.get_node("Cooldown").visible and not q.get_node("Remaining").visible and q.get_node("Frame").get_theme_stylebox("panel").border_color == q.ready_border_color, "expiry restores white border and removes overlay/time")
		await frames(3)
		check(not skill.is_active() and not p._skill_requested, "a Q held during cooldown never auto-repeats at expiry")
		await button(&"weapon_skill", false)
		await button(&"weapon_skill", true)
		check(skill.is_active(), "fresh press after cooldown starts Q")
		skill.abort()
		check(not skill.is_cooling_down(), "aborted charge before lunge spends no cooldown")
	await reset(true)
	await launch(1)
	var deadline := Time.get_ticks_msec() + 4000
	while not skill.is_finish_freezing() and skill.is_active() and Time.get_ticks_msec() < deadline: await frames()
	check(skill.is_finish_freezing(), "charged hit reaches frozen zoom return")
	var before: float = skill.cooldown_remaining
	await button(&"weapon_skill", false)
	await button(&"weapon_skill", true)
	await wait_real(0.08)
	check(is_equal_approx(skill.cooldown_remaining, before), "Q return freeze also freezes cooldown")
	check(await finish_skill(), "charged return completes with pending fresh Q")
	check(not skill.is_active() and skill.is_cooling_down(), "buffered Q after return cannot bypass cooldown")
	await reset(false)
	await launch(0)
	deadline = Time.get_ticks_msec() + 3000
	while p.state_machine.current != S.SKILL_RECOVERY and skill.is_active() and Time.get_ticks_msec() < deadline: await frames()
	p.damage.apply_stagger(Vector2.LEFT, 10.0, 0.05, 0.05, 0.2)
	check(not skill.is_active() and skill.is_cooling_down(), "interruption after lunge retains spent cooldown")
	await reset(false)
	check(not skill.is_cooling_down() and not q.get_node("Cooldown").visible, "checkpoint reset clears cooldown and its presentation")

func debug_cooldown_checks() -> void:
	# Verify the debug switch with the designer's actual scene overrides as well.
	skill.tap_cooldown = authored_cooldowns[0]
	skill.charged_cooldown = authored_cooldowns[1]
	skill.full_cooldown = authored_cooldowns[2]
	await reset(false)
	await launch(0)
	check(await finish_skill(), "debug fixture completes a real Q with cooldown active")
	var menu = p.get_node("Camera2D/UI_Layer/PauseMenu")
	var toggle: CheckButton = menu.get_node("VBoxContainer/SkillDebug/CooldownsEnabled")
	var q = hud.weapon_loadout.get_node("Q")
	var save_before := JSON.stringify(SaveManager._data)
	menu.pause_and_unpause()
	check(get_tree().paused and menu.visible and toggle.button_pressed and not toggle.disabled and toggle.is_visible_in_tree(), "pause opens with skill cooldowns enabled by default")
	toggle.button_pressed = false
	check(get_tree().paused and menu.visible and not skill.is_cooling_down() and skill.cooldown_remaining == 0.0 and skill.cooldown_total == 0.0, "turning cooldowns off clears active cooldown without closing pause")
	check(not q.get_node("Cooldown").visible and not q.get_node("Remaining").visible and q.get_node("Frame").get_theme_stylebox("panel").border_color == q.ready_border_color, "debug toggle immediately restores ready HUD while paused")
	await frames(3)
	var panel: Control = menu.get_node("VBoxContainer")
	check(panel.get_global_rect().position.y >= 0.0 and panel.get_global_rect().end.y <= menu.get_viewport_rect().size.y, "pause content including skill debug fits the viewport")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://pause-skill-cooldown-debug.png")
	menu.pause_and_unpause()
	for tier in [0, 1, 2]:
		await reset(false)
		await launch(tier)
		check(await finish_skill(), "debug mode completes Q tier %d" % tier)
		check(not skill.is_cooling_down() and skill.cooldown_total == 0.0 and not q.get_node("Cooldown").visible, "disabled cooldown stays off after Q tier %d" % tier)
	var other_menu = load("res://scenes/UI/game_pause_menu.tscn").instantiate()
	scene.add_child(other_menu)
	check(not other_menu.get_node("VBoxContainer/SkillDebug/CooldownsEnabled").button_pressed, "new pause instance inherits the disabled session setting")
	other_menu.queue_free()
	menu.pause_and_unpause()
	check(not toggle.button_pressed, "reopening pause keeps cooldown disabled")
	toggle.button_pressed = true
	check(not skill.is_cooling_down() and skill.cooldown_remaining == 0.0, "re-enabling affects the next cast without inventing a current cooldown")
	menu.pause_and_unpause()
	await reset(false)
	await launch(1)
	check(skill.is_cooling_down() and skill.cooldown_total == authored_cooldowns[1], "re-enabling restores the authored charge-level-one cooldown")
	check(skill.tap_cooldown == authored_cooldowns[0] and skill.charged_cooldown == authored_cooldowns[1] and skill.full_cooldown == authored_cooldowns[2], "debug toggle preserves the designer's cooldown overrides")
	check(JSON.stringify(SaveManager._data) == save_before, "skill debug setting never changes checkpoint data")
	await reset(false)

func run() -> void:
	Engine.max_fps = 144
	Debug.ai_disabled = true
	Debug.immortal = true
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	await frames(70)
	origin = p.position
	skill = p.saber_skill
	authored_cooldowns.assign([skill.tap_cooldown, skill.charged_cooldown, skill.full_cooldown])
	# The general timing suite uses a fixed fixture; debug checks restore scene tuning.
	skill.tap_cooldown = 5.0
	skill.charged_cooldown = 8.0
	skill.full_cooldown = 10.0
	hud = p.get_node("Camera2D/hud")
	p.vitals.simulation_enabled = false
	p.hit_stop_enabled = false
	skill.tap_windup = 0.05
	skill.charge_level_1_time = 0.12
	skill.charge_level_2_time = 0.3
	skill.charged_release_windup = 0.03
	skill.full_charge_final_pose = 0.04
	for prefix in ["tap", "charged", "full"]:
		skill.set(prefix + "_impact_slow_motion_enabled", false)
		skill.set(prefix + "_impact_zoom_in_duration", 0.03)
	for hit in [false, true]:
		for tier in [1, 2]:
			await reset(hit)
			await button(&"jump", true)
			await button(&"jump", false)
			await frames(3)
			check(not p.is_on_floor(), "fixture jumps before Q input")
			await button(&"weapon_skill", true)
			check(p._skill_requested and not skill.is_active(), "Q held in air waits for landing")
			check(await reach_skill(), "landing consumes held Q into charge")
			var deadline := Time.get_ticks_msec() + 3000
			var target_charge: float = skill.charge_level_1_time + 0.02 if tier == 1 else skill.charge_level_2_time + skill.full_charge_final_pose + 0.02
			while skill.charge_time < target_charge and p.state_machine.current == S.SKILL_CHARGE and Time.get_ticks_msec() < deadline: await frames()
			if tier == 1: await button(&"weapon_skill", false)
			await button(&"move_right", true)
			check(await finish_skill(), "air-held Q completes tier %d hit=%s" % [tier, hit])
			await frames(5)
			check(p.velocity.x > 0.0 and p.spine_anim.assigned_animation == &"walk", "already-held movement replaces Q/ready animation tier %d hit=%s" % [tier, hit])
	await reset(false)
	var defaults := SaberWeaponSkill.new()
	check(defaults.tap_cooldown == 5.0 and defaults.charged_cooldown == 8.0 and defaults.full_cooldown == 10.0, "script cooldown defaults are 5/8/10 game seconds")
	defaults.free()
	check(skill.has_method("is_cooling_down"), "gameplay exposes cooldown availability")
	if skill.has_method("is_cooling_down"):
		await cooldown_checks()
		await debug_cooldown_checks()
	print("Q COOLDOWN RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
