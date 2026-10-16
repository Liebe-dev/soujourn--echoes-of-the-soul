extends Node
## Run only in a copied project with a CodexFracture custom user directory.
const S = AdelStateMachine.State
class DamageProbe extends CharacterBody2D:
	var calls := 0
	var total := 0
	func take_damage(amount: int, _origin: Vector2 = Vector2.INF) -> bool:
		calls += 1
		total += amount
		return true

var checks := 0
var failures := 0
var p
var floor_position: Vector2

func _ready() -> void:
	if not OS.get_user_data_dir().contains("CodexFracture"):
		get_tree().quit(2)
		return
	run.call_deferred()

func frames(n: int = 1) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("FRACTURE ", "PASS " if ok else "FAIL ", label)

func reset(level: int = 0) -> void:
	for action in [&"attack", &"move_right", &"move_left", &"jump", &"guard and deflect", &"weapon_skill"]:
		Input.action_release(action)
	p.clear_combat_input()
	p.state_machine.resume_locomotion()
	p.combat.combo_step = 0
	p.stats.clear_all_debuffs()
	p.stats.fracture_level = level
	p.stats.restore_stamina_full()
	p.damage.reset()
	p._defense_lock_left = 0.0
	p._set_facing_direction(1)
	p.position = floor_position
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	p._sync_attack_speed()
	p.presentation.play(&"idle")

