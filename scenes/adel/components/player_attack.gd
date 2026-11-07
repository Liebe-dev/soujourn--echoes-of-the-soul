extends RefCounted
## Extracted from playable_adel.gd; `p` is the owning Player.
var p: CharacterBody2D

func _init(player: CharacterBody2D) -> void:
	p = player

func _handle_attack_input() -> void:
	if p.is_sentinel_entering() or p._guard_requested or p._skill_requested or p.is_sentinel_exit_pending(): return
	p.combat.attack_buffer_duration = p.attack_input_buffer
	if p.combat.should_cancel_jump_attack_land():
		_cancel_jump_attack_land()
	match p.combat.handle_attack_input(p.is_doing_action):
		CombatComponent.AttackAction.START_JUMP_ATTACK: _play_jump_attack()
		CombatComponent.AttackAction.START_COMBO: _play_combo_step()
		CombatComponent.AttackAction.QUEUE_COMBO:
			if p._attack_interrupt_ready: _advance_queued_combo()

func _play_combo_step() -> void:
	p._combo_visual_finished = false
	p._defense_lock_left = p.attack_4_defense_unlock_time if p.combat.combo_step == 4 else p.attack_defense_unlock_time
	p.jump_hitbox.end_attack()
	var attack_direction: float = Input.get_axis("move_left", "move_right")
	if attack_direction != 0.0:
		p._update_facing(attack_direction)

	p.state_machine.transition(AdelStateMachine.State.COMBO)
	_sync_attack_speed()
	p.velocity.x = 0
	p._playing_land_anim = false 
	p.is_skidding = false
	p.velocity.x = p.facing_direction * 150.0 if p.is_on_floor() else 0.0

	var attack_animation: StringName = p.combat.get_attack_anim_name()
	p.combat.arm_air_attack_pause(p.presentation.sprite_frame_time(attack_animation, 1) if p.combat.combo_step <= 3 else -1.0, p.air_attack_frame_pause_duration)
	p.spine_anim.play(attack_animation)
	p.saber_hitbox.play_attack_window(attack_animation, p.combat.get_combo_damage())
	_arm_attack_interrupt()

func _advance_queued_combo() -> void:
	if p.is_sentinel_entering() or p._guard_requested or p._skill_requested or p.is_sentinel_exit_pending(): return
	p._attack_interrupt_token += 1
	p._attack_interrupt_ready = false

	if p.combat.on_attack_anim_finished() == CombatComponent.AttackAction.START_COMBO:
		_play_combo_step()

func _cancel_combo_for_movement(direction: float) -> void:
	p.state_machine.resume_locomotion()
	p._combo_reset_timer = 0.3
	p._update_facing(direction)
	p._update_ground_animation(direction)

func _arm_attack_interrupt() -> void:
	p._attack_interrupt_token += 1
	p._attack_interrupt_ready = false

func _tick_attack_interrupt() -> void:
	if p.state_machine.current != AdelStateMachine.State.COMBO or p._attack_interrupt_ready: return
	var interrupt_time: float = p.ATTACK_INTERRUPT_TIME
	if p.combat.combo_step == 4:
		interrupt_time = p.ATTACK_4_INTERRUPT_TIME
	if p.spine_anim.current_animation_position + 0.00001 >= interrupt_time:
		_on_attack_interrupt_ready(p._attack_interrupt_token, p.combat.get_attack_anim_name())

func _on_attack_interrupt_ready(
	token: int,
	attack_animation: StringName
) -> void:
	if token != p._attack_interrupt_token:
		return

	if p.state_machine.current != AdelStateMachine.State.COMBO:
		return

	if not p.is_doing_action:
		return

	p._attack_interrupt_ready = true
	if p.combat.attack_queued:
		_advance_queued_combo()
		return

	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0 and not p._guard_requested and not p._skill_requested:
		_cancel_combo_for_movement(direction)

func _reset_combo() -> void:
	p.combat.reset_combo_if_idle(p.is_doing_action)

func _play_jump_attack() -> void:
	# Switching within ATTACK must also invalidate the preceding combo swing.
	p._attack_interrupt_token += 1
	p._attack_interrupt_ready = false
	p.saber_hitbox.stop_attack_window()
	p.combat.disable_attack_hitbox()
	p.jump_hitbox.begin_attack(p.jump_attack_damage)
	p.combat.start_jump_attack(p.spine_anim.get_animation(&"jump_attack(air)").length, true)
	p.state_machine.transition(AdelStateMachine.State.JUMP_HANG)
	p.velocity = Vector2.ZERO
	p.presentation.play(&"jump_attack(air)")

func _play_jump_attack_land() -> void:
	p._jump_land_visual_finished = false
	p._defense_lock_left = p.jump_attack_land_defense_unlock_time
	p.combat.begin_jump_attack_land()
	p.state_machine.transition(AdelStateMachine.State.JUMP_LAND)
	p._playing_land_anim = false
	p.spine_anim.play("jump_attack(land)")
	p.jump_hitbox.set_damage_window(p.jump_attack_landing_active_time > 0.0)
	p.jump_hitbox.sample_damage()

func _cancel_jump_attack_land() -> void:
	p.combat.cancel_jump_attack_land()
	p.state_machine.resume_locomotion()

