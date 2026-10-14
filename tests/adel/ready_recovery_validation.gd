extends Node
var checks := 0
var failures := 0
func _ready() -> void:
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
	print("READY ", "PASS " if ok else "FAIL ", label)
func button(action: StringName, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)
	await frames(1)
func _run() -> void:
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	var p = scene.get_node("PlayableAdel")
	scene.get_node("Enemy").set_physics_process(false)
	await frames(65)
	var hud = p.get_node("Camera2D/hud")
	var sprite = p.spine_rig.get_node("TestAttackSprite")
	for origin in ["defense", "guard", "deflect", "stagger"]:
		hud.restore_stamina_full()
		hud.hp = 100
		hud.clear_all_debuffs()
		hud.restore_stagger_thresholds()
		p.damage.is_invulnerable = false
		await button(&"guard and deflect", true)
		if origin == "guard":
			await wait(0.24)
			p.take_damage(20, p.global_position + Vector2(80, 0))
		elif origin == "deflect":
			p.take_damage(20, p.global_position + Vector2(80, 0))
		elif origin == "stagger":
			hud.hp = 70
			p.take_damage(20, p.global_position + Vector2(-80, 0))
		await button(&"guard and deflect", false)
		if origin == "deflect": await wait(p.deflect_slow_motion_duration + 0.03)
		if origin == "stagger":
			while p.damage.is_stunned: await frames(1)
		await frames(1)
		check(p.spine_anim.assigned_animation == &"saber_ready" and sprite.frame == 2, origin + " immediately recovers at final frame")
		check(p.spine_anim.get_animation(&"saber_ready").length == 1.0 and p.can_move and not p.is_doing_action, origin + " duration 1 second and unlocked")
		await wait(0.5)
		check(p.spine_anim.assigned_animation == &"saber_ready" and sprite.frame == 2, origin + " still frame 2 midway")
		if origin == "defense":
			await wait(0.55)
			check(p.spine_anim.assigned_animation == &"idle", "uninterrupted ready ends after one second")
		else:
			await button(&"attack", true)
			await button(&"attack", false)
			check(p.spine_anim.current_animation.begins_with("saber_attack_"), origin + " ready interrupted by attack")
			await frames(70)
			check(sprite.frame != 2 or p.spine_anim.assigned_animation != &"saber_ready" or p.spine_anim.current_animation_position > 0.35, "normal combo recovery keeps source frame sequence")
	await button(&"guard and deflect", true)
	await button(&"guard and deflect", false)
	await button(&"move_right", true)
	check(p.spine_anim.assigned_animation == &"walk", "movement interrupts final ready")
	await button(&"move_right", false)
	await frames(70)
	await button(&"guard and deflect", true)
	await button(&"guard and deflect", false)
	await button(&"jump", true)
	check(p.spine_anim.assigned_animation == &" jump_start", "jump interrupts final ready")
	await button(&"jump", false)
	print("READY RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
