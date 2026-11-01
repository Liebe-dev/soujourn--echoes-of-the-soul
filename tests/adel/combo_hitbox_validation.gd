extends SceneTree
## Run with --script in an isolated CodexComboRectangle project/user directory.

class DamageProbe extends CharacterBody2D:
	var calls := 0
	var current_health := 100
	func take_damage(amount: int, _origin: Vector2) -> bool:
		calls += 1
		current_health -= amount
		return true

var checks := 0
var failures := 0
var p
var enemy
var probe: DamageProbe

func _initialize() -> void:
	_run.call_deferred()

func ticks(count: int = 3) -> void:
	for i in count:
		await physics_frame
		await process_frame

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("COMBO RECTANGLE FAIL " + label)

func reset(facing: int, point: Vector2) -> void:
	p.saber_skill.cancel()
	p.saber_hitbox.stop_attack_window()
	p.state_machine.resume_locomotion()
	p._set_facing_direction(facing)
	probe.global_position = p.to_global(Vector2(facing * point.x, point.y))
	probe.calls = 0
	probe.current_health = 100
	await ticks()

func _run() -> void:
	if not OS.get_user_data_dir().contains("CodexComboRectangle"):
		push_error("Use an isolated CodexComboRectangle project/user directory.")
		quit(2)
		return
	create_timer(30.0, true, false, true).timeout.connect(func(): quit(2))
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	p = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	for name in ["Enemy", "SpineEnemy"]:
		var actor = scene.get_node(name)
		actor.set_physics_process(false)
		actor.position.x = 4000.0
	p.hit_stop_enabled = false
	p.vitals.simulation_enabled = false
	await ticks(15)
	p.set_physics_process(false)
	p.spine_anim.pause()
	p.saber_hitbox.hitbox_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for prefix in ["tap", "charged", "full"]:
		p.saber_skill.set(prefix + "_impact_zoom_enabled", false)
		p.saber_skill.set(prefix + "_impact_slow_motion_enabled", false)
	probe = DamageProbe.new()
	probe.collision_layer = 4
	probe.collision_mask = 0
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 2.0
	collider.shape = circle
	probe.add_child(collider)
	scene.add_child(probe)
	check(p.saber_hitbox.hitbox_shape == p.attack_hitbox_shape, "controller uses the selected AttackHitbox")
	check(p.attack_hitbox_shape.shape is RectangleShape2D, "combo shape is rectangular")
	check(p.attack_hitbox.position == Vector2.ZERO, "no WeaponData parent offset applied at startup")
	check(p.attack_hitbox_shape.position.is_equal_approx(Vector2(99.35505, 15.5)), "scene position preserved")
	check(p.attack_hitbox_shape.shape.size.is_equal_approx(Vector2(163.2899, 97)), "scene size preserved")
	check(not p.has_node("WeaponPivot/SaberHitbox/SkillHitbox"), "Q capsule node removed")
	var cases := [
		{"point": Vector2(99, 15.5), "hit": true, "name": "rectangle center"},
		{"point": Vector2(175, 55), "hit": true, "name": "rectangle corner beyond old capsule"},
		{"point": Vector2(63, -45), "hit": false, "name": "old capsule outside rectangle"},
		{"point": Vector2(-80, 15.5), "hit": false, "name": "behind player"},
	]
	for facing in [1, -1]:
		for step in [1, 2, 3, 4]:
			for test in cases:
				await reset(facing, test.point)
				var label := "step=%d facing=%d %s" % [step, facing, test.name]
				p.combat.combo_step = step
				var damage: int = p.combat.get_combo_damage()
				p.saber_hitbox.play_attack_window(StringName("saber_attack_%d" % step), damage)
				p.saber_hitbox.hitbox_animation.advance(0.0)
				await ticks(2)
				check(probe.calls == 0, label + " no startup damage")
				p.saber_hitbox.hitbox_animation.advance(0.16)
				await ticks(4)
				var expected: int = p.scale_attack_damage(damage) if test.hit else 0
				check(100 - probe.current_health == expected, label + " active damage")
				await ticks(2)
				check(probe.calls == (1 if test.hit else 0), label + " at most one hit")
				p.saber_hitbox.hitbox_animation.advance(0.16)
				await ticks(2)
				check(p.attack_hitbox_shape.disabled, label + " window closes")
	# Also exercise the game's real Enemy damage receiver in every combo/facing.
	probe.position.x = 5000.0
	for facing in [1, -1]:
		for step in [1, 2, 3, 4]:
			p.saber_hitbox.stop_attack_window()
			p._set_facing_direction(facing)
			enemy.global_position = p.attack_hitbox_shape.global_position
			enemy.current_health = 100
			enemy.is_dead = false
			await ticks()
			p.combat.combo_step = step
			var damage: int = p.combat.get_combo_damage()
			p.saber_hitbox.play_attack_window(StringName("saber_attack_%d" % step), damage)
			p.saber_hitbox.hitbox_animation.advance(0.16)
			await ticks(4)
			check(enemy.current_health == 100 - p.scale_attack_damage(damage), "real enemy step=%d facing=%d" % [step, facing])
			enemy.position.x = 4000.0
	# Scene tuning stays authoritative when a clip starts.
	p.saber_hitbox.stop_attack_window()
	p.attack_hitbox_shape.position = Vector2(135, -10)
	p.attack_hitbox_shape.shape.size = Vector2(80, 60)
	await reset(-1, Vector2(135, -10))
	p.saber_hitbox.play_attack_window(&"saber_attack_1", 20)
	p.saber_hitbox.hitbox_animation.advance(0.16)
	await ticks(4)
	check(probe.calls == 1, "edited rectangle position/size is used for damage")
	check(p.attack_hitbox_shape.position == Vector2(135, -10), "animation does not reset edited position")
	# Q damage and lunge detection use this same edited rectangle, both facings.
	var q_cases := [
		{"point": Vector2(135, -10), "hit": true},
		{"point": Vector2(170, 15), "hit": true},
		{"point": Vector2(63, -45), "hit": false},
		{"point": Vector2(-80, -10), "hit": false},
	]
	for facing in [1, -1]:
		for test in q_cases:
			await reset(facing, test.point)
			p.saber_hitbox.begin_skill_window(20)
			await ticks()
			p.saber_hitbox.sample_skill_damage()
			p.saber_hitbox.sample_skill_damage()
			await ticks()
			check(probe.calls == (1 if test.hit else 0), "Q rectangle damage/dedup facing %d point %s" % [facing, test.point])
			check(not p.attack_hitbox_shape.disabled, "Q opens shared rectangle")
		await reset(facing, Vector2(170, 15))
		p.saber_skill._active = true
		p.saber_skill._direction = facing
		p.saber_skill.tier = 0
		p.saber_skill._start_lunge()
		p.saber_skill._lunge(1.0 / 60.0)
		await ticks()
		check(p.saber_skill.contact_target == probe and probe.calls == 1, "Q detects rectangle corner beyond body collider facing %d" % facing)
	p.saber_skill.cancel()
	p.saber_hitbox.stop_attack_window()
	await ticks()
	check(p.attack_hitbox_shape.disabled, "cancel closes shared rectangle")
	print("COMBO_RECTANGLE_RESULT checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