func _physics_attack(delta: float) -> void:
	if p.combat.is_jump_attack_landing:
		p.combat.jump_attack_land_timer += delta * p.get_attack_speed_multiplier()
		p.jump_hitbox.set_damage_window(p.combat.jump_attack_land_timer < minf(p.jump_attack_landing_active_time, CombatComponent.JUMP_ATTACK_LAND_UNLOCK))
		if p.combat.is_jump_attack_land_unlocked() and p.can_move and not p._guard_requested:
			p.move_ctl._physics_locomotion(delta)
			return
	var direction := Input.get_axis("move_left", "move_right")
	if p._attack_interrupt_ready and p.state_machine.current == AdelStateMachine.State.COMBO and direction != 0.0 and not p.combat.attack_queued and not p._guard_requested and not p._skill_requested:
		_cancel_combo_for_movement(direction)
		p.move_ctl._physics_locomotion(delta)
		return
	_physics_locked(delta)
	if p.state_machine.is_in(AdelStateMachine.State.JUMP_ATTACK):
		p.state_machine.transition(AdelStateMachine.State.JUMP_HANG if p.combat.is_jump_attack_hanging else AdelStateMachine.State.JUMP_FALL)

func _physics_locked(delta: float) -> void:
	if p.combat.tick_air_attack_pause(p.spine_anim.current_animation_position, delta):
		p.velocity.y = 0.0
	elif not p.combat.apply_combat_air_physics(delta, p.air_attack_fall_speed_multiplier):
		p.locomotion.apply_vertical_physics(delta)
	if p.combat.is_jump_attacking:
		p.jump_hitbox.set_damage_window(not p.combat.is_jump_attack_hanging)
	p.velocity.x = move_toward(p.velocity.x, 0.0, p.locomotion.GROUND_FRICTION * delta)
	p.move_and_slide()
	if p.combat.is_jump_attacking or p.combat.is_jump_attack_landing:
		# Sample the last flight contact before switching to the landing window.
		p.jump_hitbox.sample_damage(p.combat.is_jump_attacking and p.is_on_floor())
	if p.is_on_floor() and p.combat.is_jump_attacking: _play_jump_attack_land()

func _on_spine_anim_finished(anim_name: StringName) -> void:
	if p.is_sentinel_entering() or p.saber_skill.is_active(): return
	if p.state_machine.is_in(AdelStateMachine.State.DEFENSE) or p.deflect_slow_motion.is_active or p.state_machine.is_in(AdelStateMachine.State.STAGGER): return
	if anim_name == &"jump_attack(air)" and p.combat.is_jump_attacking:
		p.combat.finish_jump_attack_hang()
		return
	if anim_name == "jump_attack(land)" and p.state_machine.current == AdelStateMachine.State.JUMP_LAND:
		p._jump_land_visual_finished = true
		p._defense_lock_left = maxf(p.jump_attack_land_defense_unlock_time - p.spine_anim.get_animation(anim_name).length, 0.0)
		if p.defense_input._try_consume_guard(): return
		_play_ready()
	elif anim_name == p.ANIM_JUMP_START and not p.is_on_floor():
		p.presentation.play(p.ANIM_JUMP_AIR)
	elif anim_name == p.ANIM_JUMP_LAND:
		p._playing_land_anim = false
		p._update_ground_animation(Input.get_axis("move_left", "move_right"))
	elif anim_name == "skid":
		p.is_skidding = false
		p._update_ground_animation(Input.get_axis("move_left", "move_right"))
	elif anim_name == "loot" and p.state_machine.current == AdelStateMachine.State.PICKUP:
		p.state_machine.resume_locomotion()
		p._update_ground_animation(Input.get_axis("move_left", "move_right"))
	elif anim_name == "saber_ready" and p.state_machine.current == AdelStateMachine.State.READY:
		p.state_machine.resume_locomotion()
		p.presentation.play(&"idle")
	elif anim_name.begins_with(p.combat.equipped_weapon.animation_prefix + "_attack_") and p.state_machine.current == AdelStateMachine.State.COMBO:
		p._combo_visual_finished = true
		var unlock = p.attack_4_defense_unlock_time if p.combat.combo_step == 4 else p.attack_defense_unlock_time
		p._defense_lock_left = maxf(unlock - p.spine_anim.get_animation(anim_name).length, 0.0)
		if p.defense_input._try_consume_guard(): return
		p._attack_interrupt_token += 1
		p._attack_interrupt_ready = false
		match p.combat.on_attack_anim_finished():
			CombatComponent.AttackAction.START_COMBO: _play_combo_step()
			CombatComponent.AttackAction.FINISH_COMBO:
				_play_ready()
				p._combo_reset_timer = 0.4

func _sync_attack_speed() -> void:
	var normal_attack = p.state_machine.current in [AdelStateMachine.State.COMBO, AdelStateMachine.State.JUMP_HANG, AdelStateMachine.State.JUMP_FALL, AdelStateMachine.State.JUMP_LAND]
	var rate = p.get_attack_speed_multiplier() if normal_attack else 1.0
	if is_equal_approx(rate, p._attack_animation_rate): return
	# Preserve other playback-speed owners; remove only our own previous factor.
	var ratio = rate / p._attack_animation_rate
	p.spine_anim.speed_scale *= ratio
	p.saber_hitbox.hitbox_animation.speed_scale *= ratio
	p._attack_animation_rate = rate

func _play_ready(final_frame_only: bool = false) -> void:
	p._ready_final_frame = final_frame_only
	if p.state_machine.current == AdelStateMachine.State.READY:
		p.presentation.ready_pose(final_frame_only)
	else:
		p.state_machine.transition(AdelStateMachine.State.READY)
