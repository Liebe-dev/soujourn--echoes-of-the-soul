extends RefCounted
## Extracted from playable_adel.gd; `p` is the owning Player.
var p: CharacterBody2D

func _init(player: CharacterBody2D) -> void:
	p = player

func _enter_player_state(state: AdelStateMachine.State) -> void:
	p.attack_ctl._sync_attack_speed()
	if state in [AdelStateMachine.State.STAGGER, AdelStateMachine.State.REST, AdelStateMachine.State.PICKUP, AdelStateMachine.State.DASH, AdelStateMachine.State.CONTACT_REACTION, AdelStateMachine.State.SENTINEL_ENTRY]: p.defense_input.clear_combat_input()
	match state:
		AdelStateMachine.State.SENTINEL_ENTRY:
			p.velocity = Vector2.ZERO
			p._playing_land_anim = false
			p.is_skidding = false
			p.presentation.play(&"idle")
		AdelStateMachine.State.READY: p.presentation.ready_pose(p._ready_final_frame)
		AdelStateMachine.State.DEFENSE:
			p.combat.combo_step = 0
			p.combat.clear_attack_buffer()
			if not p.deflect_slow_motion.is_active: p.defense.begin_guard(p._guard_press_age)
			p._playing_land_anim = false
			p.is_skidding = false
			p.velocity.x = 0.0
		AdelStateMachine.State.DEFENSE_HOLD:
			p._defense_hit_pose_time_left = 0.0
			p.defense_input._show_defense_pose(p.ANIM_DEFENSE)

func _exit_player_state(state: AdelStateMachine.State) -> void:
	match state:
		AdelStateMachine.State.STAGGER: p.stagger_impact.cancel()
		AdelStateMachine.State.SKILL: p.saber_skill.cancel()
		AdelStateMachine.State.ATTACK:
			p._attack_interrupt_token += 1
			p._attack_interrupt_ready = false
			p.combat.interrupt()
			p.saber_hitbox.stop_attack_window()
			p.jump_hitbox.end_attack()
			p.combat.disable_attack_hitbox()
		AdelStateMachine.State.DEFENSE:
			p.velocity.x = 0.0
			p.defense.end_guard()
			p._defense_hit_pose_time_left = 0.0
		AdelStateMachine.State.DASH:
			p.dash.end_dash()
