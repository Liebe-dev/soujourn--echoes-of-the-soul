extends SceneTree
## Real Player/Enemy regressions; run in an isolated CodexCombatHitbox directory.

var checks := 0
var failures := 0
var p
var enemy
var other

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
		push_error("HITBOX_REGRESSION FAIL " + label)

func reset(facing: int) -> void:
	p.saber_skill.cancel()
	p.saber_hitbox.stop_attack_window()
	p.state_machine.resume_locomotion()
	p.position = Vector2(300, -500)
	p._set_facing_direction(facing)
	p.velocity = Vector2.ZERO
	for actor in [enemy, other]:
		actor.position = Vector2(5000, -500)
		actor.current_health = 1000
		actor.is_dead = false
		var stun = actor.get_node_or_null("WeaponSkillStun")
		if stun != null: stun.queue_free()
	await ticks()

func start_q(facing: int, tier: int = 0) -> void:
	p.saber_skill._active = true
	p.saber_skill._direction = facing
	p.saber_skill.tier = tier
	p.saber_skill.distance_travelled = 0.0
	p.saber_skill.contact_target = null
	p.saber_skill._confirmed = false
	p.saber_skill._start_lunge()

func _run() -> void:
	if not OS.get_user_data_dir().contains("CodexCombatHitbox"):
		quit(2)
		return
	create_timer(30.0, true, false, true).timeout.connect(func(): quit(2))
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	p = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	other = scene.get_node("SpineEnemy")
	for actor in [enemy, other]:
		actor.set_physics_process(false)
		actor.position.x = 5000
	p.hit_stop_enabled = false
	p.vitals.simulation_enabled = false
	await ticks(15)
	p.set_physics_process(false)
	p.spine_anim.pause()
	p.saber_hitbox.hitbox_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for prefix in ["tap", "charged", "full"]:
		p.saber_skill.set(prefix + "_impact_zoom_enabled", false)
		p.saber_skill.set(prefix + "_impact_slow_motion_enabled", false)
	for facing in [1, -1]:
		for step in [1, 2, 3]:
			for pattern in ["fine", "skip_window", "skip_entire_clip"]:
				await reset(facing)
				enemy.global_position = p.attack_hitbox_shape.global_position
				await ticks()
				p.saber_hitbox.play_attack_window(StringName("saber_attack_%d" % step), 20)
				var anim: AnimationPlayer = p.saber_hitbox.hitbox_animation
				if pattern == "skip_window":
					anim.advance(0.14)
					await ticks()
					check(enemy.current_health == 1000, "no hit before active window")
					anim.advance(0.07)
				else:
					anim.advance(0.16 if pattern == "fine" else 0.5)
				await ticks(4)
				check(enemy.current_health == 1000 - p.scale_attack_damage(20), "combo %d facing %d %s hits once" % [step, facing, pattern])
				if pattern != "fine": check(p.attack_hitbox_shape.disabled, "crossed window closes rectangle")
		# Entering the rectangle after the window closes must not deal late damage.
		await reset(facing)
		p.saber_hitbox.play_attack_window(&"saber_attack_1", 20)
		p.saber_hitbox.hitbox_animation.advance(0.21)
		await ticks()
		enemy.global_position = p.attack_hitbox_shape.global_position
		await ticks()
		check(enemy.current_health == 1000, "no late combo damage facing %d" % facing)
		for tier in [0, 1, 2]:
			await reset(facing)
			enemy.global_position = p.global_position + Vector2(-facing * 95, 0)
			await ticks()
			start_q(facing, tier)
			p.saber_skill._lunge(1.0 / 60.0)
			await ticks()
			check(p.saber_skill.is_dashing() and p.saber_skill.distance_travelled > 0.0, "Q ignores rear overlap facing %d tier %d" % [facing, tier])
			check(enemy.current_health == 1000, "rear enemy takes no Q damage")
			# A rear overlap must not hide a valid enemy ahead.
			await reset(facing)
			enemy.global_position = p.global_position + Vector2(-facing * 95, 0)
			other.global_position = p.global_position + Vector2(facing * 95, 0)
			await ticks()
			start_q(facing, tier)
			p.saber_skill._lunge(1.0 / 60.0)
			await ticks()
			check(p.saber_skill.contact_target == other and other.current_health < 1000, "Q selects forward overlap facing %d tier %d" % [facing, tier])
			check(enemy.current_health == 1000, "forward Q does not damage rear enemy")
			# The attack rectangle already reaches this target; bodies do not yet touch.
			await reset(facing)
			enemy.global_position = p.global_position + Vector2(facing * 180, 0)
			await ticks()
			start_q(facing, tier)
			p.saber_skill._lunge(1.0 / 60.0)
			await ticks(1)
			check(p.saber_skill.is_dashing() and p.saber_skill.contact_target == null, "Q does not stop at attack reach facing %d tier %d" % [facing, tier])
			check(enemy.current_health == 1000, "Q causes no early damage before body contact")
			for i in 20:
				if not p.saber_skill.is_dashing(): break
				p.saber_skill._lunge(1.0 / 60.0)
				await ticks(1)
			check(p.saber_skill.contact_target == enemy and enemy.current_health < 1000, "Q reaches body contact and still damages facing %d tier %d" % [facing, tier])
		# Sweep must still stop on the first enemy reached, before the farther one.
		await reset(facing)
		enemy.global_position = p.global_position + Vector2(facing * 270, 0)
		other.global_position = p.global_position + Vector2(facing * 480, 0)
		await ticks()
		start_q(facing)
		for i in 20:
			if not p.saber_skill.is_dashing(): break
			p.saber_skill._lunge(1.0 / 60.0)
			await ticks(1)
		check(p.saber_skill.contact_target == enemy and enemy.current_health < 1000, "Q sweep hits first enemy facing %d" % facing)
		check(p.saber_skill.distance_travelled > 0.0, "Q cast moves into damage contact")
		check(other.current_health == 1000, "Q leaves farther enemy untouched")
		# Multiple enemies ahead still select the first body contact.
		await reset(facing)
		enemy.global_position = p.global_position + Vector2(facing * 95, 0)
		other.global_position = p.global_position + Vector2(facing * 160, 0)
		await ticks()
		start_q(facing)
		p.saber_skill._lunge(1.0 / 60.0)
		await ticks()
		check(p.saber_skill.contact_target == enemy, "Q initial overlaps select nearest forward enemy")
		# Tap range is measured by body travel, without adding attack reach.
		await reset(facing)
		enemy.global_position = p.global_position + Vector2(facing * 300, 0)
		await ticks()
		start_q(facing)
		for i in 20:
			if not p.saber_skill.is_dashing(): break
			p.saber_skill._lunge(1.0 / 60.0)
			await ticks(1)
		check(p.saber_skill.contact_target == null and enemy.current_health == 1000, "Q whiffs if bodies cannot meet within tap travel facing %d" % facing)
		check(absf(p.saber_skill.distance_travelled - p.saber_skill.lunge_distance) < 0.1, "Q maximum travel remains unchanged")
		# Terrain remains a physical stop, never an enemy impact.
		await reset(facing)
		var wall := StaticBody2D.new()
		wall.collision_layer = 1
		wall.collision_mask = 0
		var collider := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(8, 250)
		collider.shape = box
		wall.add_child(collider)
		scene.add_child(wall)
		wall.global_position = p.global_position + Vector2(facing * 60, 0)
		await ticks()
		start_q(facing)
		for i in 20:
			if not p.saber_skill.is_dashing(): break
			p.saber_skill._lunge(1.0 / 60.0)
			await ticks(1)
		check(p.state_machine.current == AdelStateMachine.State.SKILL_RECOVERY and p.saber_skill.contact_target == null, "wall ends Q without enemy impact")
		wall.queue_free()
	await reset(1)
	print("HITBOX_REGRESSION_RESULT checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
