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
	print("HFSM ", "PASS " if ok else "FAIL ", label)
func button(action: StringName, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)
	await frames(1)
func click(action: StringName) -> void:
	await button(action, true)
	await button(action, false)
func _run() -> void:
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	var p = scene.get_node("PlayableAdel")
	# Presentation is covered by stagger_impact_validation; isolate combat clocks here.
	p.stagger_zoom_enabled = false
	p.stagger_slow_motion_enabled = false
	p.hit_stop_enabled = false
	scene.get_node("Enemy").set_physics_process(false)
	await frames(65)
	var hud = p.get_node("Camera2D/hud")
	var fsm = p.state_machine
	var S = AdelStateMachine.State
	check(fsm.current == S.GROUNDED and fsm.is_in(S.LOCOMOTION) and not fsm.is_in(S.ATTACK), "grounded is a locomotion child")
	await button(&"guard and deflect", true)
	check(fsm.current == S.DEFENSE_HOLD and fsm.is_in(S.DEFENSE) and not p.can_move, "guard enters defense hierarchy and owns movement")
	await wait(0.34)
	var duration: float = p.holding_duration
	p.take_damage(20, p.global_position + Vector2(80, 0))
	check(fsm.current == S.GUARD_REACTION and p.holding_duration >= duration and p.is_guarding, "sibling defense transition does not exit parent or reset timing")
	await wait(0.25)
	check(fsm.current == S.DEFENSE_HOLD, "reaction timeout returns to hold")
	await button(&"guard and deflect", false)
	check(fsm.current == S.READY and fsm.is_in(S.LOCOMOTION) and not p.is_guarding, "release exits defense parent and enters interruptible ready")
	await click(&"attack")
	check(fsm.current == S.COMBO and fsm.is_in(S.ATTACK) and p.is_doing_action, "attack input enters combo child")
	await wait(0.24)
	await click(&"attack")
	check(p.combat.attack_queued, "input queues real combo")
	p.damage.is_invulnerable = false
	hud.hp = 70
	p.take_damage(20, p.global_position + Vector2(80, 0))
	check(fsm.current == S.KNOCKBACK and fsm.is_in(S.STAGGER), "threshold preempts attack into stagger knockback")
	check(not p.combat.attack_queued and not p.saber_hitbox._attack_active and not p.is_doing_action and not p._attack_interrupt_ready, "attack parent exit cleans queue, hitbox and callback generation")
	await wait(p.stagger_knockback_duration + 0.06)
	check(fsm.current == S.STUN and p.spine_rig.get_node("TestAttackSprite").frame == 1, "stagger sibling switches to stun frame")
	await click(&"attack")
	check(fsm.current == S.STUN and not p.saber_hitbox._attack_active, "stun rejects attacks")
	await wait(p.stagger_stun_duration + 0.08)
	check(fsm.current == S.READY and p.can_move and p.spine_rig.get_node("TestAttackSprite").frame == 2, "stagger exit restores frame-2 ready")
	await click(&"attack")
	check(fsm.current == S.COMBO, "fresh attack succeeds after interrupted combo and stagger")
	p.enter_rest(false)
	check(fsm.current == S.REST and p.is_resting and not p.is_doing_action and not p.saber_hitbox._attack_active, "rest preempts attack with cleanup")
	await wait(0.6)
	check(fsm.current == S.REST and p.spine_anim.assigned_animation == &"idle", "old attack callbacks cannot override rest")
	p.exit_rest()
	check(fsm.is_in(S.LOCOMOTION) and p.can_move and not p.is_resting, "rest exit restores locomotion")
	p.is_locked = true
	await click(&"attack")
	await button(&"guard and deflect", true)
	check(fsm.is_in(S.LOCOMOTION) and not p.is_guarding and not p.is_doing_action and not p.can_move, "external map lock is honored by action requests")
	await button(&"guard and deflect", false)
	p.is_locked = false
	p.can_move = false
	await click(&"attack")
	check(not p.is_doing_action and not p.can_move, "legacy movement lock cannot be bypassed by attack")
	p.can_move = true
	check(p.can_move, "legacy unlock restores locomotion permission")
	await frames(10)
	p.play_pickup_animation()
	check(fsm.current == S.PICKUP and not p.can_move, "pickup owns exclusive action")
	await click(&"attack")
	check(fsm.current == S.PICKUP, "pickup rejects attack override")
	p.enter_rest(false)
	p.exit_rest()
	await button(&"move_right", true)
	await click(&"dodge")
	check(fsm.current == S.DASH_ACTIVE and fsm.is_in(S.DASH) and p.dash.is_dodging, "dash enters active child")
	await button(&"move_right", false)
	p.enter_rest(false)
	check(not p.dash.is_dodging and not p.damage.is_invulnerable and not p._dash_tween.is_running(), "dash parent exit cancels tween and invulnerability")
	await wait(0.6)
	check(fsm.current == S.REST and p.velocity == Vector2.ZERO, "cancelled dash cannot move or replace resting animation later")
	p.exit_rest()
	await wait(1.1)
	await click(&"jump")
	check(fsm.current == S.AIRBORNE and fsm.is_in(S.LOCOMOTION), "jump updates locomotion hierarchy")
	await button(&"move_down", true)
	await click(&"attack")
	await button(&"move_down", false)
	check(fsm.is_in(S.JUMP_ATTACK) and fsm.is_in(S.ATTACK), "air attack enters nested attack hierarchy")
	await wait(0.18)
	check(fsm.current == S.JUMP_FALL or fsm.current == S.JUMP_LAND, "jump attack progresses from hang to fall/landing")
	await wait(1.2)
	check(fsm.is_in(S.LOCOMOTION) and p.can_move and not p.is_doing_action, "jump attack landing returns to controllable locomotion")
	hud.hp = 100
	hud.clear_all_debuffs()
	hud.restore_stagger_thresholds()
	p.damage.is_invulnerable = false
	await button(&"guard and deflect", true)
	await wait(0.12)
	p.take_damage(20, p.global_position + Vector2(80, 0))
	await button(&"guard and deflect", false)
	p.is_locked = true
	await wait(p.deflect_slow_motion_duration + 0.04)
	check(fsm.is_in(S.LOCOMOTION) and not p.is_doing_action and not p.can_move, "pulse expiry under map lock clears released defense ownership")
	p.is_locked = false
	await click(&"attack")
	check(fsm.current == S.COMBO, "map unlock after pulse restores attack without orphaned defense state")
	p.enter_rest(false)
	p.exit_rest()
	# Each rig has a private library; variants cannot alter another player/source.
	var other = load("res://scenes/adel/playable_adel.tscn").instantiate()
	p._play_ready(true)
	var other_anim = other.get_node("SpinePivot/SpineRig/AnimationPlayer")
	check(other_anim.get_animation(&"saber_ready").track_get_key_count(4) == 3, "ready variant does not mutate another instance's source clip")
	other.free()
	print("HFSM RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
