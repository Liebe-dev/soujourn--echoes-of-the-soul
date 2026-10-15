extends Node
var checks := 0
var failures := 0
func _ready() -> void:
	var isolated: bool = ProjectSettings.get_setting("application/config/use_custom_user_dir", false)
	var directory := String(ProjectSettings.get_setting("application/config/custom_user_dir_name", ""))
	if not isolated or not directory.begins_with("CodexGuardStamina"):
		push_error("Run this checkpoint-writing test in an isolated project with custom user directory CodexGuardStaminaValidation.")
		get_tree().quit(2)
		return
	_run.call_deferred()
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("GUARD STAMINA ", "PASS " if ok else "FAIL ", label)
func button(action: StringName, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)
	await frames(1)
func click(action: StringName) -> void:
	await button(action, true)
	await button(action, false)
func fresh(p, hud, late: bool, stamina: float = 100.0) -> void:
	if p.deflect_slow_motion.is_active: await wait(p.deflect_slow_motion_duration + 0.04)
	await button(&"guard and deflect", false)
	if p.damage.is_stunned or p.damage.is_invulnerable: await wait(1.1)
	hud.hp = 100
	hud.clear_all_debuffs()
	hud.restore_stagger_thresholds()
	hud.restore_stamina_full()
	hud.stamina = stamina
	hud.sync_stamina_display()
	p._set_facing_direction(1)
	await button(&"guard and deflect", true)
	await wait(0.34 if late else 0.12)
func hit(p, amount: int = 20, y: float = 0.0) -> void:
	p.take_damage(amount, p.global_position + Vector2(p.facing_direction * 80, y))
