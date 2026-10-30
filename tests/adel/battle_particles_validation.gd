extends SceneTree
## Production Player/acceptance pipeline; no save access outside the isolated copy.

class Receiver:
	extends CharacterBody2D
	var current_health := 1000
	var accepted := 0
	var reject := false
	var lethal := false
	func take_damage(amount: int, _from: Vector2 = Vector2.INF) -> bool:
		if reject or amount <= 0: return false
		current_health -= amount
		accepted += 1
		if lethal: queue_free()
		return true

var actor: CharacterBody2D
var vfx: BattleHitParticles
var stage: Node2D
var targets: Array[Receiver] = []
var checks := 0
var failures := 0

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFXParticlesIntegration"):
		quit(2)
		return
	var watchdog := Timer.new()
	watchdog.wait_time = 35.0
	watchdog.one_shot = true
	watchdog.ignore_time_scale = true
	watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(watchdog)
	watchdog.timeout.connect(func() -> void:
		paused = false
		Engine.time_scale = 1.0
		push_error("Particles validation timeout")
		quit(2))
	watchdog.start()
	stage = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	actor = stage.get_node("PlayableAdel")
	for name in ["Enemy", "SpineEnemy"]:
		var enemy := stage.get_node(name) as Node2D
		enemy.set_physics_process(false)
		enemy.position.x = 10000
	actor.set_physics_process(false)
	actor.vitals.simulation_enabled = false
	actor.spine_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	vfx = actor.battle_particles
	for test: StringName in [&"test_q_acceptance_and_profiles", &"test_stagger_and_exclusions", &"test_world_layers_and_clock", &"test_capacity_reset_and_cleanup"]:
		if await call(test) != true: check(false, "%s completed normally" % test)
	paused = false
	Engine.time_scale = 1.0
	watchdog.queue_free()
	print("BATTLE PARTICLES RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PARTICLES FAIL: " + label)
	else:
		print("PARTICLES PASS: ", label)

func frames(count: int = 2) -> void:
	for i in count:
		await process_frame

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000)
	while Time.get_ticks_usec() < deadline: await process_frame

func reset_fixture() -> void:
	paused = false
	actor.saber_skill.cancel()
	actor.saber_skill.cancel_impact_feedback()
	actor.stagger_impact.cancel()
	actor.deflect_slow_motion.cancel()
	root.get_node("CombatTime").remove(actor)
	Engine.time_scale = 1.0
	actor.saber_hitbox.stop_attack_window()
	actor.jump_hitbox.end_attack()
	actor.damage.reset()
	actor.defense.end_guard()
	actor.stats.stagger_thresholds_enabled = true
	actor.stats.max_hp = 100
	actor.stats.heal_to_full()
	actor.stats.bleeding_level = 0
	actor.state_machine.resume_locomotion()
	actor.player_blood.clear_blood()
	vfx.clear_effects()
	vfx.enabled = true
	vfx.max_particles = 96
	actor.hit_stop_enabled = true
	for target in targets:
		if is_instance_valid(target): target.queue_free()
	targets.clear()
	await frames()

func receiver_at(direction: int = 1) -> Receiver:
	var target := Receiver.new()
	target.collision_layer = 4
	target.collision_mask = 0
	target.z_index = 100
	var collider := CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	collider.position = Vector2(-5, -25)
	var shape := CapsuleShape2D.new()
	shape.radius = 30.0
	shape.height = 90.0
	collider.shape = shape
	target.add_child(collider)
	stage.add_child(target)
	target.position = actor.position + Vector2(direction * 2000, 0)
	targets.append(target)
	return target

func start_q(tier: int, direction: int = 1) -> void:
	actor._set_facing_direction(direction)
	actor.saber_skill._active = true
	actor.saber_skill._confirmed = false
	actor.saber_skill.tier = tier
	actor.state_machine.current = AdelStateMachine.State.SKILL_IMPACT
	actor.saber_hitbox.begin_skill_window(20)

