extends Node2D
const Enemy = preload("res://scenes/enemy/spine_enemy.tscn")
const Sight = preload("res://scenes/enemy/enemy_sight.gd")
const Stun = preload("res://scenes/adel/components/enemy_skill_stun.gd")
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
	print("ENEMY FSM ", "PASS " if ok else "FAIL ", label)

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

func _run() -> void:
	body(Vector2(0, 100), Vector2(4000, 40), 1)
	var enemy = Enemy.instantiate()
	enemy.position = Vector2(0, 0)
	enemy.speed = 0.0
	add_child(enemy)
	await frames(10)
	enemy.set_physics_process(false)
	var player := body(Vector2(350, -25), Vector2(20, 40), 3)
	player.add_to_group("Player")
	await frames()
	enemy._refresh_target(0.016)
	check(enemy.target == player and enemy.target_visible, "clear sight acquires player even when player also occupies terrain layer")
	check(enemy._evaluate_transition() == enemy.State.DETECT, "patrol transitions to detection")
	var remembered: Vector2 = enemy.last_seen_position
	var wall := body(Vector2(170, -50), Vector2(30, 400), 1)
	await frames()
	check(not Sight.can_see(enemy, player), "solid wall blocks sight")
	enemy._refresh_target(0.1)
	check(enemy.target == player and not enemy.target_visible, "occluded target is remembered briefly")
	player.position.x = 450
	await frames()
	enemy._refresh_target(0.1)
	check(enemy.last_seen_position == remembered, "hidden movement does not update remembered location")
	enemy._enter_state(enemy.State.RUN)
	check(enemy._evaluate_transition() == enemy.State.RUN, "occluded target cannot trigger attack")
	enemy._refresh_target(2.0)
	check(enemy.target == null, "memory expires behind wall without reacquiring through it")
	wall.position.x = -170
	player.position.x = -350
	await frames()
	enemy._refresh_target(0.016)
	check(enemy.target == null and not Sight.can_see(enemy, player), "wall blocks detection from opposite direction")
	wall.position.x = 1000
	await frames()
	enemy._refresh_target(0.016)
	check(enemy.target == player and enemy.target_visible, "removing obstruction permits reacquisition")
	# Areas/hitboxes must not occlude vision; configurable terrain layers must.
	wall.position.x = -170
	wall.collision_layer = 8
	await frames()
	check(Sight.can_see(enemy, player), "non-terrain layer is ignored")
	check(not Sight.can_see(enemy, player, 8), "custom obstacle mask blocks its selected layer")
	wall.queue_free()
	await frames()
	enemy.target = null
	player.remove_from_group("Player")
	enemy._enter_state(enemy.State.WALK)
	enemy._elapsed = enemy.walk_duration
	check(enemy._evaluate_transition() == enemy.State.IDLE, "patrol timer selects idle")
	enemy._enter_state(enemy.State.IDLE)
	check(not enemy.animation_player.is_playing() and not enemy._window_open, "idle pauses available walk pose and closes combat")
	enemy._elapsed = enemy.idle_duration
	check(enemy._evaluate_transition() == enemy.State.WALK, "idle timer resumes patrol")
	player.add_to_group("Player")
	enemy._refresh_target(0.016)
	enemy.current_health = 20
	check(enemy._evaluate_transition() == enemy.State.FLEE, "low health selects flee")
	enemy._enter_state(enemy.State.FLEE)
	enemy._update_state(0.016)
	check(enemy.velocity.x > 0, "flee moves away from threat on left")
	enemy.current_health = 40
	check(enemy._evaluate_transition() == enemy.State.RUN, "healing above recovery threshold ends flee")
	enemy.current_health = 20
	enemy.last_seen_position = enemy.position + Vector2(700, 0)
	check(enemy._evaluate_transition() == enemy.State.IDLE, "safe distance ends flee")
	enemy._enter_state(enemy.State.IDLE)
	check(enemy._evaluate_transition() == enemy.State.IDLE, "safe low-health enemy waits instead of chasing back into danger")
	enemy.flee_health_ratio = 0.0
	enemy._enter_state(enemy.State.RUN)
	check(enemy._evaluate_transition() != enemy.State.FLEE, "zero threshold disables flee")
	enemy.current_health = 100
	enemy._refresh_target(0.016)
	enemy.attack_animation = &"attack2"
	enemy._enter_state(enemy.State.MELEE)
	enemy._set_damage_window(true)
	check(enemy._window_open, "attack fixture opens hitbox")
	var stun := Stun.new()
	stun.name = "WeaponSkillStun"
	stun.remaining = 0.2
	enemy.add_child(stun)
	check(enemy.state == enemy.State.STUNNED and not enemy._window_open and not enemy.animation_player.is_playing(), "skill stun enters FSM and immediately stops attack")
	stun.extend(0.5)
	check(is_equal_approx(enemy._stun_remaining, 0.5), "repeated stun extends remaining duration")
	enemy._update_state(0.3)
	check(enemy._evaluate_transition() == enemy.State.STUNNED, "stun cannot finish before extended duration")
	stun.extend(0.1)
	check(is_equal_approx(enemy._stun_remaining, 0.2), "short repeat stun does not restart the original longer duration")
	enemy._update_state(0.3)
	check(enemy._evaluate_transition() == enemy.State.RUN, "expired stun resumes pursuit")
	enemy._enter_state(enemy.State.RUN)
	await frames()
	check(not is_instance_valid(stun) and enemy.animation_player.is_playing(), "stun bridge cleans itself up after FSM resumes")
	enemy.apply_ai_stun(1.0)
	enemy.die()
	enemy.apply_ai_stun(2.0)
	enemy._enter_state(enemy.State.RUN)
	check(enemy.state == enemy.State.DEAD and not enemy._window_open, "death overrides stun and cannot be revived by stale requests")
	# Exercise the older prototype's Area2D signal and polling path as well.
	player.position = Vector2(1350, -25)
	var legacy_wall := body(Vector2(1275, -25), Vector2(20, 400), 1)
	var legacy = load("res://scenes/enemy/s_1e_1.gd").new()
	legacy.position = Vector2(1200, 0)
	var pivot := Node2D.new()
	pivot.name = "WeaponPivot"
	legacy.add_child(pivot)
	var hurt := Area2D.new()
	hurt.name = "HurtBox"
	legacy.add_child(hurt)
	var detection := Area2D.new()
	detection.name = "DetectionArea"
	detection.collision_layer = 0
	detection.collision_mask = 2
	var detection_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 300
	detection_shape.shape = circle
	detection.add_child(detection_shape)
	legacy.add_child(detection)
	add_child(legacy)
	legacy.set_physics_process(false)
	await frames(3)
	legacy._refresh_sight()
	check(legacy.target_player == null, "legacy Area2D cannot acquire through wall")
	legacy_wall.position.x = 1700
	await frames()
	legacy._refresh_sight()
	check(legacy.target_player == player and legacy.is_player_in_sight, "legacy polling acquires after wall is removed without reentering area")
	var legacy_memory: Vector2 = legacy.last_seen_position
	legacy_wall.position.x = 1275
	player.position.x = 1400
	await frames()
	legacy._refresh_sight()
	check(not legacy.is_player_in_sight and legacy.last_seen_position == legacy_memory, "legacy hidden movement preserves last seen position")
	legacy._handle_chase(11.0)
	check(legacy.target_player == null and legacy.ai_state == "idle", "legacy memory expires behind wall")
	print("ENEMY FSM RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
