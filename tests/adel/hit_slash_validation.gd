extends SceneTree
## Real Player wiring and Area2D contacts, isolated save/config only.

class Receiver:
	extends CharacterBody2D
	var current_health := 1000
	var attempts := 0
	var accepted := 0
	var reject := false
	var lethal := false
	func take_damage(amount: int, _from: Vector2 = Vector2.INF) -> bool:
		attempts += 1
		if reject or amount <= 0: return false
		current_health -= amount
		accepted += 1
		if lethal: queue_free()
		return true

var checks := 0
var failures := 0
var actor: CharacterBody2D
var vfx: SaberHitSlashVFX
var scene: Node2D
var receivers: Array[Receiver] = []

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		quit(2)
		return
	var watchdog := Timer.new()
	watchdog.wait_time = 30.0
	watchdog.one_shot = true
	watchdog.ignore_time_scale = true
	watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(watchdog)
	watchdog.timeout.connect(func() -> void:
		paused = false
		Engine.time_scale = 1.0
		push_error("Hit slash validation timed out")
		quit(2))
	watchdog.start()
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate() as Node2D
	root.add_child(scene)
	current_scene = scene
	actor = scene.get_node("PlayableAdel") as CharacterBody2D
	for name in ["Enemy", "SpineEnemy"]:
		var target := scene.get_node(name) as Node2D
		target.set_physics_process(false)
		target.position.x = 10000.0
	actor.vitals.simulation_enabled = false
	actor.set_physics_process(false)
	actor.spine_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	actor.saber_hitbox.hitbox_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	vfx = actor.hit_slash_vfx
	for test: StringName in [&"test_physics_and_geometry", &"test_multiple_targets_and_following", &"test_rejected_miss_and_q", &"test_real_clock_and_pause", &"test_capacity_and_lethal", &"test_owner_cleanup"]:
		if await call(test) != true: check(false, "%s completed without runtime error" % test)
	paused = false
	Engine.time_scale = 1.0
	watchdog.queue_free()
	print("HIT SLASH RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("HIT SLASH ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 2) -> void:
	for i in count:
		await physics_frame
		await process_frame

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline: await process_frame

func reset_fixture() -> void:
	paused = false
	root.get_node("CombatTime").remove(actor)
	Engine.time_scale = 1.0
	actor.saber_hitbox.stop_attack_window()
	vfx.clear_effects()
	vfx.enabled = true
	vfx.max_marks = 24
	actor.hit_stop_enabled = true
	for receiver in receivers:
		if is_instance_valid(receiver): receiver.queue_free()
	receivers.clear()
	await frames()

func receiver_at(offset: Vector2 = Vector2(110, 0)) -> Receiver:
	var target := Receiver.new()
	target.collision_layer = 4
	target.collision_mask = 0
	target.z_index = 100
	var collider := CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	collider.position = Vector2(-5, -25)
	var capsule := CapsuleShape2D.new()
	capsule.radius = 76.0
	capsule.height = 152.0
	collider.shape = capsule
	target.add_child(collider)
	scene.add_child(target)
	target.global_position = actor.global_position + offset
	receivers.append(target)
	return target

func start_attack(attack: int, direction: int = 1, amount: int = 20) -> void:
	actor._set_facing_direction(direction)
	var clip := StringName("saber_attack_%d" % attack)
	actor.spine_anim.play(clip)
	actor.spine_anim.advance(0.16)
	actor.saber_hitbox.play_attack_window(clip, amount)
	actor.saber_hitbox.hitbox_animation.advance(0.16)

func test_physics_and_geometry() -> bool:
	for direction in [1, -1]:
		for attack in range(1, 5):
			await reset_fixture()
			var target := receiver_at(Vector2(direction * 110, 0))
			await frames()
			var observed: Array[bool] = []
			var callback := func(_body: Node2D) -> void: observed.append(vfx._marks.size() == 1)
			actor.saber_hitbox.target_hit.connect(callback)
			start_attack(attack, direction)
			await frames()
			actor.saber_hitbox.target_hit.disconnect(callback)
			var label := "attack %d facing %d" % [attack, direction]
			check(target.accepted == 1 and vfx._marks.size() == 1, label + " real physics emits one accepted mark")
			check(observed == [true], label + " mark exists within accepted-hit signal dispatch")
			if vfx._marks.is_empty(): continue
			var mark: Dictionary = vfx._marks[0]
			var sprite: Sprite2D = mark.sprite
			check(sprite.texture == vfx.attack_textures[attack - 1], label + " approved image mapping")
			check(sprite.z_index < actor.spine_rig.get_node("SaberSwingVFX")._source_depth() - 1 and sprite.z_index > 100, label + " enemy < mark < sword trail")
			check(sprite.global_transform.determinant() * direction > 0.0, label + " mirrors the whole stroke")
			var axis := Vector2.from_angle(deg_to_rad(vfx.attack_axes_degrees[attack - 1]))
			var perpendicular := axis.orthogonal()
			var unit := vfx.attack_widths[attack - 1] / sprite.texture.get_width()
			var along := (sprite.global_transform.x * axis.x + sprite.global_transform.y * axis.y).length() / unit
			var across := (sprite.global_transform.x * perpendicular.x + sprite.global_transform.y * perpendicular.y).length() / unit
			check(absf(along - 1.3) < 0.001 and absf(across - 1.0) < 0.001, label + " 130% length, 100% thickness")
			check(vfx.tint.to_html(false) == "edf3f7" and is_equal_approx(vfx.fade_duration, 0.2), label + " approved color and fade")
			actor.saber_hitbox._on_hitbox_body_entered(target)
			check(target.accepted == 1 and vfx._marks.size() == 1, label + " repeated contact is deduplicated")
	return true

