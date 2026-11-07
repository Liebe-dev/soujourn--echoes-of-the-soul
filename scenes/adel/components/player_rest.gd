extends RefCounted
## Extracted from playable_adel.gd; `p` is the owning Player.
var p: CharacterBody2D

func _init(player: CharacterBody2D) -> void:
	p = player

func begin_campfire_ui(owner: Node) -> bool:
	if is_campfire_ui_active() or p.get_tree().paused or not p.state_machine.can_begin_action(): return false
	p._campfire_ui_owner = owner
	p._campfire_cursor_ready = false
	var hud = p._find_hud()
	if hud != null and hud.has_method("set_campfire_hidden"): hud.set_campfire_hidden(true)
	refresh_gameplay_cursor()
	return true

func is_campfire_ui_active() -> bool:
	return is_instance_valid(p._campfire_ui_owner)

func is_in_rest_state() -> bool:
	return p.state_machine.current == AdelStateMachine.State.REST

func set_campfire_cursor_ready(owner: Node, ready: bool) -> void:
	if p._campfire_ui_owner != owner: return
	p._campfire_cursor_ready = ready
	refresh_gameplay_cursor(ready)

func end_campfire_ui(owner: Node) -> void:
	if p._campfire_ui_owner != owner: return
	p._campfire_ui_owner = null
	p._campfire_cursor_ready = false
	var hud = p._find_hud()
	if hud != null and hud.has_method("set_campfire_hidden"): hud.set_campfire_hidden(false)
	# Scene removal can run after another screen has selected its cursor mode.
	var scene = p.get_tree().current_scene if p.is_inside_tree() else null
	if scene != null and (scene == p or scene.is_ancestor_of(p)): refresh_gameplay_cursor()

func refresh_gameplay_cursor(center_mouse: bool = false) -> void:
	if not p.is_inside_tree(): return
	if is_campfire_ui_active():
		CursorPolicy.set_visible(p.get_viewport(), p._campfire_cursor_ready, center_mouse)
		return
	var visible_menu := false
	for path in ["Camera2D/UI_Layer/master_menu", "Camera2D/UI_Layer/PauseMenu"]:
		var menu = p.get_node_or_null(path) as Control
		visible_menu = visible_menu or (menu != null and menu.visible)
	CursorPolicy.set_visible(p.get_viewport(), visible_menu, center_mouse)

func prepare_to_exit_rest() -> void:
	# Keep Rest ownership through the exit fade, but restore position/camera now.
	p.global_position = p._position_before_rest
	p.velocity = Vector2.ZERO
	p.presentation.play(&"idle")
	snap_feet_to_floor()

func enter_rest(face_left: bool) -> void:
	p._defense_lock_left = 0.0
	p.defense_input.clear_combat_input()
	CombatTime.remove(p)
	p.deflect_slow_motion.cancel()
	p._position_before_rest = p.global_position
	p.state_machine.transition(AdelStateMachine.State.REST)
	p.velocity = Vector2.ZERO
	p._playing_land_anim = false
	p._set_facing_direction(-1 if face_left else 1)
	p.presentation.play(&"idle")

func play_rest_animation() -> void:
	p.spine_anim.play("RESET", 0.0, 1.0, true)
	p.spine_anim.advance(0) 
	p.spine_anim.play("rest", 0.0)

func exit_rest() -> void:
	p.state_machine.resume_locomotion()
	p.velocity = Vector2.ZERO
	p.global_position = p._position_before_rest
	snap_feet_to_floor()

func restore_checkpoint_state(saved_position: Vector2, face_left: bool, keep_resting: bool = false) -> void:
	p.player_blood.clear_blood()
	p.battle_particles.clear_effects()
	if p.damage != null: p.damage.reset()
	p.vitals.cancel_transients()
	p.end_sentinel()
	# exit_rest restores this anchor; update it before leaving the old state.
	p._position_before_rest = saved_position
	p.global_position = saved_position
	if keep_resting:
		enter_rest(face_left)
	else:
		exit_rest()
		p._set_facing_direction(-1 if face_left else 1)
		p.presentation.play(&"idle")
	p.velocity = Vector2.ZERO
	if p.saber_skill != null: p.saber_skill.reset_cooldown()
	snap_feet_to_floor()

func snap_feet_to_floor(max_drop: float = 96.0) -> void:
	var col = p.get_node("CollisionShape2D") as CollisionShape2D
	if col == null or col.shape == null:
		return
	var half_h := _capsule_half_height(col)
	var feet := Vector2(col.global_position.x, col.global_position.y + half_h)
	var space = p.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		feet + Vector2(0, -4.0),
		feet + Vector2(0, max_drop)
	)
	query.collision_mask = p.collision_mask
	query.exclude = [p.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	p.global_position.y += hit.position.y - feet.y

func play_pickup_animation() -> void:
	if not p.is_on_floor() or not p.state_machine.can_begin_action(): return
	p.state_machine.transition(AdelStateMachine.State.PICKUP)
	p.velocity.x = 0.0
	p.presentation.play(&"loot")

func _capsule_half_height(col: CollisionShape2D) -> float:
	var capsule := col.shape as CapsuleShape2D
	if capsule == null:
		return 32.0
	var scale_y := col.global_transform.get_scale().y
	return capsule.height * 0.5 * scale_y
