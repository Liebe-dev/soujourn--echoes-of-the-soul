extends Node
class DamageProbe extends CharacterBody2D:
	var calls := 0
	var total := 0
	func take_damage(amount: int, _origin: Vector2 = Vector2.INF) -> void:
		calls += 1
		total += amount
var checks := 0
var failures := 0
func _ready() -> void:
	_run.call_deferred()
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("LEAP HITBOX ", "PASS " if ok else "FAIL ", label)
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout
func button(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames(1)
func probe(scene: Node) -> DamageProbe:
	var p := DamageProbe.new()
	p.collision_layer = 2
	p.collision_mask = 0
	p.add_to_group("Player")
	var collider := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 8
	shape.height = 16
	collider.shape = shape
	p.add_child(collider)
	scene.add_child(p)
	return p
func prepare(enemy, target, leap: bool, amount: int = 20) -> void:
	enemy.target = target
	enemy._hit_targets.clear()
	enemy._swing_damage = amount
	enemy.attack_animation = &"attack2"
	enemy._enter_state(enemy.State.LEAP if leap else enemy.State.MELEE)
	if not leap: enemy._set_damage_window(true)
func fresh_guard(p, hud, late: bool) -> void:
	if p.deflect_slow_motion.is_active: await wait(p.deflect_slow_motion_duration + 0.04)
	await button(&"guard and deflect", false)
	hud.restore_stamina_full()
	hud.hp = 100
	hud.clear_all_debuffs()
	hud.restore_stagger_thresholds()
	p.damage.is_invulnerable = false
	await button(&"guard and deflect", true)
	await wait(0.34 if late else 0.12)
func _run() -> void:
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	var p = scene.get_node("PlayableAdel")
	p.hit_stop_enabled = false
	var enemy = scene.get_node("Enemy")
	enemy.speed = 0.0
	enemy.patrol_range = 0.0
	enemy.detection_distance = 1.0
	await frames(70)
	enemy.set_physics_process(false)
	p.set_physics_process(false)
	var hud = p.get_node("Camera2D/hud")
	hud.set_process(false)
	var original_player_position: Vector2 = p.position
	p.position.x = -1000
	enemy.position = Vector2(700, 300)
	var a := probe(scene)
	var b := probe(scene)
	b.position = Vector2(-2000, -2000)
	var body_shape = enemy.get_node("CollisionShape2D")
	check(enemy.leap_hitbox_shape.shape != body_shape.shape, "leap uses an independent shape resource")
	check(enemy.leap_hitbox_shape.position == body_shape.position, "leap center matches body collider")
	check(enemy.leap_hitbox_shape.shape.radius == body_shape.shape.radius and enemy.leap_hitbox_shape.shape.height == body_shape.shape.height, "initial leap size matches body")
	check(enemy.hitbox_shape.position == Vector2(-114.5, -55) and enemy.hitbox_shape.shape.size == Vector2(231, 170), "user's melee VFX box preserved")
	check(enemy.leap_hitbox.collision_mask == 2 and not enemy.leap_hitbox.monitorable, "leap area only detects player layer")
	for direction in [-1, 1]:
		enemy._direction = direction
		enemy._update_facing()
		for rear in [false, true]:
			a.calls = 0
			a.total = 0
			a.position = enemy.position + Vector2(direction * (-35 if rear else 35), -25)
			prepare(enemy, a, true)
			await frames(3)
			check(not enemy.leap_hitbox_shape.disabled and enemy.hitbox_shape.disabled, "leap enables only body area, direction %d rear=%s" % [direction, rear])
			check(enemy.leap_hitbox.get_overlapping_bodies().has(a), "real body area overlaps target, direction %d rear=%s" % [direction, rear])
			enemy._apply_swing_damage()
			enemy._apply_leap_contact_damage()
			check(a.calls == 1 and a.total == enemy.leap_damage, "body leap hits front/rear once, direction %d rear=%s" % [direction, rear])
			for i in 6: enemy._apply_swing_damage()
			check(a.calls == 1, "overlap and boundary query cannot double hit")
			enemy._set_damage_window(false)
			await frames(2)
		# A location exclusive to the extended VFX must not hurt during leap.
		a.position = enemy.position + Vector2(direction * 200, -55)
		a.calls = 0
		prepare(enemy, a, true)
		await frames(3)
		enemy._apply_swing_damage()
		enemy._apply_leap_contact_damage()
		check(a.calls == 0, "leap does not use forward VFX extent, direction %d" % direction)
		for clip in [&"attack2", &"attack3"]:
			prepare(enemy, a, false, enemy.attack2_damage if clip == &"attack2" else enemy.attack3_damage)
			enemy.attack_animation = clip
			await frames(3)
			check(not enemy.hitbox_shape.disabled and enemy.leap_hitbox_shape.disabled, "%s enables only VFX area" % clip)
			enemy._apply_swing_damage()
			check(a.calls == 1, "%s retains forward reach, direction %d" % [clip, direction])
			enemy._set_damage_window(false)
			a.calls = 0
			await frames(2)
			a.position = enemy.position + Vector2(-direction * 35, -25)
			prepare(enemy, a, false)
			await frames(3)
			enemy._apply_swing_damage()
			check(a.calls == 0, "%s never uses leap body to hit rear" % clip)
			enemy._set_damage_window(false)
			await frames(2)
			a.position = enemy.position + Vector2(direction * 200, -55)
	for phase in [enemy.State.WALK, enemy.State.DETECT, enemy.State.RUN, enemy.State.WINDUP, enemy.State.LAND, enemy.State.RECOVERY]:
		a.position = enemy.position + Vector2(0, -25)
		a.calls = 0
		enemy._enter_state(phase)
		await frames(2)
		enemy._apply_swing_damage()
		enemy._apply_leap_contact_damage()
		check(not enemy._window_open and enemy.leap_hitbox_shape.disabled and enemy.hitbox_shape.disabled and a.calls == 0, "non-attack phase %d cannot cause contact damage" % phase)
	# Physical shape queries cover activation before Area2D has an overlap list.
	a.calls = 0
	a.position = enemy.position + Vector2(0, -25)
	await frames(2)
	prepare(enemy, a, true)
	enemy._apply_leap_contact_damage()
	check(a.calls == 1, "target already inside at activation is caught immediately")
	enemy._enter_state(enemy.State.LAND)
	await frames(2)
	# Last movement touches a target not in the previous Area overlap list.
	a.calls = 0
	a.position = enemy.position + Vector2(300, -25)
	await frames(3)
	prepare(enemy, a, true)
	await frames(4)
	check(not enemy.leap_hitbox.get_overlapping_bodies().has(a), "landing fixture starts outside cached overlap")
	enemy.position.x += 300
	enemy._apply_leap_contact_damage()
	enemy._enter_state(enemy.State.LAND)
	check(a.calls == 1, "final contact resolves before landing disables window")
	await frames(2)
	enemy._apply_swing_damage()
	check(a.calls == 1 and enemy.leap_hitbox_shape.disabled, "landing does not add another contact")
	# Exercise the actual move_and_slide -> contact -> LAND ordering on the floor.
	enemy.position = Vector2(700, 400)
	a.position = Vector2(695, 500)
	a.calls = 0
	prepare(enemy, a, true)
	await frames(3)
	check(not enemy.leap_hitbox.get_overlapping_bodies().has(a), "real landing starts outside previous overlap")
	enemy._leap_opening_check_pending = false
	enemy._has_left_floor = true
	enemy._leap_velocity_x = 0.0
	enemy.position = Vector2(700, 549)
	enemy.velocity = Vector2(0, 30)
	enemy._physics_process(1.0 / 60.0)
	check(enemy.state == enemy.State.LAND and enemy.is_on_floor() and a.calls == 1, "actual landing frame deals body contact before closing window")
	await frames(2)
	enemy._apply_swing_damage()
	check(a.calls == 1 and enemy.leap_hitbox_shape.disabled, "actual LAND remains harmless after last-flight contact")
	# Multiple players are independently deduplicated in one swing.
	a.calls = 0
	b.calls = 0
	a.position = enemy.position + Vector2(-25, -25)
	b.position = enemy.position + Vector2(25, -25)
	prepare(enemy, a, true)
	await frames(3)
	enemy._apply_swing_damage()
	enemy._apply_swing_damage()
	check(a.calls == 1 and b.calls == 1, "one leap can hit each player once")
	a.position = b.position + Vector2(1000, 0)
	await frames(2)
	a.position = enemy.position + Vector2(-25, -25)
	await frames(2)
	enemy._apply_swing_damage()
	check(a.calls == 1, "leaving and reentering never repeats the same leap")
	prepare(enemy, a, true)
	await frames(2)
	enemy._apply_swing_damage()
	check(a.calls == 2, "new leap resets target registry")
	prepare(enemy, a, true)
	a.queue_free()
	b.queue_free()
	await frames(2)
	enemy._leap_velocity_x = 0.0
	enemy._physics_process(1.0 / 60.0)
	await frames(2)
	check(not enemy._window_open and enemy.leap_hitbox_shape.disabled and enemy.hitbox_shape.disabled, "freed target closes both areas during leap")
	enemy._enter_state(enemy.State.RECOVERY)
	# Real Adel damage interface, both facing directions and all three attacks.
	p.position = original_player_position
	p.set_physics_process(true)
	for direction in [-1, 1]:
		for mode in ["leap", "attack2", "attack3"]:
			for late in [false, true]:
				enemy._enter_state(enemy.State.RECOVERY)
				await frames(2)
				await fresh_guard(p, hud, late)
				p._set_facing_direction(-direction)
				enemy._direction = direction
				enemy._update_facing()
				enemy.position = p.position + Vector2(-direction * (55 if mode == "leap" else 115), 25 if mode == "leap" else 55)
				var amount: int = enemy.leap_damage if mode == "leap" else (enemy.attack2_damage if mode == "attack2" else enemy.attack3_damage)
				prepare(enemy, p, mode == "leap", amount)
				if mode != "leap": enemy.attack_animation = mode
				await frames(3)
				enemy._apply_swing_damage()
				check(hud.hp == 100 - (int(round(amount * 0.5)) if late else 0) and p.is_guarding, "%s direction %d uses real %s" % [mode, direction, "Guard" if late else "Deflect"])
				check(enemy._hit_targets.size() == 1, "defense consumes exactly one contact in target registry")
				enemy._enter_state(enemy.State.RECOVERY)
				await frames(2)
	await button(&"guard and deflect", false)
	if p.deflect_slow_motion.is_active: await wait(p.deflect_slow_motion_duration + 0.04)
	hud.restore_stamina_full()
	hud.hp = 100
	hud.clear_all_debuffs()
	p.damage.is_invulnerable = false
	await button(&"guard and deflect", true)
	p._set_facing_direction(-1)
	enemy.position = p.position + Vector2(55, 25)
	prepare(enemy, p, true)
	await frames(3)
	enemy._apply_swing_damage()
	check(hud.hp == 80, "leap from behind still deals full damage against guard")
	enemy._enter_state(enemy.State.RECOVERY)
	await button(&"guard and deflect", false)
	check(p.get_collision_exceptions().has(enemy), "player and enemy bodies still pass through")
	enemy.die()
	check(not enemy._window_open and enemy._active_hitbox == null, "death immediately clears active damage area")
	await frames(2)
	check(not is_instance_valid(enemy), "dead enemy is freed safely")
	print("LEAP HITBOX RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
