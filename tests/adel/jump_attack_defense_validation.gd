extends Node
var checks := 0
var failures := 0
var p
var hud
var enemy
var floor_y: float
var S = AdelStateMachine.State
func _ready() -> void:
	if not String(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("CodexCombatFeel"):
		get_tree().quit(2)
		return
	_run.call_deferred()
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame
func wait(t: float) -> void:
	await get_tree().create_timer(t,true,false,true).timeout
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("JUMP DEFENSE ", "PASS " if ok else "FAIL ", label)
func button(action: StringName, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)
	await frames(1)
func click(action: StringName) -> void:
	await button(action,true)
	await button(action,false)
func reset() -> void:
	for action in [&"attack", &"jump", &"move_down", &"move_right", &"guard and deflect"]: await button(action,false)
	p.enter_rest(false)
	p.exit_rest()
	p.position = Vector2(300,floor_y)
	p.velocity = Vector2.ZERO
	p.combat.combo_step = 0
	p.damage.is_stunned = false
	p.damage.is_invulnerable = false
	p.damage.is_touched_enemy = false
	hud.hp = 100
	hud.clear_all_debuffs()
	hud.restore_stagger_thresholds()
	hud.restore_stamina_full()
	enemy.position = Vector2(3000, floor_y)
	enemy.current_health = 1000
	await frames(3)
func jump_attack() -> void:
	await click(&"jump")
	await frames(6)
	await button(&"move_down",true)
	await click(&"attack")
	await button(&"move_down",false)
	check(p.state_machine.current == S.JUMP_HANG, "real input starts jump_attack air")
func reach(state: int) -> bool:
	for i in 180:
		if p.state_machine.current == state:return true
		await frames(1)
	return false
func finish_land() -> void:
	for i in 100:
		if p.state_machine.current != S.JUMP_LAND:return
		await frames(1)
func _run() -> void:
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	await frames(70)
	floor_y = p.position.y
	hud = p.get_node("Camera2D/hud")
	hud.set_process(false)
	p.vitals.simulation_enabled = false
	p.hit_stop_enabled = false
	for facing in [-1,1]:
		await reset()
		p._set_facing_direction(facing)
		enemy.position = p.position + Vector2(facing*65,0)
		await jump_attack()
		check(await reach(S.JUMP_LAND), "actual floor contact begins landing, facing %d" % facing)
		await button(&"guard and deflect",true)
		await frames(12)
		check(not p.is_guarding and p.state_machine.current == S.JUMP_LAND, "landing cannot defend during first part of clip")
		await finish_land()
		check(p.is_guarding and p.spine_anim.assigned_animation == &"saber_defense", "held landing input becomes defense after actual animation, facing %d" % facing)
		check(not p.jump_hitbox._attack_active and not p.jump_hitbox._window_open, "landing-to-defense closes jump damage completely")
		check(enemy.current_health == 980, "held Defense preserves one jump hit of 20, facing %d" % facing)
	# Holding from air/fall records intent but never grants airborne defense.
	for phase in [S.JUMP_HANG,S.JUMP_FALL]:
		await reset()
		await jump_attack()
		check(await reach(phase), "jump reaches requested air/fall phase")
		await button(&"guard and deflect",true)
		check(not p.is_guarding and p.state_machine.is_in(S.JUMP_ATTACK), "air/fall cannot enter Defense on press")
		check(p.defense.classify_hit(p.position,p.facing_direction,p.position+Vector2(p.facing_direction*80,0)) == DefenseComponent.HitResult.NONE, "air/fall has neither Guard nor Deflect protection")
		check(await reach(S.JUMP_LAND), "held request does not interrupt flight or landing")
		await finish_land()
		check(p.is_guarding, "holding from air/fall only executes after land ends")
	# A release in flight discards the request.
	await reset()
	await jump_attack()
	await button(&"guard and deflect",true)
	await button(&"guard and deflect",false)
	check(await reach(S.JUMP_LAND), "released air request still lands normally")
	await finish_land()
	check(not p.is_guarding and not p._guard_requested, "released request never creates ghost defense after landing")
	# Movement's old 0.3s unlock must not override a held defensive request.
	await reset()
	await jump_attack()
	check(await reach(S.JUMP_LAND), "movement-priority case reaches landing")
	await button(&"guard and deflect",true)
	await button(&"move_right",true)
	await frames(18)
	check(p.state_machine.current == S.JUMP_LAND and not p.is_guarding, "held Defense preserves landing through the old movement unlock")
	await finish_land()
	check(p.is_guarding, "held Defense still executes with movement held")
	# Release in landing, zero stamina and interruption retain normal rejection.
	await reset()
	await jump_attack()
	check(await reach(S.JUMP_LAND), "release case reaches landing")
	await button(&"guard and deflect",true)
	await button(&"guard and deflect",false)
	await finish_land()
	check(not p.is_guarding, "release in landing cancels pending Defense")
	await reset()
	await jump_attack()
	check(await reach(S.JUMP_LAND), "zero-stamina case reaches landing")
	hud.stamina = 0
	await button(&"guard and deflect",true)
	await finish_land()
	check(not p.is_guarding and not p._guard_requested, "zero stamina rejects landing Defense")
	await reset()
	await jump_attack()
	check(await reach(S.JUMP_LAND), "stagger case reaches landing")
	await button(&"guard and deflect",true)
	hud.hp = 70
	p.take_damage(20,p.global_position+Vector2(80,0))
	check(p.damage.is_stunned and not p._guard_requested and not p.jump_hitbox._window_open, "stagger clears landing request and hitbox")
	await wait(1.1)
	check(not p.is_guarding and p.can_move, "stagger recovery does not replay held landing Defense")
	print("JUMP DEFENSE RESULT: %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
