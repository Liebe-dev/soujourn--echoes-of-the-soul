extends Node2D
const Enemy = preload("res://scenes/enemy/spine_enemy.tscn")
const AI = preload("res://scenes/enemy/enemy_utility_ai.gd")
const Profile = preload("res://scenes/enemy/enemy_utility_profile.gd")
var checks := 0
var failures := 0

func _ready() -> void:
	_run.call_deferred()

func frames(count: int = 2) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("FLEE COUNTER ", "PASS " if ok else "FAIL ", label)

func body(at: Vector2, size: Vector2, layer: int) -> StaticBody2D:
	var result := StaticBody2D.new()
	result.position = at
	result.collision_layer = layer
	result.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	result.add_child(collider)
	add_child(result)
	return result

func distance(enemy, player, value: float) -> void:
	player.global_position = enemy.global_position + Vector2(value, 0)
	enemy.last_seen_position = player.global_position

func prepare(enemy, player, mode: int, gap: float = 200.0) -> void:
	enemy._reset_flee_response()
	enemy.decision_mode = mode
	enemy._previous_decision_mode = mode
	enemy.current_health = 20
	enemy.target = player
	enemy.target_visible = true
	enemy._lost_time = 0.0
	enemy._utility_detected_target_id = player.get_instance_id()
	enemy._stun_remaining = 0.0
	enemy.opener_available = false
	enemy.velocity = Vector2.ZERO
	enemy.utility_action = &"flee"
	distance(enemy, player, gap)
	enemy._enter_state(enemy.State.FLEE)

