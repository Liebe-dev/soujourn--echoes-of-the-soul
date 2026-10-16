extends Node
var checks := 0
var failures := 0
var p
const S = AdelStateMachine.State

func _ready() -> void:
	if not OS.get_user_data_dir().contains("CodexAirCombo20261016"):
		get_tree().quit(2)
		return
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("AIR COMBO ", "PASS " if ok else "FAIL ", label)

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame

func airborne(initial_y: float = 0.0) -> void:
	p.clear_combat_input()
	p.state_machine.resume_locomotion()
	p.global_position = Vector2(300, -20000)
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	p.velocity.y = initial_y
	p.combat.combo_step = 1
	p._play_combo_step()
	p.spine_anim.pause()

func run() -> void:
	Engine.max_fps = 144
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	var enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	enemy.position.x = 6000
	p.hit_stop_enabled = false
	# Use a stable trajectory fixture; preserve the authored scene override.
	p.air_attack_fall_speed_multiplier = 0.3
	p.vitals.simulation_enabled = false
	await frames(65)
	var floor_position: Vector2 = p.position
	p.set_physics_process(false)
	check(p.is_on_floor(), "fixture reaches an actual floor")
	for facing in [-1, 1]:
		p._set_facing_direction(facing)
		p.combat.combo_step = 1
		p._play_combo_step()
		check(is_equal_approx(p.velocity.x, facing * 150.0), "ground swing keeps its forward impulse facing %d" % facing)
		p.spine_anim.pause()
	check(is_equal_approx(p.air_attack_fall_speed_multiplier, 0.3), "trajectory fixture uses 0.3 fall speed ratio")
	var reference := CharacterBody2D.new()
	add_child(reference)
	var normal := LocomotionComponent.new(reference)
	await frames(1)
	for ticks in [30, 60, 120]:
		for initial in [0.0, 200.0, 920.0]:
			airborne(initial)
			reference.velocity = Vector2(0, initial)
			var actual_distance := 0.0
			var normal_distance := 0.0
			var ratios_match := true
			var descends := true
			var previous := 0.0
			var sequence_preserved := true
			for i in ticks:
				var dt := 1.0 / float(ticks)
				normal.apply_vertical_physics(dt)
				p.combat.apply_combat_air_physics(dt, p.air_attack_fall_speed_multiplier)
				ratios_match = ratios_match and absf(p.velocity.y - reference.velocity.y * 0.3) < 0.02
				descends = descends and p.velocity.y > 0.0 and p.velocity.y + 0.01 >= previous
				actual_distance += p.velocity.y * dt
				normal_distance += reference.velocity.y * dt
				previous = p.velocity.y
				if i in [int(ticks / 4.0), int(ticks / 2.0), int(ticks * 3.0 / 4.0)]:
					p.combat.combo_step += 1
					p._play_combo_step()
					p.spine_anim.pause()
					sequence_preserved = sequence_preserved and is_equal_approx(p.velocity.y, previous) and is_zero_approx(p.velocity.x)
			check(ratios_match and absf(actual_distance - normal_distance * 0.3) < 0.02, "speed and integrated distance are 0.3 of normal: %dHz, initial %.0f" % [ticks, initial])
			check(descends and sequence_preserved, "all four swings preserve continuous descent with zero attack drift: %dHz, initial %.0f" % [ticks, initial])
			check(is_equal_approx(p.velocity.y, 276.0), "air combo terminal speed is 276px/s at %dHz" % ticks)
	for facing in [-1, 1]:
		airborne(-500.0)
		p._set_facing_direction(facing)
		p.velocity.x = facing * 450.0
		p._play_combo_step()
		p.spine_anim.pause()
		var start: Vector2 = p.position
		for i in 12: p._physics_locked(1.0 / 60.0)
		check(p.position.y > start.y and p.velocity.y > 0.0, "rising jump becomes a downward air attack facing %d" % facing)
		check(absf(p.position.x - start.x) < 0.01, "actual move_and_slide adds no forward swing displacement facing %d" % facing)
	airborne(100.0)
	p.air_attack_fall_speed_multiplier = 0.5
	p.combat.apply_combat_air_physics(1.0, p.air_attack_fall_speed_multiplier)
	check(is_equal_approx(p.velocity.y, 460.0), "Inspector ratio 0.5 changes the terminal fall speed to 460px/s")
	p.air_attack_fall_speed_multiplier = 0.3
	p.state_machine.resume_locomotion()
	var before: float = p.velocity.y
	p.locomotion.apply_vertical_physics(0.1)
	check(p.velocity.y > before + 100.0, "leaving attack resumes ordinary falling acceleration")
	airborne(0.0)
	p.combat.apply_combat_air_physics(1.0)
	p.state_machine.resume_locomotion()
	p.velocity.y = 0.0
	p.combat.combo_step = 1
	p._play_combo_step()
	p.spine_anim.pause()
	p.combat.apply_combat_air_physics(1.0 / 60.0)
	check(p.velocity.y < 10.0, "a new combo never inherits the prior combo terminal fall reference")
	p.combat.start_jump_attack()
	p.combat.apply_combat_air_physics(0.05)
	check(is_zero_approx(p.velocity.y) and p.combat.is_jump_attack_hanging, "dedicated downward jump attack retains its hang phase")
	p.combat.apply_combat_air_physics(0.2)
	p.combat.apply_combat_air_physics(0.01)
	check(is_equal_approx(p.velocity.y, 1500.0), "dedicated downward jump attack retains 1500px/s descent")
	p.combat.interrupt()
	airborne(0.0)
	p._perform_dash(1.0)
	check(p.state_machine.is_in(S.DASH) and p.dash.is_dodging, "air combo can still transition into dash")
	p.state_machine.resume_locomotion()
	# Exercise the real physics loop and animation playback after the isolated trajectories.
	airborne(0.0)
	p.spine_anim.play(&"saber_attack_1")
	var start_x: float = p.position.x
	var start_y: float = p.position.y
	p.set_physics_process(true)
	await frames(18)
	check(p.state_machine.current == S.COMBO and p.position.y > start_y and p.velocity.y > 0, "live animated air swing descends in Godot physics")
	check(absf(p.position.x - start_x) < 0.1, "live animated swing has no attack-driven horizontal movement")
	p.state_machine.resume_locomotion()
	p.position = floor_position
	p.velocity = Vector2.ZERO
	await frames(6)
	check(p.is_on_floor(), "player still lands and returns to ordinary locomotion")
	reference.queue_free()
	print("RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
