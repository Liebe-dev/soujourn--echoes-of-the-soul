extends RefCounted
## Extracted from playable_adel.gd; `p` is the owning Player.
var p: CharacterBody2D

func _init(player: CharacterBody2D) -> void:
	p = player

func cancel_weapon_skill_request() -> void:
	p._skill_requested = false

func request_weapon_skill() -> void:
	if not p.can_use_weapon_skill(): return
	if p._skill_requested or p.saber_skill.is_active() or _weapon_skill_input_blocked(): return
	if not p.state_machine.is_in(AdelStateMachine.State.LOCOMOTION) and not p.state_machine.is_in(AdelStateMachine.State.DASH) and not p.state_machine.is_in(AdelStateMachine.State.DEFENSE) and p.state_machine.current != AdelStateMachine.State.COMBO: return
	p._skill_requested = true
	p.combat.clear_attack_buffer()
	_clear_guard_request()
	_try_consume_weapon_skill()

func release_weapon_skill() -> void:
	cancel_weapon_skill_request()
	p.saber_skill.release()

func _weapon_skill_input_blocked() -> bool:
	return not p.can_use_weapon_skill() or p.saber_skill.is_cooling_down() or p.is_locked or not p.state_machine.movement_enabled or p.damage.is_stunned or p.damage.is_touched_enemy or p.is_sentinel_exit_pending() or p.is_sentinel_entering() or p.rest_ctl.is_campfire_ui_active() or p.get_tree().paused

func _consume_buffered_combat_input() -> void:
	if _try_consume_weapon_skill(): return
	if p._guard_requested: _try_consume_guard()

func _try_consume_weapon_skill() -> bool:
	if not p._skill_requested: return false
	if not Input.is_action_pressed("weapon_skill") or _weapon_skill_input_blocked():
		cancel_weapon_skill_request()
		return false
	# Only a fresh accepted press creates intent; holding Q cannot auto-repeat.
	if p.state_machine.is_in(AdelStateMachine.State.DASH) or p.state_machine.current == AdelStateMachine.State.COMBO: return false
	if not p.state_machine.is_in(AdelStateMachine.State.LOCOMOTION) and not p.state_machine.is_in(AdelStateMachine.State.DEFENSE): return false
	if p.saber_skill.begin(true):
		p._guard_requires_release = Input.is_action_pressed("guard and deflect")
		return true
	return false

func _dash_blocks_defense() -> bool:
	return p.state_machine.is_in(AdelStateMachine.State.DASH)

func _try_begin_guard() -> void:
	if p._guard_requires_release or p._skill_requested or p._guard_requested or p.is_guarding: return
	if (not p.has_action_stamina() and not _dash_blocks_defense()) or p.is_locked or not p.state_machine.movement_enabled or p.damage.is_stunned or p.damage.is_touched_enemy or p.deflect_slow_motion.is_active: return
	if not p.state_machine.is_in(AdelStateMachine.State.LOCOMOTION) and not p.state_machine.is_in(AdelStateMachine.State.DASH) and p.state_machine.current not in [AdelStateMachine.State.COMBO, AdelStateMachine.State.JUMP_LAND] and not p.state_machine.is_in(AdelStateMachine.State.JUMP_ATTACK): return
	p._guard_requested = true
	p._guard_press_age = 0.0
	p.combat.clear_attack_buffer()
	_try_consume_guard()

func _try_consume_guard() -> bool:
	if p._guard_requires_release or p._skill_requested: return false
	if not p._guard_requested or p.is_guarding or not p.has_action_stamina() or p.is_locked or not p.state_machine.movement_enabled or p.damage.is_stunned or p.damage.is_touched_enemy or p.deflect_slow_motion.is_active: return false
	# Hold through dash/skid only; cooldown restricts the next dash, not defense.
	if _dash_blocks_defense(): return false
	if p.state_machine.current == AdelStateMachine.State.COMBO:
		var unlock = p.attack_4_defense_unlock_time if p.combat.combo_step == 4 else p.attack_defense_unlock_time
		if not p._combo_visual_finished and p.spine_anim.current_animation_position + 0.00001 < unlock: return false
		if p._combo_visual_finished and p._defense_lock_left > 0.00001: return false
	elif p.state_machine.current == AdelStateMachine.State.JUMP_LAND:
		if not p._jump_land_visual_finished and p.spine_anim.current_animation_position + 0.00001 < p.jump_attack_land_defense_unlock_time: return false
		if p._jump_land_visual_finished and p._defense_lock_left > 0.00001: return false
	elif not p.state_machine.can_begin_action() or p._defense_lock_left > 0.00001:
		return false
	p.state_machine.transition(AdelStateMachine.State.DEFENSE_HOLD)
	return true

func _clear_guard_request() -> void:
	p._guard_requested = false
	p._guard_press_age = 0.0

