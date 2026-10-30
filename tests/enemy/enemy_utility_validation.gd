extends Node2D
const AI = preload("res://scenes/enemy/enemy_utility_ai.gd")
const Profile = preload("res://scenes/enemy/enemy_utility_profile.gd")
var checks := 0
var failures := 0
var decisions := 0

func _ready() -> void:
	_run.call_deferred()

func frames(count: int = 2) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("ENEMY UTILITY ", "PASS " if ok else "FAIL ", label)

func context() -> Dictionary:
	return {&"has_target": true, &"visible": true, &"grounded": true, &"reachable": true,
		&"health": 1.0, &"player_health": 1.0, &"allies": 0, &"distance": 400.0,
		&"memory": 1.0, &"opener": true, &"leap_range": 280.0, &"melee_range": 110.0,
		&"safe_distance": 600.0, &"flee_enabled": true, &"resting": false, &"phase_progress": 0.0}

func wall(at: Vector2) -> StaticBody2D:
	var result := StaticBody2D.new()
	result.position = at
	result.collision_layer = 1
	result.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 600)
	collider.shape = shape
	result.add_child(collider)
	add_child(result)
	return result

func _run() -> void:
	if not OS.get_user_data_dir().contains("CodexEnemyDeath"):
		get_tree().quit(2)
		return
	var ai := AI.new()
	var profile := Profile.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261030
	var c := context()
	var scores := ai.evaluate(c, profile)
	check(ai.choose(&"", rng) == &"chase", "healthy distant enemy chooses chase")
	c.distance = 200.0
	ai.evaluate(c, profile)
	check(ai.choose(&"", rng) == &"leap", "visible grounded target within opening range chooses leap")
	c.distance = 80.0
	c.opener = false
	scores = ai.evaluate(c, profile)
	check(ai.choose(&"", rng) == &"melee" and scores.leap == 0.0, "after opener, nearby target selects melee")
	var healthy_melee: float = scores.melee
	c.health = 0.2
	scores = ai.evaluate(c, profile)
	check(ai.choose(&"", rng) == &"flee" and scores.melee < healthy_melee, "critical health changes preference from attack to flee")
	var unsupported_flee: float = scores.flee
	var unsupported_melee: float = scores.melee
	c.allies = 3
	scores = ai.evaluate(c, profile)
	check(scores.melee > unsupported_melee and scores.flee < unsupported_flee, "allied support raises attack utility and lowers flee utility")
	var full_health_victim_melee: float = scores.melee
	var full_health_victim_flee: float = scores.flee
	c.player_health = 0.1
	scores = ai.evaluate(c, profile)
	check(scores.melee > full_health_victim_melee and scores.flee < full_health_victim_flee, "weak player raises aggression independently of ally count")
	c = context()
	c.visible = false
	c.distance = 80.0
	scores = ai.evaluate(c, profile)
	check(scores.leap == 0.0 and scores.melee == 0.0, "invisible target cannot score any attack")
	c.visible = true
	c.grounded = false
	scores = ai.evaluate(c, profile)
	check(scores.leap == 0.0 and scores.melee == 0.0, "airborne enemy cannot start ground attacks")
	c.grounded = true
	c.reachable = false
	scores = ai.evaluate(c, profile)
	check(scores.leap == 0.0 and scores.melee == 0.0, "unreachable target height excludes attacks")
	c = context()
	c.opener = false
	scores = ai.evaluate(c, profile)
	check(scores.leap == 0.0 and scores.melee == 0.0, "out of range attacks have zero utility")
	c.health = 0.1
	c.flee_enabled = false
	scores = ai.evaluate(c, profile)
	check(scores.flee == 0.0, "enemy can explicitly disable fleeing")
	c = context()
	c.has_target = false
	scores = ai.evaluate(c, profile)
	check(ai.choose(&"", rng) == &"patrol" and scores.chase == 0.0 and scores.flee == 0.0, "no perceived target permits only idle or patrol")
	c.phase_progress = 1.0
	ai.evaluate(c, profile)
	check(ai.choose(&"patrol", rng) == &"idle", "patrol progress makes rest more valuable")
	c.resting = true
	c.phase_progress = 0.0
	ai.evaluate(c, profile)
	check(ai.choose(&"", rng) == &"idle", "new idle state gets time to rest")
	c.phase_progress = 1.0
	ai.evaluate(c, profile)
	check(ai.choose(&"idle", rng) == &"patrol", "rest progress eventually resumes patrol")
	check(is_equal_approx(Profile.response(profile.health_confidence, -1.0), 0.0) and is_equal_approx(Profile.response(profile.health_confidence, 2.0), 1.0), "curve inputs clamp to normalized range")
	var bounded := true
	for health in [0.0, 0.2, 0.5, 1.0]:
		for distance in [0.0, 80.0, 280.0, 600.0, 2000.0]:
			c = context()
			c.health = health
			c.distance = distance
			for value in ai.evaluate(c, profile).values(): bounded = bounded and is_finite(value) and value >= 0.0 and value <= 1.0
	check(bounded, "scores stay finite and normalized across health/distance extremes")
	c = context()
	c.distance = 50.0
	c.opener = false
	profile.melee_weight = 0.0
	ai.evaluate(c, profile)
	check(ai.choose(&"", rng) != &"melee", "profile weight can disable an action")
	profile.melee_weight = 1.0
	ai.scores = {&"melee": 1.0, &"chase": 0.95}
	check(ai.choose(&"chase", rng, false, 0.85, 0.08) == &"chase", "hysteresis keeps current action through small score fluctuations")
	ai.scores[&"chase"] = 0.7
	check(ai.choose(&"chase", rng) == &"melee", "clear utility advantage switches actions")
	ai.scores = {&"melee": 1.0, &"leap": 0.9, &"chase": 0.2, &"flee": 0.0}
	var sampled := {}
	var only_top := true
	for i in 400:
		var selected := ai.choose(&"", rng, true, 0.85)
		sampled[selected] = true
		only_top = only_top and selected in [&"melee", &"leap"]
	check(only_top and sampled.size() == 2, "seeded weighted selection varies only among positive top-scoring actions")
	ai.scores = {}
	check(ai.choose(&"", rng, true) == &"idle", "empty/zero utility safely falls back to idle")
	# Real prefab + real player model, physics sight and animation lifecycle.
	var scene = load("res://scenes/enemy/utility_ai_test.tscn").instantiate()
	add_child(scene)
	var enemy = scene.get_node("UtilityEnemy")
	var baseline = scene.get_node("FSMEnemy")
	var player = scene.get_node("PlayableAdel")
	baseline.set_physics_process(false)
	baseline.position.x = 2500
	await frames(70)
	enemy.set_physics_process(false)
	player.set_physics_process(false)
	player.vitals.simulation_enabled = false
	check(enemy.decision_mode == enemy.DecisionMode.UTILITY and baseline.decision_mode == baseline.DecisionMode.FSM, "comparison scene uses Utility prefab alongside unchanged FSM baseline")
	player.stats.hp = 25
	player.stats.max_hp = 100
	check(is_equal_approx(player.get_ai_health_ratio(), 0.25), "AI health query reads player stats model")
	player.stats.hp = 100
	player.position = enemy.position + Vector2(420, 0)
	enemy.utility_decided.connect(func(_action, _scores): decisions += 1)
	enemy._physics_process(1.0 / 60.0)
	check(enemy.state == enemy.State.DETECT and decisions == 0, "utility decisions cannot bypass initial detection animation")
	await frames(45)
	check(enemy.state == enemy.State.RUN, "actual detect completion releases the decision layer")
	enemy._physics_process(1.0 / 60.0)
	check(enemy.utility_action == &"chase" and enemy.state == enemy.State.RUN and decisions == 1, "scored chase drives actual FSM run state")
	for i in 3: enemy._physics_process(1.0 / 60.0)
	check(decisions == 1, "decision cadence avoids rescoring every physics frame")
	enemy.take_damage(1)
	check(enemy._utility_think_left == 0.0, "incoming damage invalidates the decision cooldown immediately")
	enemy.current_health = 100
	player.position = enemy.position + Vector2(200, 0)
	enemy._utility_think_left = 0.0
	enemy._physics_process(1.0 / 60.0)
	check(enemy.utility_action == &"leap" and enemy.state == enemy.State.WINDUP, "selected leap drives windup rather than skipping attack phases")
	var committed_decisions := decisions
	enemy.current_health = 20
	check(enemy._evaluate_transition() == enemy.State.WINDUP and decisions == committed_decisions, "committed windup is not rerolled on health changes")
	enemy._physics_process(enemy.windup_time + 0.01)
	check(enemy.state == enemy.State.LEAP and not enemy.opener_available, "utility opener launches through the real leap executor")
	enemy.apply_ai_stun(0.1)
	check(enemy.state == enemy.State.STUNNED and not enemy._window_open, "forced stun overrides utility attack and closes hitbox")
	enemy._update_state(0.2)
	enemy._physics_process(1.0 / 60.0)
	check(enemy.state == enemy.State.FLEE and enemy.utility_action == &"flee", "stun expiry makes a fresh survival decision")
	enemy._enter_state(enemy.State.RECOVERY)
	enemy._elapsed = 0.1
	check(enemy._evaluate_transition() == enemy.State.RECOVERY, "utility cannot skip attack recovery")
	enemy._elapsed = enemy.recovery_time + 0.01
	check(enemy._evaluate_transition() == enemy.State.FLEE, "utility resumes decisions after recovery completes")
	# Occlusion must not reveal movement or HP changes.
	enemy.current_health = 100
	enemy._enter_state(enemy.State.RUN)
	enemy._refresh_target(0.016)
	var visible_context: Dictionary = enemy._utility_context()
	var last_seen: Vector2 = enemy.last_seen_position
	var obstruction := wall((enemy.global_position + player.global_position) * 0.5 + Vector2(0, -50))
	await frames()
	player.position.x += 40
	player.stats.hp = 1
	enemy._refresh_target(0.1)
	var hidden_context: Dictionary = enemy._utility_context()
	enemy._evaluate_transition()
	check(not enemy.target_visible and enemy.last_seen_position == last_seen and hidden_context.player_health == visible_context.player_health, "utility perception retains last seen position/HP behind wall")
	check(enemy.utility_scores.leap == 0.0 and enemy.utility_scores.melee == 0.0, "real wall forces both attack scores to zero")
	enemy._refresh_target(2.0)
	enemy._evaluate_transition()
	check(enemy.target == null and enemy.utility_action in [&"idle", &"patrol"], "expired sight memory returns Utility enemy to noncombat behavior")
	obstruction.queue_free()
	await frames()
	baseline.position = enemy.position + Vector2(-300, 0)
	await frames()
	check(enemy._utility_context().allies == 1, "nearby living visible enemy provides allied support")
	var ally_wall := wall((enemy.global_position + baseline.global_position) * 0.5 + Vector2(0, -50))
	await frames()
	check(enemy._utility_context().allies == 0, "allies behind terrain do not grant unseen support")
	ally_wall.queue_free()
	await frames()
	baseline.die()
	check(enemy._utility_context().allies == 0, "dead enemy is removed from allied support")
	var prior_decisions := decisions
	enemy.decision_mode = enemy.DecisionMode.FSM
	enemy._evaluate_transition()
	check(decisions == prior_decisions and enemy.utility_action == &"", "switching to baseline stops utility selection")
	enemy.decision_mode = enemy.DecisionMode.UTILITY
	enemy.utility_profile = null
	enemy._evaluate_transition()
	check(enemy.utility_profile != null and decisions == prior_decisions + 1, "switching back resumes scoring with a safe default for a missing profile")
	enemy.die()
	check(enemy.state == enemy.State.DEAD and enemy.utility_scores.is_empty() and enemy._evaluate_transition() == enemy.State.DEAD, "death clears utility diagnostics and prevents new actions")
	print("ENEMY UTILITY RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
