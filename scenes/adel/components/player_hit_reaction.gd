extends RefCounted
## Extracted from playable_adel.gd; `p` is the owning Player.
var p: CharacterBody2D

func _init(player: CharacterBody2D) -> void:
	p = player

func take_damage(dmg: int, hit_from_global: Vector2 = Vector2.INF) -> void:
	if p.is_skill_finish_frozen() or dmg <= 0 or p.is_skill_damage_immune() or not p.damage.can_take_damage():
		return

	var health = p.vitals

	# A depleted held stance cannot classify another hit before the next physics tick.
	if p.is_guarding and not p.has_action_stamina(): p.defense.end_guard(false)
	var defense_result = p.defense.classify_hit(p.global_position, p.facing_direction, hit_from_global)
	var exhausted := false
	if defense_result != DefenseComponent.HitResult.NONE:
		var action := "deflect" if defense_result == DefenseComponent.HitResult.DEFLECT else "guard"
		exhausted = not p.stats.can_spend_stamina(action)
		health.spend_stamina(action, true)
		# Finish this accepted reaction, but remove protection as soon as energy hits zero.
		if not p.has_action_stamina(): p.defense.end_guard(false)
	match defense_result:
		DefenseComponent.HitResult.DEFLECT:
			health.combat_activity.emit()
			if exhausted:
				_apply_stamina_exhaustion(hit_from_global)
			else:
				var impact_delay = _request_hit_stop(p.deflect_hit_stop_duration)
				p.deflect_slow_motion.start(p.deflect_slow_motion_scale, p.deflect_slow_motion_duration, impact_delay)
				p.defense_input._play_defense_hit_pose(p.ANIM_DEFLECT)
			return
		DefenseComponent.HitResult.GUARD:
			if not exhausted: _request_hit_stop(p.guard_hit_stop_duration)
			if not exhausted:
				p.defense.start_guard_push(p.guard_knockback_distance, p.guard_knockback_duration, -float(p.facing_direction))
				p.defense_input._play_defense_hit_pose(p.ANIM_GUARD)
			dmg = maxi(0, int(round(float(dmg) * p.stats.get_guard_damage_multiplier())))
			if dmg == 0:
				health.combat_activity.emit()
				if exhausted: _apply_stamina_exhaustion(hit_from_global)
				return
	var hit: Dictionary = health.apply_damage(dmg, hit_from_global, exhausted)
	# Damage can synchronously respawn or remove this Player from the tree.
	if hit.get("died", false):
		p.player_blood.clear_blood()
		p.battle_particles.clear_effects()
		p.stagger_impact.cancel()
		var camera = p.get_node_or_null("Camera2D") as Camera2D
		if camera != null and camera.has_method("cancel_hit_stop_zoom"): camera.cancel_hit_stop_zoom()
		p.defense_input.clear_combat_input()
		CombatTime.remove(p)
		p.defense.end_guard()
		if p.is_inside_tree() and not p.is_queued_for_deletion():
			p.deflect_slow_motion.cancel()
			p.state_machine.resume_locomotion()
		return
	if not p.is_inside_tree() or p.is_queued_for_deletion():
		return
	if exhausted:
		_apply_stamina_exhaustion(hit_from_global)
	elif hit.get("staggered", false) and not hit.get("skip_player_stagger", false):
		p.player_blood.add_stagger(int(hit.get("stagger_tier", -1)))
		var direction = Vector2(-float(p.facing_direction), 0.0) if defense_result == DefenseComponent.HitResult.GUARD else p.damage.compute_knockback_dir(hit_from_global, p.facing_direction)
		p.damage.apply_stagger(direction)
		if p.damage.is_stunned: p.battle_particles.add_player_stagger(p.velocity)
	elif hit.get("damage_taken", 0) > 0:
		p.damage.start_invulnerability(DamageComponent.HIT_INVULN_SEC)