func _run() -> void:
	var model := StatsComponent.new()
	check(model.stamina == 100 and model.max_stamina == 100, "default stamina capacity and current value are 100")
	for action in ["dash", "guard", "deflect"]:
		model.restore_stamina_full()
		check(model.spend_stamina(action) and model.stamina == 80, action + " defaults to 20 cost")
	model.restore_stamina_full()
	model.spend_stamina("dash")
	check(not model.regen_stamina(1.49) and model.stamina == 80, "no model regen before 1.5 seconds")
	check(model.regen_stamina(0.02) and is_equal_approx(model.stamina, 80.28), "regen uses only time beyond delay, at 28 per second")
	check(not model.regen_stamina(5.0, true), "blocked action never regenerates")
	check(not model.regen_stamina(1.5) and is_equal_approx(model.stamina, 80.28), "blocking resets full idle delay")
	model.regen_stamina(10.0)
	check(model.stamina == 100, "regen clamps at maximum")
	model.stamina = 10
	check(not model.can_spend_stamina("deflect"), "insufficiency is checked before spending")
	check(model.spend_stamina("dash", true) and model.stamina == 0, "partial spending consumes remainder without negatives")
	check(model.spend_stamina("attack") and model.stamina == 0, "attack has no stamina charge in this scope")
	model.hp = 70
	var damage_result := model.apply_damage(10, Vector2.INF, true)
	check(model.hp == 60 and not damage_result.staggered and model.stagger_tiers_ready == [true, true] and not model.has_any_debuff(), "exhausted guard HP loss can cross 66 without triggering threshold")
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	var p = scene.get_node("PlayableAdel")
	p.hit_stop_enabled = false
	var enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	await frames(70)
	var hud = p.get_node("Camera2D/hud")
	hud.set_process(false)
	var pose = p.spine_rig.get_node("TestAttackSprite")
	var guard_distance: float = p.guard_knockback_distance
	var guard_duration: float = p.guard_knockback_duration
	check(hud.stamina == 100 and hud.stamina_bar.value == 100, "HUD green bar starts at 100")
	for facing in [-1, 1]:
		await fresh(p, hud, true)
		p._set_facing_direction(facing)
		var start: Vector2 = p.position
		hit(p, 20, 40)
		check(hud.hp == 90 and hud.stamina == 80 and hud.stamina_bar.value == 80, "guard damage and HUD stamina debit, facing %d" % facing)
		check(p.is_guarding and not p.damage.is_stunned and p.spine_anim.assigned_animation == &"saber_guard" and p.velocity.y == 0.0, "guard stays active with no upward impulse")
		await frames(6)
		check(p.spine_anim.assigned_animation == &"saber_guard" and p.is_guarding, "guard pose held throughout push")
		await frames(10)
		check(absf(p.position.x - start.x + facing * guard_distance) < 0.5 and absf(p.position.y - start.y) < 0.1, "normal guard travels its configured distance horizontally, facing %d" % facing)
		check(p.is_guarding and not p.damage.is_stunned and p.spine_anim.assigned_animation == &"saber_defense", "push ends back in continuous neutral defense")
	await fresh(p, hud, true)
	hit(p)
	await frames(5)
	p.damage.is_invulnerable = false
	hit(p)
	check(hud.stamina == 60 and hud.hp == 80 and p.is_guarding and not p.damage.is_stunned, "next valid hit during push remains guardable and costs once")
	await frames(15)
	check(not p.defense.guard_push_active and p.is_guarding, "repeated guard push settles without cancelling protection")
	await fresh(p, hud, true)
	p.guard_knockback_distance = 30
	p.guard_knockback_duration = 0.3
	p.defense_hit_pose_duration = 0.05
	var start: Vector2 = p.position
	hit(p)
	await frames(10)
	check(p.spine_anim.assigned_animation == &"saber_guard", "longer configured push preserves guard beyond ordinary pose timer")
	await frames(12)
	check(absf(p.position.x - start.x + 30) < 0.5, "guard distance/duration can be configured independently")
	p.guard_knockback_distance = guard_distance
	p.guard_knockback_duration = guard_duration
	p.defense_hit_pose_duration = 0.2
	await fresh(p, hud, true)
	var wall := StaticBody2D.new()
	wall.position = p.position + Vector2(-60, 0)
	var shape_node := CollisionShape2D.new()
	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2(20, 400)
	shape_node.shape = wall_shape
	wall.add_child(shape_node)
	scene.add_child(wall)
	await frames(2)
	start = p.position
	hit(p)
	await frames(16)
	check(p.position.x > start.x - guard_distance and p.position.x < start.x and p.is_guarding and not p.defense.guard_push_active, "wall clips horizontal push without teleport or guard lock")
	wall.queue_free()
	await frames(2)
	await button(&"guard and deflect", false)
	await wait(0.3)
	await click(&"jump")
	await fresh(p, hud, true)
	var vertical_before: float = p.velocity.y
	hit(p)
	check(p.velocity.y == vertical_before, "airborne guard adds no vertical velocity")
	await frames(85)

	# Exactly the configured cost still buys this hit's normal reaction.
	await fresh(p, hud, false, 20)
	hit(p)
	check(hud.stamina == 0 and not p.damage.is_stunned and p.deflect_slow_motion.is_active and hud.hp == 100, "exactly 20 buys a normal Deflect with no exhaustion")
	check(not p.is_guarding, "final paid Deflect removes protection immediately")
	hit(p)
	check(hud.hp == 80 and not p.damage.is_stunned and hud.stamina == 0, "same-frame subsequent hit at zero is unguarded and undeflected")
	check(p.deflect_slow_motion.is_active and pose.frame == 0 and p.spine_anim.assigned_animation == &"saber_deflect", "paid Deflect still holds its pose through slow motion at zero")
	await wait(p.deflect_slow_motion_duration + 0.05)
	check(not p.is_guarding and p.can_move and p.spine_anim.assigned_animation == &"saber_ready" and pose.frame == 2, "pulse expiry at zero releases to ready and cannot restart held defense")
	await fresh(p, hud, true, 20)
	start = p.position
	hit(p)
	check(hud.hp == 90 and hud.stamina == 0 and not p.is_guarding and not p.damage.is_stunned and p.defense.guard_push_active, "exactly 20 buys normal Guard recoil while ending protection")
	check(p.spine_anim.assigned_animation == &"saber_guard", "final paid Guard retains guard pose")
	await frames(16)
	check(absf(p.position.x - start.x + guard_distance) < 0.5 and p.can_move and not p.is_guarding, "final paid Guard completes unchanged recoil then releases controls")
	p.damage.is_invulnerable = false
	hit(p)
	check(hud.hp == 70 and hud.stamina == 0 and not p.deflect_slow_motion.is_active, "next frontal hit after final paid Guard receives full damage")
	for late in [false, true]:
		await fresh(p, hud, late, 10)
		hud.hp = 70
		var event_count := {"value": 0}
		var callback := func(_tier, _floor): event_count.value += 1
		hud.stagger_triggered.connect(callback)
		start = p.position
		hit(p, 20, 40)
		check(hud.stamina == 0 and hud.stamina_bar.value == 0 and hud.hp == (60 if late else 70), "partial %s drains remainder and preserves damage rule" % ("Guard" if late else "Deflect"))
		check(p.damage.is_knocking_back and p.damage.is_invulnerable and pose.frame == 0 and p.velocity.y == 0.0 and not p.is_guarding, "exhaustion starts horizontal stagger frame 0 with iframe and ends protection")
		check(p.damage.active_knockback_distance == p.damage.knockback_distance and p.damage.active_knockback_duration == p.damage.knockback_duration and p.damage._active_stun_duration == p.damage.stun_duration and p.damage._active_invulnerability_duration == DamageComponent.STAGGER_INVULN_SEC, "exhaustion shares every threshold stagger setting")
		check(not p.deflect_slow_motion.is_active and Engine.time_scale == 1.0, "insufficient Deflect never masks stagger with slow motion")
		check(hud.stagger_tiers_ready == [true, true] and hud.stagger_lock_timer == 0 and event_count.value == 0 and not hud.has_any_debuff(), "exhaustion never consumes HP marker or applies random debuff")
		await click(&"attack")
		check(not p.saber_hitbox._attack_active and p.state_machine.current == AdelStateMachine.State.KNOCKBACK, "exhaustion knockback rejects attack input")
		await wait(p.stagger_knockback_duration + 0.03)
		var tolerance: float = p.damage.knockback_distance / p.damage.knockback_duration / 60.0 + 1.0
		check(absf(p.position.x - start.x + p.damage.knockback_distance) <= tolerance and absf(p.position.y - start.y) < 0.1, "exhaustion uses shared stagger travel without upward displacement")
		check(p.damage.is_stunned and not p.damage.is_knocking_back and pose.frame == 1 and p.spine_anim.assigned_animation == &"saber_stagger", "exhaustion switches to stagger frame 1 and keeps full stun")
		await click(&"attack")
		check(not p.saber_hitbox._attack_active and p.state_machine.current == AdelStateMachine.State.STUN, "exhaustion stun rejects attack input")
		var hp_before: int = hud.hp
		hit(p)
		check(hud.hp == hp_before, "shared stagger iframe rejects damage during stun")
		await wait(p.stagger_stun_duration + 0.02)
		check(not p.damage.is_stunned and p.can_move and pose.frame == 2 and p.spine_anim.assigned_animation == &"saber_ready", "shared stun completes into interruptible frame-2 ready")
		check(p.damage.is_invulnerable, "same stagger iframe continues after control recovers")
		await wait(0.3)
		check(not p.damage.is_invulnerable, "shared 1-second iframe ends")
		await click(&"attack")
		check(p.state_machine.current == AdelStateMachine.State.COMBO and p.saber_hitbox._attack_active, "attack works again after exhaustion without stuck state")
		p.enter_rest(false)
		p.exit_rest()
		hud.stagger_triggered.disconnect(callback)
	# Zero disables both fresh input and an already-held stance, including pre-physics hits.
	await fresh(p, hud, false, 0)
	check(not p.is_guarding and p.can_move, "zero stamina rejects actual Defense input")
	p._try_begin_guard()
	check(not p.is_guarding and not p.state_machine.is_in(AdelStateMachine.State.DEFENSE), "zero also rejects direct Defense request")
	hit(p)
	check(hud.hp == 80 and not p.deflect_slow_motion.is_active and hud.stamina == 0, "zero stance cannot Guard or Deflect incoming damage")
	await fresh(p, hud, false)
	hud.stamina = 0
	hit(p)
	check(hud.hp == 80 and not p.is_guarding and not p.deflect_slow_motion.is_active, "depleted held Defense rejects hit before the next physics update")
	await frames(2)
	check(p.can_move and not p.blocks_stamina_regeneration(), "depleted hold releases action ownership")
	await fresh(p, hud, true)
	hud.stamina = 0
	await frames(2)
	check(not p.is_guarding and p.can_move, "physics polling also ends held Defense at zero without a hit")
	await fresh(p, hud, true)
	hud.hp = 70
	hit(p, 20, 40)
	check(hud.hp == 66 and not hud.stagger_tiers_ready[0] and p.damage.is_stunned and p.velocity.y == 0.0, "funded Guard still honors real threshold mechanic without upward kick")
	await wait(1.1)
	await button(&"guard and deflect", false)
	for available in [100.0, 10.0]:
		hud.restore_stamina_full()
		hud.stamina = available
		hud.hp = 100
		hud.clear_all_debuffs()
		hud.restore_stagger_thresholds()
		p.damage.is_invulnerable = false
		p.dash.able_to_dodge = true
		p.position = Vector2(300, p.position.y)
		await frames(2)
		await button(&"move_right", true)
		await click(&"dodge")
		check(p.dash.is_dodging and hud.stamina == maxf(available - 20, 0) and not p.damage.is_stunned, "dash with %d stamina charges remaining budget and has no exhaustion punishment" % int(available))
		await button(&"move_right", false)
		await wait(0.65)
		check(not p.dash.is_dodging and p.can_move, "partial dash completes normally")
	hud.stamina = 0
	p.dash.able_to_dodge = true
	p.dodge_cooldown.stop()
	var delay_before: float = hud._stats._stamina_regen_time_left
	var position_before: Vector2 = p.position
	await button(&"move_right", true)
	await click(&"dodge")
	await button(&"move_right", false)
	check(not p.dash.is_dodging and p.dash.able_to_dodge and p.dodge_cooldown.is_stopped() and not p.damage.is_invulnerable, "zero blocks actual dash without cooldown or iframe")
	check(hud.stamina == 0 and hud._stats._stamina_regen_time_left == delay_before and absf(p.position.x - position_before.x) < 50.0, "rejected zero dash never spends or resets recovery delay")
	p._perform_dash(1)
	check(not p.dash.is_dodging and p.dash.able_to_dodge, "zero also blocks direct dash request")
	hud.set_process(true)
	await button(&"guard and deflect", true)
	await wait(1.7)
	check(hud.stamina > 0 and not p.is_guarding and p.can_move, "held rejected Defense allows stamina recovery without automatic restart")
	await button(&"guard and deflect", false)
	await button(&"guard and deflect", true)
	check(p.is_guarding, "fresh Defense input works after stamina recovers")
	await button(&"guard and deflect", false)
	hud.set_process(false)
	# Real HUD process timing uses action state instead of the 3s visibility delay.
	hud.stamina = 100
	hud.spend_stamina("dash", true)
	hud.in_combat = true
	hud.hide_delay = 20
	hud.set_process(true)
	await wait(maxf(0.05, p.stamina_regen_delay - 0.15))
	check(hud.stamina == 80 and hud.stamina_bar.value == 80, "actual HUD waits the configured delay after expenditure")
	await wait(0.3)
	check(hud.stamina > 80 and hud.stamina < 87 and hud.in_combat, "actual green bar regens at configured rate while HUD combat flag remains true")
	await wait(0.8)
	check(hud.stamina == 100 and hud.stamina_bar.value == 100, "actual HUD refill reaches maximum")
	await button(&"guard and deflect", true)
	hud.spend_stamina("guard", true)
	await wait(1.7)
	check(hud.stamina == 80 and p.spine_anim.assigned_animation == &"saber_defense", "holding neutral defense indefinitely prevents regen")
	await button(&"guard and deflect", false)
	await wait(maxf(0.05, p.stamina_regen_delay - 0.15))
	check(hud.stamina == 80, "releasing defense starts fresh configured wait")
	await wait(0.3)
	check(hud.stamina > 80, "regen resumes after defense idle delay")
	hud.restore_stamina_full()
	hud.spend_stamina("dash", true)
	for i in 20:
		await click(&"attack")
		await frames(5)
	check(hud.stamina == 80 and p.blocks_stamina_regeneration(), "continuous attacks block regen without adding attack costs")
	for i in 120:
		if not p.blocks_stamina_regeneration(): break
		await frames(1)
	await wait(maxf(0.05, p.stamina_regen_delay - 0.15))
	check(hud.stamina == 80, "attack completion starts fresh recovery delay")
	await wait(0.3)
	check(hud.stamina > 80, "idle after attacking regains stamina")
	hud.set_process(false)
	await fresh(p, hud, true)
	hit(p)
	var capture_path := OS.get_environment("CODEX_STAMINA_SCREENSHOT")
	if DisplayServer.get_name() != "headless" and not capture_path.is_empty():
		await fresh(p, hud, true, 10)
		hit(p)
		await wait(0.35)
		hud.hud_art.modulate = Color.WHITE
		hud.modulate = Color.WHITE
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_path)
	await fresh(p, hud, true, 10)
	var saves = get_node("/root/SaveManager")
	saves._data["scene_path"] = scene.scene_file_path
	saves._data["spawn_position"] = {"x": p.position.x, "y": p.position.y}
	saves._write_slot_to_disk(saves.active_slot)
	hud.hp = 5
	hit(p)
	check(p.is_inside_tree() and hud.hp == hud.max_hp, "exhausted lethal Guard completes same-scene respawn")
	check(not p.damage.is_stunned and not p.damage.is_invulnerable and not p.defense.guard_push_active and not p.is_doing_action and p.can_move, "lethal Guard cancels recoil and cannot start exhaustion on respawned player")
	print("GUARD STAMINA RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
