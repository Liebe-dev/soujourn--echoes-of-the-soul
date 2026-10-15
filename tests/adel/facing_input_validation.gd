extends Node

var checks := 0
var failures := 0
var player
var skill
var enemy
var hud
var S = AdelStateMachine.State

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("FACING INPUT ", "PASS " if ok else "FAIL ", label)

func frame(count: int = 2) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func input(action: StringName, pressed: bool, ticks: int = 1) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	await frame(ticks)

func reach(state: int, timeout: float = 3.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while player.state_machine.current != state and Time.get_ticks_msec() < deadline:
		await frame(1)
	return player.state_machine.current == state

func charge_until(time: float) -> void:
	var deadline := Time.get_ticks_msec() + 3000
	while skill.charge_time < time and player.state_machine.current == S.SKILL_CHARGE and Time.get_ticks_msec() < deadline:
		await frame(1)

func stop_skill() -> void:
	await input(&"move_left", false)
	await input(&"move_right", false)
	await input(&"weapon_skill", false)
	skill.abort()
	await frame(2)

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexFacingInput20261015"):
		get_tree().quit(2)
		return
	Engine.max_fps = 120
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	player = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	enemy.position.x = 3000.0
	await frame(65)
	skill = player.saber_skill
	hud = player.get_node("Camera2D/hud")
	hud.set_process(false)
	player.vitals.simulation_enabled = false
	player.hit_stop_enabled = false
	player.position.x = 700.0
	player._set_facing_direction(1)
	await input(&"guard and deflect", true)
	var defense_x: float = player.position.x
	await get_tree().create_timer(0.35).timeout
	var guard_age: float = player.defense.holding_duration
	await input(&"move_left", true)
	check(player.facing_direction == -1 and player.spine_pivot.scale.x < 0.0 and player.weapon_pivot.scale.x < 0.0, "A mirrors player and weapon while holding defense")
	check(absf(player.position.x - defense_x) < 0.1, "turning defense does not walk the player")
	check(player.defense.is_guarding and player.defense.holding_duration >= guard_age and not player.defense.is_in_deflect_window(), "turning preserves guard age without reopening deflect window")
	check(player.defense.classify_hit(player.global_position, player.facing_direction, player.global_position - Vector2(80, 0)) == DefenseComponent.HitResult.GUARD, "left-side strike is now frontal guard")
	check(player.defense.classify_hit(player.global_position, player.facing_direction, player.global_position + Vector2(80, 0)) == DefenseComponent.HitResult.NONE, "right-side strike becomes a back hit after turning left")
	var hp_before: int = hud.hp
	var stamina_before: float = hud.stamina
	player.take_damage(10, player.global_position - Vector2(80, 0))
	check(hud.hp == hp_before - 5 and hud.stamina < stamina_before, "real hit from new facing direction uses guard damage and stamina cost")
	await input(&"move_left", false)
	await input(&"move_right", true)
	check(player.facing_direction == 1 and player.spine_anim.assigned_animation == player.ANIM_GUARD, "turning during guard reaction keeps guard animation")
	check(player.velocity.x >= 0.0, "turning does not reverse existing guard knockback")
	await input(&"move_left", true)
	check(player.facing_direction == 1, "opposing movement inputs preserve last facing")
	await input(&"move_left", false)
	await input(&"move_right", false)
	await input(&"guard and deflect", false)
	await frame(12)
	player._set_facing_direction(1)
	await input(&"guard and deflect", true)
	await frame(7)
	await input(&"move_left", true)
	check(player.defense.is_in_deflect_window() and player.facing_direction == -1, "turning during the original deflect window preserves that window")
	var deflect_hp: int = hud.hp
	player.take_damage(10, player.global_position - Vector2(80, 0))
	check(hud.hp == deflect_hp and player.spine_anim.assigned_animation == player.ANIM_DEFLECT, "actual left-side hit deflects after turning")
	await input(&"move_left", false)
	await input(&"move_right", true)
	check(player.facing_direction == 1 and player.spine_anim.assigned_animation == player.ANIM_DEFLECT, "deflect pose turns without restarting its animation")
	await input(&"move_right", false)
	await input(&"guard and deflect", false)
	await get_tree().create_timer(player.deflect_slow_motion_duration + 0.05, true, false, true).timeout
	await frame(3)
	hud.restore_stamina_full()
	player._set_facing_direction(1)
	skill.charge_level_1_time = 0.4
	skill.charge_level_2_time = 1.0
	var charge_x: float = player.position.x
	await input(&"weapon_skill", true)
	var charge_before: float = skill.charge_time
	await input(&"move_left", true)
	check(player.facing_direction == -1 and skill._direction == -1, "Q charge updates player and stored lunge direction together")
	check(skill.charge_time >= charge_before and player.spine_anim.assigned_animation == &"saber_skill_1", "turning preserves charge time and charge pose")
	check(absf(player.position.x - charge_x) < 0.1, "turning charge does not move the player")
	await input(&"move_left", false)
	await charge_until(0.43)
	check(player.spine_anim.assigned_animation == &"saber_skill_2", "charge still reaches second pose normally")
	await input(&"move_right", true)
	check(player.facing_direction == 1 and skill._direction == 1 and skill.charge_time >= 0.4, "second charge pose also turns without dropping charge tier")
	await input(&"move_right", false)
	# Change direction and release Q in the same input frame, before physics runs.
	Input.action_press(&"move_left")
	enemy.position = player.position - Vector2(155, 0)
	enemy.current_health = 1000
	await input(&"weapon_skill", false)
	check(skill._direction == -1 and player.facing_direction == -1 and player.state_machine.current == S.SKILL_RELEASE, "release captures last-frame direction before committing charged windup")
	Input.action_release(&"move_left")
	await input(&"move_right", true)
	check(skill._direction == -1 and player.facing_direction == -1, "committed release cannot turn after Q has been released")
	check(await reach(S.SKILL_IMPACT), "charged lunge contacts enemy on newly selected left side")
	var expected := int(round(skill.damage * skill.charged_damage_multiplier))
	check(skill.contact_target == enemy and enemy.current_health == 1000 - expected, "mirrored skill hitbox deals correct damage to left-side target")
	check(player.facing_direction == -1 and skill._direction == -1, "impact direction stays locked despite opposite movement input")
	await stop_skill()
	enemy.position.x = 3000.0
	player._set_facing_direction(1)
	await frame(5)
	await input(&"weapon_skill", true)
	await charge_until(0.83)
	check(player.spine_anim.assigned_animation == &"saber_skill_3", "full charge final pose starts at authored threshold")
	await input(&"move_left", true)
	check(player.facing_direction == -1 and skill._direction == -1, "final charge pose can still turn before automatic launch")
	var origin: float = player.position.x
	check(await reach(S.SKILL_DASH), "full charge still launches automatically while Q held")
	await input(&"move_left", false)
	await input(&"move_right", true)
	check(skill._direction == -1 and player.facing_direction == -1 and player.position.x < origin, "automatic lunge travels left and cannot reverse mid-dash")
	await stop_skill()
	await frame(4)
	player._set_facing_direction(1)
	await input(&"weapon_skill", true)
	Input.action_press(&"move_left")
	await input(&"weapon_skill", false)
	check(player.state_machine.current == S.SKILL_CHARGE and skill._direction == -1 and skill.charge_time < skill.tap_windup, "quick tap captures last-frame turn while preserving minimum startup")
	Input.action_release(&"move_left")
	await input(&"move_right", true)
	check(await reach(S.SKILL_DASH), "quick tap still enters its normal lunge")
	check(skill._direction == -1 and player.facing_direction == -1, "quick tap cannot redirect after release during remaining startup")
	await stop_skill()
	print("FACING INPUT RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