func clear_combat_input() -> void:
	if p.saber_skill != null: p.saber_skill.cancel_impact_feedback()
	cancel_weapon_skill_request()
	_clear_guard_request()
	if p.combat != null: p.combat.clear_attack_buffer()
	if p.is_guarding: _end_guard(false)
	if p.saber_skill != null and p.saber_skill.is_active(): p.saber_skill.abort()

func _release_guard_input() -> void:
	p._guard_requires_release = false
	_clear_guard_request()
	if p.is_guarding: _end_guard()

func _end_guard(play_release: bool = true) -> void:
	_clear_guard_request()
	p.defense.end_guard()
	p._defense_hit_pose_time_left = 0.0
	if p.deflect_slow_motion.is_active: return
	if p.state_machine.is_in(AdelStateMachine.State.STAGGER) or p.is_resting: return
	if play_release and not p.is_locked and p.state_machine.movement_enabled: p.attack_ctl._play_ready(true)
	else: p.state_machine.resume_locomotion()

func _update_defense(delta: float) -> void:
	if p.is_guarding and not p.has_action_stamina(): p.defense.end_guard(false)
	if not p.is_guarding:
		# A paid hit may consume the final point: keep its pose/recoil, without protection.
		if p.state_machine.is_in(AdelStateMachine.State.DEFENSE) and not p.deflect_slow_motion.is_active:
			p._defense_hit_pose_time_left = maxf(p._defense_hit_pose_time_left - delta, 0.0)
			if p.is_locked or p.damage.is_stunned or p.damage.is_touched_enemy:
				_end_guard(false)
			elif p._defense_hit_pose_time_left <= 0.0 and not p.defense.guard_push_active:
				_end_guard()
		return
	# Poll release before movement locks; also recover when focus/input is lost.
	if p.damage.is_stunned or p.damage.is_touched_enemy or p.is_resting or p.is_locked:
		_end_guard(false)
		return
	if not Input.is_action_pressed("guard and deflect"):
		_end_guard()
		return
	p.defense.sync_press_age(p._guard_press_age)
	if p.deflect_slow_motion.is_active:
		return
	p._defense_hit_pose_time_left = maxf(p._defense_hit_pose_time_left - delta, 0.0)
	if p._defense_hit_pose_time_left <= 0.0 and not p.defense.guard_push_active and p.state_machine.current != AdelStateMachine.State.DEFENSE_HOLD:
		p.state_machine.transition(AdelStateMachine.State.DEFENSE_HOLD)

func _play_defense_hit_pose(clip: StringName) -> void:
	if p.deflect_slow_motion.is_active and clip != p.ANIM_DEFLECT:
		return
	# Reaction timing is separate from the window measured since the original press.
	p._defense_hit_pose_time_left = maxf(p.defense_hit_pose_duration, 0.05)
	p.state_machine.transition(AdelStateMachine.State.DEFLECT_REACTION if clip == p.ANIM_DEFLECT else AdelStateMachine.State.GUARD_REACTION)
	_show_defense_pose(clip)

func _show_defense_pose(clip: StringName) -> void:
	p.presentation.hold(clip)

func _on_deflect_slow_motion_finished() -> void:
	p._defense_hit_pose_time_left = 0.0
	if p.damage.is_stunned:
		p.hit_ctl._show_stagger_frame(0 if p.damage.is_knocking_back else 1)
		return
	if p.damage.is_touched_enemy or p.is_resting:
		return
	if p.is_locked:
		_end_guard(false)
		return
	if p.is_guarding and p.has_action_stamina() and Input.is_action_pressed("guard and deflect"):
		if p.defense.guard_push_active:
			p.state_machine.transition(AdelStateMachine.State.GUARD_REACTION)
			_show_defense_pose(p.ANIM_GUARD)
		else:
			p.state_machine.transition(AdelStateMachine.State.DEFENSE_HOLD)
	else:
		_end_guard()

func consume_skill_finish_input(action: StringName, direction: float) -> void:
	if p.get_tree().paused or p.is_locked or p.damage.is_stunned or p.is_sentinel_exit_pending() or p.is_sentinel_entering() or p.rest_ctl.is_campfire_ui_active(): return
	if not p.state_machine.can_begin_action(): return
	match action:
		&"attack": p.attack_ctl._handle_attack_input()
		&"weapon_skill":
			if p.saber_skill.begin():
				p._guard_requires_release = Input.is_action_pressed("guard and deflect")
				if not Input.is_action_pressed("weapon_skill"): p.saber_skill.release()
		&"guard and deflect":
			if Input.is_action_pressed("guard and deflect"):
				p._guard_requires_release = false
				_try_begin_guard()
		&"dodge": p.move_ctl._perform_dash(direction)
		&"jump": p.locomotion.perform_buffered_jump()
		&"soul_heal": p.vitals.begin_flask_use()
