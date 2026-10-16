extends Node
const S = AdelStateMachine.State
var p
var skill
var enemy
var camera
var origin: Vector2
var base_zoom: Vector2
var checks := 0
var failures := 0
var seen_states: Array[int] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("Q IMPACT ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func reach(state: int, seconds: float = 3.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		if p.state_machine.current == state: return true
		await frames()
	return false

func reset() -> void:
	for action in ["weapon_skill", "attack", "guard and deflect", "move_left", "move_right"]: Input.action_release(action)
	p.end_sentinel()
	p.clear_combat_input()
	p.damage.reset()
	p.stagger_impact.cancel()
	p.state_machine.resume_locomotion()
	p.stats.heal_to_full()
	p.position = origin
	p.velocity = Vector2.ZERO
	p._set_facing_direction(1)
	p.combat.combo_step = 0
	p.hit_stop_enabled = false
	p.stagger_zoom_enabled = true
	p.stagger_slow_motion_enabled = true
	enemy.position = origin + Vector2(2000, 0)
	enemy.set_physics_process(false)
	enemy.current_health = 1000
	var stun = enemy.get_node_or_null("WeaponSkillStun")
	if stun != null: stun.queue_free()
	await frames(3)

func launch(tier: int, hit: bool = true) -> void:
	seen_states.clear()
	if hit: enemy.position = p.position + Vector2(155, 0)
	await frames(2)
	Input.action_press("weapon_skill")
	check(skill.begin(), "Q starts for tier %d" % tier)
	if tier > 0:
		while skill.charge_time < (skill.charge_level_1_time + 0.02 if tier == 1 else skill.charge_level_2_time - 0.01) and p.state_machine.current == S.SKILL_CHARGE: await frames()
	if tier < 2:
		Input.action_release("weapon_skill")
		skill.release()

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexQImpact20261016"):
		get_tree().quit(2)
		return
	Engine.max_fps = 144
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	p.state_machine.transitioned.connect(func(_previous: int, current: int): seen_states.append(current))
	enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	enemy.position.x = 6000
	await frames(65)
	origin = p.position
	camera = p.get_node("Camera2D")
	base_zoom = camera.zoom
	skill = p.saber_skill
	p.vitals.simulation_enabled = false
	skill.tap_windup = 0.05
	skill.charge_level_1_time = 0.12
	skill.charge_level_2_time = 0.30
	skill.full_charge_final_pose = 0.04
	skill.charged_release_windup = 0.03
	skill.lunge_speed = 900
	if DisplayServer.get_name() != "headless":
		for clip in [&"saber_skill_1", &"saber_skill_2", &"saber_skill_3", &"saber_skill_4", &"saber_skill_5", &"saber_skill_6", &"saber_ready"]:
			p.presentation.hold(clip)
			await RenderingServer.frame_post_draw
	var stagger_settings := {}
	for name in ["stagger_zoom_multiplier", "stagger_zoom_in_duration", "stagger_zoom_return_lead", "stagger_slow_motion_scale", "stagger_slow_motion_duration", "stagger_knockback_duration", "stagger_stun_duration"]: stagger_settings[name] = p.get(name)
	var property_names := []
	for property in skill.get_property_list():
		if property.usage & PROPERTY_USAGE_EDITOR: property_names.append(property.name)
	for prefix in ["tap", "charged", "full"]:
		for suffix in ["zoom_enabled", "zoom_multiplier", "zoom_in_duration", "zoom_duration", "slow_motion_enabled", "slow_motion_scale", "slow_motion_duration"]:
			check((prefix + "_impact_" + suffix) in property_names, "Inspector exports " + prefix + " impact " + suffix)
	for tier in range(3):
		await reset()
		var prefix: String = ["tap", "charged", "full"][tier] + "_impact_"
		skill.set(prefix + "zoom_multiplier", [1.25, 1.45, 1.7][tier])
		skill.set(prefix + "zoom_in_duration", [0.04, 0.07, 0.09][tier])
		skill.set(prefix + "zoom_duration", [0.42, 0.52, 0.62][tier])
		skill.set(prefix + "slow_motion_scale", [0.55, 0.4, 0.25][tier])
		skill.set(prefix + "slow_motion_duration", [0.21, 0.28, 0.36][tier])
		p.stagger_zoom_multiplier = 2.0
		p.stagger_zoom_in_duration = 0.3
		p.stagger_slow_motion_scale = 0.9
		p.stagger_slow_motion_duration = 1.0
		p.stagger_knockback_duration = 0.1
		p.stagger_stun_duration = 0.1
		await launch(tier)
		check(await reach(S.SKILL_IMPACT), "tier %d actually collides with enemy" % tier)
		check(skill.tier == tier and p.spine_anim.assigned_animation == &"saber_skill_5", "collision selects skill_5 at the correct charge tier")
		check(is_equal_approx(Engine.time_scale, skill.get(prefix + "slow_motion_scale")), "selected Q tier slow motion ignores stagger tuning")
		check(camera.has_combat_zoom(&"skill_impact") and not camera.has_combat_zoom(&"stagger"), "Q has a separate zoom source from stagger")
		var feedback = skill._impact_feedback
		check(is_equal_approx(feedback._multiplier, skill.get(prefix + "zoom_multiplier")) and is_equal_approx(feedback._zoom_in_duration, skill.get(prefix + "zoom_in_duration")), "zoom uses only the selected tier magnitude and entry duration")
		var pulse: Dictionary = CombatTime._effects[str(feedback.get_instance_id()) + ":stagger_impact"]
		check(absf(pulse.left - skill.get(prefix + "slow_motion_duration")) < 0.04 and is_equal_approx(pulse.scale, skill.get(prefix + "slow_motion_scale")), "slow-motion duration and scale are separate for each tier")
		check(enemy.current_health == 1000 - [20, 24, 32][tier] and not p.damage.is_stunned, "feedback preserves Q damage and never staggers Player")
		check(is_equal_approx(feedback._restore_at, skill.get(prefix + "zoom_duration")), "Q zoom return duration is independent of stagger knockback/stun")
		await wait(skill.get(prefix + "zoom_in_duration") + 0.025)
		check(camera.zoom.x > base_zoom.x * (skill.get(prefix + "zoom_multiplier") - 0.06) and camera.zoom.x <= base_zoom.x * skill.get(prefix + "zoom_multiplier") + 0.001, "actual camera reaches this tier zoom instead of stagger zoom")
		if DisplayServer.get_name() != "headless" and tier == 0:
			await RenderingServer.frame_post_draw
			var capture := OS.get_user_data_dir().path_join("q-impact.png")
			p.get_viewport().get_texture().get_image().save_png(capture)
			print("Q IMPACT CAPTURE ", capture)
		check(await reach(S.READY), "Q finishes in ready state")
		check(not p._ready_final_frame and p.spine_anim.assigned_animation == &"saber_ready", "Q requests the original full ready animation")
		var clip: Animation = p.spine_anim.get_animation(&"saber_ready")
		var frame_track := -1
		for track in clip.get_track_count():
			if String(clip.track_get_path(track)) == "TestAttackSprite:frame": frame_track = track
		check(frame_track >= 0 and clip.track_get_key_count(frame_track) == 3 and clip.track_get_key_value(frame_track, 0) == 0 and clip.track_get_key_value(frame_track, 1) == 1 and clip.track_get_key_value(frame_track, 2) == 2, "ready restores all three authored frame keys")
		check(is_equal_approx(clip.length, 1.0) and p.can_move and not p.is_doing_action, "full ready keeps its one-second duration and remains interruptible")
		var pose: Sprite2D = p.get_node("SpinePivot/SpineRig/TestAttackSprite")
		check(pose.frame == 0, "full ready begins at frame zero after Q")
		await wait(0.95)
		check(camera.zoom.is_equal_approx(base_zoom) and not camera.has_combat_zoom(&"skill_impact") and is_equal_approx(Engine.time_scale, 1.0), "pulse smoothly returns camera and world speed without leaking ownership")
		Input.action_release("weapon_skill")
	for name in stagger_settings: p.set(name, stagger_settings[name])
	var packed := PackedScene.new()
	check(packed.pack(skill) == OK, "configured Q tier settings can be packed as a scene")
	check(ResourceSaver.save(packed, "user://q-tier-tuning.tscn") == OK, "custom tier tuning can be saved")
	var reloaded = load("user://q-tier-tuning.tscn").instantiate()
	check(is_equal_approx(reloaded.tap_impact_zoom_multiplier, 1.25) and is_equal_approx(reloaded.charged_impact_zoom_multiplier, 1.45) and is_equal_approx(reloaded.full_impact_zoom_multiplier, 1.7), "all three distinct Inspector overrides survive scene save/load")
	reloaded.free()
	skill.tap_impact_slow_motion_duration = 0.36
	# Explicit toggles affect only their own tier and component.
	await reset()
	skill.charged_impact_zoom_enabled = false
	await launch(1)
	check(await reach(S.SKILL_IMPACT), "level 1 toggle test reaches contact")
	check(not camera.has_combat_zoom(&"skill_impact") and is_equal_approx(Engine.time_scale, skill.charged_impact_slow_motion_scale), "level 1 zoom can be disabled while its slow motion remains active")
	p.clear_combat_input()
	skill.charged_impact_zoom_enabled = true
	await reset()
	skill.full_impact_slow_motion_enabled = false
	await launch(2)
	check(await reach(S.SKILL_IMPACT), "level 2 toggle test reaches contact")
	check(camera.has_combat_zoom(&"skill_impact") and is_equal_approx(Engine.time_scale, 1.0), "level 2 slow motion can be disabled while its zoom remains active")
	p.clear_combat_input()
	skill.full_impact_slow_motion_enabled = true
	await reset()
	p.stagger_zoom_enabled = false
	p.stagger_slow_motion_enabled = false
	await launch(0)
	check(await reach(S.SKILL_IMPACT), "tap independence test reaches contact")
	check(camera.has_combat_zoom(&"skill_impact") and is_equal_approx(Engine.time_scale, skill.tap_impact_slow_motion_scale), "tap feedback stays enabled when all stagger feedback is disabled")
	p.clear_combat_input()
	await reset()
	await launch(0, false)
	var whiff_deadline := Time.get_ticks_msec() + 3000
	while skill.is_active() and Time.get_ticks_msec() < whiff_deadline: await frames()
	check(S.SKILL_RECOVERY in seen_states, "whiff reaches skill_6")
	check(not camera.has_combat_zoom(&"skill_impact") and is_equal_approx(Engine.time_scale, 1.0), "missing enemy does not trigger impact zoom or slow motion")
	check(S.READY in seen_states and not p._ready_final_frame, "whiff also returns to full ready")
	await reset()
	await launch(0)
	check(await reach(S.SKILL_IMPACT), "pause test reaches impact")
	get_tree().paused = true
	var zoom_before: Vector2 = camera.zoom
	var left_before: float = CombatTime._effects[str(skill._impact_feedback.get_instance_id()) + ":stagger_impact"].left
	await wait(0.2)
	check(camera.zoom == zoom_before and is_equal_approx(CombatTime._effects[str(skill._impact_feedback.get_instance_id()) + ":stagger_impact"].left, left_before), "pause freezes zoom and pulse lifetime")
	get_tree().paused = false
	p.clear_combat_input()
	check(not camera.has_combat_zoom(&"skill_impact") and is_equal_approx(Engine.time_scale, 1.0), "input cleanup cancels Q feedback immediately")
	await reset()
	await launch(0)
	check(await reach(S.SKILL_IMPACT), "stagger interruption reaches impact")
	p.damage.apply_stagger(Vector2.LEFT, 10.0, 0.1, 0.2, 0.4)
	check(p.state_machine.is_in(S.STAGGER) and not skill.is_active() and not camera.has_combat_zoom(&"skill_impact") and camera.has_combat_zoom(&"stagger"), "actual stagger replaces Q feedback with its own source")
	await reset()
	await launch(0)
	check(await reach(S.SKILL_IMPACT), "checkpoint interruption reaches impact")
	p.restore_checkpoint_state(origin, false)
	check(not skill.is_active() and not camera.has_combat_zoom(&"skill_impact") and is_equal_approx(Engine.time_scale, 1.0), "checkpoint cleanup restores zoom and time scale")
	await reset()
	await launch(0)
	check(await reach(S.SKILL_IMPACT), "Sentinel interruption reaches impact")
	p.begin_sentinel()
	check(p.is_sentinel_entering() and not skill.is_active() and not camera.has_combat_zoom(&"skill_impact") and is_equal_approx(Engine.time_scale, 1.0), "Sentinel entry cancels Q pulse without losing entry immunity")
	p.end_sentinel()
	await reset()
	p.hit_stop_enabled = true
	await launch(0)
	check(await reach(S.SKILL_IMPACT), "hit-stop integration reaches contact")
	check(CombatTime.is_hit_stopping() and is_equal_approx(Engine.time_scale, p.hit_stop_scale), "existing hit-stop coexists with heavy impact pulse using strongest time scale")
	check(not camera.has_combat_zoom(&"hit_stop"), "Q does not stack a second light hit-stop zoom")
	await wait(0.13)
	check(is_equal_approx(Engine.time_scale, skill.tap_impact_slow_motion_scale), "tap-specific slow motion continues after hit-stop")
	p.clear_combat_input()
	await reset()
	await launch(0, false)
	check(await reach(S.READY), "interruptible ready test reaches completion")
	p._handle_attack_input()
	check(p.state_machine.current == S.COMBO, "normal attack can interrupt full ready after Q")
	p.clear_combat_input()
	print("Q IMPACT RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