func run() -> void:
	Engine.max_fps = 144
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	scene.get_node("Enemy").set_physics_process(false)
	scene.get_node("Enemy").position.x = 6000.0
	p.hit_stop_enabled = false
	p.stagger_zoom_enabled = false
	p.stagger_slow_motion_enabled = false
	await frames(65)
	floor_position = p.position
	p.vitals.simulation_enabled = false
	p.set_physics_process(false)
	var probe := DamageProbe.new()
	scene.add_child(probe)
	probe.position = Vector2(-6000, -6000)
	for level in range(4):
		reset(level)
		var dealt: int = [20, 17, 16, 13][level]
		var taken: int = [10, 12, 14, 16][level]
		p.stats.hp = 100
		check(p.vitals.apply_damage(10, Vector2.INF, true).damage_taken == taken, "level %d incoming damage" % level)
		for step in [1, 4]:
			p.combat.combo_step = step
			p._play_combo_step()
			var before := probe.total
			p.saber_hitbox._on_hitbox_body_entered(probe)
			p.saber_hitbox._on_hitbox_body_entered(probe)
			var expected := dealt if step == 1 else int(round(24.0 * [1.0, 0.85, 0.8, 0.65][level]))
			check(probe.total - before == expected, "level %d combo %d damage exactly once" % [level, step])
		p.jump_hitbox.begin_attack(20)
		p.jump_hitbox.set_damage_window(true)
		var before := probe.total
		p.jump_hitbox._try_hit_body(probe)
		p.jump_hitbox._try_hit_body(probe)
		check(probe.total - before == dealt, "level %d jump damage exactly once" % level)
		p.state_machine.resume_locomotion()
		for tier in range(3):
			p.saber_skill.tier = tier
			before = probe.total
			p.saber_skill._impact()
			p.saber_hitbox._on_hitbox_body_entered(probe)
			var base: int = [20, 24, 32][tier]
			check(probe.total - before == int(round(base * [1.0, 0.85, 0.8, 0.65][level])), "level %d Q tier %d damage" % [level, tier])
		p.saber_hitbox.stop_attack_window()
		p.state_machine.resume_locomotion()
		for running in [false, true]:
			p.locomotion.is_running = running
			p.locomotion._run_boost_timer = 0.0
			p.locomotion.apply_horizontal_movement(1.0, 1.0)
			var expected := (450.0 if running else 140.0) * (0.72 if level >= 2 else 1.0)
			check(is_equal_approx(p.velocity.x, expected), "level %d ground speed running=%s" % [level, running])
		p.locomotion._run_boost_timer = 1.0
		p.locomotion.apply_horizontal_movement(-1.0, 1.0)
		check(is_equal_approx(p.velocity.x, -520.0 * (0.72 if level >= 2 else 1.0)), "level %d run boost and reverse" % level)
		p.position.y = -20000
		p.move_and_slide()
		p.locomotion._air_speed_cap = 450.0
		p.velocity = Vector2.ZERO
		p.locomotion.apply_horizontal_movement(1.0, 2.0)
		check(is_equal_approx(p.velocity.x, 450.0 * (0.72 if level >= 2 else 1.0)), "level %d airborne horizontal cap" % level)
		reset(level)
		p.combat.combo_step = 1
		p._play_combo_step()
		check(is_equal_approx(p.spine_anim.speed_scale, 0.75 if level >= 2 else 1.0), "level %d visual attack speed" % level)
		check(is_equal_approx(p.saber_hitbox.hitbox_animation.speed_scale, p.spine_anim.speed_scale), "level %d hitbox speed follows visual" % level)
		p.spine_anim.pause()
		p.spine_anim.seek(0.39, true)
		p._tick_attack_interrupt()
		check(not p._attack_interrupt_ready, "combo cannot bypass reduced speed with an early chain")
		p.spine_anim.seek(0.4, true)
		p._tick_attack_interrupt()
		check(p._attack_interrupt_ready, "combo unlock follows actual animation progress")
	# Flask changes during an existing swing must restore both clocks without resetting progress.
	reset(2)
	p.combat.combo_step = 1
	p._play_combo_step()
	p.spine_anim.seek(0.2, true)
	p.stats.hp = 80
	p.stats.flask_charges = 3
	check(p.stats.use_soul_flask().used and p.stats.fracture_level == 1, "flask removes one level")
	p._sync_attack_speed()
	check(is_equal_approx(p.spine_anim.speed_scale, 1.0) and is_equal_approx(p.saber_hitbox.hitbox_animation.speed_scale, 1.0), "flask restores attack clocks during swing")
	check(is_equal_approx(p.spine_anim.current_animation_position, 0.2), "cure does not restart the swing")
	p.stats._apply_fracture(99)
	check(p.stats.fracture_level == 3, "fracture stacks to level three")
	p.stats.cure_debuffs_from_flask()
	check(p.stats.fracture_level == 2, "flask preserves level-two slow after level three")
	p.stats.clear_all_debuffs()
	p._sync_attack_speed()
	check(is_equal_approx(p.spine_anim.speed_scale, 1.0), "full cure restores base speed")
	reset(2)
	p.spine_anim.speed_scale = 0.5
	p.combat.combo_step = 1
	p._play_combo_step()
	check(is_equal_approx(p.spine_anim.speed_scale, 0.375), "debuff composes with other playback speed")
	p.state_machine.resume_locomotion()
	check(is_equal_approx(p.spine_anim.speed_scale, 0.5), "attack exit removes only fracture speed factor")
	p.spine_anim.speed_scale = 1.0
	# Timed integration: both animation players advance at the same reduced rate.
	reset(2)
	p.combat.combo_step = 1
	p._play_combo_step()
	p.set_physics_process(true)
	await frames(12)
	var visual: float = p.spine_anim.current_animation_position
	var hitbox: float = p.saber_hitbox.hitbox_animation.current_animation_position
	check(absf(visual - hitbox) < 0.03 and visual > 0.05, "live visual/hitbox progress remains synchronized (%.3f / %.3f)" % [visual, hitbox])
	p.set_physics_process(false)
	reset(2)
	p.position.y = -20000
	p.move_and_slide()
	p._play_jump_attack()
	check(is_equal_approx(p.spine_anim.speed_scale, 0.75), "jump hang uses reduced attack speed")
	p.set_physics_process(true)
	await frames(16)
	check(p.combat.is_jump_attack_hanging, "jump waits for slowed hang animation rather than old timer")
	await frames(12)
	check(not p.combat.is_jump_attack_hanging, "slowed jump proceeds to fall")
	p.set_physics_process(false)
	reset(2)
	p._play_jump_attack_land()
	p._physics_attack(0.2)
	check(not p.combat.is_jump_attack_land_unlocked(), "land movement unlock uses attack clock")
	p._physics_attack(0.21)
	check(p.combat.is_jump_attack_land_unlocked(), "land unlock opens at scaled duration")
	# Real held input must wait for the slowed commitment, including the ready tail.
	reset(2)
	p.combat.combo_step = 1
	p._play_combo_step()
	Input.action_press("guard and deflect")
	p._try_begin_guard()
	p.set_physics_process(true)
	await frames(38)
	check(not p.is_guarding, "held Defense cannot use unscaled combo commitment")
	await frames(16)
	check(p.is_guarding, "held Defense opens after slowed combo commitment")
	p.set_physics_process(false)
	reset(2)
	p.combat.combo_step = 1
	p._play_combo_step()
	var enemy = scene.get_node("Enemy")
	enemy.current_health = 1000
	enemy.global_position = p.saber_hitbox.hitbox_shape.global_position
	p.set_physics_process(true)
	await frames(20)
	check(enemy.current_health == 984, "real physics overlap deals reduced damage once")
	enemy.position.x = 6000.0
	p.set_physics_process(false)
	reset(2)
	check(p.saber_skill.begin(), "Q remains available with fracture")
	check(is_equal_approx(p.spine_anim.speed_scale, 1.0), "Q preserves its independent charge/recovery clock")
	p.saber_skill.abort()
	check(is_equal_approx(p.spine_anim.speed_scale, 1.0), "Q cancel leaves no slowed ready pose")
	print("FRACTURE RESULT ", checks, " checks, ", failures, " failures")
	get_tree().quit(1 if failures else 0)