func test_q_acceptance_and_profiles() -> bool:
	check(vfx._blood_cells.size() == 10 and vfx._bone_cells.size() == 8, "approved sheet has 10 blood and 8 bone cells")
	for direction in [-1, 1]:
		for tier in range(3):
			await reset_fixture()
			var target := receiver_at(direction)
			start_q(tier, direction)
			var accepted_hold: Array[float] = []
			var hold_callback := func(seconds: float) -> void: accepted_hold.append(seconds)
			actor.saber_skill.impact_confirmed.connect(hold_callback)
			actor.saber_hitbox._on_hitbox_body_entered(target)
			actor.saber_skill.impact_confirmed.disconnect(hold_callback)
			var label := "Q tier %d facing %d" % [tier, direction]
			check(target.accepted == 1 and vfx._active.size() == [6,11,15][tier], label + " accepted contact immediately creates quota")
			if vfx._active.is_empty(): continue
			check(vfx._active.filter(func(p): return p.kind == 1).size() == [2,3,5][tier], label + " bone allocation")
			check(accepted_hold.size() == 1 and accepted_hold[0] > 0.0, label + " existing Q producer accepted hit-stop")
			var born: int = vfx._active[0].born
			check(absf(float(born - vfx._clock_usec) / 1000000.0 - accepted_hold[0]) < 0.004, label + " uses actual accepted hold")
			var valid_motion := true
			var valid_art := true
			var upward := 0
			for particle in vfx._active:
				var sprite: Sprite2D = particle.sprite
				var rect := (sprite.texture as AtlasTexture).region
				var size := sprite.scale.x * maxf(rect.size.x, rect.size.y)
				var base_speed: float = [720.0,1080.0,1560.0][tier] * (0.75 if particle.kind == 1 else 1.0)
				valid_motion = valid_motion and signf(particle.direction.x) == direction and float(particle.speed) >= base_speed * 0.899 and float(particle.speed) <= base_speed * 1.101
				valid_art = valid_art and size >= 14.99 and size <= (21.01 if particle.kind == 1 else 24.01) and sprite.z_index == vfx.canvas_depth(vfx._source) - 3
				var angle := rad_to_deg(asin(particle.direction.y))
				if angle < 0:
					upward += 1
					valid_motion = valid_motion and angle >= -12.01 and angle <= -7.99
				else:
					valid_motion = valid_motion and angle <= 8.01
			check(valid_motion and upward == [1,1,2][tier], label + " mostly forward, narrow upper accents, approved speed")
			check(valid_art, label + " world size and Q layer match V3")
			actor.saber_hitbox._on_hitbox_body_entered(target)
			check(target.accepted == 1 and vfx._active.size() == [6,11,15][tier], label + " contact deduplicated")
			var second := receiver_at(direction)
			actor.saber_hitbox._on_hitbox_body_entered(second)
			check(second.accepted == 1 and vfx._active.size() == 2 * [6,11,15][tier], label + " multiple targets each receive burst")
			check(vfx._active.back().born == born, label + " multiple targets share one hold deadline")
	await reset_fixture()
	var rejected := receiver_at()
	rejected.reject = true
	start_q(2)
	actor.saber_hitbox._on_hitbox_body_entered(rejected)
	check(vfx._active.is_empty(), "rejected Q contact creates no particles")
	await reset_fixture()
	start_q(0)
	check(vfx._active.is_empty(), "Q without accepted target creates no particles")
	for attack: StringName in [&"saber_attack_1", &"saber_attack_4"]:
		await reset_fixture()
		var target := receiver_at()
		actor.saber_hitbox.play_attack_window(attack, 20)
		actor.saber_hitbox._on_hitbox_body_entered(target)
		check(target.accepted == 1 and vfx._active.is_empty(), "%s accepted contact excluded" % attack)
	await reset_fixture()
	var jump_target := receiver_at()
	actor.jump_hitbox.begin_attack(20)
	actor.jump_hitbox.set_damage_window(true)
	actor.jump_hitbox._try_hit_body(jump_target)
	actor.jump_hitbox.end_attack()
	check(jump_target.accepted == 1 and vfx._active.is_empty(), "actual jump hitbox accepted contact excluded")
	return true

func test_stagger_and_exclusions() -> bool:
	for direction in [-1,1]:
		await reset_fixture()
		actor._set_facing_direction(-direction)
		actor.take_damage(40, actor.global_position - Vector2(direction * 80, 0))
		check(actor.damage.is_stunned and vfx._active.size() == 8, "direct HP stagger fixed quota facing %d" % direction)
		check(vfx._active.all(func(p): return p.player and p.kind == 0 and signf(p.direction.x) == direction), "stagger uses actual knockback, independent of facing %d" % direction)
		check(vfx._active.filter(func(p): return p.direction.y < 0).size() == 1, "stagger has one narrow upward accent")
		var before := vfx._active.size()
		actor.take_damage(40)
		actor._on_damage_stagger_recovered()
		check(vfx._active.size() == before, "iframe rejection and stagger recovery never repeat burst")
	await reset_fixture()
	actor.take_damage(10)
	check(actor.stats.hp < 100 and vfx._active.is_empty(), "ordinary accepted Player hit excluded")
	actor.damage.reset()
	actor.damage.start_invulnerability(1.0)
	actor.take_damage(80)
	check(vfx._active.is_empty(), "invulnerable Player excluded")
	await reset_fixture()
	actor._apply_stamina_exhaustion(Vector2.INF)
	check(vfx._active.is_empty(), "stamina exhaustion excluded")
	await reset_fixture()
	actor.defense.begin_guard(actor.defense.deflect_delay + actor.defense.deflect_window * 0.5)
	actor.take_damage(80, actor.global_position + Vector2(actor.facing_direction * 80, 0))
	check(actor.stats.hp == 100 and vfx._active.is_empty(), "successful deflect excluded")
	await reset_fixture()
	actor.vitals.drain_hp_nonlethal(50)
	actor.stats.bleeding_level = 2
	actor.vitals.simulation_enabled = true
	actor.vitals.tick(1.1, 1.1)
	actor.vitals.simulation_enabled = false
	check(vfx._active.is_empty(), "self drain and bleed tick excluded")
	return true

