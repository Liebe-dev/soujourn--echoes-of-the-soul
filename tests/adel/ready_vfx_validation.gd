extends SceneTree
## Exercise the actual Player presentation library, including its private held Ready.

var checks := 0
var failures := 0
var actor: CharacterBody2D
var player: AnimationPlayer
var vfx: SaberReadyVFX

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		push_error("Run Ready VFX validation in an isolated CodexSaberVFX project.")
		quit(2)
		return
	var watchdog := Timer.new()
	watchdog.wait_time = 20.0
	watchdog.one_shot = true
	watchdog.ignore_time_scale = true
	watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(watchdog)
	watchdog.timeout.connect(func() -> void:
		Engine.time_scale = 1.0
		paused = false
		push_error("Ready VFX validation timed out.")
		quit(2)
	)
	watchdog.start()
	actor = load("res://scenes/adel/playable_adel.tscn").instantiate() as CharacterBody2D
	root.add_child(actor)
	current_scene = actor
	actor.set_process(false)
	actor.set_physics_process(false)
	actor.vitals.simulation_enabled = false
	player = actor.spine_anim as AnimationPlayer
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	vfx = actor.get_node("SpinePivot/SpineRig/SaberReadyVFX") as SaberReadyVFX
	vfx.set_process(false)
	for test: StringName in [&"test_authored_flick", &"test_final_only_library", &"test_skip_cancel_facing", &"test_clock_and_hit_stop", &"test_pause_capacity_owner"]:
		if await call(test) != true:
			check(false, "%s completed without a runtime error" % test)
	Engine.time_scale = 1.0
	paused = false
	watchdog.queue_free()
	print("READY VFX RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("READY VFX ", "PASS " if ok else "FAIL ", label)

func pose(final_only: bool, time: float) -> void:
	player.stop()
	actor.presentation.ready_pose(final_only)
	player.advance(time)
	vfx._sample_animation()
	vfx._tick_residuals(Time.get_ticks_usec())

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await process_frame

func test_authored_flick() -> bool:
	pose(false, 0.34)
	check(vfx._markers.is_equal_approx(Vector2(0.345, 0.35)), "Ready reads authored motion/final markers from current resource")
	check(not vfx._overhead.visible and not vfx._front.visible and vfx._residuals.is_empty(), "preparation does not emit")
	player.advance(0.006)
	vfx._sample_animation()
	check(vfx._overhead.visible and not vfx._front.visible and vfx._residuals.is_empty(), "five-millisecond middle pose displays overhead flick only")
	player.advance(0.005)
	vfx._sample_animation()
	check(not vfx._overhead.visible and vfx._front.visible and vfx._residuals.size() == 1, "final pose emits front stroke and short independent residual")
	var residual: MeshInstance2D = vfx._residuals[0].node
	check(residual.material != vfx._front.material, "attached and residual uniforms are independent")
	check(residual.z_index == vfx._source_depth() - 1, "Ready stays just behind blade as approved")
	vfx._sample_animation()
	check(vfx._residuals.size() == 1, "same playback emits residual only once")
	vfx.clear_effects()
	return true

func test_final_only_library() -> bool:
	pose(true, 0.0)
	check(vfx._markers.x < 0.0 and is_zero_approx(vfx._markers.y), "actual private Ready variant has no flick marker")
	player.advance(0.50)
	vfx._sample_animation()
	check(vfx._residuals.is_empty() and not vfx._front.visible and not vfx._overhead.visible, "held final Ready never emits a delayed ghost slash")
	pose(false, 0.36)
	check(vfx._residuals.size() == 1, "full Ready emits again after held variant replaced the library entry")
	var residual: MeshInstance2D = vfx._residuals[0].node
	pose(true, 0.50)
	check(vfx._residuals.size() == 1 and not vfx._front.visible, "switching to final-only removes attachment without spawning a second residual")
	check(is_instance_valid(residual), "earlier real flick survives variant switch")
	vfx.clear_effects()
	pose(false, 0.20)
	player.play(&"idle")
	player.advance(0.0)
	vfx._sample_animation()
	check(vfx._residuals.is_empty(), "cancel before flick emits nothing")
	return true

func test_skip_cancel_facing() -> bool:
	pose(false, 0.40)
	check(vfx._source.frame == 2 and vfx._residuals.size() == 1, "skipping the 5 ms middle frame still emits the forward flick")
	check(not vfx._overhead.visible, "skipped overhead is not emitted late on final pose")
	var node: MeshInstance2D = vfx._residuals[0].node
	var initial := node.global_transform
	player.play(&"saber_attack_1")
	player.advance(0.16)
	vfx._sample_animation()
	check(not vfx._front.visible and vfx._residuals.size() == 1, "next attack removes attachment while Ready remnant survives")
	actor.position += Vector2(80, 10)
	actor._set_facing_direction(-1)
	check(node.global_transform.is_equal_approx(initial), "old Ready remnant stays fixed when actor moves and flips")
	pose(false, 0.36)
	check((vfx._residuals.back().node as MeshInstance2D).global_transform.determinant() < 0.0, "new flick mirrors to the left")
	check((vfx._front.material as ShaderMaterial) != (vfx._residuals.back().node as MeshInstance2D).material, "mirrored flick keeps separate materials")
	actor.position = Vector2.ZERO
	actor._set_facing_direction(1)
	vfx.clear_effects()
	return true

func test_clock_and_hit_stop() -> bool:
	vfx.set_process(true)
	pose(false, 0.346)
	Engine.time_scale = 0.01
	await wait_real(0.035)
	check(not vfx._overhead.visible, "frozen middle pose cannot prolong overhead beyond its real-time cap")
	pose(false, 0.36)
	var frozen_position := player.current_animation_position
	var mat := (vfx._residuals[0].node as MeshInstance2D).material as ShaderMaterial
	await wait_real(0.04)
	check(vfx._residuals.is_empty() or float(mat.get_shader_parameter("progress")) > 0.2, "Ready residual progresses during near-zero time scale")
	check(not vfx._front.visible and is_equal_approx(player.current_animation_position, frozen_position), "attachment expires without moving frozen animation")
	await wait_real(0.09)
	check(vfx._residuals.is_empty(), "frozen final pose leaves no Ready residual after short real lifetime")
	Engine.time_scale = 1.0
	pose(false, 0.36)
	var combat_time := root.get_node("CombatTime")
	combat_time.request(actor, &"hit_stop", 0.01, 0.18)
	await wait_real(0.13)
	check(combat_time.is_hit_stopping() and vfx._residuals.is_empty() and not vfx._front.visible, "Ready is completely clear while actual CombatTime hit-stop still holds")
	await wait_real(0.08)
	check(is_equal_approx(Engine.time_scale, 1.0), "Ready does not interfere with CombatTime restoring speed")
	return true

func test_pause_capacity_owner() -> bool:
	pose(false, 0.36)
	paused = true
	await wait_real(0.13)
	check(vfx._residuals.is_empty() and not vfx._front.visible, "scene-tree pause does not keep Ready effects stuck")
	paused = false
	vfx.set_process(false)
	vfx.max_residuals = 2
	for i in range(4):
		pose(false, 0.36)
	check(vfx._residuals.size() == 2, "rapid Ready replays respect capacity")
	vfx.enabled = false
	vfx._process(0.0)
	check(vfx._residuals.is_empty() and not vfx._front.visible and not vfx._overhead.visible, "disabling clears every Ready layer")
	vfx.enabled = true
	pose(false, 0.36)
	var node: MeshInstance2D = vfx._residuals[0].node
	actor.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(node), "owner removal frees anchored Ready residual")
	return true
