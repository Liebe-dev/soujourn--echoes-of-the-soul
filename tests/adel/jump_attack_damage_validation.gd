extends Node

class DamageProbe extends CharacterBody2D:
	var calls := 0
	var total := 0
	func take_damage(amount: int, _origin: Vector2 = Vector2.INF) -> void:
		calls += 1
		total += amount

var checks := 0
var failures := 0
var ground_y: float
var enemy_ground_y: float

func _ready() -> void:
	_run.call_deferred()

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("JUMP DAMAGE ", "PASS " if ok else "FAIL ", label)

func button(action: StringName, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)
	await frames(1)

func click(action: StringName) -> void:
	await button(action, true)
	await button(action, false)

func make_probe(scene: Node) -> DamageProbe:
	var target := DamageProbe.new()
	target.collision_layer = 4
	target.collision_mask = 0
	target.position = Vector2(-2000, -2000)
	var node := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 8
	shape.height = 16
	node.shape = shape
	target.add_child(node)
	scene.add_child(target)
	return target

func reset_player(p, hud, enemy) -> void:
	for action in [&"attack", &"move_down", &"move_left", &"move_right", &"guard and deflect", &"jump", &"dodge"]:
		Input.action_release(action)
	if p.damage.is_stunned or p.damage.is_invulnerable:
		await get_tree().create_timer(1.1).timeout
	p.enter_rest(false)
	p.exit_rest()
	p.combat.combo_step = 0
	p.position = Vector2(300, ground_y)
	p.velocity = Vector2.ZERO
	p._set_facing_direction(1)
	p.weapon.damage = 20
	p.weapon.combo_finisher_multiplier = 1.2
	p.jump_attack_damage = 20
	p.jump_attack_landing_active_time = 0.15
	p.set_physics_process(true)
	enemy.position = Vector2(1100, enemy_ground_y)
	enemy.current_health = 1000
	hud.hp = 100
	hud.clear_all_debuffs()
	hud.restore_stagger_thresholds()
	hud.restore_stamina_full()
	p.damage.is_invulnerable = false
	await frames(3)

func start_jump(p) -> void:
	await click(&"jump")
	await frames(6)
	await button(&"move_down", true)
	await click(&"attack")
	await button(&"move_down", false)

