extends Node
const DebugSettings = preload("res://scenes/enemy/enemy_debug_settings.gd")
const S = AdelStateMachine.State
var checks := 0
var failures := 0
var p
var enemy
var menu
var scene
var origin: Vector2
var hit_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("ENEMY DEBUG ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func reach(state: int) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while p.state_machine.current != state and Time.get_ticks_msec() < deadline: await frames()
	return p.state_machine.current == state

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexEnemyDebug20261016"):
		get_tree().quit(2)
		return
	Engine.max_fps = 144
	check(not DebugSettings.is_ai_disabled() and not DebugSettings.is_immortal(), "fresh session starts with normal AI and damage")
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	enemy.position.x = 1500
	await frames(65)
	origin = p.position
	p.vitals.simulation_enabled = false
	p.hit_stop_enabled = false
	p.stagger_zoom_enabled = false
	p.stagger_slow_motion_enabled = false
	for prefix in ["tap", "charged", "full"]:
		p.saber_skill.set(prefix + "_impact_zoom_enabled", false)
		p.saber_skill.set(prefix + "_impact_slow_motion_enabled", false)
	menu = p.get_node("Camera2D/UI_Layer/PauseMenu")
	var ai: CheckButton = menu.get_node("VBoxContainer/EnemyDebug/DisableAI")
	var immortal: CheckButton = menu.get_node("VBoxContainer/EnemyDebug/Immortal")
	check(not ai.button_pressed and not immortal.button_pressed and ai.visible and immortal.visible, "pause contains two unchecked debug controls")
	var before_save := JSON.stringify(SaveManager._data)
	menu.pause_and_unpause()
	check(get_tree().paused and menu.visible, "pause opens normally with debug section")
	ai.button_pressed = true
	immortal.button_pressed = true
	check(get_tree().paused and DebugSettings.is_ai_disabled() and DebugSettings.is_immortal(), "both toggles update session settings while world remains paused")
	check(JSON.stringify(SaveManager._data) == before_save, "debug switches do not modify save data")
	await frames(3)
	var panel: Control = menu.get_node("VBoxContainer")
	check(panel.get_global_rect().position.y >= 0 and panel.get_global_rect().end.y <= menu.get_viewport_rect().size.y, "pause content including debug controls fits viewport")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var path := OS.get_user_data_dir().path_join("enemy-debug-pause.png")
		get_viewport().get_texture().get_image().save_png(path)
		print("ENEMY DEBUG CAPTURE ", path)
	menu.pause_and_unpause()
	await frames(8)
	var idle_position: Vector2 = enemy.position
	await frames(12)
	check(enemy.position.distance_to(idle_position) < 0.1 and enemy.velocity.x == 0, "disabled AI stops enemy horizontal movement")
	check(enemy.target == null and enemy.state == enemy.State.WALK and not enemy.animation_player.is_playing(), "disabled Spine enemy stays neutral without detection or attack animation")
	check(not enemy._window_open and enemy.hitbox_shape.disabled and enemy.leap_hitbox_shape.disabled, "both attack shapes are disabled")
	check(enemy.get_lock_on_point().is_finite() and not enemy.get_node("CollisionShape2D").disabled, "AI disable preserves hurtbox and lock-on point")
	var hp: int = enemy.current_health
	var exp_before: int = PlayerProgress.exp
	check(enemy.take_damage(999999, p.global_position) and enemy.current_health == hp and not enemy.is_dead, "immortal enemy accepts lethal hits without losing HP or dying")
	enemy.die()
	check(not enemy.is_dead and not enemy.is_queued_for_deletion(), "immortality also guards the enemy death entry point")
	check(PlayerProgress.exp == exp_before, "immortal hits grant no kill reward")
	# Starting a previously queued swing cannot hurt Player before the first AI tick.
	enemy.attack_animation = &"attack2"
	enemy.target = p
	enemy.state = enemy.State.MELEE
	enemy._window_open = true
	enemy._active_hitbox = enemy.hitbox
	enemy._swing_damage = 99
	enemy._hit_targets.clear()
	var player_hp: int = p.stats.hp
	enemy._try_hit_body(p)
	check(p.stats.hp == player_hp, "stale attack callback cannot deal damage while AI is disabled")
	enemy._set_damage_window(true)
	check(not enemy._window_open, "AI-disabled enemy cannot reopen a damage window")
	# A real Q hit still registers on an immortal training dummy.
	enemy.position = p.position + Vector2(155, 0)
	await frames(3)
	p._set_facing_direction(1)
	p.saber_hitbox.target_hit.connect(func(_target): hit_count += 1)
	Input.action_press("weapon_skill")
	check(p.saber_skill.begin(), "real Q can target the immortal dummy")
	Input.action_release("weapon_skill")
	p.saber_skill.release()
	check(await reach(S.SKILL_IMPACT), "real Q collides with dummy hurtbox")
	check(hit_count > 0 and enemy.current_health == hp and not enemy.is_dead, "actual Q hit feedback is preserved without HP loss")
	p.clear_combat_input()
	# Turning immunity off restores damage, without requiring a scene reload.
	menu.pause_and_unpause()
	immortal.button_pressed = false
	check(ai.button_pressed and not DebugSettings.is_immortal(), "AI and immortality can be switched independently")
	menu.pause_and_unpause()
	enemy.take_damage(3)
	check(enemy.current_health == hp - 3, "turning immortality off restores normal HP loss")
	# New enemies inherit the active session setting and retain world gravity.
	var fresh = load("res://scenes/enemy/spine_enemy.tscn").instantiate()
	fresh.position = origin + Vector2(700, -150)
	scene.add_child(fresh)
	var start_y: float = fresh.position.y
	var start_x: float = fresh.position.x
	await frames(8)
	check(fresh.position.y > start_y and is_equal_approx(fresh.position.x, start_x), "new AI-disabled enemy falls naturally without walking")
	check(fresh._debug_ai_was_disabled and not fresh._window_open, "spawned enemies immediately inherit the AI toggle")
	var wobtear = load("res://scenes/enemy/wobtear_enemy.tscn").instantiate()
	wobtear.position = origin + Vector2(850, 0)
	scene.add_child(wobtear)
	await frames(5)
	var wobtear_x: float = wobtear.position.x
	await frames(10)
	check(is_equal_approx(wobtear.position.x, wobtear_x), "EnemyBase/Wobtear respects the same AI toggle")
	DebugSettings.immortal = true
	var wobtear_hp: int = wobtear.current_health
	check(wobtear.take_damage(999) and wobtear.current_health == wobtear_hp and not wobtear.is_dead, "EnemyBase/Wobtear respects the same immortality toggle")
	# Reopening and recreating the menu shows the current session values.
	menu.pause_and_unpause()
	check(ai.button_pressed and immortal.button_pressed, "reopening pause syncs the current shared values")
	var other_menu = load("res://scenes/UI/game_pause_menu.tscn").instantiate()
	scene.add_child(other_menu)
	check(other_menu.get_node("VBoxContainer/EnemyDebug/DisableAI").button_pressed and other_menu.get_node("VBoxContainer/EnemyDebug/Immortal").button_pressed, "new pause instance keeps session debug settings")
	other_menu.queue_free()
	menu.pause_and_unpause()
	# Re-enable AI near the player: reacquire from a neutral state, never resume the old attack.
	menu.pause_and_unpause()
	ai.button_pressed = false
	immortal.button_pressed = false
	menu.pause_and_unpause()
	enemy.position = origin + Vector2(350, 0)
	p.position = origin
	p.damage.reset()
	await frames(3)
	check(not enemy._debug_ai_was_disabled and enemy.target == p and enemy.state in [enemy.State.DETECT, enemy.State.RUN], "re-enabled AI reacquires Player through normal detection")
	check(not enemy._window_open and enemy.animation_player.is_playing(), "re-enabled AI resumes animation without the old attack window")
	# Dead enemies remain dead and keep their death animation even when switches change.
	DebugSettings.ai_disabled = true
	enemy.take_damage(999999)
	check(enemy.is_dead and enemy.animation_player.assigned_animation == &"death", "AI-disabled enemy can die normally when immunity is off")
	DebugSettings.immortal = true
	await frames(5)
	check(enemy.is_dead and enemy.animation_player.is_playing() and enemy.animation_player.assigned_animation == &"death", "enabling debug switches never resurrects or pauses an existing corpse")
	DebugSettings.ai_disabled = false
	DebugSettings.immortal = false
	fresh.queue_free()
	wobtear.queue_free()
	print("ENEMY DEBUG RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
