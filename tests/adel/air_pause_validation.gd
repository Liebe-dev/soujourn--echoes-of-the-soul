extends Node
var checks := 0
var failures := 0
var p
const S = AdelStateMachine.State
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.get_user_data_dir().contains("CodexAirPause20261016"):
		get_tree().quit(2)
		return
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("AIR PAUSE ", "PASS " if ok else "FAIL ", label)
func frames(n: int = 1) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame
func air(step: int = 1) -> void:
	p.set_physics_process(false)
	p.clear_combat_input()
	p.state_machine.resume_locomotion()
	p.global_position = Vector2(300, -20000)
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	p.velocity.y = 300.0
	p.combat.combo_step = step
	p._play_combo_step()
	p.spine_anim.pause()
func run() -> void:
	Engine.max_fps = 144
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	scene.get_node("Enemy").set_physics_process(false)
	scene.get_node("Enemy").position.x = 6000.0
	p.hit_stop_enabled = false
	p.air_attack_fall_speed_multiplier = 0.3
	p.vitals.simulation_enabled = false
	await frames(65)
	var floor_position: Vector2 = p.position
	check(is_equal_approx(p.air_attack_frame_pause_duration, 0.07), "Inspector pause defaults to 0.07 game seconds")
	for ticks in [30, 60, 120]:
		for step in [1, 2, 3]:
			air(step)
			var clip: StringName = p.combat.get_attack_anim_name()
			var marker: float = p.presentation.sprite_frame_time(clip, 1)
			check(is_equal_approx(marker, 0.15), "reads actual second sprite frame for swing %d at %dHz" % [step, ticks])
			p.spine_anim.seek(marker - 0.04, true)
			var start_y: float = p.position.y
			p._physics_locked(1.0 / ticks)
			check(p.position.y > start_y, "swing falls before frame 1")
			p.spine_anim.seek(marker, true)
			start_y = p.position.y
			var paused := true
			var pause_ticks := int(ceil(0.07 * ticks))
			for i in pause_ticks:
				p._physics_locked(1.0 / ticks)
				paused = paused and is_zero_approx(p.velocity.y) and absf(p.position.y - start_y) < 0.01
			check(paused, "frame 1 holds altitude for 0.07s (within one physics tick)")
			p._physics_locked(1.0 / ticks)
			check(p.velocity.y > 90 and p.position.y > start_y, "resumes existing slow fall without restarting acceleration: v=%.3f y=%.3f start=%.3f" % [p.velocity.y, p.position.y, start_y])
			var before: float = p.position.y
			p._physics_locked(1.0 / ticks)
			check(p.position.y > before, "staying on frame 1 cannot retrigger pause")
	air(4)
	p.spine_anim.seek(0.2, true)
	var start_y: float = p.position.y
	p._physics_locked(0.02)
	check(p.position.y > start_y, "saber_attack_4 receives no added pause")
	air(1)
	p.air_attack_frame_pause_duration = 0.0
	p._play_combo_step()
	p.spine_anim.pause()
	p.spine_anim.seek(0.15, true)
	p._physics_locked(0.02)
	check(p.velocity.y > 0, "duration zero disables combo pause")
	p.air_attack_frame_pause_duration = 0.12
	p._play_combo_step()
	p.spine_anim.pause()
	p.spine_anim.seek(0.15, true)
	for i in 6: p._physics_locked(0.02)
	check(is_zero_approx(p.velocity.y), "custom 0.12 duration holds for six 0.02s ticks")
	p._physics_locked(0.02)
	check(p.velocity.y > 0, "custom duration expires")
	p.air_attack_frame_pause_duration = 0.07
	air(1)
	p.spine_anim.seek(0.15, true)
	p._physics_locked(0.01)
	p.state_machine.resume_locomotion()
	check(not p.combat.tick_air_attack_pause(0.15, 0.01), "leaving ATTACK cancels pending pause")
	# A ground marker is consumed without applying a late freeze after stepping off.
	p.position = floor_position
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	p.combat.combo_step = 1
	p._play_combo_step()
	p.spine_anim.pause()
	p.spine_anim.seek(0.15, true)
	check(not p.combat.tick_air_attack_pause(0.15, 0.01), "ground attack marker causes no pause")
	p.global_position.y = -20000
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	check(not p.combat.tick_air_attack_pause(0.2, 0.01), "ground marker cannot trigger later after leaving a ledge")
	# Editing frame timing is read from the private animation library at attack start.
	var library: AnimationLibrary = p.spine_anim.get_animation_library(&"")
	var original: Animation = library.get_animation(&"saber_attack_1")
	var changed := original.duplicate() as Animation
	for track in changed.get_track_count():
		if String(changed.track_get_path(track)) == "TestAttackSprite:frame": changed.track_set_key_time(track, 1, 0.12)
	library.remove_animation(&"saber_attack_1")
	library.add_animation(&"saber_attack_1", changed)
	air(1)
	p.spine_anim.seek(0.12, true)
	p._physics_locked(0.01)
	check(is_zero_approx(p.velocity.y), "pause follows edited frame-1 timing instead of hardcoded 0.15s")
	library.remove_animation(&"saber_attack_1")
	library.add_animation(&"saber_attack_1", original)
	for speed in [1.0, 0.5]:
		air(1)
		p.spine_anim.speed_scale = speed
		p._play_jump_attack()
		p.set_physics_process(true)
		var jump_y: float = p.position.y
		var stayed := true
		var observed := false
		var start := Time.get_ticks_usec()
		for i in 120:
			await frames()
			if not p.combat.is_jump_attack_hanging: break
			observed = true
			stayed = stayed and absf(p.position.y - jump_y) < 0.01 and is_zero_approx(p.velocity.y)
		var elapsed := float(Time.get_ticks_usec() - start) / 1000000.0
		check(observed and stayed, "jump_attack(air) holds altitude throughout real animation at speed %.1f" % speed)
		check(elapsed >= 0.25 / speed - 0.03 and elapsed < 0.25 / speed + 0.15, "hang ends with full 0.25s clip, including animation speed changes")
		await frames(2)
		check(p.combat.is_jump_attacking and not p.combat.is_jump_attack_hanging and p.velocity.y > 0, "jump attack descends after animation completion")
		check(p.jump_hitbox._window_open, "jump attack damage opens during descent")
	p.spine_anim.speed_scale = 1.0
	# Real animation continues while only vertical movement is held.
	air(2)
	p.spine_anim.play(&"saber_attack_2")
	p.set_physics_process(true)
	var found_pause := false
	var animation_advanced := false
	for i in 30:
		await frames()
		if is_zero_approx(p.velocity.y) and p.spine_anim.current_animation_position >= 0.15 and p.state_machine.current == S.COMBO:
			found_pause = true
			var position_before: float = p.spine_anim.current_animation_position
			await frames(1)
			animation_advanced = p.spine_anim.current_animation_position > position_before
			break
	check(found_pause and animation_advanced, "live combo pauses falling while animation keeps advancing")
	await frames(8)
	check(p.velocity.y > 0, "live combo resumes slow falling after the short pause")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
