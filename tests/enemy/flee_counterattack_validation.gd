extends Node2D
const Enemy = preload("res://scenes/enemy/spine_enemy.tscn")
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

func prepare(enemy, player, mode: int, x: float = 0.0) -> void:
	enemy._reset_flee_response()
	enemy.global_position.x = x
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
	player.global_position = enemy.global_position - Vector2(180, 0)
	enemy.last_seen_position = player.global_position
	enemy._enter_state(enemy.State.RUN)

func _run() -> void:
	if not OS.get_user_data_dir().contains("CodexEnemyDeath"):
		get_tree().quit(2)
		return
	# A real platform ending at x = 600; the enemy's body extends 71 units right.
	body(Vector2(0, 100), Vector2(1200, 40), 1)
	var enemy = Enemy.instantiate()
	enemy.speed = 0.0
	add_child(enemy)
	await frames(20)
	enemy.set_physics_process(false)
	var player := body(Vector2(-180, 0), Vector2(20, 40), 3)
	player.add_to_group("Player")
	await frames()
	for mode in [enemy.DecisionMode.FSM, enemy.DecisionMode.UTILITY]:
		var label := "FSM" if mode == enemy.DecisionMode.FSM else "Utility"
		prepare(enemy, player, mode)
		check(enemy._evaluate_transition() == enemy.State.FLEE, label + ": low health starts retreat")
		enemy._enter_state(enemy.State.FLEE)
		enemy._tick_flee_response(1.0)
		player.global_position.x = enemy.global_position.x + 400.0
		enemy.last_seen_position = player.global_position
		enemy.current_health = 100
		enemy._utility_think_left = 0.0
		enemy._update_state(1.0 / 60.0)
		check(enemy._evaluate_transition() == enemy.State.FLEE and enemy.velocity.x > 0.0, label + ": one continuous direction despite target movement/healing/reselection")
		enemy.target_visible = false
		enemy._tick_flee_response(2.01)
		check(enemy.flee_exhausted and enemy.counterattack_active and enemy.opener_available and enemy._evaluate_transition() == enemy.State.RUN, label + ": time cap returns to combat without pursuit or visibility pressure")
		enemy.current_health = 20
		enemy._tick_flee_response(0.1)
		enemy._enter_state(enemy.State.RUN)
		player.global_position = enemy.global_position + Vector2(80, 0)
		enemy.last_seen_position = player.global_position
		enemy.target_visible = true
		enemy.opener_available = false
		check(enemy._evaluate_transition() == enemy.State.MELEE, label + ": used retreat cannot replace follow-up combat")
		# Walk toward the actual ledge and stop before losing the platform.
		prepare(enemy, player, mode, 500.0)
		enemy._enter_state(enemy.State.FLEE)
		for i in 20:
			enemy._physics_process(1.0 / 60.0)
			if enemy.flee_exhausted: break
		check(enemy.counterattack_active and not enemy.opener_available and enemy.is_on_floor() and enemy.global_position.x < 529.0 and is_zero_approx(enemy.velocity.x), label + ": cliff ends retreat on supported ground without a hazard leap")
		# A wall also consumes the only attempt and turns the enemy toward the player.
		prepare(enemy, player, mode)
		var wall := body(Vector2(150, -20), Vector2(20, 300), 1)
		await frames()
		enemy._enter_state(enemy.State.FLEE)
		for i in 30:
			enemy._physics_process(1.0 / 60.0)
			if enemy.flee_exhausted: break
		check(enemy.counterattack_active and enemy.global_position.x < 70.0 and enemy._direction == -1, label + ": blocked retreat stops and faces player")
		wall.queue_free()
		await frames()
		prepare(enemy, player, mode)
		enemy._enter_state(enemy.State.FLEE)
		enemy.apply_ai_stun(0.1)
		enemy._update_state(0.2)
		check(enemy.flee_exhausted and enemy.counterattack_active and enemy._evaluate_transition() != enemy.State.FLEE, label + ": interruption cannot start a second retreat")
		enemy.target = null
		enemy._tick_flee_response(0.1)
		check(not enemy.flee_started and not enemy.counterattack_active, label + ": encounter loss resets the one-use policy")
	enemy.queue_free()
	await frames()
	print("FLEE COUNTER RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
