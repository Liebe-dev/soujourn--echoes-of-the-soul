extends Node
var checks := 0
var failures := 0
var p
var hud
var enemy
var scene
var S = AdelStateMachine.State

func _ready() -> void:
	if not String(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("CodexCombatFeel"):
		push_error("Run in isolated CodexCombatFeel custom user directory.")
		get_tree().quit(2)
		return
	_run.call_deferred()
func wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if p != null: print("COMBAT FAILURE CONTEXT state=", p.state_machine.current, " intent=",p._guard_requested," input=",Input.is_action_pressed("guard and deflect")," clip=",p.spine_anim.assigned_animation," position=",p.spine_anim.current_animation_position," scale=",Engine.time_scale)
	print("COMBAT FEEL ", "PASS " if ok else "FAIL ", label)
func button(action: StringName, down: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = down
	Input.parse_input_event(e)
	await frames(1)
func click(action: StringName) -> void:
	await button(action, true)
	await button(action, false)
func reset() -> void:
	for action in [&"guard and deflect", &"attack", &"move_right", &"move_left"]: await button(action, false)
	p.enter_rest(false)
	p.exit_rest()
	p.combat.combo_step = 0
	p.damage.is_invulnerable = false
	p.damage.is_stunned = false
	p.damage.is_touched_enemy = false
	p.is_locked = false
	p.can_move = true
	hud.hp = 100
	hud.clear_all_debuffs()
	hud.restore_stagger_thresholds()
	hud.restore_stamina_full()
	enemy.position = Vector2(3000, 0)
	p.position = Vector2(300, p.position.y)
	await frames(3)
func attack(step: int) -> void:
	p.combat.combo_step = step - 1
	await click(&"attack")
	check(p.state_machine.current == S.COMBO and p.combat.combo_step == step, "real input starts attack %d" % step)
func result() -> int:
	return p.defense.classify_hit(p.global_position, 1, p.global_position + Vector2(80,0))
func hit() -> void:
	p.take_damage(20, p.global_position + Vector2(80,0))
func _run() -> void:
	var model := DefenseComponent.new(0.2, 0.1)
	for age in [0.0, 0.099, 0.1, 0.299, 0.3, 1.0]:
		model.begin_guard(age)
		var expected := DefenseComponent.HitResult.DEFLECT if age >= 0.1 and age < 0.3 else DefenseComponent.HitResult.GUARD
		check(model.classify_hit(Vector2.ZERO,1,Vector2(80,0)) == expected, "exact deflect boundary %.3f" % age)
		check(model.classify_hit(Vector2.ZERO,1,Vector2(-80,0)) == DefenseComponent.HitResult.NONE, "rear remains unprotected at %.3f" % age)
	model.end_guard()
	check(model.classify_hit(Vector2.ZERO,1,Vector2(80,0)) == DefenseComponent.HitResult.NONE, "release removes all protection")
	model = DefenseComponent.new(0.05,0.25)
	model.begin_guard(0.26)
	check(model.is_in_deflect_window(), "delay and window independently configurable")
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	await wait(1.1)
	hud = p.get_node("Camera2D/hud")
	hud.set_process(false)
	p.vitals.simulation_enabled = false
	p._set_facing_direction(1)
	check(p.attack_defense_unlock_time == 0.6 and p.attack_4_defense_unlock_time == 0.75, "default defense commitment is 0.60/0.75 seconds")
	# This matrix tests the approved 100ms baseline, independent of designer scene overrides.
	p.deflect_delay = 0.1
	p.defense.deflect_delay = 0.1
	check(p.attack_input_buffer == 0.18 and p.deflect_delay == 0.1 and p.deflect_window == 0.2, "buffer and deflect regression fixture matches approved baseline")
	for step in range(1,5):
		await reset()
		await attack(step)
		await wait(0.08)
		await button(&"guard and deflect", true)
		await wait(0.35 if step < 4 else 0.5)
		check(not p.is_guarding and p.state_machine.current == S.COMBO, "attack %d cannot enter defense before its full commitment" % step)
		# Wait for the actual animation/state boundary, not wall time during first-use shader compilation.
		var deadline := Time.get_ticks_msec() + 1500
		while p.state_machine.current == S.COMBO and Time.get_ticks_msec() < deadline:
			await frames(1)
		check(p.is_guarding and p.spine_anim.assigned_animation == &"saber_defense", "held input enters defense after attack %d, without another click" % step)
		check(result() == DefenseComponent.HitResult.GUARD, "early press does not receive a fresh parry window after attack %d" % step)
		check(not p.combat.attack_queued and p.combat.combo_step == 0 and not p.saber_hitbox._attack_active, "defense clears attack %d queue, sequence and hitbox" % step)
	# Release intent before the end must never produce a ghost defense.
	await reset()
	await attack(1)
	await button(&"guard and deflect", true)
	await button(&"guard and deflect", false)
	await wait(0.7)
	check(not p.is_guarding and not p._guard_requested, "released pending defense never executes later")
	# A recent press near completion can still Deflect after its 100ms startup.
	await reset()
	await attack(1)
	await wait(0.45)
	await button(&"guard and deflect", true)
	await wait(0.15)
	check(p.is_guarding and result() == DefenseComponent.HitResult.DEFLECT, "late attack-to-defense press preserves only its remaining Deflect window")
	await wait(0.21)
	check(result() == DefenseComponent.HitResult.GUARD, "held button becomes Guard after 0.30, with no reset")
	# Attack buffer and defensive priority through actual input.
	await reset()
	await attack(1)
	await click(&"attack")
	await wait(0.45)
	check(p.combat.combo_step == 1 and not p.combat.attack_queued, "early attack request expires instead of executing late")
	await reset()
	await attack(1)
	await wait(0.24)
	await click(&"attack")
	check(p.combat.attack_queued, "recent press occupies one combo buffer slot")
	await wait(0.18)
	check(p.combat.combo_step == 2, "recent buffered press executes at existing combo link")
	await reset()
	await attack(1)
	await wait(0.24)
	await click(&"attack")
	await button(&"guard and deflect", true)
	await wait(0.4)
	check(p.is_guarding and p.combat.combo_step == 0, "held defense wins over a queued attack and does not shorten commitment")
	await button(&"guard and deflect", false)
	await wait(0.2)
	check(not p.is_doing_action and not p.combat.attack_queued, "release defense does not resurrect old attack")
	# Existing movement cancellation must not bypass the new defense commitment.
	await reset()
	await attack(1)
	await button(&"move_right", true)
	await wait(0.39)
	await button(&"guard and deflect", true)
	check(not p.is_guarding, "movement cancel cannot open defense before original 0.60")
	await wait(0.22)
	check(p.is_guarding, "pending defense survives movement cancel and starts at original unlock")
	# Stagger / rest / menus / focus discard intentions.
	await reset()
	await attack(1)
	await button(&"guard and deflect", true)
	hud.hp = 70
	hit()
	check(p.damage.is_stunned and not p._guard_requested and not p.combat.attack_queued, "stagger preempts and clears pending actions")
	await wait(1.1)
	check(not p.is_guarding, "held input rejected by stagger does not automatically restart defense")
	await reset()
	await attack(1)
	await button(&"guard and deflect", true)
	p.enter_rest(false)
	await wait(0.7)
	check(p.is_resting and not p._guard_requested and not p.saber_hitbox._attack_active, "rest cancels all pending attack/defense callbacks")
	await reset()
	await attack(1)
	await button(&"guard and deflect", true)
	var pause = p.get_node("Camera2D/UI_Layer/PauseMenu")
	pause.pause_and_unpause()
	check(get_tree().paused and not p._guard_requested and not p.combat.attack_queued, "pause clears buffered intent")
	pause.pause_and_unpause()
	await wait(0.7)
	check(not p.is_guarding, "resume cannot replay a pre-menu defensive request")
	await reset()
	hud.stamina = 0
	await button(&"guard and deflect", true)
	hud.restore_stamina_full()
	await wait(0.4)
	check(not p.is_guarding, "zero stamina requires a fresh press after recovery")
	await reset()
	await button(&"guard and deflect", true)
	check(result() == DefenseComponent.HitResult.GUARD, "real input begins as Guard immediately")
	hit()
	check(hud.hp == 90 and hud.stamina == 80 and p.spine_anim.assigned_animation == &"saber_guard", "startup Guard applies existing damage/stamina/reaction rules")
	check(Engine.time_scale == p.hit_stop_scale, "successful Guard requests its impact pulse")
	await wait(0.08)
	check(Engine.time_scale == 1.0, "Guard impact restores normal speed")
	# Deflect hit-stop precedes the full pre-existing slow-motion pulse.
	await reset()
	await button(&"guard and deflect", true)
	await wait(0.12)
	check(result() == DefenseComponent.HitResult.DEFLECT, "real input enters Deflect after startup")
	var started := Time.get_ticks_usec()
	hit()
	check(hud.hp == 100 and hud.stamina == 80 and Engine.time_scale == p.hit_stop_scale, "Deflect blocks HP, charges stamina and starts strongest impact")
	check(p.deflect_slow_motion.is_active and p.spine_anim.assigned_animation == &"saber_deflect", "Deflect pose is held from impact start")
	await wait(p.deflect_hit_stop_duration + 0.035)
	check(is_equal_approx(Engine.time_scale,p.deflect_slow_motion_scale) and p.deflect_slow_motion.is_active, "impact expiry restores ongoing Deflect slow motion, not 1x")
	check(p.spine_anim.assigned_animation == &"saber_deflect", "Deflect pose remains held throughout slow motion")
	await wait(p.deflect_slow_motion_duration + 0.04)
	check(Engine.time_scale == 1.0 and not p.deflect_slow_motion.is_active and p.is_guarding, "full pulse ends into continuous Defense at normal speed")
	check(float(Time.get_ticks_usec()-started)/1000000.0 >= p.deflect_hit_stop_duration+p.deflect_slow_motion_duration, "hit-stop does not consume the slow-motion duration")
	# Actual collision confirms a hit; whiffs and duplicate targets never restart it.
	for step in [1,4]:
		await reset()
		enemy.current_health = 1000
		var observations: Array = []
		var cb := func(name): observations.append([name,Engine.time_scale])
		p.saber_hitbox.hit_confirmed.connect(cb)
		await attack(step)
		enemy.global_position = p.saber_hitbox.hitbox_shape.global_position
		await wait(0.24)
		check(enemy.current_health < 1000 and observations.size() == 1, "real attack %d overlap damages target and confirms exactly one impact" % step)
		check(observations.size() == 1 and observations[0][1] == p.hit_stop_scale, "attack %d confirmed impact changes global simulation speed" % step)
		check(Engine.time_scale == 1.0, "attack %d impact finishes within its short real-time duration" % step)
		p.saber_hitbox.hit_confirmed.disconnect(cb)
	await reset()
	await attack(1)
	await wait(0.24)
	check(CombatTime._effects.is_empty() and Engine.time_scale == 1.0, "whiff never requests hit-stop")
	# Buffer lifetime is suspended during near-freeze while actual input still arrives.
	await reset()
	await attack(1)
	await wait(0.24)
	await click(&"attack")
	p._request_hit_stop(0.15)
	await wait(0.1)
	check(p.combat.attack_queued and Engine.time_scale == p.hit_stop_scale, "queued attack survives wall-time spent in hit-stop")
	await wait(0.3)
	check(p.combat.combo_step == 2, "buffered attack executes once simulation resumes")
	await reset()
	p._request_hit_stop(0.12)
	await button(&"guard and deflect", true)
	await wait(0.065)
	check(p.is_guarding and result() == DefenseComponent.HitResult.GUARD, "input received during hit-stop stays in startup until combat time resumes")
	await wait(0.2)
	check(result() == DefenseComponent.HitResult.DEFLECT, "Deflect clock resumes after hit-stop without losing input")
	await reset()
	# Existing legacy receiver keeps its void API but still receives impact feedback.
	await reset()
	var legacy = load("res://scenes/testing/Enemies/enemy.tscn").instantiate()
	# This old fixture only has idle; supply an in-memory walk alias for its existing ready() call.
	var legacy_sprite = legacy.get_node("AnimatedSprite2D")
	legacy_sprite.sprite_frames = legacy_sprite.sprite_frames.duplicate()
	legacy_sprite.sprite_frames.add_animation(&"walk")
	legacy_sprite.sprite_frames.add_frame(&"walk", legacy_sprite.sprite_frames.get_frame_texture(&"idle", 0))
	scene.add_child(legacy)
	legacy.set_physics_process(false)
	legacy.position = Vector2(-3000,0)
	await attack(1)
	p.saber_hitbox._on_hitbox_body_entered(legacy)
	check(legacy.current_health == legacy.max_health-20 and Engine.time_scale == p.hit_stop_scale, "legacy void receiver confirms actual HP loss without changing its script")
	CombatTime.remove(p)
	p.saber_hitbox._on_hitbox_body_entered(enemy)
	check(Engine.time_scale == 1.0, "second target in same swing cannot restart impact")
	legacy.queue_free()
	await reset()
	await attack(1)
	await button(&"guard and deflect", true)
	p.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await wait(0.7)
	check(not p._guard_requested and not p.is_guarding, "focus loss clears held intent instead of replaying on return")
	await reset()
	await button(&"guard and deflect", true)
	p.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not p.is_guarding and not p._guard_requested, "focus loss also releases an already-active Defense")
	await reset()
	p.attack_defense_unlock_time = 0.9
	await attack(1)
	await button(&"guard and deflect", true)
	await wait(0.64)
	check(not p.is_guarding, "Inspector commitment above clip length adds a real lock")
	await wait(0.3)
	check(p.is_guarding, "configured extended commitment eventually accepts held Defense")
	p.attack_defense_unlock_time = 0.6
	await reset()
	p.hit_stop_enabled = false
	await button(&"guard and deflect", true)
	hit()
	check(hud.hp == 90 and Engine.time_scale == 1.0, "Hit Stop Enabled off preserves Guard damage without pulse")
	p.hit_stop_enabled = true
	await reset()
	p._request_hit_stop(0.15)
	p._request_hit_stop(0.02)
	await wait(0.09)
	check(Engine.time_scale == p.hit_stop_scale, "weaker repeated impact cannot shorten strongest remaining pulse")
	await wait(0.11)
	check(Engine.time_scale == 1.0, "repeated impact durations are not added")
	# Arbitration, cancellation and pause restoration have deterministic ownership.
	Engine.time_scale = 0.8
	var owner := Node.new()
	add_child(owner)
	CombatTime.request(owner,&"test_slow",0.5,0.3)
	CombatTime.request(owner,&"hit_stop",0.05,0.06)
	check(Engine.time_scale == 0.05, "overlapping effects choose strongest slowdown")
	await wait(0.1)
	check(Engine.time_scale == 0.5, "impact expiration restores underlying effect")
	owner.queue_free()
	await frames(2)
	check(is_equal_approx(Engine.time_scale,0.8) and CombatTime._effects.is_empty(), "removing effect owner restores captured base scale")
	Engine.time_scale = 1.0
	p._request_hit_stop(0.14)
	get_tree().paused = true
	await wait(0.2)
	check(Engine.time_scale == 1.0 and not CombatTime._effects.is_empty(), "pause shows UI at base speed and suspends remaining pulse")
	get_tree().paused = false
	await frames(2)
	check(Engine.time_scale == p.hit_stop_scale, "resume restores pending impact without stale timer expiry")
	await wait(0.18)
	check(Engine.time_scale == 1.0 and CombatTime._effects.is_empty(), "resumed impact expires cleanly")
	p._request_hit_stop(0.2)
	p.enter_rest(false)
	check(Engine.time_scale == 1.0 and CombatTime._effects.is_empty(), "campfire/rest immediately removes player-owned impact")
	p.exit_rest()
	if DisplayServer.get_name() != "headless":
		await reset()
		await attack(4)
		await button(&"guard and deflect", true)
		await wait(0.8)
		check(p.is_guarding and p.spine_anim.assigned_animation == &"saber_defense", "rendered attack-to-defense transition uses actual animation")
		await RenderingServer.frame_post_draw
		var capture := OS.get_environment("CODEX_COMBAT_SCREENSHOT")
		if not capture.is_empty(): get_viewport().get_texture().get_image().save_png(capture)
	print("COMBAT FEEL RESULT: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
