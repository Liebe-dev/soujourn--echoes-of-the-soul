extends Node
var checks := 0
var failures := 0
var p
var hud
var origin: Vector2
const S = AdelStateMachine.State

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("Q HOLD ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func button(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames()

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func until_skill() -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while not p.saber_skill.is_active() and Time.get_ticks_msec() < deadline: await frames()
	return p.saber_skill.is_active()

func reset() -> void:
	for action in [&"weapon_skill", &"guard and deflect", &"attack", &"move_right", &"dodge"]: await button(action, false)
	p.clear_combat_input()
	p.end_sentinel()
	p.state_machine.resume_locomotion()
	while not p.dash.able_to_dodge: await frames()
	p.damage.reset()
	p.stats.heal_to_full()
	p.position = origin
	p.velocity = Vector2.ZERO
	p.saber_skill.allow_airborne = false
	await frames(4)

func dash() -> void:
	await button(&"move_right", true)
	await button(&"dodge", true)
	await button(&"dodge", false)
	await button(&"move_right", false)
	check(p.dash.is_dodging, "actual dash input enters active dash")

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexQHold20261016"):
		get_tree().quit(2)
		return
	Engine.max_fps = 144
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	scene.get_node("Enemy").set_physics_process(false)
	scene.get_node("Enemy").position.x = 6000.0
	p.stagger_zoom_enabled = false
	p.stagger_slow_motion_enabled = false
	p.hit_stop_enabled = false
	await frames(65)
	origin = p.position
	hud = p.get_node("Camera2D/hud")
	p.vitals.simulation_enabled = false
	var authored_cooldown: float = p.dodge_cooldown.wait_time
	p.dodge_cooldown.wait_time = 0.35
	await dash()
	await button(&"weapon_skill", true)
	check(p._skill_requested and not p.saber_skill.is_active() and p.dash.is_dodging, "held Q queues without cancelling dash")
	while p.dash.is_dodging: await frames()
	check(p.saber_skill.is_active() and not p.dash.able_to_dodge, "held Q starts immediately at skid end while dash cooldown remains")
	check(p.dodge_cooldown.time_left > 0.25, "Q does not wait for any of the remaining dash cooldown")
	check(p.state_machine.current == S.SKILL_CHARGE, "still-held Q enters charge directly after skid")
	check(p.saber_skill.charge_time < 0.1 and p.state_machine.current == S.SKILL_CHARGE, "charge timer starts at actual skill entry rather than original Q press")
	check(not p._skill_requested, "accepted intent is consumed once")
	await reset()
	await dash()
	await button(&"weapon_skill", true)
	await button(&"weapon_skill", false)
	await wait(1.0)
	check(not p.saber_skill.is_active() and not p._skill_requested, "Q release during dash cancels intent without delayed tap attack")
	await reset()
	await dash()
	while p.dash.is_dodging: await frames()
	await button(&"weapon_skill", true)
	check(p.saber_skill.is_active() and not p.dash.able_to_dodge, "fresh Q during dash cooldown starts immediately")
	await button(&"weapon_skill", false)
	check(not p._skill_requested and p.saber_skill.is_active(), "Q release after immediate entry follows normal tap windup")
	await wait(0.65)
	await reset()
	p.dodge_cooldown.wait_time = 1.0
	await dash()
	while p.dash.is_dodging: await frames()
	var stamina_before: float = p.stats.stamina
	p._perform_dash(1.0)
	check(not p.dash.is_dodging and p.stats.stamina == stamina_before, "cooldown still rejects another dash without spending stamina")
	await button(&"attack", true)
	await button(&"attack", false)
	check(p.state_machine.current == S.COMBO and not p.dash.able_to_dodge, "ordinary attack starts during dash cooldown")
	await reset()
	await dash()
	while p.dash.is_dodging: await frames()
	await button(&"jump", true)
	await button(&"jump", false)
	check(not p.is_on_floor() and not p.dash.able_to_dodge, "jump starts during dash cooldown")
	check(p.state_machine.can_begin_action(), "dash cooldown does not lock the general action permission")
	p.dodge_cooldown.wait_time = 0.35
	for step in [1, 2, 3, 4]:
		await reset()
		p.combat.combo_step = step - 1
		await button(&"attack", true)
		await button(&"attack", false)
		await button(&"weapon_skill", true)
		await button(&"move_right", true)
		check(p.state_machine.current == S.COMBO and p._skill_requested and not p.saber_skill.is_active(), "attack %d retains current swing while Q waits" % step)
		await wait(0.45 if step != 4 else 0.60)
		check(p.state_machine.current == S.COMBO and not p.saber_skill.is_active(), "queued Q does not exploit early movement cancel on attack %d" % step)
		check(await until_skill(), "attack %d finishes and enters held Q" % step)
		check(p.saber_skill.charge_time < 0.1, "attack %d waiting time does not pre-charge Q" % step)
	await reset()
	await button(&"attack", true)
	await button(&"attack", false)
	await button(&"attack", true)
	await button(&"attack", false)
	await button(&"weapon_skill", true)
	check(not p.combat.attack_queued, "Q replaces previously buffered next combo")
	await button(&"attack", true)
	await button(&"attack", false)
	check(not p.combat.attack_queued and p.combat.combo_step == 1, "new combo input cannot steal accepted Q intent")
	await button(&"weapon_skill", false)
	await wait(0.8)
	check(not p.saber_skill.is_active() and not p._skill_requested, "release during ordinary attack cancels queued Q")
	await reset()
	await button(&"guard and deflect", true)
	check(p.is_guarding, "defense fixture starts normally")
	await button(&"weapon_skill", true)
	check(p.saber_skill.is_active() and not p.is_guarding and p.state_machine.current == S.SKILL_CHARGE, "Q immediately interrupts held defense")
	check(p._guard_requires_release and not p._guard_requested and Input.is_action_pressed("guard and deflect"), "held defense is latched until physical release")
	await button(&"weapon_skill", false)
	await wait(0.8)
	p._try_begin_guard()
	check(not p.is_guarding and p._guard_requires_release, "defense cannot restart after Q while original button remains held")
	await button(&"guard and deflect", false)
	await button(&"guard and deflect", true)
	check(p.is_guarding and not p._guard_requires_release, "release followed by fresh defense press rearms protection")
	await reset()
	await button(&"guard and deflect", true)
	p._play_defense_hit_pose(p.ANIM_GUARD)
	p.defense.start_guard_push(20.0, 0.1, -1.0)
	await button(&"weapon_skill", true)
	check(p.saber_skill.is_active() and not p.defense.guard_push_active and not p.is_guarding, "Q cleans up a guard hit reaction and push")
	await reset()
	await button(&"guard and deflect", true)
	p.deflect_slow_motion.start(0.5, 0.4)
	p._play_defense_hit_pose(p.ANIM_DEFLECT)
	await button(&"weapon_skill", true)
	check(p.saber_skill.is_active() and not p.deflect_slow_motion.is_active and Engine.time_scale == 1.0, "Q cancels held deflect reaction without leftover slow motion")
	await reset()
	await dash()
	await button(&"weapon_skill", true)
	p.clear_combat_input()
	await wait(1.0)
	check(not p._skill_requested and not p.saber_skill.is_active() and Input.is_action_pressed("weapon_skill"), "menu/input cleanup cancels intent even while Q stays physically held")
	await reset()
	await button(&"attack", true)
	await button(&"attack", false)
	await button(&"weapon_skill", true)
	p.damage.apply_stagger(Vector2.LEFT, 10.0, 0.05, 0.05, 0.2)
	await wait(0.35)
	check(not p._skill_requested and not p.saber_skill.is_active(), "stagger cancels queued Q without replay after recovery")
	await reset()
	await button(&"attack", true)
	await button(&"attack", false)
	await button(&"weapon_skill", true)
	p.begin_sentinel()
	p.sentinel_state.tick(p.sentinel_entry_duration)
	p._handle_attack_input()
	p.stats.hp = 1
	p.sentinel_state.tick(0.0)
	check(p.is_sentinel_exit_pending() and not p._skill_requested, "Sentinel pending exit discards queued Q")
	await wait(0.9)
	check(not p.saber_skill.is_active(), "held Q cannot replay through forced Sentinel exit")
	await reset()
	p.stats.stamina = 0.0
	await button(&"weapon_skill", true)
	check(p.saber_skill.is_active(), "existing Saber Q still has no new stamina cost")
	await wait(p.saber_skill.charge_level_2_time + 0.8)
	check(not p.saber_skill.is_active() and not p._skill_requested and Input.is_action_pressed("weapon_skill"), "holding Q after auto-release never loops a second skill")
	await reset()
	p.dodge_cooldown.wait_time = authored_cooldown
	check(p.dodge_cooldown.wait_time == authored_cooldown, "authored dash cooldown remains unchanged")
	print("Q HOLD RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
