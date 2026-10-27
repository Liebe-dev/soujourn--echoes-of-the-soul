extends SceneTree
## Exercise the production Player/combat boundary in an isolated user directory.

var checks := 0
var failures := 0
var actor: CharacterBody2D
var vfx: JumpAttackVFX

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
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
		push_error("Descent VFX validation timed out.")
		quit(2)
	)
	watchdog.start()
	var scene := load("res://scenes/enemy/spine_enemy_test.tscn").instantiate() as Node2D
	root.add_child(scene)
	current_scene = scene
	actor = scene.get_node("PlayableAdel") as CharacterBody2D
	vfx = actor.get_node("SpinePivot/SpineRig/JumpAttackVFX") as JumpAttackVFX
	actor.vitals.simulation_enabled = false
	for enemy_name in ["Enemy", "SpineEnemy"]:
		var enemy := scene.get_node(enemy_name) as Node2D
		enemy.set_physics_process(false)
		enemy.position.x = 3000.0
	await wait_real(0.4)
	for test: StringName in [&"test_state_boundary", &"test_facing_and_interrupt", &"test_hit_stop_and_cleanup"]:
		if await call(test) != true:
			check(false, "%s completed without a runtime error" % test)
	Engine.time_scale = 1.0
	paused = false
	watchdog.queue_free()
	print("DESCENT VFX RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("DESCENT VFX ", "PASS " if ok else "FAIL ", label)

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await process_frame

func test_state_boundary() -> bool:
	check(actor.is_on_floor(), "production Player settles on the test floor")
	vfx._sample_descent()
	check(not vfx._descent.visible, "grounded idle has no descent crescent")
	actor.set_physics_process(false)
	actor.global_position.y -= 360.0
	actor.velocity = Vector2.ZERO
	actor.move_and_slide()
	actor.spine_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	actor.combat.interrupt()
	vfx._sample_descent()
	check(not actor.is_on_floor() and not vfx._descent.visible, "ordinary airborne state has no descent crescent")
	actor.combat.start_jump_attack(0.25, true)
	actor.spine_anim.play(vfx.AIR_CLIP)
	actor.spine_anim.advance(0.19)
	vfx._sample_descent()
	check(vfx._source.frame == 1 and not vfx._descent.visible, "AIR final pose during preparation does not show the descent layer")
	actor.spine_anim.advance(0.10)
	vfx._sample_descent()
	check(not actor.combat.is_jump_attack_hanging and vfx._descent.visible, "AIR completion hands off to the held descent crescent")
	check(actor.spine_anim.current_animation.is_empty(), "descent remains active after the AIR clip ends")
	check(vfx._descent.z_index == vfx._source_depth() + 1, "crescent draws over the approved portion of the blade")
	await wait_real(0.20)
	check(vfx._descent.visible and vfx._source.frame == 1, "long held descent outlives the short AIR residual")
	check(vfx._effects.is_empty(), "sustained descent does not accumulate world residuals")
	return true

func test_facing_and_interrupt() -> bool:
	var before := vfx._descent.global_transform
	actor.global_position += Vector2(20, 45)
	vfx._sample_descent()
	check((vfx._descent.global_transform.origin - before.origin).is_equal_approx(Vector2(20, 45)), "descent follows the moving player")
	actor.presentation.face(-1)
	vfx._sample_descent()
	check(vfx._descent.global_transform.determinant() < 0.0, "descent mirrors left with the blade")
	actor.presentation.face(1)
	vfx._sample_descent()
	check(vfx._descent.global_transform.determinant() > 0.0, "descent mirrors back right")
	vfx.descent_enabled = false
	vfx._sample_descent()
	check(not vfx._descent.visible, "descent can be disabled independently")
	vfx.descent_enabled = true
	vfx._source.visible = false
	vfx._sample_descent()
	check(not vfx._descent.visible, "hidden source has no floating crescent")
	vfx._source.visible = true
	# Exercise the handoff even if combat still reports descent for this frame.
	vfx._sample_descent()
	vfx._spawn_landing(vfx._source_frame_transform(), vfx.floor_y_pixels)
	check(not vfx._descent.visible, "LAND emission immediately hides descent before the combat state changes")
	vfx._sample_descent()
	check(not vfx._descent.visible, "LAND emission prevents descent from returning on stale combat state")
	vfx.clear_effects()
	actor.combat.begin_jump_attack_land()
	actor.spine_anim.play(vfx.LAND_CLIP)
	actor.spine_anim.advance(0.0)
	vfx._process(0.0)
	check(not vfx._descent.visible and vfx._effects.size() == 1, "LAND replaces the descent layer with the existing impact")
	check(vfx._effects[0].nodes.size() == 2, "approved LAND retains only crush and ground air")
	vfx.clear_effects()
	actor.combat.cancel_jump_attack_land()
	actor.combat.start_jump_attack(0.25, true)
	actor.spine_anim.play(vfx.AIR_CLIP)
	actor.spine_anim.advance(0.29)
	vfx._sample_descent()
	check(vfx._descent.visible, "next dive reuses the held layer")
	actor.combat.interrupt()
	vfx._sample_descent()
	check(not vfx._descent.visible, "interruption removes descent immediately")
	return true

func test_hit_stop_and_cleanup() -> bool:
	actor.combat.start_jump_attack(0.25, true)
	actor.spine_anim.play(vfx.AIR_CLIP)
	actor.spine_anim.advance(0.29)
	vfx._sample_descent()
	root.get_node("CombatTime").request(actor, &"hit_stop", 0.01, 0.12)
	await wait_real(0.05)
	check(vfx._descent.visible and root.get_node("CombatTime").is_hit_stopping(), "held descent survives real CombatTime hit-stop")
	await wait_real(0.12)
	check(vfx._descent.visible and is_equal_approx(Engine.time_scale, 1.0), "real clock restores speed without expiring an ongoing dive")
	vfx.enabled = false
	vfx._process(0.0)
	check(not vfx._descent.visible, "component disable clears the held crescent")
	vfx.enabled = true
	vfx._sample_descent()
	check(vfx._descent.visible, "component re-enable restores only a still-active descent")
	var held_node := vfx._descent
	actor.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(held_node), "removing Player frees the attached descent layer")
	return true