func _run() -> void:
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	var p = scene.get_node("PlayableAdel")
	var enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	await frames(70)
	var hud = p.get_node("Camera2D/hud")
	hud.set_process(false)
	p.vitals.simulation_enabled = false
	ground_y = p.position.y
	enemy_ground_y = enemy.position.y
	if not "jump_hitbox" in p or not p.has_node("WeaponPivot/JumpAttackHitbox"):
		check(false, "Player must have an independent jump damage area")
		get_tree().quit(1)
		return
	check(p.weapon.damage == 20 and p.jump_attack_damage == 20 and is_equal_approx(p.weapon.combo_finisher_multiplier, 1.2), "default base/jump damage 20 and finisher 1.2")
	check(hud.max_hp == PlayerProgress.get_max_hp() and enemy.max_health == 100, "Player progression HP and enemy HP contract retained")
	check(enemy.leap_damage == 20 and enemy.attack2_damage == 12 and enemy.attack3_damage == 18, "enemy skill damage exports unchanged")
	check(p.jump_hitbox.collision_mask == 4 and not p.jump_hitbox._window_open and p.jump_hitbox.collision_shape.disabled, "jump damage area detects enemy layer and starts closed")
	# Real Saber areas and the actual attack starter for each combo step.
	for direction in [-1, 1]:
		for step in range(1, 5):
			await reset_player(p, hud, enemy)
			p._set_facing_direction(direction)
			enemy.position.x = p.position.x + direction * 90
			p.combat.combo_step = step
			p._play_combo_step()
			await frames(30)
			var expected := 24 if step == 4 else 20
			check(1000 - enemy.current_health == expected, "real combo step %d facing %d deals %d once" % [step, direction, expected])
			check(not p.jump_hitbox._window_open, "normal combo never opens jump damage")
	await reset_player(p, hud, enemy)
	p.weapon.damage = 30
	p.weapon.combo_finisher_multiplier = 1.5
	enemy.position.x = p.position.x + 90
	p.combat.combo_step = 4
	p._play_combo_step()
	p.weapon.damage = 99
	await frames(30)
	check(enemy.current_health == 955, "configured 30 x 1.5 snapshots 45 for the whole swing")
	await reset_player(p, hud, enemy)
	enemy.position.x = p.position.x + 90
	p.saber_hitbox.stop_attack_window()
	p.combat.combo_step = 1
	p._play_combo_step()
	await frames(30)
	check(enemy.current_health == 980, "deferred stop from an old swing cannot kill its replacement")
	await reset_player(p, hud, enemy)
	p.weapon.damage = 0
	enemy.position.x = p.position.x + 90
	p.combat.combo_step = 1
	p._play_combo_step()
	await frames(30)
	check(enemy.current_health == 1000, "configured zero normal damage never becomes minimum one")
	# Actual input, airborne transition, floor contact and the real enemy receiver.
	for direction in [-1, 1]:
		await reset_player(p, hud, enemy)
		p._set_facing_direction(direction)
		enemy.position.x = p.position.x + direction * 65
		await start_jump(p)
		check(p.state_machine.current == AdelStateMachine.State.JUMP_HANG and enemy.current_health == 1000 and not p.jump_hitbox._window_open, "real jump hang has no damage, facing %d" % direction)
		var saw_fall := false
		var saw_land := false
		for i in 65:
			await frames(1)
			saw_fall = saw_fall or p.state_machine.current == AdelStateMachine.State.JUMP_FALL
			saw_land = saw_land or p.state_machine.current == AdelStateMachine.State.JUMP_LAND
		check(saw_fall and saw_land and enemy.current_health == 980, "real fall and landing together deal exactly 20 once, facing %d" % direction)
		check(not p.jump_hitbox._attack_active and not p.jump_hitbox._window_open and p.can_move, "jump completion closes damage and returns control")
	var a := make_probe(scene)
	var b := make_probe(scene)
	await reset_player(p, hud, enemy)
	await start_jump(p)
	a.position = p.position + Vector2(65, 20)
	b.position = a.position + Vector2(10, 0)
	var hangs_harmless := true
	for i in 70:
		if p.state_machine.current == AdelStateMachine.State.JUMP_HANG:
			hangs_harmless = hangs_harmless and a.calls == 0 and b.calls == 0
		if p.state_machine.current == AdelStateMachine.State.JUMP_LAND:
			# Reenter the same area on landing: it remains the same swing.
			a.position = p.jump_hitbox.global_position
			b.position = a.position + Vector2(10, 0)
		await frames(1)
	check(hangs_harmless and a.calls == 1 and b.calls == 1 and a.total == 20 and b.total == 20, "multiple enemies each take one hit across air and landing reentry")
	a.position = Vector2(-2000, -2000)
	b.position = Vector2(-2000, -2000)
	# A target first encountered during the impact window is hit.
	await reset_player(p, hud, enemy)
	a.calls = 0
	a.total = 0
	await start_jump(p)
	for i in 40:
		if p.state_machine.current == AdelStateMachine.State.JUMP_LAND: break
		await frames(1)
	a.position = p.jump_hitbox.global_position
	await frames(3)
	check(a.calls == 1 and a.total == 20, "landing window can hit a newly arriving enemy")
	await frames(14)
	b.calls = 0
	b.position = p.jump_hitbox.global_position
	await frames(3)
	check(b.calls == 0 and not p.jump_hitbox._window_open, "late landing recovery cannot damage a new target")
	a.position = Vector2(-2000, -2000)
	b.position = Vector2(-2000, -2000)
	# Final flight-frame contact must survive a zero-length landing window.
	await reset_player(p, hud, enemy)
	p.set_physics_process(false)
	p.position.y = ground_y - 300
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	a.calls = 0
	a.total = 0
	a.position = Vector2(365, ground_y + 20)
	await frames(3)
	p.jump_attack_landing_active_time = 0
	p._play_jump_attack()
	p.combat.is_jump_attack_hanging = false
	p.state_machine.transition(AdelStateMachine.State.JUMP_FALL)
	p.position.y = ground_y - 1
	p._physics_attack(1.0 / 60.0)
	check(p.is_on_floor() and p.state_machine.current == AdelStateMachine.State.JUMP_LAND and a.calls == 1, "last physical flight contact damages before a zero landing window closes")
	check(not p.jump_hitbox._window_open, "zero landing active time is respected")
	a.position = Vector2(-2000, -2000)
	await reset_player(p, hud, enemy)
	p.jump_attack_damage = 35
	enemy.position.x = p.position.x + 65
	await start_jump(p)
	await frames(60)
	check(enemy.current_health == 965, "jump damage export changes actual receiver damage to 35")
	await reset_player(p, hud, enemy)
	p.jump_attack_damage = 0
	enemy.position.x = p.position.x + 65
	await start_jump(p)
	await frames(60)
	check(enemy.current_health == 1000 and not p.jump_hitbox._window_open, "zero jump damage keeps area harmless")
	# Stagger cancels pending damage and leaves no attack lock after recovery.
	await reset_player(p, hud, enemy)
	await start_jump(p)
	p.damage.apply_stagger(Vector2(-1, 0))
	check(not p.jump_hitbox._attack_active and not p.jump_hitbox._window_open and not p.saber_hitbox._attack_active, "stagger interruption immediately cancels both damage paths")
	await frames(70)
	check(p.can_move and not p.damage.is_stunned, "jump interruption recovers without a stuck action")
	await reset_player(p, hud, enemy)
	p._play_jump_attack()
	p.enter_rest(false)
	check(not p.jump_hitbox._attack_active and not p.is_doing_action, "rest preemption cancels jump damage")
	p.exit_rest()
	# Jump-to-combo sibling transition must close leap registry/window immediately.
	p._play_jump_attack()
	p._play_jump_attack_land()
	p.combat.combo_step = 1
	p._play_combo_step()
	check(not p.jump_hitbox._attack_active and p.saber_hitbox._attack_active, "switching landing to combo only leaves the new Saber swing active")
	await reset_player(p, hud, enemy)
	# Target removed inside a live query is safe and not revisited later.
	a.position = p.position + Vector2(65, 20)
	p.jump_hitbox.begin_attack(20)
	p.jump_hitbox.set_damage_window(true)
	a.queue_free()
	await frames(2)
	p.jump_hitbox.sample_damage(true)
	check(not is_instance_valid(a), "freed target during jump sampling is safely ignored")
	p.jump_hitbox.end_attack()
	b.queue_free()
	# A lethal jump reaches the inherited enemy death/EXP API once.
	await reset_player(p, hud, enemy)
	var wob = load("res://scenes/enemy/wobtear_enemy.tscn").instantiate()
	wob.speed = 0
	wob.patrol_range = 0
	scene.add_child(wob)
	wob.position = Vector2(p.position.x + 65, ground_y)
	await frames(4)
	PlayerProgress.level = 1
	PlayerProgress.exp = 0
	await start_jump(p)
	await frames(60)
	check(not is_instance_valid(wob) and PlayerProgress.exp == 30, "lethal real jump frees Wobtear and grants EXP once")
	var capture_path := OS.get_environment("CODEX_JUMP_SCREENSHOT")
	if DisplayServer.get_name() != "headless" and not capture_path.is_empty():
		await reset_player(p, hud, enemy)
		enemy.position.x = p.position.x + 65
		await start_jump(p)
		for i in 30:
			if p.state_machine.current == AdelStateMachine.State.JUMP_FALL: break
			await frames(1)
		var outline := Line2D.new()
		var half: Vector2 = p.jump_hitbox.collision_shape.shape.size / 2.0
		outline.points = PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y), -half])
		outline.default_color = Color(1.0, 0.75, 0.1)
		outline.width = 2
		p.jump_hitbox.collision_shape.add_child(outline)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_path)
	print("JUMP DAMAGE RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