func test_world_layers_and_clock() -> bool:
	await reset_fixture()
	var target := receiver_at()
	start_q(2)
	actor.saber_hitbox._on_hitbox_body_entered(target)
	vfx.set_process(false)
	var particle: Dictionary = vfx._active[0]
	var sprite: Sprite2D = particle.sprite
	var start: Vector2 = particle.origin
	vfx._update_particles(int(particle.born) - 1)
	check(sprite.global_position.is_equal_approx(start) and sprite.modulate.a == 1.0, "Q cluster stays fully visible throughout accepted hold")
	target.position += Vector2(50,20)
	actor.position += Vector2(10,5)
	vfx._update_particles(int(particle.born))
	check(sprite.global_position.is_equal_approx(start), "moving either actor does not drag world particles")
	target.queue_free()
	actor.saber_skill.cancel()
	await frames()
	vfx._update_particles(int(particle.born) + 200000)
	check(is_instance_valid(sprite) and sprite.global_position.distance_to(start) > 10, "freed target and interrupted Q leave existing particles finishing")
	vfx._update_particles(int(particle.born) + int((float(particle.life) - 0.065) * 1000000))
	check(absf(sprite.modulate.a - 0.5) < 0.01, "last 130ms fades through intermediate opacity")
	vfx._update_particles(int(particle.born) + 900000)
	check(vfx._active.is_empty() and vfx.get_child_count() == 0, "expired sprites fully freed")
	vfx.set_process(true)
	await reset_fixture()
	actor.take_damage(40)
	for clip: StringName in [&"idle", &"run", &"jump_air (fall)", &"saber_attack_1", &"saber_skill_6", &"saber_defense"]:
		actor.spine_anim.play(clip)
		actor.spine_anim.advance(0.0)
		vfx._update_particles(vfx._clock_usec)
		var behind := true
		for node in actor.spine_rig.find_children("*", "Sprite2D", true, false):
			if node.texture != null and node.is_visible_in_tree():
				for p in vfx._active: behind = behind and p.sprite.z_index < vfx.canvas_depth(node)
		check(behind and not vfx._active.is_empty(), "%s stagger particles behind visible rig/FBF" % clip)
	var before := vfx._advance_clock(Time.get_ticks_usec())
	vfx._update_particles(before)
	var location: Vector2 = vfx._active[0].sprite.global_position
	paused = true
	await wait_real(0.13)
	check(vfx._clock_usec == before and vfx._active[0].sprite.global_position.is_equal_approx(location), "pause freezes clock and positions")
	paused = false
	Engine.time_scale = 0.02
	before = vfx._clock_usec
	await wait_real(0.13)
	check(vfx._clock_usec - before >= 100000, "slow motion does not stretch real particle lifetime")
	Engine.time_scale = 1.0
	await wait_real(0.7)
	check(vfx._active.is_empty(), "stagger burst finishes by real time")
	return true

func test_capacity_reset_and_cleanup() -> bool:
	await reset_fixture()
	var target := receiver_at()
	target.lethal = true
	start_q(0)
	actor.saber_hitbox._on_hitbox_body_entered(target)
	await frames()
	check(not is_instance_valid(target) and vfx._active.size() == 6, "accepted lethal queued deletion keeps Q burst")
	await reset_fixture()
	vfx.max_particles = 20
	start_q(2)
	var total_accepted := 0
	for i in range(10):
		var receiver := receiver_at()
		actor.saber_hitbox._on_hitbox_body_entered(receiver)
		total_accepted += receiver.accepted
	check(total_accepted == 10 and vfx._active.size() == 20 and vfx.get_child_count() == 20, "capacity evicts oldest visuals without dropping target damage")
	actor.restore_checkpoint_state(actor.global_position, false)
	check(vfx._active.is_empty() and vfx._swing_holds.is_empty() and vfx.get_child_count() == 0, "checkpoint/respawn clears particles and old hold")
	await reset_fixture()
	actor.take_damage(40)
	vfx.enabled = false
	await frames()
	check(vfx._active.is_empty() and vfx.get_child_count() == 0, "disable clears all live sprites")
	await reset_fixture()
	actor.take_damage(40)
	actor.stats.hp = 0
	await frames()
	check(vfx._active.is_empty(), "non-contact death clears active particles")
	await reset_fixture()
	actor.stats.stagger_thresholds_enabled = false
	actor.stats.hp = 1
	# In-memory checkpoint: exercise real respawn without reloading the fixture.
	var saves := root.get_node("SaveManager")
	saves._data.scene_path = stage.scene_file_path
	saves._data.spawn_position = {"x":actor.position.x,"y":actor.position.y}
	actor.take_damage(40)
	check(vfx._active.is_empty() and actor.stats.hp > 0, "lethal Player damage respawns without stagger burst")
	await reset_fixture()
	actor.take_damage(40)
	var children: Array[Sprite2D] = []
	for p in vfx._active: children.append(p.sprite)
	check(not children.is_empty(), "owner cleanup fixture has live particles")
	stage.queue_free()
	await frames()
	check(not is_instance_valid(vfx) and children.all(func(s): return not is_instance_valid(s)), "scene/owner removal frees all top-level sprites")
	return true