func _run() -> void:
	if not OS.get_user_data_dir().contains("CodexEnemyDeath"):
		get_tree().quit(2)
		return
	body(Vector2(0, 100), Vector2(4000, 40), 1)
	var enemy = Enemy.instantiate()
	enemy.speed = 0.0
	add_child(enemy)
	await frames(15)
	enemy.set_physics_process(false)
	var player := body(Vector2(200, 0), Vector2(20, 40), 3)
	player.add_to_group("Player")
	var replacement := body(Vector2(-400, 0), Vector2(20, 40), 3)
	await frames()
	for mode in [enemy.DecisionMode.FSM, enemy.DecisionMode.UTILITY]:
		var label := "FSM" if mode == enemy.DecisionMode.FSM else "Utility"
		prepare(enemy, player, mode)
		enemy._tick_flee_response(2.9)
		check(not enemy.counterattack_active and not enemy.flee_exhausted, label + ": no premature turnaround")
		enemy._tick_flee_response(0.11)
		check(enemy.counterattack_active and enemy.flee_exhausted and enemy.opener_available, label + ": sustained threat arms a fresh leap")
		check(enemy._evaluate_transition() == enemy.State.WINDUP, label + ": low HP cannot override counterattack with flee")
		enemy._direction = -1
		enemy._enter_state(enemy.State.WINDUP)
		check(enemy._direction == 1 and enemy.animation_player.assigned_animation == &"attack1_1", label + ": turns to face pursuer during telegraph")
		enemy._elapsed = enemy.windup_time + 0.01
		check(enemy._evaluate_transition() == enemy.State.LEAP, label + ": full windup precedes leap")
		enemy._launch()
		check(enemy.state == enemy.State.LEAP and not enemy.opener_available, label + ": one fresh leap consumes opener")
		distance(enemy, player, 80.0)
		enemy._enter_state(enemy.State.LAND)
		enemy._elapsed = enemy.landing_time + 0.01
		check(enemy._evaluate_transition() == enemy.State.RECOVERY, label + ": landing still requires recovery")
		enemy._enter_state(enemy.State.RECOVERY)
		enemy._elapsed = enemy.recovery_time + 0.01
		var next: int = enemy._evaluate_transition()
		if next == enemy.State.RUN:
			enemy._enter_state(enemy.State.RUN)
			next = enemy._evaluate_transition()
		check(next == enemy.State.MELEE, label + ": follows leap with melee instead of fleeing again")
		enemy._begin_melee()
		check(enemy._evaluate_transition() == enemy.State.MELEE, label + ": low health does not cancel follow-up attack")
		prepare(enemy, player, mode, 400.0)
		enemy._tick_flee_response(3.1)
		check(enemy.flee_exhausted and not enemy.counterattack_active and enemy._evaluate_transition() != enemy.State.FLEE, label + ": weak pressure still cannot cause endless retreat")
		enemy._enter_state(enemy.State.IDLE)
		enemy._tick_flee_response(1.0)
		check(enemy.flee_pressure_time == 0.0 and not enemy.counterattack_active, label + ": distant player does not force counterattack")
		distance(enemy, player, 200.0)
		enemy._tick_flee_response(1.5)
		check(not enemy.counterattack_active, label + ": pressure can build while waiting after cap")
		enemy._tick_flee_response(1.6)
		check(enemy.counterattack_active, label + ": pursuit after cap eventually forces combat")
		prepare(enemy, player, mode)
		enemy._tick_flee_response(2.0)
		distance(enemy, player, 300.0)
		enemy._tick_flee_response(0.1)
		check(is_equal_approx(enemy.get_flee_threat(), 0.5) and enemy.flee_pressure_time == 0.0, label + ": threat exactly 0.5 breaks consecutive pressure")
		distance(enemy, player, 200.0)
		enemy._tick_flee_response(1.5)
		check(not enemy.counterattack_active, label + ": separate pressure bursts do not add together")
		enemy._tick_flee_response(1.6)
		check(enemy.counterattack_active, label + ": new uninterrupted interval can arm counterattack")
		prepare(enemy, player, mode, 400.0)
		enemy._tick_flee_response(1.6)
		enemy._enter_state(enemy.State.IDLE)
		enemy._tick_flee_response(0.5)
		enemy._enter_state(enemy.State.FLEE)
		enemy._tick_flee_response(1.5)
		check(enemy.flee_exhausted and is_equal_approx(enemy.flee_time, 3.1), label + ": state switches do not refill retreat budget")
		prepare(enemy, player, mode)
		enemy._tick_flee_response(2.0)
		enemy.apply_ai_stun(0.1)
		enemy._tick_flee_response(0.05)
		check(enemy.flee_pressure_time == 0.0 and is_equal_approx(enemy.flee_time, 2.0), label + ": stun breaks pressure but preserves retreat budget")
		enemy._update_state(0.2)
		enemy._enter_state(enemy.State.FLEE)
		enemy._tick_flee_response(1.1)
		check(enemy.flee_exhausted and not enemy.counterattack_active, label + ": stun cannot grant another full retreat")
		prepare(enemy, player, mode)
		enemy._tick_flee_response(2.8)
		var obstruction := body((enemy.global_position + player.global_position) * 0.5, Vector2(20, 400), 1)
		await frames()
		enemy._refresh_target(0.1)
		enemy._tick_flee_response(0.3)
		check(enemy.target == player and not enemy.target_visible and enemy.flee_pressure_time == 0.0 and not enemy.counterattack_active, label + ": wall resets pressure while target memory persists")
		obstruction.queue_free()
		await frames()
		enemy._refresh_target(0.016)
		enemy._enter_state(enemy.State.IDLE)
		enemy._tick_flee_response(0.5)
		check(not enemy.counterattack_active and is_equal_approx(enemy.flee_pressure_time, 0.5), label + ": sight reacquisition starts fresh pressure interval")
		enemy.current_health = 100
		enemy._tick_flee_response(0.1)
		check(enemy.flee_time == 0.0 and not enemy.flee_exhausted and not enemy.counterattack_active, label + ": healing resets retreat policy")
		prepare(enemy, player, mode)
		enemy._tick_flee_response(2.8)
		enemy.target = replacement
		enemy.last_seen_position = replacement.global_position
		enemy._tick_flee_response(0.1)
		check(enemy.flee_time < 0.2 and not enemy.counterattack_active, label + ": pressure from different targets cannot combine")
		enemy.target = null
		enemy._tick_flee_response(0.1)
		check(enemy.flee_time == 0.0 and enemy.flee_pressure_time == 0.0, label + ": losing target clears retreat history")
		for hz in [30, 60, 120]:
			prepare(enemy, player, mode)
			for i in int(3.1 * hz): enemy._tick_flee_response(1.0 / hz)
			check(enemy.counterattack_active, "%s: frame-rate independent timing at %d Hz" % [label, hz])
		var saved_pressure: float = enemy.flee_pressure_time
		enemy._tick_flee_response(0.0)
		check(enemy.flee_pressure_time == saved_pressure, label + ": zero game delta does not advance timers")
		prepare(enemy, player, mode)
		enemy.flee_max_duration = 1.0
		enemy.counterattack_pressure_duration = 0.5
		enemy._tick_flee_response(0.6)
		check(enemy.counterattack_active, label + ": configurable shorter pressure duration changes turnaround time")
		enemy.flee_max_duration = 3.0
		enemy.counterattack_pressure_duration = 3.0
	prepare(enemy, player, enemy.DecisionMode.UTILITY)
	enemy._tick_flee_response(1.0)
	enemy.current_health = 40
	enemy._tick_flee_response(0.1)
	check(enemy.flee_time > 1.0, "Utility partial healing does not refill budget while flee-need curve remains positive")
	var ai := AI.new()
	var profile := Profile.new()
	var context := {&"has_target": true, &"visible": true, &"grounded": true, &"reachable": true,
		&"health": 0.1, &"player_health": 1.0, &"allies": 0, &"distance": 80.0,
		&"memory": 1.0, &"opener": false, &"leap_range": 280.0, &"melee_range": 110.0,
		&"safe_distance": 600.0, &"flee_enabled": true, &"resting": false, &"phase_progress": 0.0,
		&"flee_exhausted": true, &"counterattack": true}
	ai.evaluate(context, profile)
	var rng := RandomNumberGenerator.new()
	rng.seed = 72
	var always_attacks := true
	for i in 100: always_attacks = always_attacks and ai.choose(&"flee", rng, true, 0.0, 0.5) == &"melee"
	check(always_attacks and ai.scores.flee == 0.0, "weighted RNG/hysteresis cannot evade forced combat")
	context.visible = false
	ai.evaluate(context, profile)
	check(ai.scores.melee == 0.0 and ai.scores.leap == 0.0 and ai.choose(&"melee", rng) == &"chase", "counterattack cannot attack through occlusion")
	prepare(enemy, player, enemy.DecisionMode.UTILITY)
	enemy._tick_flee_response(3.1)
	enemy.apply_ai_stun(0.1)
	check(enemy._evaluate_transition() == enemy.State.STUNNED and not enemy._window_open, "stun overrides armed counterattack")
	enemy._update_state(0.2)
	check(enemy._evaluate_transition() != enemy.State.FLEE and enemy.counterattack_active, "stun expiry retains combat commitment")
	enemy.die()
	check(not enemy.counterattack_active and not enemy.flee_exhausted and enemy.flee_time == 0.0 and enemy.state == enemy.State.DEAD, "death clears retreat/counterattack and stays terminal")
	print("FLEE COUNTER RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
