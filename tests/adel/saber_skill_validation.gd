extends Node
var checks := 0
var failures := 0
var p
var skill
var hud
var enemy
var scene
var floor_y: float
var S = AdelStateMachine.State
func _ready() -> void:
	if not String(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("CodexSaberSkill"):
		get_tree().quit(2)
		return
	_run.call_deferred()
func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		await get_tree().process_frame
func wait(t: float) -> void:
	await get_tree().create_timer(t,true,false,true).timeout
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if p != null: print("SKILL FAILURE CONTEXT state=",p.state_machine.current," tier=",skill.tier," charge=",skill.charge_time," clip=",p.spine_anim.assigned_animation," scale=",Engine.time_scale)
	print("SABER SKILL ","PASS " if ok else "FAIL ",label)
func button(action: StringName,down: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = down
	Input.parse_input_event(e)
	await frames(1)
func click(action: StringName) -> void:
	await button(action,true)
	await button(action,false)
func reach(phase: int, seconds: float = 4.0) -> bool:
	var end := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<end:
		if p.state_machine.current == phase:return true
		await frames(1)
	return false
func finished() -> bool:
	var end := Time.get_ticks_msec()+5000
	while skill.is_active() and Time.get_ticks_msec()<end: await frames(1)
	return not skill.is_active()
func reset() -> void:
	for action in [&"weapon_skill",&"attack",&"guard and deflect",&"move_right",&"move_left",&"jump"]:await button(action,false)
	p.enter_rest(false)
	p.exit_rest()
	if p.damage.is_stunned or p.damage.is_invulnerable:await wait(1.1)
	p.damage.is_stunned = false
	p.damage.is_knocking_back = false
	p.damage.is_invulnerable = false
	p.damage.is_touched_enemy = false
	p.is_locked = false
	p.can_move = true
	p.position = Vector2(300,floor_y)
	p.velocity = Vector2.ZERO
	p._set_facing_direction(1)
	p.combat.combo_step = 0
	hud.set_process(false)
	hud.hp = 100
	hud.clear_all_debuffs()
	hud.restore_stagger_thresholds()
	hud.restore_stamina_full()
	var stun = enemy.get_node_or_null("WeaponSkillStun")
	if stun != null:stun.queue_free()
	await frames(1)
	enemy.set_physics_process(false)
	enemy.position = Vector2(3000,floor_y)
	enemy.current_health = 1000
	enemy.is_dead = false
	await frames(3)
func hold_until(t: float) -> void:
	var end := Time.get_ticks_msec()+4000
	while skill.charge_time < t and p.state_machine.current == S.SKILL_CHARGE and Time.get_ticks_msec()<end:await frames(1)
func take_hit(amount: int = 20) -> void:
	p.take_damage(amount,p.global_position+Vector2(80,0))
func _run() -> void:
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	skill = p.saber_skill
	enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	await frames(70)
	floor_y = p.position.y
	hud = p.get_node("Camera2D/hud")
	hud.set_process(false)
	check(InputMap.has_action(&"weapon_skill") and InputMap.action_get_events(&"weapon_skill")[0].physical_keycode == KEY_Q,"weapon skill is bound to physical Q")
	check(skill.damage == 20 and skill.lunge_distance == 180 and skill.lunge_speed == 900,"configurable tap damage and lunge defaults")
	check(skill.charge_level_1_time == 1.0 and skill.charge_level_2_time == 2.0 and skill.charged_release_windup == 0.1,"approved charge and release timing defaults")
	check(skill.recovery_slow_motion_scale == 0.5 and skill.charged_recovery_duration == 0.3,"charged recovery slows world to 0.5x for 0.3s")
	for i in range(1,7):check(p.spine_anim.has_animation("saber_skill_%d"%i),"user-authored skill clip %d exists"%i)
	if DisplayServer.get_name() != "headless":
		# Upload each supplied texture before timing assertions; first-use GPU work is not combat time.
		for i in range(1,7):
			p.presentation.hold(StringName("saber_skill_%d"%i))
			await RenderingServer.frame_post_draw
	# Whiffs measure complete lunge distance and animation flow, facing both ways.
	for facing in [-1,1]:
		for tier in range(3):
			await reset()
			p._set_facing_direction(facing)
			var start: Vector2 = p.position
			await button(&"weapon_skill",true)
			check(p.state_machine.current == S.SKILL_CHARGE and p.spine_anim.assigned_animation == &"saber_skill_1","Q starts skill_1, tier %d facing %d"%[tier,facing])
			if tier == 0:
				await button(&"weapon_skill",false)
				await frames(4)
				check(p.state_machine.current == S.SKILL_CHARGE,"tap preserves 0.2s minimum startup")
			elif tier == 1:
				await hold_until(1.02)
				check(p.spine_anim.assigned_animation == &"saber_skill_2","holding beyond 1s shows skill_2")
				await button(&"weapon_skill",false)
				check(p.state_machine.current == S.SKILL_RELEASE,"tier 1 release commits extra skill_2 windup")
			else:
				await hold_until(1.82)
				check(p.spine_anim.assigned_animation == &"saber_skill_3","full charge final 0.2s shows skill_3")
			check(await reach(S.SKILL_DASH),"tier %d starts lunge"%tier)
			check(skill.tier == tier and p.spine_anim.assigned_animation == &"saber_skill_4" and p.is_skill_damage_immune(),"lunge owns skill_4 and immunity, tier %d"%tier)
			if tier == 2:check(Input.is_action_pressed("weapon_skill"),"full charge lunges without Q release")
			check(await reach(S.SKILL_RECOVERY),"whiff reaches recovery without fake impact")
			var expected: float = skill.lunge_distance * [1.0,1.5,2.0][tier]
			check(absf(p.position.x-start.x-facing*expected)<0.5 and absf(skill.distance_travelled-expected)<0.5,"whiff range ratio %d is exact, facing %d"%[tier,facing])
			check(not p.is_skill_damage_immune() and Engine.time_scale == 1.0,"whiff grants neither recovery immunity nor slow motion")
			check(is_equal_approx(p.spine_anim.get_playing_speed(),2.0 if tier==0 else 1.0),"skill_6 playback speed matches tier")
			check(await finished(),"whiff recovery finishes cleanly")
			check(p.can_move and not p.is_doing_action and not p.saber_hitbox._attack_active,"skill exit restores control and closes sword hitbox")
	# Releasing between thresholds selects the lower completed level.
	for held in [0.4,1.5,1.9]:
		await reset()
		await button(&"weapon_skill",true)
		await hold_until(held)
		var before: float = skill.charge_time
		await button(&"weapon_skill",false)
		check(await reach(S.SKILL_DASH),"partial hold %.1f starts lunge"%held)
		check(skill.tier == (0 if held<1 else 1),"partial hold %.1f selects lower completed tier"%held)
		check(skill.charge_time>=before,"release does not reset accumulated charge")
		await finished()
	# Actual hurtbox collision: first enemy stops the lunge and takes matching damage.
	for tier in range(3):
		await reset()
		enemy.position = p.position+Vector2(155,0)
		await button(&"weapon_skill",true)
		if tier==0:await button(&"weapon_skill",false)
		elif tier==1:
			await hold_until(1.02)
			await button(&"weapon_skill",false)
		if tier>0:
			check(await reach(S.SKILL_DASH),"charged stun test reaches lunge before enabling real enemy AI")
			enemy.attack_animation = &"attack2"
			enemy.target = p
			enemy._enter_state(enemy.State.MELEE)
			enemy._elapsed = 0.31
			enemy.set_physics_process(true)
		check(await reach(S.SKILL_IMPACT),"tier %d stops on actual enemy hurtbox"%tier)
		var frozen_attack_clock: float = enemy._elapsed
		check(skill.contact_target == enemy and skill.distance_travelled<skill.lunge_distance,"contact ends travel before full range")
		check(p.spine_anim.assigned_animation == &"saber_skill_5" and p.velocity.x==0,"impact holds skill_5 with no lunge velocity")
		var expected: int = [20,24,32][tier]
		check(enemy.current_health==1000-expected,"tier %d applies exact damage %d once"%[tier,expected])
		check(Engine.time_scale==p.hit_stop_scale,"confirmed skill hit starts configured hit-stop")
		var effect: Dictionary = CombatTime._effects[str(p.get_instance_id())+":hit_stop"]
		check(effect.left<=[0.065,0.075,0.1][tier] and effect.left>=[0.065,0.075,0.1][tier]-0.025,"tier %d hit-stop has its own duration"%tier)
		var target_stun = enemy.get_node_or_null("WeaponSkillStun")
		check((target_stun==null) if tier==0 else (target_stun!=null and target_stun.remaining>0),"tier %d stun rule"%tier)
		if tier>0:
			check(not enemy.hitbox.monitoring and not enemy.is_physics_processing(),"stun disables enemy attack area and AI")
		check(await reach(S.SKILL_RECOVERY),"impact advances into skill_6")
		check(not p.is_skill_damage_immune(),"recovery is vulnerable")
		if tier>0:
			check(Engine.time_scale==0.5 and is_equal_approx(CombatTime.actor_delta(p,0.01),0.02) and CombatTime.actor_delta(enemy,0.01)==0.01,"world slowed while only Player gets normal delta")
			check(p.dodge_cooldown.ignore_time_scale,"Player cooldown is exempt during recovery")
			var clocks := {"player":false,"enemy":false}
			CombatTime.actor_timeout(p,0.15,func():clocks.player=true)
			CombatTime.actor_timeout(enemy,0.15,func():clocks.enemy=true)
			await wait(0.19)
			check(clocks.player and not clocks.enemy,"Player damage timers progress normally while world timers remain slow")
			check(enemy._elapsed == frozen_attack_clock and hud.hp == 100,"stun freezes a running enemy attack and prevents HP damage throughout recovery")
		check(await finished(),"tier %d recovery ends"%tier)
		check(Engine.time_scale==1.0 and CombatTime._actor_exemptions.is_empty() and not p.dodge_cooldown.ignore_time_scale,"recovery restores world speed and timer ownership")
		check(enemy.current_health==1000-expected,"no duplicate damage during hit-stop or recovery")
	# Lunge invulnerability covers direct hits, threshold, HUD damage and bleeding.
	await reset()
	await click(&"weapon_skill")
	check(await reach(S.SKILL_DASH),"immunity test reaches lunge")
	take_hit(99)
	hud.apply_damage(99)
	p.damage.apply_stagger(Vector2.LEFT)
	hud.bleeding_level = 1
	hud._stats._bleed_tick_timer = StatsComponent.BLEED_TICK_INTERVAL
	hud._process(0.01)
	check(hud.hp==100 and not p.damage.is_stunned and skill.is_dashing(),"lunge rejects direct/HUD/bleed damage and stagger")
	hud.clear_all_debuffs()
	await finished()
	check(not p.damage.is_invulnerable and not p.is_skill_damage_immune(),"skill immunity never overwrites or leaks the normal iframe flag")
	# Swept shape must stop at nearest enemy even at high lunge speed.
	await reset()
	var second = load("res://scenes/enemy/spine_enemy.tscn").instantiate()
	scene.add_child(second)
	second.set_physics_process(false)
	second.current_health=1000
	enemy.position=p.position+Vector2(145,0)
	second.position=p.position+Vector2(410,0)
	var old_speed: float = skill.lunge_speed
	skill.lunge_speed=9000
	await click(&"weapon_skill")
	check(await reach(S.SKILL_IMPACT),"swept lunge hits at high speed")
	check(skill.contact_target==enemy and enemy.current_health==980 and second.current_health==1000,"first hurtbox wins; distant second enemy is untouched")
	skill.lunge_speed=old_speed
	second.queue_free()
	await finished()
	# Wall blocks before the enemy; no hit through world collision.
	await reset()
	var wall := StaticBody2D.new()
	wall.position=p.position+Vector2(65,0)
	var node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size=Vector2(10,250)
	node.shape=shape
	wall.add_child(node)
	scene.add_child(wall)
	enemy.position=p.position+Vector2(180,0)
	await frames(2)
	await click(&"weapon_skill")
	check(await reach(S.SKILL_RECOVERY),"world wall ends lunge safely")
	check(enemy.current_health==1000 and skill.distance_travelled<65,"no damage or movement through wall")
	wall.queue_free()
	await finished()
	# Highest priority stagger cancels every vulnerable phase, never leaves stale time effects.
	for phase in [S.SKILL_CHARGE,S.SKILL_RELEASE,S.SKILL_IMPACT,S.SKILL_RECOVERY]:
		await reset()
		if phase in [S.SKILL_IMPACT,S.SKILL_RECOVERY]:enemy.position=p.position+Vector2(155,0)
		await button(&"weapon_skill",true)
		if phase==S.SKILL_RELEASE or phase==S.SKILL_RECOVERY:
			await hold_until(1.02)
			await button(&"weapon_skill",false)
		elif phase==S.SKILL_IMPACT:await button(&"weapon_skill",false)
		check(await reach(phase),"interruption reaches phase %d"%phase)
		hud.hp=70
		p.damage.is_invulnerable=false
		take_hit()
		check(p.damage.is_stunned and p.state_machine.is_in(S.STAGGER) and not skill.is_active(),"stagger interrupts vulnerable phase %d"%phase)
		check(Engine.time_scale==1.0 and CombatTime._actor_exemptions.is_empty() and not p.saber_hitbox._attack_active,"phase %d cleanup restores time, actor and hitbox"%phase)
		await wait(1.1)
		check(p.can_move and not skill.is_active(),"old skill callbacks cannot override stagger recovery")
	# Pause/focus ownership aborts skill rather than replaying a stale charge.
	await reset()
	await button(&"weapon_skill",true)
	var pause = p.get_node("Camera2D/UI_Layer/PauseMenu")
	pause.pause_and_unpause()
	check(get_tree().paused and not skill.is_active(),"pause aborts charge")
	pause.pause_and_unpause()
	await wait(0.3)
	check(not skill.is_active() and p.can_move,"resume does not auto-execute Q held before menu")
	await reset()
	await button(&"weapon_skill",true)
	p.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not skill.is_active(),"focus loss clears charge safely")
	# Existing action commitment and lack of arbitrary stamina charge.
	await reset()
	await click(&"attack")
	await button(&"weapon_skill",true)
	check(p.state_machine.current==S.COMBO and not skill.is_active(),"Q cannot cancel ordinary attack")
	await reset()
	await button(&"guard and deflect",true)
	await button(&"weapon_skill",true)
	check(p.is_guarding and not skill.is_active(),"Q cannot override Defense")
	await reset()
	hud.stamina=0
	await click(&"weapon_skill")
	check(skill.is_active() and hud.stamina==0,"skill adds no unspecified stamina cost or zero-stamina restriction")
	await finished()
	print("SABER SKILL RESULT: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)
