extends SceneTree
## Real rig + authored markers; run only in an isolated CodexSaberVFX project.

var checks := 0
var failures := 0
var rig: Node2D
var player: AnimationPlayer
var vfx: JumpAttackVFX

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		push_error("Run jump VFX validation in an isolated CodexSaberVFX user directory.")
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
		push_error("Jump VFX validation timed out.")
		quit(2)
	)
	watchdog.start()
	rig = load("res://asset/Character/Adel/adel spine action use.tscn").instantiate() as Node2D
	root.add_child(rig)
	current_scene = rig
	player = rig.get_node("AnimationPlayer") as AnimationPlayer
	vfx = rig.get_node("JumpAttackVFX") as JumpAttackVFX
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	vfx.set_process(false)
	for test: StringName in [&"test_markers_and_air", &"test_landing_and_transition", &"test_crush_and_capacity", &"test_real_clock", &"test_combat_hit_stop", &"test_pause_and_owner"]:
		if await call(test) != true:
			check(false, "%s finished without a runtime error" % test)
	Engine.time_scale = 1.0
	paused = false
	watchdog.queue_free()
	print("JUMP VFX RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("JUMP VFX ", "PASS " if ok else "FAIL ", label)

func pose(clip: StringName, position: float) -> void:
	player.stop()
	player.play(clip)
	player.advance(position)
	vfx._sample_animation()
	vfx._tick_effects(Time.get_ticks_usec())

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await process_frame

func test_markers_and_air() -> bool:
	check(is_equal_approx(vfx._markers[vfx.AIR_CLIP], 0.18), "AIR uses authored final-frame marker")
	check(is_zero_approx(vfx._markers[vfx.LAND_CLIP]), "landing emits at authored frame 2, time zero")
	pose(vfx.AIR_CLIP, 0.17)
	check(vfx._effects.is_empty() and not vfx._attached.visible, "AIR preparation has no VFX")
	player.advance(0.015)
	vfx._sample_animation()
	check(vfx._effects.size() == 1 and vfx._attached.visible, "AIR final frame emits attached + residual")
	var record: Dictionary = vfx._effects[0]
	var residual: MeshInstance2D = record.nodes[0]
	check(residual.material != vfx._attached.material, "AIR materials have independent age uniforms")
	check(residual.z_index == 49 and vfx._attached.z_index == 49, "AIR depth matches accepted preview behind blade")
	var old_transform := residual.global_transform
	player.play(&"saber_ready")
	player.advance(0.0)
	vfx._sample_animation()
	check(not vfx._attached.visible and vfx._effects.size() == 1, "clip change removes attached AIR only")
	rig.position += Vector2(80, 15)
	rig.scale.x = -1.0
	check(residual.global_transform.is_equal_approx(old_transform), "AIR remnant does not follow translation or new facing")
	pose(vfx.AIR_CLIP, 0.19)
	check(vfx._attached.global_transform.determinant() < 0.0, "new AIR mirrors with current facing")
	rig.scale = Vector2.ONE
	rig.position = Vector2.ZERO
	vfx.clear_effects()
	return true

func test_landing_and_transition() -> bool:
	pose(vfx.LAND_CLIP, 0.0)
	check(vfx._effects.size() == 1, "landing starts even at animation time zero")
	var record: Dictionary = vfx._effects[0]
	check(record.nodes.size() == 2, "landing has only main crush and clean low air")
	check(not vfx._attached.visible, "landing has no additional sword-covering layer")
	var crush: MeshInstance2D = record.nodes[0]
	var ground: MeshInstance2D = record.nodes[1]
	check(crush.z_index == 51 and ground.z_index == 52, "landing draws over authored strike sprite")
	var transform := crush.global_transform
	var air_transform := ground.global_transform
	var before_scale := vfx._source_frame_transform()
	player.advance(0.03)
	vfx._sample_animation()
	check(vfx._effects.size() == 1, "last landing frame does not retrigger impact")
	player.play(&"saber_attack_1")
	player.advance(0.16)
	vfx._sample_animation()
	rig.position += Vector2(110, 10)
	rig.scale.x = -1.0
	check(crush.global_transform.is_equal_approx(transform) and ground.global_transform.is_equal_approx(air_transform), "landing survives next attack and stays anchored in original direction")
	pose(vfx.LAND_CLIP, 0.15)
	check(vfx._effects.size() == 2, "skipping initial landing frame still emits once")
	var newest: Dictionary = vfx._effects.back()
	check((newest.nodes[0] as MeshInstance2D).global_transform.determinant() < 0.0, "new landing mirrors left")
	check(not before_scale.is_equal_approx(vfx._source_frame_transform()), "facing and movement changed source, not old effects")
	rig.scale = Vector2.ONE
	rig.position = Vector2.ZERO
	vfx.clear_effects()
	return true

func mesh_height(mesh: ArrayMesh) -> float:
	var vertices: PackedVector2Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var low := INF
	var high := -INF
	for point in vertices:
		low = minf(low, point.y)
		high = maxf(high, point.y)
	return high - low

func test_crush_and_capacity() -> bool:
	pose(vfx.LAND_CLIP, 0.0)
	var record: Dictionary = vfx._effects[0]
	var crush: MeshInstance2D = record.nodes[0]
	var full_height := mesh_height(crush.mesh)
	vfx._tick_effects(int(record.born) + 62000)
	check(mesh_height(crush.mesh) < full_height * 0.30, "main crescent compresses vertically toward floor")
	vfx._tick_effects(int(record.born) + 140000)
	check(not crush.visible and (record.nodes[1] as MeshInstance2D).visible, "crush ends first while low ground air continues")
	vfx._tick_effects(int(record.born) + 280000)
	check(vfx._effects.is_empty(), "all landing effects end within approved short lifetime")
	vfx.max_residuals = 2
	for i in range(4):
		pose(vfx.LAND_CLIP, 0.0)
	check(vfx._effects.size() == 2, "rapid replays respect effect capacity")
	vfx.enabled = false
	vfx._process(0.0)
	check(vfx._effects.is_empty() and not vfx._attached.visible, "disabling component clears all layers")
	vfx.enabled = true
	vfx.max_residuals = 3
	return true

func test_real_clock() -> bool:
	vfx.set_process(true)
	pose(vfx.AIR_CLIP, 0.19)
	Engine.time_scale = 0.01
	await wait_real(0.10)
	check(vfx._effects.is_empty() and not vfx._attached.visible, "AIR clears during a frozen final frame without leaving attached arc")
	pose(vfx.LAND_CLIP, 0.0)
	var frozen_position := player.current_animation_position
	await wait_real(0.16)
	check(vfx._effects.size() == 1 and not (vfx._effects[0].nodes[0] as MeshInstance2D).visible, "crush finishes while near-zero time scale holds the pose")
	check(is_equal_approx(player.current_animation_position, frozen_position), "effect does not advance or modify the animation")
	await wait_real(0.15)
	check(vfx._effects.is_empty(), "ground air also expires on real time")
	Engine.time_scale = 1.0
	return true

func test_combat_hit_stop() -> bool:
	pose(vfx.LAND_CLIP, 0.0)
	var combat_time := root.get_node("CombatTime")
	combat_time.request(rig, &"hit_stop", 0.01, 0.22)
	await wait_real(0.15)
	check(combat_time.is_hit_stopping() and vfx._effects.size() == 1, "real CombatTime hit-stop coexists with landing residual")
	check(not (vfx._effects[0].nodes[0] as MeshInstance2D).visible, "main crush has already ended inside actual hit-stop")
	await wait_real(0.15)
	check(vfx._effects.is_empty() and is_equal_approx(Engine.time_scale, 1.0), "hit-stop restores speed and landing leaves no remnant")
	return true

func test_pause_and_owner() -> bool:
	pose(vfx.LAND_CLIP, 0.0)
	paused = true
	await wait_real(0.31)
	check(vfx._effects.is_empty(), "scene-tree pause does not extend visual remnants")
	paused = false
	pose(vfx.LAND_CLIP, 0.0)
	var nodes: Array = vfx._effects[0].nodes.duplicate()
	rig.queue_free()
	await process_frame
	await process_frame
	for node in nodes:
		check(not is_instance_valid(node), "removing owner frees world-anchored landing node")
	return true
