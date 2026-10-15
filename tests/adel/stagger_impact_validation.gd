extends Node
var checks := 0
var failures := 0
var scene
var player
var camera
var hud
var rendered := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not ProjectSettings.get_setting("application/config/use_custom_user_dir", false) or not String(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("CodexStaggerImpact"):
		get_tree().quit(2)
		return
	Engine.max_fps = 120
	rendered = DisplayServer.get_name() != "headless"
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("STAGGER IMPACT ", "PASS " if ok else "FAIL ", label)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func frame() -> void:
	await get_tree().process_frame

func button(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	await frame()

func ready_player() -> void:
	while player.damage.is_stunned: await frame()
	player.stagger_impact.cancel()
	player.deflect_slow_motion.cancel()
	CombatTime.remove(player)
	player.damage.is_invulnerable = false
	hud.hp = 100
	hud.clear_all_debuffs()
	hud.restore_stagger_thresholds()
	hud.restore_stamina_full()
	player.position.x = 300.0
	player.velocity = Vector2.ZERO
	await wait(0.04)

func wait_recovery() -> void:
	var deadline := Time.get_ticks_msec() + 3000
	while player.damage.is_stunned and Time.get_ticks_msec() < deadline: await frame()
	check(not player.damage.is_stunned, "stagger recovers within bounded time")

func capture(label: String) -> void:
	if not rendered: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://stagger-impact-" + label + ".png")

func run() -> void:
	if rendered:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1280, 720)
		get_window().position = Vector2i(40, 40)
		get_window().grab_focus()
		await wait(0.15)
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	player = scene.get_node("PlayableAdel")
	scene.get_node("Enemy").set_physics_process(false)
	player.hit_stop_enabled = false
	camera = player.get_node("Camera2D")
	hud = player.get_node("Camera2D/hud")
	await wait(0.8)
	var settle_deadline := Time.get_ticks_msec() + 5000
	while not player.is_on_floor() and Time.get_ticks_msec() < settle_deadline: await frame()
	check(player.is_on_floor(), "actual Player settles on test floor")
	check(player.stagger_knockback_distance == 200.0 and camera.mouse_pan_max_distance == Vector2(120, 75), "existing player recoil and camera tuning preserved")
	var pose: Sprite2D = player.spine_rig.get_node("TestAttackSprite")
	var base_zoom: Vector2 = camera.zoom
	for hit in [Vector2(80, -200), Vector2(80, 200), Vector2(-80, -200), Vector2.ZERO]:
		var direction: Vector2 = player.damage.compute_knockback_dir(player.global_position + hit, 1)
		check(direction.y == 0.0 and absf(direction.x) == 1.0, "hit direction is horizontal regardless of source height " + str(hit))
	for fps in [30, 60, 120]:
		var model := DamageComponent.new(player, 200.0, 0.3, 0.45)
		model.apply_stagger(Vector2(-1, -1))
		var total := 0.0
		var frame0 := 0.0
		var early_tail := 0.0
		var late_tail := 0.0
		for step in int(0.5 * fps):
			var travel: float = model.consume_knockback_distance(1.0 / fps)
			total += travel
			if step < int(0.3 * fps): frame0 += travel
			elif step < int(0.4 * fps): early_tail += travel
			else: late_tail += travel
		check(absf(total - 200.0) < 0.001, "integrated recoil keeps exact 200px at " + str(fps) + " steps")
		check(frame0 > 0.0 and frame0 < total and early_tail > late_tail and late_tail > 0.0, "motion continues after frame switch and decelerates strongly at " + str(fps))
		check(model.consume_knockback_distance(0.2) < 0.001, "recoil consumes no distance after 0.5s at " + str(fps))
	# Combat integration without presentation pulses isolates motion/animation timing.
	player.stagger_zoom_enabled = false
	player.stagger_slow_motion_enabled = false
	await button(&"attack", true)
	await button(&"attack", false)
	check(player.state_machine.is_in(AdelStateMachine.State.ATTACK), "real attack starts before threshold interruption")
	hud.hp = 70
	var origin: Vector2 = player.position
	player.take_damage(20, player.global_position + Vector2(80, 200))
	hud.clear_all_debuffs()
	check(hud.hp == 66 and player.damage.is_stunned and player.velocity.y == 0.0 and pose.frame == 0, "real threshold clamps HP and starts frame 0 without launching player")
	check(not player.saber_hitbox._attack_active and not player.combat.attack_queued, "stagger interrupts attack hitbox and queue")
	while player.damage.is_knocking_back: await frame()
	await frame()
	check(pose.frame == 1 and player.state_machine.current == AdelStateMachine.State.STUN and player.velocity.x < 0.0, "frame 1 begins at 0.3s while horizontal push continues")
	var tail_x: float = player.position.x
	await wait(0.08)
	check(player.position.x < tail_x, "player still slides while holding final stagger frame")
	await wait(0.16)
	check(absf(player.velocity.x) < 0.001 and absf(origin.x - player.position.x - 200.0) < 0.1, "tail stops at 0.5s with full configured distance")
	check(absf(player.position.y - origin.y) < 0.1, "grounded stagger does not move player upward")
	check(player.damage.is_stunned and player.damage.is_invulnerable, "stun and iframe outlast sliding")
	await wait_recovery()
	check(pose.frame == 2 and player.can_move and player.spine_anim.assigned_animation == &"saber_ready", "recovery returns to interruptible final ready frame")
	await button(&"attack", true)
	await button(&"attack", false)
	check(player.state_machine.current == AdelStateMachine.State.COMBO, "attack works again after interruption")
	# Full presentation: immediate slow motion, 50% zoom and timed return.
	await ready_player()
	player.stagger_zoom_enabled = true
	player.stagger_slow_motion_enabled = true
	player.damage.apply_stagger(Vector2(-1, -5))
	check(is_equal_approx(Engine.time_scale, 0.35), "stagger immediately requests configurable 0.35x world slowdown")
	check(player.velocity.y == 0.0, "even a direct diagonal stagger request cannot launch player")
	var started := Time.get_ticks_msec()
	var peak := 1.0
	var focus_peak := 0.0
	var captured_peak := false
	while Time.get_ticks_msec() - started < 120:
		await frame()
		peak = maxf(peak, camera.zoom.x / base_zoom.x)
		focus_peak = maxf(focus_peak, camera._stagger_focus_weight)
		if camera.zoom.x / base_zoom.x >= 1.49 and rendered and not captured_peak:
			captured_peak = true
			await capture("peak")
	check(peak >= 1.49 and peak <= 1.501, "zoom quickly reaches exactly 1.5x previous zoom")
	check(focus_peak >= 0.99, "impact zoom focuses on player instead of cropping original low framing")
	check(player.damage._knockback_elapsed < 0.1, "player physics actually slows with world time")
	while Time.get_ticks_msec() - started < 220: await frame()
	await frame()
	check(is_equal_approx(Engine.time_scale, 1.0), "stagger slow motion expires after real-time pulse; elapsed=" + str(Time.get_ticks_msec() - started))
	while player.stagger_impact._zoom_active: await frame()
	check(camera.zoom.is_equal_approx(base_zoom) and camera._stagger_focus_weight == 0.0, "zoom and original framing fully restored")
	check(player.damage.is_stunned and player.stagger_impact._game_elapsed <= player.damage.stagger_duration() - 0.2 + 0.02, "base zoom returns at least 0.2 animation seconds before stagger recovery")
	await capture("restored-before-recovery")
	await wait_recovery()
	check(camera.zoom.is_equal_approx(base_zoom) and Engine.time_scale == 1.0, "recovery leaves no zoom or slowdown")
	# Pause freezes both effect clocks, not just the physical state.
	await ready_player()
	player.damage.apply_stagger(Vector2.LEFT)
	await wait(0.025)
	var pause = player.get_node("Camera2D/UI_Layer/PauseMenu")
	pause.pause_and_unpause()
	var paused_zoom: Vector2 = camera.zoom
	var paused_elapsed: float = player.stagger_impact._real_elapsed
	await wait(0.25)
	check(camera.zoom == paused_zoom and player.stagger_impact._real_elapsed == paused_elapsed, "pause freezes stagger zoom")
	check(is_equal_approx(Engine.time_scale, 1.0), "pause delegates time scale to existing arbiter")
	pause.pause_and_unpause()
	await wait(0.04)
	check(player.stagger_impact._real_elapsed < 0.15 and camera.zoom.x > base_zoom.x, "resume excludes paused wall time from zoom-in")
	await wait_recovery()
	# Camera ownership changes and retriggers cannot strand zoom/time scale.
	await ready_player()
	player.damage.apply_stagger(Vector2.LEFT)
	await wait(0.04)
	var other := Camera2D.new()
	scene.add_child(other)
	other.make_current()
	await wait(0.03)
	check(camera.zoom.is_equal_approx(base_zoom) and not player.stagger_impact._active and Engine.time_scale == 1.0, "switching to another camera cancels and restores impact")
	other.queue_free()
	camera.make_current()
	await wait_recovery()
	await ready_player()
	var settings := {"zoom_multiplier": 1.5, "zoom_in_duration": 0.06, "return_lead": 0.2, "slow_motion_enabled": false}
	player.stagger_impact.start(camera, 0.75, settings)
	await wait(0.15)
	player.stagger_impact.start(camera, 0.75, settings)
	await wait(0.42)
	check(camera.zoom.x > base_zoom.x and player.stagger_impact._zoom_active, "old callback cannot end a newly restarted zoom")
	await wait(0.16)
	check(camera.zoom.is_equal_approx(base_zoom), "retrigger restores original zoom without multiplying baseline")
	player.stagger_impact.cancel()
	# Shared stamina reaction also receives the same presentation without HP threshold.
	hud.stamina = 10
	hud.hp = 100
	player._set_facing_direction(1)
	await button(&"guard and deflect", true)
	await wait(0.34)
	player.take_damage(20, player.global_position + Vector2(80, 200))
	await button(&"guard and deflect", false)
	check(hud.stamina == 0 and hud.hp == 90 and player.damage.is_stunned, "exhausted guard preserves stamina and half-damage rules")
	check(Engine.time_scale == player.stagger_slow_motion_scale and player.stagger_impact._zoom_active and not player.deflect_slow_motion.is_active, "exhaustion uses stagger impact without a Deflect pulse")
	check(hud.stagger_tiers_ready == [true, true] and not hud.has_any_debuff(), "exhaustion impact does not consume threshold or debuff")
	await wait_recovery()
	# Freeing the owner during the impact must release global time ownership.
	await ready_player()
	player.damage.apply_stagger(Vector2.LEFT)
	await wait(0.04)
	player.queue_free()
	await wait(0.05)
	check(Engine.time_scale == 1.0 and CombatTime._effects.is_empty(), "freeing Player during impact releases time scale without stale access")
	print("STAGGER IMPACT RESULT checks=", checks, " failures=", failures, " display=", DisplayServer.get_name())
	get_tree().quit(1 if failures else 0)
