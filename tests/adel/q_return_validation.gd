extends Node
const Finish = preload("res://scenes/adel/components/charged_skill_finish.gd")
const Debug = preload("res://scenes/enemy/enemy_debug_settings.gd")
const S = AdelStateMachine.State
class WorldClock extends Node:
	var ticks := 0
	func _physics_process(_delta: float) -> void: ticks += 1
var checks := 0
var failures := 0
var p
var enemy
var skill
var camera
var scene
var clock: WorldClock
var origin: Vector2
var base_zoom: Vector2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("Q RETURN CONTEXT ", p.state_machine.current, " paused=",get_tree().paused," active=",skill.is_active()," phase=",p.spine_anim.assigned_animation," time=",p.spine_anim.current_animation_position)
	print("Q RETURN ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func event(action: StringName, pressed: bool) -> void:
	var input := InputEventAction.new()
	input.action = action
	input.pressed = pressed
	Input.parse_input_event(input)
	await frames()

func reach_return() -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while not skill._charged_finish.returning and skill.is_active() and Time.get_ticks_msec() < deadline: await frames()
	return skill._charged_finish.returning

func finish_return() -> void:
	var deadline := Time.get_ticks_msec() + 3000
	while Finish.is_freezing() and Time.get_ticks_msec() < deadline: await frames()

func reset() -> void:
	p.clear_combat_input()
	p.end_sentinel()
	get_tree().paused = false
	for action in ["attack", "weapon_skill", "guard and deflect", "dodge", "jump", "move_right", "move_left"]: Input.action_release(action)
	p.damage.reset()
	p.stats.heal_to_full()
	p.state_machine.resume_locomotion()
	p.position = origin
	p.velocity = Vector2.ZERO
	p.dash.able_to_dodge = true
	p._guard_requires_release = false
	p._set_facing_direction(1)
	Debug.ai_disabled = true
	Debug.immortal = true
	enemy.position = origin + Vector2(155, 0)
	skill.charged_impact_zoom_enabled = true
	skill.full_impact_zoom_enabled = true
	skill.charged_impact_zoom_duration = 0.24
	skill.full_impact_zoom_duration = 0.3
	await frames(4)

func launch(tier: int, hit: bool = true) -> void:
	if not hit: enemy.position.x = origin.x + 3000
	Input.action_press("weapon_skill")
	check(skill.begin(), "Q starts at requested tier %d" % tier)
	if tier > 0:
		var threshold: float = skill.charge_level_1_time + 0.02 if tier == 1 else skill.charge_level_2_time + 0.02
		while skill.charge_time < threshold and p.state_machine.current == S.SKILL_CHARGE: await frames()
	if tier < 2:
		Input.action_release("weapon_skill")
		skill.release()

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexQReturn20261016"):
		get_tree().quit(2)
		return
	Engine.max_fps = 144
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	Debug.ai_disabled = true
	Debug.immortal = true
	await frames(65)
	origin = p.position
	camera = p.get_node("Camera2D")
	base_zoom = camera.zoom
	skill = p.saber_skill
	p.vitals.simulation_enabled = false
	p.hit_stop_enabled = false
	clock = WorldClock.new()
	scene.add_child(clock)
	skill.tap_windup = 0.05
	skill.charge_level_1_time = 0.12
	skill.charge_level_2_time = 0.3
	skill.charged_release_windup = 0.03
	skill.full_charge_final_pose = 0.04
	skill.lunge_speed = 900
	for prefix in ["tap", "charged", "full"]:
		skill.set(prefix + "_impact_zoom_in_duration", 0.03)
		skill.set(prefix + "_impact_slow_motion_enabled", false)
	if DisplayServer.get_name() != "headless":
		for clip in [&"saber_skill_1", &"saber_skill_2", &"saber_skill_3", &"saber_skill_4", &"saber_skill_5", &"saber_skill_6", &"saber_ready"]:
			p.presentation.hold(clip)
			await RenderingServer.frame_post_draw
	for tier in [1, 2]:
		await reset()
		await launch(tier)
		while p.state_machine.current != S.SKILL_RECOVERY: await frames()
		await wait(0.08)
		check(not get_tree().paused and not skill._charged_finish.returning, "no freeze while skill_6 is still playing")
		var peak: float = skill.charged_impact_zoom_multiplier if tier == 1 else skill.full_impact_zoom_multiplier
		check(camera.zoom.is_equal_approx(base_zoom * peak), "zoom remains held at the configured tier peak during skill_6")
		check(await reach_return(), "charged Q starts frozen zoom return")
		var return_usec := Time.get_ticks_usec()
		check(get_tree().paused and p.state_machine.current == S.SKILL_RECOVERY and skill.is_active(), "world is paused without transitioning to ready early")
		check(p.spine_anim.current_animation_position >= p.spine_anim.get_animation(&"saber_skill_6").length - 0.001, "skill_6 reaches its final pose before freeze")
		var ticks: int = clock.ticks
		var player_pos: Vector2 = p.position
		var enemy_pos: Vector2 = enemy.position
		var animation_pos: float = p.spine_anim.current_animation_position
		var zoom_before: Vector2 = camera.zoom
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = 0.07
		scene.add_child(timer)
		var timer_state := {"done": false}
		timer.timeout.connect(func(): timer_state.done = true)
		timer.start()
		await wait(0.1)
		check(clock.ticks == ticks and p.position == player_pos and enemy.position == enemy_pos, "player, enemy and world physics are completely frozen")
		check(p.spine_anim.current_animation_position == animation_pos and not timer_state.done, "animations and gameplay timers remain frozen")
		check(camera.zoom.x < zoom_before.x and camera.zoom.x > base_zoom.x, "camera alone returns smoothly while world is frozen")
		var player_hp: int = p.stats.hp
		var enemy_hp: int = enemy.current_health
		Debug.immortal = false
		p.take_damage(999, enemy.global_position)
		p.vitals.apply_damage(999)
		enemy.take_damage(999, p.global_position)
		check(p.stats.hp == player_hp and enemy.current_health == enemy_hp, "late damage callbacks cannot modify HP during the frozen return")
		Debug.immortal = true
		if DisplayServer.get_name() != "headless" and tier == 1:
			await RenderingServer.frame_post_draw
			var capture := OS.get_user_data_dir().path_join("charged-q-return.png")
			get_viewport().get_texture().get_image().save_png(capture)
			print("Q RETURN CAPTURE ", capture)
		var pause = p.get_node("Camera2D/UI_Layer/PauseMenu")
		pause.pause_and_unpause()
		p.get_node("Camera2D/UI_Layer/master_menu")._open_menu()
		check(get_tree().paused and not pause.visible and not p.get_node("Camera2D/UI_Layer/master_menu").visible, "menus cannot accidentally release or take over the cinematic pause")
		await event(&"attack", true)
		await event(&"attack", false)
		check(Finish.is_freezing() and p.state_machine.current == S.SKILL_RECOVERY, "attack buffer accepts a tap without executing during freeze")
		await finish_return()
		var return_seconds := float(Time.get_ticks_usec() - return_usec) / 1000000.0
		var configured: float = skill.charged_impact_zoom_duration if tier == 1 else skill.full_impact_zoom_duration
		check(return_seconds >= configured - 0.04 and return_seconds <= configured + 0.12, "each tier return uses its configured real-time duration")
		check(not get_tree().paused and not Finish.is_freezing() and camera.zoom.is_equal_approx(base_zoom), "zoom completion releases only cinematic pause and restores camera")
		check(p.state_machine.current == S.COMBO and not skill.is_active(), "buffered attack executes immediately after unfreezing")
		await wait(0.12)
		check(clock.ticks > ticks and timer_state.done and not p.combat.attack_queued, "game clocks resume and buffered attack does not repeat")
		timer.queue_free()
	# Last fresh combat press wins; a released Q still starts a tap skill after return.
	await reset()
	skill.charged_impact_zoom_duration = 0.5
	await launch(1)
	check(await reach_return(), "long-buffer test reaches freeze")
	await event(&"attack", true)
	await event(&"attack", false)
	await wait(0.25)
	check(Finish.is_freezing() and p.state_machine.current == S.SKILL_RECOVERY, "queued action waits even beyond the normal attack-buffer timeout")
	await finish_return()
	check(p.state_machine.current == S.COMBO, "frozen input buffer survives until the camera return actually ends")
	await reset()
	await launch(1)
	check(await reach_return(), "last-input test reaches freeze")
	await event(&"attack", true)
	await event(&"attack", false)
	await event(&"weapon_skill", true)
	await event(&"weapon_skill", false)
	await finish_return()
	check(skill.is_active() and p.state_machine.is_in(S.SKILL) and p.combat.combo_step == 0, "latest buffered Q overrides attack and begins even after Q was released")
	await reset()
	await launch(1)
	check(await reach_return(), "defense buffer reaches freeze")
	p._guard_requires_release = true
	await event(&"guard and deflect", true)
	await finish_return()
	check(p.is_guarding and p.state_machine.is_in(S.DEFENSE), "fresh held defense during freeze is accepted after Q despite the prior release gate")
	await reset()
	await launch(1)
	check(await reach_return(), "released-defense test reaches freeze")
	await event(&"guard and deflect", true)
	await event(&"guard and deflect", false)
	await finish_return()
	check(not p.is_guarding and p.state_machine.current == S.READY, "releasing defense cancels the buffered hold")
	await reset()
	await launch(2)
	check(await reach_return(), "dash buffer reaches freeze")
	Input.action_press("move_right")
	await event(&"dodge", true)
	await event(&"dodge", false)
	await finish_return()
	check(p.state_machine.is_in(S.DASH), "buffered directional dash executes after return")
	await reset()
	await launch(1)
	check(await reach_return(), "jump buffer reaches freeze")
	await event(&"jump", true)
	await event(&"jump", false)
	await finish_return()
	check(p.velocity.y < 0, "buffered jump executes after return")
	await reset()
	await launch(1)
	check(await reach_return(), "checkpoint cancellation reaches freeze")
	await event(&"attack", true)
	p.restore_checkpoint_state(origin, false)
	check(not get_tree().paused and not Finish.is_freezing() and not camera.has_combat_zoom(&"skill_impact") and not skill.is_active(), "checkpoint cleanup releases pause and cancels buffered action")
	await reset()
	skill.charged_impact_zoom_enabled = false
	await launch(1)
	await wait(0.8)
	check(not get_tree().paused and not Finish.is_freezing() and not skill.is_active(), "disabled charged zoom does not create an invisible freeze")
	await reset()
	skill.charged_impact_zoom_duration = 0.0
	await launch(1)
	await wait(0.8)
	check(not get_tree().paused and not skill.is_active(), "zero return duration finishes immediately without leaving pause ownership")
	await reset()
	skill.full_impact_slow_motion_enabled = true
	skill.full_impact_slow_motion_duration = 3.0
	p.hit_stop_enabled = true
	await launch(2)
	check(await reach_return(), "long impact slow motion still waits for the full skill_6 clip before freeze")
	check(p.spine_anim.current_animation_position >= p.spine_anim.get_animation(&"saber_skill_6").length - 0.001, "real hit-stop and slow motion never cut off the final recovery frame")
	await finish_return()
	check(is_equal_approx(Engine.time_scale, 1.0) and not get_tree().paused, "frozen return ends old Q slow-motion pulses instead of resuming them after unfreeze")
	skill.full_impact_slow_motion_enabled = false
	await reset()
	await launch(0)
	await wait(0.8)
	check(not Finish.is_freezing() and not skill.is_active() and not get_tree().paused, "tap Q retains its existing non-freezing exit")
	await reset()
	await launch(1, false)
	await wait(1.0)
	check(not Finish.is_freezing() and not skill.is_active() and not get_tree().paused, "charged whiff has no held impact zoom or frozen return")
	await reset()
	get_tree().paused = true
	skill._charged_finish.cancel()
	check(get_tree().paused, "cinematic cleanup never unpauses an unrelated menu pause")
	get_tree().paused = false
	check(p.z_index == 200 and enemy.z_index == 100, "Player render band is above enemy band without changing internal rig ordering")
	# Exit while the pause is owned must not strand the next scene in paused state.
	await launch(1)
	check(await reach_return(), "scene cleanup reaches freeze")
	p.queue_free()
	await frames(3)
	checks += 1
	if get_tree().paused or Finish.is_freezing(): failures += 1
	print("Q RETURN ", "PASS " if not get_tree().paused and not Finish.is_freezing() else "FAIL ", "freeing Player releases cinematic pause")
	Debug.ai_disabled = false
	Debug.immortal = false
	print("Q RETURN RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
