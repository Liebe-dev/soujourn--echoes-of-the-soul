extends SceneTree
## Exercise the real Q producer and rig consumer in isolated save/config data.

var checks := 0
var failures := 0
var actor: CharacterBody2D
var enemy: CharacterBody2D
var skill
var vfx: Node2D

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		quit(2)
		return
	var watchdog := Timer.new()
	watchdog.wait_time = 25.0
	watchdog.one_shot = true
	watchdog.ignore_time_scale = true
	watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(watchdog)
	watchdog.timeout.connect(func() -> void:
		paused = false
		Engine.time_scale = 1.0
		push_error("Q VFX validation timed out.")
		quit(2)
	)
	watchdog.start()
	var scene := load("res://scenes/enemy/spine_enemy_test.tscn").instantiate() as Node2D
	root.add_child(scene)
	current_scene = scene
	actor = scene.get_node("PlayableAdel") as CharacterBody2D
	enemy = scene.get_node("Enemy") as CharacterBody2D
	for name in ["Enemy", "SpineEnemy"]:
		var target := scene.get_node(name) as Node2D
		target.set_physics_process(false)
		target.position.x = 3000.0
	actor.vitals.simulation_enabled = false
	await wait_real(0.4)
	actor.set_physics_process(false)
	skill = actor.saber_skill
	vfx = actor.get_node("SpinePivot/SpineRig/SaberSkillVFX") as Node2D
	for prefix in ["tap", "charged", "full"]:
		skill.set(prefix + "_impact_zoom_enabled", false)
		skill.set(prefix + "_impact_slow_motion_enabled", false)
	for test: StringName in [&"test_hits_and_directions", &"test_whiff_and_interrupt", &"test_zero_stop_and_disable", &"test_pause_and_charged_freeze", &"test_owner_cleanup"]:
		if await call(test) != true:
			check(false, "%s completed without runtime errors" % test)
	paused = false
	Engine.time_scale = 1.0
	watchdog.queue_free()
	print("Q VFX RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("Q VFX ", "PASS " if ok else "FAIL ", label)

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await process_frame

func begin_fixture(tier: int, direction: int) -> void:
	skill.cancel()
	vfx.clear_effects()
	actor._set_facing_direction(direction)
	skill.tier = tier
	skill._active = true
	skill._confirmed = false
	skill._released = true
	skill._return_started = false
	skill._start_lunge()

func bounds(mesh: ArrayMesh) -> Rect2:
	var vertices: PackedVector2Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var rect := Rect2(vertices[0], Vector2.ZERO)
	for point in vertices:
		rect = rect.expand(point)
	return rect

func test_hits_and_directions() -> bool:
	check(vfx._skill == skill, "rig VFX binds to the production Q instance")
	check(vfx.tint.is_equal_approx(Color("#ef241e")), "both Q arcs use sampled reference red ef241e")
	check(vfx.highlight_tint.is_equal_approx(Color("#f55d58")), "painted accents use sampled reference pink f55d58")
	check(vfx._dash.texture == vfx.dash_texture and vfx._slash.texture == vfx.slash_texture, "both meshes draw the approved two-tooth tapered artwork")
	check(not vfx._dash_strip.is_empty() and not vfx._slash_strip.is_empty(), "approved art supplies continuous tail-to-cap strips")
	for tier in range(3):
		for direction in [1, -1]:
			begin_fixture(tier, direction)
			check(vfx._holding_dash and vfx._dash.visible, "tier %d facing %d lunge event holds VFX" % [tier, direction])
			check(vfx._dash.z_index == vfx._source_depth() + 1, "held dash draws in front of source")
			check(signf(vfx._dash.global_transform.determinant()) == float(direction), "dash mirrors with current facing")
			var start: Transform2D = vfx._dash.global_transform
			actor.position.x += 15.0 * direction
			vfx._process(0.0)
			check(is_equal_approx(vfx._dash.global_transform.origin.x - start.origin.x, 15.0 * direction), "held dash follows lunge translation")
			var full := bounds(vfx._dash.mesh)
			var contact_frame: Transform2D = vfx._dash_transform()
			skill._impact()
			skill._on_target_hit(enemy)
			var duration: float = [skill.tap_hit_stop_duration, skill.charged_hit_stop_duration, skill.full_hit_stop_duration][tier]
			check(is_equal_approx(vfx._impact_duration, duration) and not vfx._holding_dash, "confirmed hit adopts actual tier %d hit-stop duration" % tier)
			check(vfx._dash.global_transform.is_equal_approx(contact_frame), "switch to skill_5 preserves outgoing skill_4 placement")
			var born: int = vfx._impact_born
			skill._on_target_hit(enemy)
			check(vfx._impact_born == born, "additional target notification does not restart erase")
			vfx._tick_effects(born + int(duration * 500000.0))
			var half := bounds(vfx._dash.mesh)
			check(half.position.x > full.position.x + 100.0 and half.end.x <= full.end.x + 1.0, "pointed rear tail disappears before blade cap")
			var full_slash := bounds(vfx._full_slash)
			var half_slash := bounds(vfx._build_slash_mesh(0.5))
			check(half_slash.end.x < full_slash.end.x - 100.0, "slash consumes its pointed right tail before upper-left blade cap")
			skill._start_recovery()
			check(vfx._slash.visible, "recovery event starts independent slash")
			var slash_transform: Transform2D = vfx._slash.global_transform
			actor.position.x += 10.0
			check(vfx._slash.global_transform.is_equal_approx(slash_transform), "slash residual stays world anchored")
			skill._finish_ready()
			check(vfx._slash.visible, "normal completion preserves short slash remnant")
			await wait_real(maxf(vfx.slash_lifetime, duration) + 0.025)
			check(not vfx._dash.visible and not vfx._slash.visible, "both Q arcs expire on real time")
	return true

func test_whiff_and_interrupt() -> bool:
	for direction in [1, -1]:
		begin_fixture(0, direction)
		skill._start_recovery()
		check(not vfx._dash.visible and vfx._slash.visible, "whiff facing %d clears dash immediately, keeps separate slash" % direction)
		skill.cancel()
		check(not vfx._dash.visible and not vfx._slash.visible, "interruption in recovery clears residuals")
	begin_fixture(0, 1)
	skill.cancel()
	check(not vfx._dash.visible and not vfx._holding_dash, "interruption during dash clears held effect")
	begin_fixture(0, 1)
	skill._impact()
	skill._on_target_hit(enemy)
	skill.cancel()
	check(not vfx._dash.visible and vfx._impact_born < 0, "interruption during impact clears real-clock remnant")
	return true

func test_zero_stop_and_disable() -> bool:
	actor.hit_stop_enabled = false
	begin_fixture(0, 1)
	skill._impact()
	skill._on_target_hit(enemy)
	check(is_zero_approx(vfx._impact_duration) and not vfx._dash.visible, "disabled hit-stop produces no artificial erase lifetime")
	actor.hit_stop_enabled = true
	skill.cancel()
	begin_fixture(0, 1)
	vfx.enabled = false
	vfx._process(0.0)
	check(not vfx._dash.visible and not vfx._slash.visible, "component disable clears all layers")
	skill._start_recovery()
	check(not vfx._slash.visible, "disabled component ignores recovery events")
	vfx.enabled = true
	skill.cancel()
	begin_fixture(0, 1)
	check(vfx._dash.visible, "next cast after re-enable starts normally")
	return true

func test_pause_and_charged_freeze() -> bool:
	begin_fixture(0, 1)
	skill._start_recovery()
	paused = true
	await wait_real(vfx.slash_lifetime + 0.035)
	check(not vfx._slash.visible, "tree pause does not extend slash life")
	paused = false
	skill.cancel()
	skill.charged_impact_zoom_enabled = true
	begin_fixture(1, 1)
	skill._impact()
	skill._on_target_hit(enemy)
	await wait_real(0.11)
	skill._start_recovery()
	skill._finish()
	check(paused and skill.is_finish_freezing(), "actual charged Q enters frozen zoom return")
	await wait_real(vfx.slash_lifetime + 0.025)
	check(not vfx._slash.visible and not vfx._dash.visible, "Q VFX expires during actual charged finish freeze")
	await wait_real(0.15)
	check(not paused, "charged return releases its pause after VFX clears")
	skill.cancel()
	return true

func test_owner_cleanup() -> bool:
	begin_fixture(0, 1)
	var dash: Node = vfx._dash
	var slash: Node = vfx._slash
	actor.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(dash) and not is_instance_valid(slash), "owner removal frees world-anchored mesh nodes")
	return true