func _apply_stamina_exhaustion(hit_from_global: Vector2) -> void:
	# Share the full threshold reaction (push, stun, frames and iframe), without firing an HP threshold.
	p.deflect_slow_motion.cancel()
	var direction = signf(p.global_position.x - hit_from_global.x)
	if is_zero_approx(direction): direction = -float(p.facing_direction)
	# The staggered signal is synchronous; scope the visual override to this call.
	p._applying_stamina_exhaustion = true
	p.damage.apply_stagger(Vector2(direction, 0.0))
	p._applying_stamina_exhaustion = false

func _on_damage_staggered(knockback_velocity: Vector2) -> void:
	var falling_velocity = maxf(p.velocity.y, 0.0)
	p.state_machine.transition(AdelStateMachine.State.KNOCKBACK)
	p.velocity = Vector2(knockback_velocity.x, falling_velocity)
	p._stagger_push_direction = signf(knockback_velocity.x) if not is_zero_approx(knockback_velocity.x) else -float(p.facing_direction)
	p._stagger_distance_left = p.damage.active_knockback_distance
	p._playing_land_anim = false
	_show_stagger_frame(0)
	p.stagger_impact.start(p.get_node_or_null("Camera2D"), p.damage.stagger_duration(), {
		"zoom_enabled": p.stagger_zoom_enabled, "zoom_multiplier": p.stamina_exhaustion_zoom_multiplier if p._applying_stamina_exhaustion else p.stagger_zoom_multiplier,
		"zoom_in_duration": p.stagger_zoom_in_duration, "return_lead": p.stagger_zoom_return_lead,
		"slow_motion_enabled": p.stagger_slow_motion_enabled,
		"slow_motion_scale": p.stagger_slow_motion_scale,
		"slow_motion_duration": p.stagger_slow_motion_duration * p.stamina_exhaustion_slow_motion_duration_multiplier if p._applying_stamina_exhaustion else p.stagger_slow_motion_duration,
	})

func _on_damage_knockback_finished() -> void:
	p.state_machine.transition(AdelStateMachine.State.STUN)
	# Frame 1 begins now; horizontal motion decelerates for the configured tail.
	_show_stagger_frame(1)

func _show_stagger_frame(frame_index: int) -> void:
	if not p.deflect_slow_motion.is_active: p.presentation.stagger(frame_index)

func _on_damage_stagger_recovered() -> void:
	p._stagger_distance_left = 0.0
	p.velocity.x = 0.0
	if p.deflect_slow_motion.is_active:
		p.state_machine.transition(AdelStateMachine.State.DEFLECT_REACTION)
	else:
		p.attack_ctl._play_ready(true)

func _request_hit_stop(duration: float, camera_zoom: bool = true) -> float:
	if not p.hit_stop_enabled or duration <= 0.0: return 0.0
	var accepted = CombatTime.request(p, &"hit_stop", p.hit_stop_scale, duration)
	if accepted > 0.0 and camera_zoom:
		var camera = p.get_node_or_null("Camera2D") as Camera2D
		if camera != null and camera.has_method("play_hit_stop_zoom"): camera.play_hit_stop_zoom()
	return accepted

func _on_saber_hit_confirmed(attack_name: StringName) -> void:
	if attack_name == &"saber_skill": return
	var accepted = _request_hit_stop(p.finisher_hit_stop_duration if attack_name == &"saber_attack_4" else p.attack_hit_stop_duration, false)
	p.hit_slash_vfx.apply_hit_stop(attack_name, accepted)

func _physics_hit_reaction(delta: float) -> void:
	if p.damage.is_stunned:
		var travel = minf(p._stagger_distance_left, p.damage.consume_knockback_distance(delta))
		p.velocity.x = p._stagger_push_direction * travel / maxf(delta, 0.000001)
		p._stagger_distance_left = maxf(p._stagger_distance_left - travel, 0.0)
	else: p.velocity.x = move_toward(p.velocity.x, 0.0, 400.0 * delta)
	p.locomotion.apply_vertical_physics(delta)
	p.move_and_slide()
	if p.damage.is_touched_enemy and p.is_on_floor():
		p.damage.is_touched_enemy = false
		p.state_machine.resume_locomotion()
