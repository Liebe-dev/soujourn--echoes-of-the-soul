extends SceneTree
## Run with --script in an isolated project/user directory; exits non-zero on failure.

var checks := 0
var failures := 0
var rig: Node2D
var player: AnimationPlayer
var vfx: SaberSwingVFX

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		push_error("Run Saber VFX validation in an isolated CodexSaberVFX user directory.")
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
		push_error("Saber VFX validation timed out.")
		quit(2)
	)
	watchdog.start()
	rig = load("res://asset/Character/Adel/adel spine action use.tscn").instantiate() as Node2D
	root.add_child(rig)
	current_scene = rig
	player = rig.get_node("AnimationPlayer") as AnimationPlayer
	vfx = rig.get_node("SaberSwingVFX") as SaberSwingVFX
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for test: StringName in [&"test_frames_and_layers", &"test_transition_and_facing", &"test_attack_directions", &"test_follow_through_shape", &"test_real_time", &"test_combat_time_hit_stop", &"test_pause_and_cleanup", &"test_skipped_frame_and_capacity"]:
		if await call(test) != true:
			check(false, "%s completed without a runtime error" % test)
	Engine.time_scale = 1.0
	paused = false
	var remaining := vfx._residuals.duplicate()
	rig.queue_free()
	await process_frame
	await process_frame
	for record: Dictionary in remaining:
		check(not is_instance_valid(record.sprite), "owner removal frees world-anchored residual")
	watchdog.queue_free()
	print("SABER VFX RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("SABER VFX ", "PASS " if ok else "FAIL ", label)

func pose(attack: int, position: float) -> void:
	player.stop()
	player.play("saber_attack_%d" % attack)
	player.advance(position)
	vfx._sample_animation()

func wait_real(seconds: float) -> void:
	# A timer created in the same tick as a time_scale change can consume that
	# tick's previous delta. Measure the requirement against the actual clock.
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await process_frame

func test_frames_and_layers() -> bool:
	for attack in range(1, 5):
		vfx.clear_effects()
		pose(attack, 0.14)
		check(vfx._residuals.is_empty() and not vfx._attached.visible, "attack %d windup has no VFX" % attack)
		player.advance(0.02)
		vfx._sample_animation()
		check(vfx._residuals.size() == 1 and vfx._attached.visible, "attack %d strike emits both layers at authored frame marker" % attack)
		var attached_material := vfx._attached.material as ShaderMaterial
		var residual_material := vfx._residuals[0].sprite.material as ShaderMaterial
		check(attached_material != residual_material, "attack %d layers have independent fade uniforms" % attack)
		check(vfx._attached.texture == vfx.attack_textures[attack - 1], "attack %d uses approved artwork" % attack)
		player.advance(0.06)
		vfx._sample_animation()
		check(not vfx._attached.visible and vfx._residuals.size() == 1, "attack %d final pose retains only residual" % attack)
	return true

func test_transition_and_facing() -> bool:
	vfx.clear_effects()
	pose(1, 0.16)
	var residual: Sprite2D = vfx._residuals[0].sprite
	var emitted_transform := residual.global_transform
	player.play(&"saber_ready")
	player.advance(0.0)
	vfx._sample_animation()
	check(not vfx._attached.visible and vfx._residuals.size() == 1, "animation change removes attached layer while residual survives")
	rig.position += Vector2(60, 0)
	rig.scale.x = -1.0
	vfx._sample_animation()
	check(residual.global_transform.is_equal_approx(emitted_transform), "old residual does not move or flip with the next pose")
	pose(2, 0.16)
	check(vfx._attached.global_transform.determinant() < 0.0, "new attached layer follows left-facing source transform")
	check(vfx._attached.z_index == 49, "slash draws just behind authored attack sprite")
	rig.scale.x = 1.0
	rig.position = Vector2.ZERO
	return true

func test_real_time() -> bool:
	vfx.clear_effects()
	pose(1, 0.22)
	var residual: Sprite2D = vfx._residuals[0].sprite
	var material := residual.material as ShaderMaterial
	var animation_position := player.current_animation_position
	Engine.time_scale = 0.01
	await wait_real(0.12)
	check(float(material.get_shader_parameter("motion_progress")) > 0.2, "follow-through advances during near-zero time scale")
	check(float(material.get_shader_parameter("head_phase")) > 1.0 and float(material.get_shader_parameter("width_scale")) < 1.0, "frozen pose still has a travelling head and narrowing stroke")
	check(is_equal_approx(player.current_animation_position, animation_position), "VFX moves while animation pose remains frozen")
	await wait_real(0.28)
	check(vfx._residuals.is_empty(), "residual expires on wall time during hit-stop")
	Engine.time_scale = 1.0
	return true

func stroke_point(attack: int, phase: float) -> Vector2:
	var index := attack - 1
	var arc := vfx._arc_setup(index)
	var angle := arc.x + arc.y * phase
	var point: Vector2 = vfx.ARC_CENTERS[index] + Vector2(cos(angle), sin(angle)) * vfx.ARC_RADII[index]
	return vfx._attack_transform(index) * point

func test_attack_directions() -> bool:
	check(stroke_point(1, 0.9).y > stroke_point(1, 0.1).y, "attack 1 sweeps from above to below")
	check(stroke_point(3, 0.9).x < stroke_point(3, 0.1).x, "attack 3 sweeps right to left in the default right-facing frame")
	check(stroke_point(4, 0.9).x > stroke_point(4, 0.1).x, "attack 4 retains its left-to-right shoulder sweep")
	check(vfx._attack_transform(1).is_equal_approx(Transform2D.IDENTITY) and not vfx.attack_reverse_motion[1], "attack 2 keeps its existing placement and direction")
	var shoulder := stroke_point(4, 0.5)
	check(shoulder.y > 250.0 and shoulder.y < 430.0, "attack 4 stays at shoulder height instead of over the head")
	check(is_equal_approx(vfx.attack_scales[3].y, 0.22) and vfx.attack_stroke_widths[3] < 1.0, "attack 4 independently flattens its arc and thins the painted stroke")
	for attack in [1, 3, 4]:
		vfx.clear_effects()
		pose(attack, 0.16)
		var residual: Sprite2D = vfx._residuals[0].sprite
		check(residual.global_transform.is_equal_approx(vfx._attached.global_transform), "attack %d applies the same per-attack transform to both layers" % attack)
		check(residual.region_enabled and residual.get_rect().size.x > residual.texture.get_width(), "attack %d follow-through has room beyond the source bitmap" % attack)
		var material := residual.material as ShaderMaterial
		var arc := vfx._arc_setup(attack - 1)
		check(is_equal_approx(float(material.get_shader_parameter("arc_sweep")), arc.y), "attack %d sends the configured direction to its residual shader" % attack)
		check(bool(material.get_shader_parameter("reverse_artwork")) == (attack == 3), "attack %d painted head/tail matches its configured swing direction" % attack)
	var original_offset := vfx.attack_offsets_pixels[3]
	vfx.attack_offsets_pixels[3] += Vector2(0, 20)
	check(is_equal_approx(stroke_point(4, 0.5).y - shoulder.y, 20.0), "per-attack offset moves attack 4 without editing its texture")
	check(vfx._attack_transform(1).is_equal_approx(Transform2D.IDENTITY), "tuning attack 4 does not alter attack 2")
	vfx.attack_offsets_pixels[3] = original_offset
	vfx.clear_effects()
	return true

func test_pause_and_cleanup() -> bool:
	vfx.clear_effects()
	pose(4, 0.22)
	var material := vfx._residuals[0].sprite.material as ShaderMaterial
	paused = true
	await wait_real(0.11)
	check(float(material.get_shader_parameter("motion_progress")) > 0.1, "residual advances while the scene tree is paused")
	await wait_real(0.38)
	check(vfx._residuals.is_empty(), "finisher clears completely after its short real-time lifetime")
	paused = false
	return true

func test_combat_time_hit_stop() -> bool:
	vfx.clear_effects()
	pose(2, 0.22)
	var combat_time := root.get_node("CombatTime")
	combat_time.request(rig, &"hit_stop", 0.01, 0.18)
	await wait_real(0.10)
	var material := vfx._residuals[0].sprite.material as ShaderMaterial
	check(combat_time.is_hit_stopping() and float(material.get_shader_parameter("motion_progress")) > 0.15, "actual CombatTime hit-stop keeps the residual moving")
	await wait_real(0.12)
	check(not combat_time.is_hit_stopping() and is_equal_approx(Engine.time_scale, 1.0), "CombatTime restores normal speed without VFX interference")
	return true

func test_follow_through_shape() -> bool:
	var full := vfx._motion_shape(0.0)
	check(full.is_equal_approx(Vector3(0.0, 1.0, 1.0)), "strike starts at the approved full arc and width")
	var previous := full
	for phase in [0.2, 0.5, 0.75, 0.9]:
		var shape := vfx._motion_shape(phase)
		check(shape.y > previous.y and shape.x > previous.x, "head and tail both advance at phase %.2f" % phase)
		check(shape.y - shape.x < previous.y - previous.x and shape.z < previous.z, "tail catches the head and width narrows at phase %.2f" % phase)
		previous = shape
	check(previous.y - previous.x < 0.05 and previous.z < 0.1, "last remnant is a short thin tip, not a full static crescent")
	vfx.clear_effects()
	pose(1, 0.22)
	var record: Dictionary = vfx._residuals[0]
	vfx._tick_residuals(int(record.born) + int(float(record.life) * 0.5 * 1000000.0))
	var material := record.sprite.material as ShaderMaterial
	check(is_equal_approx(float(material.get_shader_parameter("opacity")), vfx.residual_opacity), "white core retains its opacity while the shape contracts")
	vfx.clear_effects()
	return true

func test_skipped_frame_and_capacity() -> bool:
	vfx.clear_effects()
	pose(3, 0.25)
	check(vfx._residuals.size() == 1 and not vfx._attached.visible, "crossing the strike between render ticks still emits one residual")
	vfx._sample_animation()
	check(vfx._residuals.size() == 1, "same swing never emits duplicate residuals")
	vfx.max_residuals = 2
	for attack in range(1, 5):
		pose(attack, 0.16)
	check(vfx._residuals.size() == 2, "rapid attacks respect residual capacity")
	vfx.enabled = false
	vfx._process(0.0)
	check(vfx._residuals.is_empty() and not vfx._attached.visible, "disabling VFX clears both layers")
	vfx.enabled = true
	pose(4, 0.16)
	return true
