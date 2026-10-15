extends Node
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
	print("ENEMY DETECT ", "PASS " if ok else "FAIL ", label)

func fresh(enemy, player, distance: float = 420.0) -> void:
	Engine.time_scale = 1.0
	enemy.animation_player.speed_scale = 1.0
	enemy.chase_memory = 1.5
	enemy.target = null
	enemy.opener_available = true
	player.position.x = enemy.position.x + distance
	enemy._enter_state(enemy.State.WALK)
	await frames(2)

func _run() -> void:
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	var enemy = scene.get_node("Enemy")
	var player = scene.get_node("PlayableAdel")
	await frames(70)
	player.set_physics_process(false)
	var hp: int = player.get_node("Camera2D/hud").hp
	check(enemy.state == enemy.State.WALK and enemy.animation_player.assigned_animation == &"walk", "outside detection range keeps walking")
	check(is_equal_approx(enemy.animation_player.get_animation(&"detect player").length, 0.7), "uses existing 0.7-second source clip")
	for distance in [-420.0, 420.0]:
		await fresh(enemy, player, distance)
		var start: Vector2 = enemy.position
		check(enemy.state == enemy.State.DETECT and enemy.animation_player.assigned_animation == &"detect player", "walk enters detect clip, direction %d" % int(signf(distance)))
		check(enemy._direction == int(signf(distance)), "detect faces player before playing")
		await frames(20)
		check(enemy.state == enemy.State.DETECT and enemy.animation_player.is_playing(), "transition is not skipped mid-clip")
		check(absf(enemy.position.x - start.x) < 0.01 and enemy.is_on_floor(), "transition stops horizontal travel and retains floor physics")
		check(not enemy._window_open and enemy.hitbox_shape.disabled and enemy.leap_hitbox_shape.disabled and enemy.opener_available, "detect cannot damage or consume opener")
		await frames(25)
		check(enemy.state == enemy.State.RUN and enemy.animation_player.assigned_animation == &"run", "detect completes before run begins")
		check(player.get_node("Camera2D/hud").hp == hp, "transition and early run deal no damage")
	# Being in leap/melee range must not bypass detect.
	await fresh(enemy, player, 90)
	await frames(20)
	check(enemy.state == enemy.State.DETECT and enemy.opener_available, "nearby player still gets the full transition before opener")
	await frames(25)
	check(enemy.state == enemy.State.WINDUP, "close target enters windup only after detect and run")
	# Use actual playback progress, not a separate fixed 0.7-second state timer.
	await fresh(enemy, player)
	enemy.animation_player.speed_scale = 0.5
	await frames(45)
	check(enemy.state == enemy.State.DETECT, "half-speed clip does not exit at unscaled original length")
	await frames(45)
	check(enemy.state == enemy.State.RUN, "half-speed detection finishes and enters run")
	await fresh(enemy, player)
	enemy.animation_player.pause()
	await frames(50)
	check(enemy.state == enemy.State.DETECT, "paused clip never advances by a separate elapsed timer")
	enemy.animation_player.play()
	await frames(45)
	check(enemy.state == enemy.State.RUN, "resuming clip restores normal completion")
	await fresh(enemy, player)
	Engine.time_scale = 0.5
	await frames(45)
	check(enemy.state == enemy.State.DETECT, "global slow motion preserves transition until the actual clip ends")
	await frames(45)
	check(enemy.state == enemy.State.RUN, "slow-motion clip eventually completes")
	Engine.time_scale = 1.0
	# Target loss cancels detection; an unrelated/stale finish cannot revive pursuit.
	await fresh(enemy, player)
	enemy.chase_memory = 0.0
	player.position.x = enemy.position.x + 2000
	await frames(2)
	check(enemy.target == null and enemy.state == enemy.State.WALK and enemy.animation_player.assigned_animation == &"walk", "disengaged target cancels detect safely")
	enemy._on_animation_finished(&"detect player")
	check(enemy.state == enemy.State.WALK, "stale detect completion cannot override walk")
	await fresh(enemy, player)
	enemy._on_animation_finished(&"walk")
	check(enemy.state == enemy.State.DETECT, "unrelated animation completion does not finish detect")
	# A new encounter returns through detection; recovery in an encounter does not.
	enemy._enter_state(enemy.State.RECOVERY)
	await frames(45)
	check(enemy.state == enemy.State.RUN, "combat recovery does not replay detect")
	await fresh(enemy, player)
	player.queue_free()
	await frames(2)
	check(enemy.target == null and enemy.state == enemy.State.WALK, "freed player cancels detection without invalid target access")
	var replacement = load("res://scenes/adel/playable_adel.tscn").instantiate()
	scene.add_child(replacement)
	replacement.set_physics_process(false)
	replacement.position = enemy.position + Vector2(420, 0)
	await frames(2)
	check(enemy.state == enemy.State.DETECT, "reacquired player replays the walk-to-run transition")
	var capture_path := OS.get_environment("CODEX_DETECT_SCREENSHOT")
	if DisplayServer.get_name() != "headless" and not capture_path.is_empty():
		await frames(12)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_path)
	enemy.die()
	enemy._on_animation_finished(&"detect player")
	check(enemy.is_dead and enemy.state == enemy.State.DEAD and not enemy._window_open, "detect timeout cannot revive a dead enemy")
	await frames(2)
	check(is_instance_valid(enemy) and enemy.animation_player.assigned_animation == &"death", "death during detection interrupts detect with death")
	enemy.animation_player.advance(10.0)
	await frames(2)
	check(not is_instance_valid(enemy), "death during detection frees after death animation")
	# An incomplete rig is disabled, not silently allowed to skip the requested clip.
	var incomplete = load("res://scenes/enemy/spine_enemy.tscn").instantiate()
	var anim = incomplete.get_node("VisualPivot/EnemyRig/AnimationPlayer")
	var library = anim.get_animation_library(&"").duplicate()
	anim.remove_animation_library(&"")
	anim.add_animation_library(&"", library)
	library.remove_animation(&"detect player")
	scene.add_child(incomplete)
	check(not incomplete.is_physics_processing(), "missing detect animation disables AI with a warning")
	incomplete.queue_free()
	print("ENEMY DETECT RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
