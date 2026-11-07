extends RefCounted
## Extracted from playable_adel.gd; `p` is the owning Player.
const EnemyDebugSettings = preload("res://scenes/enemy/enemy_debug_settings.gd")
var p: CharacterBody2D

func _init(player: CharacterBody2D) -> void:
	p = player

func _physics_defense(delta: float) -> void:
	p._update_facing(Input.get_axis("move_left", "move_right"))
	p.velocity.x = p.defense.consume_guard_push(delta)
	p.locomotion.apply_vertical_physics(delta)
	p.move_and_slide()
	p.locomotion.update_ground_state()

func _physics_locomotion(delta: float) -> void:
	p.locomotion.update_run_state(delta)

	var direction := Input.get_axis("move_left", "move_right")

	if p.dash.is_dodging:
		p.velocity.y = 0
	else:
		if p.dash.can_dash(direction, p.is_on_floor()):
			_perform_dash(direction)
			if p.dash.is_dodging:
				_physics_dash(delta)
				return

		if p.can_move and not p.dash.is_dodging:
			p.locomotion.apply_horizontal_movement(direction, delta)
			p._update_facing(direction)
			p._update_ground_animation(direction)
	if not p.dash.is_dodging:
		p.locomotion.handle_jump()
		p.locomotion.apply_vertical_physics(delta)

	p.move_and_slide()
	if not p.state_machine.is_in(AdelStateMachine.State.DASH):
		p._update_air_animation()
	p.locomotion.update_ground_state()
	if p.state_machine.is_in(AdelStateMachine.State.LOCOMOTION):
		if p.state_machine.current != AdelStateMachine.State.READY or direction != 0.0 or not p.is_on_floor():
			p.state_machine.resume_locomotion()

	for i in p.get_slide_collision_count():
		var collision = p.get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("Enemy"):
			if collider is EnemyBase and EnemyDebugSettings.is_ai_disabled(): continue
			if p.dash.is_dodging or p.damage.is_invulnerable or p.damage.is_touched_enemy:
				continue
			p.hit_ctl.take_damage(p.ENEMY_CONTACT_DAMAGE, collider.global_position)
			break

func _physics_dash(delta: float) -> void:
	if p.dash.physics_update(delta):
		# The DASH parent exit starts the cooldown before dispatching queued input.
		p.state_machine.resume_locomotion()
		p.defense_input._consume_buffered_combat_input()

func _perform_dash(dash_direction: float) -> void:
	if not p.dash.can_start(dash_direction, p.is_on_floor()) or not p.has_action_stamina() or p.is_sentinel_exit_pending() or p.is_sentinel_entering(): return
	if p.combat.is_jump_attack_landing: p.attack_ctl._cancel_jump_attack_land()
	if p.dash.start_dash(dash_direction, p.is_on_floor(), p.facing_direction): p._playing_land_anim = false

func _on_locomotion_jumped() -> void:
	if p.state_machine.is_in(AdelStateMachine.State.LOCOMOTION): p.state_machine.resume_locomotion()
	p.dash.reset_air_dash()
	p._play_jump_start()

func _on_locomotion_landed() -> void:
	if p.is_sentinel_entering() or p.saber_skill.is_active(): return
	p.dash.reset_air_dash()
	p.combat.has_air_comboed = false
	if p.is_guarding or p.deflect_slow_motion.is_active:
		return
	if p.state_machine.current == AdelStateMachine.State.READY:
		return
	if p.combat.is_jump_attack_landing or p.combat.is_jump_attacking:
		return
	p._play_jump_land()

func _setup_enemy_passthrough() -> void:
	# Body collision stays off before, during, and after every dash.
	p.set_collision_mask_value(p.ENEMY_COLLISION_LAYER, false)
	p.get_tree().node_added.connect(_exclude_enemy_body)
	_exclude_existing_enemy_bodies(p.get_tree().root)

func _exclude_existing_enemy_bodies(node: Node) -> void:
	_exclude_enemy_body(node)
	for child in node.get_children():
		_exclude_existing_enemy_bodies(child)

func _exclude_enemy_body(node: Node) -> void:
	var body := node as CharacterBody2D
	if body == null or body == p or body.is_in_group("Player"):
		return
	var enemy_layer = 1 << (p.ENEMY_COLLISION_LAYER - 1)
	# The damage API also identifies legacy enemies still on the world layer.
	if (body.collision_layer & enemy_layer) == 0 and not body.is_in_group("Enemy") and not body.has_method("take_damage"):
		return
	# Both bodies ignore each other; their Area2D combat hitboxes remain active.
	p.add_collision_exception_with(body)
	body.add_collision_exception_with(p)