func test_multiple_targets_and_following() -> bool:
	await reset_fixture()
	var first := receiver_at(Vector2(100, 0))
	var second := receiver_at(Vector2(120, 0))
	await frames()
	start_attack(1)
	await frames()
	check(first.accepted == 1 and second.accepted == 1 and vfx._marks.size() == 2, "one swing marks each accepted target")
	if vfx._marks.size() != 2: return true
	check(vfx._marks[0].fade_start == vfx._marks[1].fade_start, "simultaneous targets share accepted hit-stop deadline")
	var record: Dictionary = vfx._marks[0]
	var target = (record.target as WeakRef).get_ref()
	var sprite: Sprite2D = record.sprite
	var before := sprite.global_position
	target.global_position += Vector2(23, 11)
	vfx._update_marks(vfx._clock_usec)
	check(sprite.global_position.is_equal_approx(before + Vector2(23, 11)), "mark follows defender movement")
	var basis := sprite.global_transform
	actor._set_facing_direction(-1)
	actor.position.x -= 30.0
	vfx._update_marks(vfx._clock_usec)
	check(sprite.global_transform.is_equal_approx(basis), "attacker movement/facing does not move an existing mark")
	return true

func test_rejected_miss_and_q() -> bool:
	for mode in ["rejected", "zero", "miss", "disabled"]:
		await reset_fixture()
		var target := receiver_at(Vector2(110 if mode != "miss" else 1200, 0))
		target.reject = mode == "rejected"
		vfx.enabled = mode != "disabled"
		await frames()
		start_attack(2, 1, 0 if mode == "zero" else 20)
		await frames()
		check(vfx._marks.is_empty(), mode + " has no hit slash")
		if mode == "rejected": check(target.attempts > 0 and target.accepted == 0, "rejected case received real contact")
	await reset_fixture()
	var target := receiver_at()
	await frames()
	actor._set_facing_direction(1)
	actor.saber_hitbox.begin_skill_window(20)
	await frames()
	actor.saber_hitbox.sample_skill_damage()
	check(target.accepted == 1 and vfx._marks.is_empty(), "Q accepted damage preserves its own VFX without a combo mark")
	return true

func test_real_clock_and_pause() -> bool:
	await reset_fixture()
	actor.hit_stop_enabled = false
	receiver_at()
	await frames()
	start_attack(1)
	await frames()
	check(vfx._marks.size() == 1, "clock fixture hit")
	if vfx._marks.is_empty(): return true
	var record: Dictionary = vfx._marks[0]
	var material := (record.sprite as Sprite2D).material as ShaderMaterial
	Engine.time_scale = 0.02
	await wait_real(0.09)
	check(float(material.get_shader_parameter("opacity")) > 0.0 and float(material.get_shader_parameter("opacity")) < 0.8, "fade advances on real time at 0.02 game scale")
	await wait_real(0.15)
	check(vfx._marks.is_empty(), "200ms fade completes despite slow motion")
	await reset_fixture()
	actor.hit_stop_enabled = false
	receiver_at()
	await frames()
	start_attack(1)
	await frames()
	if vfx._marks.is_empty(): return false
	material = (vfx._marks[0].sprite as Sprite2D).material as ShaderMaterial
	await wait_real(0.04)
	paused = true
	await process_frame
	var alpha := float(material.get_shader_parameter("opacity"))
	await wait_real(0.25)
	check(vfx._marks.size() == 1 and absf(float(material.get_shader_parameter("opacity")) - alpha) < 0.03, "menu pause suspends mark lifetime")
	paused = false
	await wait_real(0.20)
	check(vfx._marks.is_empty(), "fade finishes after unpause")
	return true

func test_capacity_and_lethal() -> bool:
	await reset_fixture()
	vfx.max_marks = 2
	actor.hit_stop_enabled = false
	start_attack(1)
	for i in range(3):
		var target := receiver_at(Vector2(1200 + i * 100, 0))
		actor.saber_hitbox._on_hitbox_body_entered(target)
	check(vfx._marks.size() == 2, "capacity bounds active marks")
	await reset_fixture()
	actor.hit_stop_enabled = false
	var lethal := receiver_at()
	lethal.lethal = true
	await frames()
	start_attack(4)
	await frames()
	check(not is_instance_valid(lethal) and vfx._marks.size() == 1, "lethal queued deletion retains the final hit mark")
	if not vfx._marks.is_empty():
		var sprite: Sprite2D = vfx._marks[0].sprite
		var before := sprite.global_position
		await process_frame
		check(sprite.global_position.is_equal_approx(before), "deleted defender keeps last world anchor")
	await wait_real(0.24)
	check(vfx._marks.is_empty(), "lethal mark cleans up after fade")
	return true

func test_owner_cleanup() -> bool:
	await reset_fixture()
	receiver_at()
	await frames()
	start_attack(1)
	await frames()
	if vfx._marks.is_empty(): return false
	var sprite: Sprite2D = vfx._marks[0].sprite
	actor.queue_free()
	await frames()
	check(not is_instance_valid(sprite), "owner removal cleans all world-anchored marks")
	return true
