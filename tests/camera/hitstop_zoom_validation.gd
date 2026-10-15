extends Node
var checks := 0
var failures := 0
var scene
var p
var enemy
var hud
var camera
var skill
var floor_y: float
var baseline: Vector2
var rendered := false
var captured := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not ProjectSettings.get_setting("application/config/use_custom_user_dir", false) or not String(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("CodexHitStopZoom"):
		get_tree().quit(2)
		return
	Engine.max_fps = 120
	rendered = DisplayServer.get_name() != "headless"
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("HITSTOP ZOOM ", "PASS " if ok else "FAIL ", label)

func frame() -> void:
	await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func button(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	await frame()

func reset() -> void:
	while p.damage.is_stunned: await frame()
	for action in [&"weapon_skill", &"attack", &"guard and deflect"]: await button(action, false)
	if skill.is_active(): skill.abort()
	p.deflect_slow_motion.cancel()
	p.stagger_impact.cancel()
	p.enter_rest(false)
	p.exit_rest()
	CombatTime.remove(p)
	camera.cancel_hit_stop_zoom()
	p.damage.is_invulnerable = false
	p.damage.is_touched_enemy = false
	hud.hp = 100
	hud.clear_all_debuffs()
	hud.restore_stagger_thresholds()
	hud.restore_stamina_full()
	p.position = Vector2(300, floor_y)
	p.velocity = Vector2.ZERO
	p._set_facing_direction(1)
	enemy.position = Vector2(3000, floor_y)
	enemy.current_health = 1000
	enemy.is_dead = false
	enemy.set_physics_process(false)
	var stun = enemy.get_node_or_null("WeaponSkillStun")
	if stun != null: stun.queue_free()
	await frame()

func observe(label: String) -> void:
	var peak: float = camera.zoom.x / baseline.x
	var until := Time.get_ticks_msec() + 190
	while Time.get_ticks_msec() < until:
		await frame()
		peak = maxf(peak, camera.zoom.x / baseline.x)
		if rendered and not captured and camera.zoom.x / baseline.x > 1.14:
			captured = true
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://hitstop-zoom-peak.png")
	check(peak > 1.135 and peak <= 1.1501, label + " peaks near +15% without stacking: " + str(peak))
	check(not camera.hit_stop_zoom.active and camera.zoom.is_equal_approx(baseline), label + " quickly restores exact original zoom")

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
	p = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	hud = p.get_node("Camera2D/hud")
	hud.set_process(false)
	camera = p.get_node("Camera2D")
	skill = p.saber_skill
	var deadline := Time.get_ticks_msec() + 6000
	while not p.is_on_floor() and Time.get_ticks_msec() < deadline: await frame()
	floor_y = p.position.y
	baseline = camera.zoom
	check(p.is_on_floor(), "real Player settles on floor")
	check(camera.hit_stop_zoom_multiplier == 1.15 and camera.hit_stop_zoom_in_duration == 0.025 and camera.hit_stop_zoom_out_duration == 0.09, "configurable 15% / 0.025s in / 0.09s out defaults")
	check(p.stagger_knockback_distance == 220.0 and p.stagger_knockback_duration == 0.4 and p.stagger_zoom_return_lead == 0.25, "latest user stagger tuning preserved")
	if rendered:
		for i in range(1, 7):
			p.presentation.hold(StringName("saber_skill_%d" % i))
			await RenderingServer.frame_post_draw
	# Confirmed Saber hit path, including one impact per swing.
	for step in range(1, 5):
		await reset()
		var clip := StringName("saber_attack_%d" % step)
		p.saber_hitbox.play_attack_window(clip, 20)
		p.saber_hitbox._on_hitbox_body_entered(enemy)
		var key := str(p.get_instance_id()) + ":hit_stop"
		var duration: float = p.finisher_hit_stop_duration if step == 4 else p.attack_hit_stop_duration
		check(enemy.current_health == 980 and camera.hit_stop_zoom.active and CombatTime._effects.has(key) and is_equal_approx(CombatTime._effects[key].left, duration), "attack %d accepted damage triggers its existing hit-stop and zoom" % step)
		var stamp: int = camera.hit_stop_zoom._last_usec
		p.saber_hitbox._on_hitbox_body_entered(enemy)
		check(camera.hit_stop_zoom._last_usec == stamp and enemy.current_health == 980, "attack %d duplicate overlap does not restart impact" % step)
		await observe("attack %d" % step)
	# Whiffs, harmless and rejected hits must not manufacture a hit-stop or zoom.
	await reset()
	p.saber_hitbox.play_attack_window(&"saber_attack_1", 20)
	await wait(0.04)
	check(not camera.hit_stop_zoom.active and CombatTime._effects.is_empty(), "whiff does not zoom")
	p.saber_hitbox.stop_attack_window()
	p.saber_hitbox.play_attack_window(&"saber_attack_1", 0)
	p.saber_hitbox._on_hitbox_body_entered(enemy)
	check(not camera.hit_stop_zoom.active, "zero damage does not zoom")
	p.saber_hitbox.stop_attack_window()
	p.saber_hitbox.play_attack_window(&"saber_attack_2", 20)
	enemy.is_dead = true
	p.saber_hitbox._on_hitbox_body_entered(enemy)
	check(not camera.hit_stop_zoom.active, "rejected hit does not zoom")
	# Guard and Deflect use the real input and damage classifier.
	for late in [true, false]:
		await reset()
		await button(&"guard and deflect", true)
		await wait(0.34 if late else 0.12)
		p.take_damage(20, p.global_position + Vector2(80, 0))
		check(camera.hit_stop_zoom.active and hud.hp == (90 if late else 100), "funded %s triggers zoom while retaining damage rules" % ("Guard" if late else "Deflect"))
		await observe("Guard" if late else "Deflect")
	# All three actual Q impact paths use the shared request, honoring user charge times.
	for tier in range(3):
		await reset()
		enemy.position = p.position + Vector2(120, 0)
		await button(&"weapon_skill", true)
		if tier == 1:
			deadline = Time.get_ticks_msec() + 3000
			while skill.charge_time < skill.charge_level_1_time + 0.03 and Time.get_ticks_msec() < deadline: await frame()
		if tier < 2: await button(&"weapon_skill", false)
		deadline = Time.get_ticks_msec() + 4000
		while not skill._confirmed and Time.get_ticks_msec() < deadline: await frame()
		check(skill._confirmed and skill.tier == tier and camera.hit_stop_zoom.active, "actual Q tier %d confirms hit and starts zoom" % tier)
		var expected: int = [20, 24, 32][tier]
		check(enemy.current_health == 1000 - expected, "Q tier %d damage unchanged" % tier)
		await observe("Q tier %d" % tier)
		await button(&"weapon_skill", false)
	# Repeated pulses never use an already-enlarged zoom as their baseline.
	await reset()
	p._request_hit_stop(0.04)
	await wait(0.04)
	p._request_hit_stop(0.04)
	check(camera._combat_zoom_base == baseline, "repeated hit-stop retains shared original zoom")
	await observe("repeated pulse")
	# Pause freezes the visual pulse and resumes without consuming paused wall time.
	await reset()
	p._request_hit_stop(0.25)
	await wait(0.018)
	var pause = p.get_node("Camera2D/UI_Layer/PauseMenu")
	pause.pause_and_unpause()
	var paused_zoom: Vector2 = camera.zoom
	var paused_elapsed: float = camera.hit_stop_zoom._elapsed
	await wait(0.2)
	check(camera.zoom == paused_zoom and camera.hit_stop_zoom._elapsed == paused_elapsed, "pause freezes hit-stop zoom")
	pause.pause_and_unpause()
	await wait(0.3)
	check(camera.zoom.is_equal_approx(baseline) and Engine.time_scale == 1.0, "resume restores original zoom and simulation speed")
	# Stagger preempts a hit-stop pulse; it never captures an inflated zoom baseline.
	await reset()
	p._request_hit_stop(0.1)
	await wait(0.03)
	p.damage.apply_stagger(Vector2.LEFT)
	check(not camera.hit_stop_zoom.active and camera.has_combat_zoom(&"stagger") and camera._combat_zoom_base == baseline, "stagger cancels hit-stop zoom and preserves original baseline")
	p._request_hit_stop(0.035)
	check(not camera.hit_stop_zoom.active, "hit-stop zoom cannot override active stagger")
	deadline = Time.get_ticks_msec() + 3000
	var stagger_peak := 1.0
	while p.stagger_impact._zoom_active and Time.get_ticks_msec() < deadline:
		await frame()
		stagger_peak = maxf(stagger_peak, camera.zoom.x / baseline.x)
	check(stagger_peak >= 1.49 and stagger_peak <= 1.5001, "overlap keeps stagger at 1.5x without multiplying zoom")
	check(camera.zoom.is_equal_approx(baseline) and p.damage.is_stunned, "stagger still returns zoom before recovery")
	p._request_hit_stop(0.035)
	check(not camera.hit_stop_zoom.active and camera.zoom.is_equal_approx(baseline), "last stagger recovery segment stays at base zoom")
	await reset()
	camera.hit_stop_zoom_enabled = false
	check(p._request_hit_stop(0.035) > 0.0 and Engine.time_scale == p.hit_stop_scale and not camera.hit_stop_zoom.active, "zoom toggle preserves hit-stop timing")
	camera.hit_stop_zoom_enabled = true
	await reset()
	p.hit_stop_enabled = false
	check(p._request_hit_stop(0.035) == 0.0 and not camera.hit_stop_zoom.active, "disabled hit-stop cannot zoom")
	p.hit_stop_enabled = true
	check(p._request_hit_stop(0.0) == 0.0 and not camera.hit_stop_zoom.active, "zero-duration hit-stop cannot zoom")
	# Existing jump attack has damage but intentionally has no hit-stop source.
	p.jump_hitbox.begin_attack(20)
	p.jump_hitbox.set_damage_window(true)
	p.jump_hitbox._try_hit_body(enemy)
	check(enemy.current_health == 980 and not camera.hit_stop_zoom.active and CombatTime._effects.is_empty(), "jump damage retains existing no-hit-stop behavior")
	p.jump_hitbox.end_attack()
	p._request_hit_stop(0.1)
	await wait(0.02)
	var other := Camera2D.new()
	scene.add_child(other)
	other.make_current()
	await wait(0.03)
	check(camera.zoom.is_equal_approx(baseline) and not camera.hit_stop_zoom.active, "camera ownership change restores old zoom")
	other.queue_free()
	camera.make_current()
	await reset()
	p._request_hit_stop(0.1)
	p.queue_free()
	await wait(0.05)
	check(Engine.time_scale == 1.0 and CombatTime._effects.is_empty(), "freeing Player releases hit-stop and zoom without stale references")
	print("HITSTOP ZOOM RESULT checks=", checks, " failures=", failures, " display=", DisplayServer.get_name())
	get_tree().quit(1 if failures else 0)
