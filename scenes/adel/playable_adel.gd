extends CharacterBody2D
@onready var dodge_cooldown = $DodgeCooldown
@onready var spine_rig = $SpinePivot/SpineRig
@onready var spine_anim = $SpinePivot/SpineRig/AnimationPlayer
@onready var spine_pivot = $SpinePivot
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var saber_hitbox: SaberHitbox = $WeaponPivot/SaberHitbox
@onready var jump_hitbox: JumpAttackHitbox = $WeaponPivot/JumpAttackHitbox
@onready var weapon: WeaponData = $WeaponHolder/Saber
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

@export_group("Jump Attack")
@export_range(0, 10000, 1, "or_greater") var jump_attack_damage: int = 20
@export_range(0.0, 1.0, 0.01, "or_greater") var jump_attack_landing_active_time: float = 0.15

@export_group("Stagger Threshold")
@export_range(0.0, 500.0, 1.0, "or_greater") var stagger_knockback_distance: float = 72.0
@export_range(0.01, 2.0, 0.01, "or_greater") var stagger_knockback_duration: float = 0.3
@export_range(0.0, 5.0, 0.01, "or_greater") var stagger_stun_duration: float = 0.45

@export_group("Defense")
@export_range(0.0, 1.0, 0.01) var deflect_window: float = 0.2
@export_range(0.05, 1.0, 0.01, "or_greater") var defense_hit_pose_duration: float = 0.2
@export_range(0.05, 1.0, 0.05) var deflect_slow_motion_scale: float = 0.6
@export_range(0.01, 1.0, 0.01, "or_greater") var deflect_slow_motion_duration: float = 0.2

@export_group("Guard Knockback")
@export_range(0.0, 500.0, 1.0, "or_greater") var guard_knockback_distance: float = 50.0
@export_range(0.01, 2.0, 0.01, "or_greater") var guard_knockback_duration: float = 0.2

@export_group("Stamina")
@export_range(0.0, 1000.0, 1.0, "or_greater") var dash_stamina_cost: float = 20.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var guard_stamina_cost: float = 20.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var deflect_stamina_cost: float = 20.0
@export_range(0.0, 10.0, 0.05, "or_greater") var stamina_regen_delay: float = 1.5
@export_range(0.0, 1000.0, 1.0, "or_greater") var stamina_regen_per_second: float = 28.0

const ANIM_DEFENSE: StringName = &"saber_defense"
const ANIM_DEFLECT: StringName = &"saber_deflect"
const ANIM_GUARD: StringName = &"saber_guard"
const ANIM_STAGGER: StringName = &"saber_stagger"
const ENEMY_COLLISION_LAYER := 3
const ANIM_JUMP_START := " jump_start"
const ANIM_JUMP_AIR := "jump_air (fall)"
const ANIM_JUMP_LAND := "jump_land"
const DEBUG_DAMAGE_AMOUNT := 10
const KNOCKBACK_FORCE := 500
const ENEMY_CONTACT_DAMAGE := 1
const ATTACK_INTERRUPT_TIME := 0.40
const ATTACK_4_INTERRUPT_TIME := 0.55
signal player_attacked

var presentation: AdelAnimationComponent
var locomotion: LocomotionComponent
var combat: CombatComponent
var damage: DamageComponent
var _defense_hit_pose_time_left: float = 0.0
var deflect_slow_motion: DeflectSlowMotion
var defense: DefenseComponent
var dash: DashComponent
var _attack_interrupt_ready: bool = false
var _attack_interrupt_token: int = 0

var state_machine: AdelStateMachine
var ghost_trail: AdelGhostTrail
var _external_movement_enabled := true
var _external_lock := false
# Compatibility properties for map scripts and SaveManager; action ownership is HFSM.
var can_move: bool:
	get:
		return state_machine.can_move() if state_machine != null else _external_movement_enabled
	set(value):
		_external_movement_enabled = value
		if state_machine != null: state_machine.movement_enabled = value
var is_locked: bool:
	get:
		return state_machine.externally_locked if state_machine != null else _external_lock
	set(value):
		_external_lock = value
		if state_machine != null: state_machine.externally_locked = value
var is_resting: bool:
	get:
		return state_machine != null and state_machine.is_in(AdelStateMachine.State.REST)
var is_guarding: bool:
	get:
		return defense != null and defense.is_guarding
var holding_duration: float:
	get:
		return defense.holding_duration if defense != null else 0.0
var _position_before_rest: Vector2 = Vector2.ZERO
var _campfire_ui_owner: Node
var _campfire_cursor_ready := false

var facing_direction: int = 1
var is_doing_action: bool:
	get:
		return state_machine != null and state_machine.is_doing_action()
var _stagger_distance_left: float = 0.0
var _stagger_push_direction: float = 1.0
var _dash_info: Dictionary = {}
var _dash_tween: Tween
var _dash_timer := 0.0
var _ready_final_frame := false
var _combo_reset_timer := 0.0
var _playing_land_anim: bool:
	get: return presentation != null and presentation.playing_land
	set(value):
		if presentation != null: presentation.playing_land = value
var is_skidding: bool:
	get: return presentation != null and presentation.skidding
	set(value):
		if presentation != null: presentation.skidding = value

#hàm hệ thống
func _ready() -> void:
	randomize()
	_setup_enemy_passthrough()

	presentation = AdelAnimationComponent.new(self, spine_rig, spine_anim)
	locomotion = LocomotionComponent.new(self)
	locomotion.jumped.connect(_on_locomotion_jumped)
	locomotion.landed.connect(_on_locomotion_landed)

	combat = CombatComponent.new(
		self,
		locomotion,
		weapon,
		$AttackHitbox
	)
	configure_attack_hitbox(combat.equipped_weapon)

	damage = DamageComponent.new(self, stagger_knockback_distance, stagger_knockback_duration, stagger_stun_duration)
	damage.staggered.connect(_on_damage_staggered)
	damage.stagger_recovered.connect(_on_damage_stagger_recovered)
	damage.knockback_finished.connect(_on_damage_knockback_finished)

	deflect_slow_motion = DeflectSlowMotion.new()
	deflect_slow_motion.name = "DeflectSlowMotion"
	add_child(deflect_slow_motion)
	deflect_slow_motion.finished.connect(_on_deflect_slow_motion_finished)
	defense = DefenseComponent.new(deflect_window)
	dash = DashComponent.new(locomotion, dodge_cooldown)

	ghost_trail = AdelGhostTrail.new()
	ghost_trail.name = "GhostTrailComponent"
	add_child(ghost_trail)
	ghost_trail.setup(spine_rig)
	state_machine = AdelStateMachine.new(self)
	state_machine.movement_enabled = _external_movement_enabled
	state_machine.externally_locked = _external_lock
	state_machine.resume_locomotion()
	_configure_stamina()
	spine_anim.animation_finished.connect(_on_spine_anim_finished)
	spine_anim.play("idle")
	refresh_gameplay_cursor()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_take_damage"):
		take_damage(DEBUG_DAMAGE_AMOUNT, global_position + Vector2(80.0, 0.0))
		get_viewport().set_input_as_handled()
		return
	state_machine.handle_input(event)

func _handle_attack_input() -> void:
	if combat.should_cancel_jump_attack_land():
		_cancel_jump_attack_land()
	match combat.handle_attack_input(is_doing_action):
		CombatComponent.AttackAction.START_JUMP_ATTACK: _play_jump_attack()
		CombatComponent.AttackAction.START_COMBO: _play_combo_step()
		CombatComponent.AttackAction.QUEUE_COMBO:
			if _attack_interrupt_ready: _advance_queued_combo()

func _physics_process(delta: float) -> void:
	if _combo_reset_timer > 0.0:
		_combo_reset_timer = maxf(_combo_reset_timer - delta, 0.0)
		if _combo_reset_timer <= 0.0: _reset_combo()
	state_machine.physics_update(delta)

func _physics_hit_reaction(delta: float) -> void:
	if damage.is_knocking_back:
		var travel := minf(_stagger_distance_left, damage.active_knockback_distance * delta / damage.active_knockback_duration)
		velocity.x = _stagger_push_direction * travel / maxf(delta, 0.000001)
		_stagger_distance_left = maxf(_stagger_distance_left - travel, 0.0)
	elif damage.is_stunned: velocity.x = 0.0
	else: velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	locomotion.apply_vertical_physics(delta)
	move_and_slide()
	if damage.is_touched_enemy and is_on_floor():
		damage.is_touched_enemy = false
		damage.is_invulnerable = false
		state_machine.resume_locomotion()

func _physics_defense(delta: float) -> void:
	velocity.x = defense.consume_guard_push(delta)
	locomotion.apply_vertical_physics(delta)
	move_and_slide()
	locomotion.update_ground_state()

func _physics_attack(delta: float) -> void:
	if combat.is_jump_attack_landing:
		combat.jump_attack_land_timer += delta
		jump_hitbox.set_damage_window(combat.jump_attack_land_timer < minf(jump_attack_landing_active_time, CombatComponent.JUMP_ATTACK_LAND_UNLOCK))
		if combat.is_jump_attack_land_unlocked() and can_move:
			_physics_locomotion(delta)
			return
	var direction := Input.get_axis("move_left", "move_right")
	if _attack_interrupt_ready and state_machine.current == AdelStateMachine.State.COMBO and direction != 0.0 and not combat.attack_queued:
		_cancel_combo_for_movement(direction)
		_physics_locomotion(delta)
		return
	_physics_locked(delta)
	if state_machine.is_in(AdelStateMachine.State.JUMP_ATTACK):
		state_machine.transition(AdelStateMachine.State.JUMP_HANG if combat.is_jump_attack_hanging else AdelStateMachine.State.JUMP_FALL)

func _physics_locked(delta: float) -> void:
	if not combat.apply_combat_air_physics(delta): locomotion.apply_vertical_physics(delta)
	if combat.is_jump_attacking:
		jump_hitbox.set_damage_window(not combat.is_jump_attack_hanging)
	velocity.x = move_toward(velocity.x, 0.0, locomotion.GROUND_FRICTION * delta)
	move_and_slide()
	if combat.is_jump_attacking or combat.is_jump_attack_landing:
		# Sample the last flight contact before switching to the landing window.
		jump_hitbox.sample_damage(combat.is_jump_attacking and is_on_floor())
	if is_on_floor() and combat.is_jump_attacking: _play_jump_attack_land()

func _physics_locomotion(delta: float) -> void:
	locomotion.update_run_state(delta)

	var direction := Input.get_axis("move_left", "move_right")

	if dash.is_dodging:
		velocity.y = 0
	else:
		if dash.can_dash(direction, is_on_floor()):
			_perform_dash(direction)

		if can_move and not dash.is_dodging:
			locomotion.apply_horizontal_movement(direction, delta)
			_update_facing(direction)
			_update_ground_animation(direction)
	if not dash.is_dodging:
		locomotion.handle_jump()
		locomotion.apply_vertical_physics(delta)

	move_and_slide()
	if not state_machine.is_in(AdelStateMachine.State.DASH):
		_update_air_animation()
	locomotion.update_ground_state()
	if state_machine.is_in(AdelStateMachine.State.LOCOMOTION):
		if state_machine.current != AdelStateMachine.State.READY or direction != 0.0 or not is_on_floor():
			state_machine.resume_locomotion()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("Enemy"):
			if dash.is_dodging or damage.is_invulnerable or damage.is_touched_enemy:
				continue
			take_damage(ENEMY_CONTACT_DAMAGE, collider.global_position)
			break

func _physics_dash(delta: float) -> void:
	_dash_timer += delta
	velocity.y = 0.0
	move_and_slide()
	locomotion.update_ground_state()
	if state_machine.current == AdelStateMachine.State.DASH_ACTIVE and _dash_timer >= DashComponent.DASH_TWEEN_DURATION:
		velocity.x = 0.0
		damage.is_invulnerable = false
		if _dash_info.is_air: state_machine.resume_locomotion()
		else: state_machine.transition(AdelStateMachine.State.DASH_SKID)
	elif state_machine.current == AdelStateMachine.State.DASH_SKID and _dash_timer >= DashComponent.DASH_SKID_DURATION:
		state_machine.resume_locomotion()

func take_damage(dmg: int, hit_from_global: Vector2 = Vector2.INF) -> void:
	if dmg <= 0 or not damage.can_take_damage():
		return

	var hud := _find_hud()
	if hud == null or not hud.has_method("apply_damage"):
		return

	# A depleted held stance cannot classify another hit before the next physics tick.
	if is_guarding and not has_action_stamina(): defense.end_guard(false)
	var defense_result := defense.classify_hit(global_position, facing_direction, hit_from_global)
	var exhausted := false
	if defense_result != DefenseComponent.HitResult.NONE:
		var action := "deflect" if defense_result == DefenseComponent.HitResult.DEFLECT else "guard"
		exhausted = not hud.can_spend_stamina(action)
		hud.spend_stamina(action, true)
		# Finish this accepted reaction, but remove protection as soon as energy hits zero.
		if not has_action_stamina(): defense.end_guard(false)
	match defense_result:
		DefenseComponent.HitResult.DEFLECT:
			hud.enter_combat()
			if exhausted:
				_apply_stamina_exhaustion(hit_from_global)
			else:
				deflect_slow_motion.start(deflect_slow_motion_scale, deflect_slow_motion_duration)
				_play_defense_hit_pose(ANIM_DEFLECT)
			return
		DefenseComponent.HitResult.GUARD:
			if not exhausted:
				defense.start_guard_push(guard_knockback_distance, guard_knockback_duration, -float(facing_direction))
				_play_defense_hit_pose(ANIM_GUARD)
			dmg = maxi(0, int(round(float(dmg) * hud.get_guard_damage_multiplier())))
			if dmg == 0:
				hud.enter_combat()
				if exhausted: _apply_stamina_exhaustion(hit_from_global)
				return
	var hit: Dictionary = hud.apply_damage(dmg, hit_from_global, exhausted)
	# Damage can synchronously respawn or remove this Player from the tree.
	if hit.get("died", false):
		defense.end_guard()
		if is_inside_tree() and not is_queued_for_deletion():
			deflect_slow_motion.cancel()
			state_machine.resume_locomotion()
		return
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if exhausted:
		_apply_stamina_exhaustion(hit_from_global)
	elif hit.get("staggered", false) and not hit.get("skip_player_stagger", false):
		var direction := Vector2(-float(facing_direction), 0.0) if defense_result == DefenseComponent.HitResult.GUARD else damage.compute_knockback_dir(hit_from_global, facing_direction)
		damage.apply_stagger(direction)
	elif hit.get("damage_taken", 0) > 0:
		damage.start_invulnerability(DamageComponent.HIT_INVULN_SEC)

func change_weapon(new_weapon: WeaponData) -> void:
	combat.change_weapon(new_weapon)

func get_damage_dealt_multiplier() -> float:
	var hud := _find_hud()
	if hud and hud.has_method("get_damage_dealt_multiplier"):
		return hud.get_damage_dealt_multiplier()
	return 1.0

func get_attack_speed_multiplier() -> float:
	var hud := _find_hud()
	if hud and hud.has_method("get_attack_speed_multiplier"):
		return hud.get_attack_speed_multiplier()
	return 1.0

func begin_campfire_ui(owner: Node) -> bool:
	if is_campfire_ui_active() or get_tree().paused or not state_machine.can_begin_action(): return false
	_campfire_ui_owner = owner
	_campfire_cursor_ready = false
	var hud := _find_hud()
	if hud != null and hud.has_method("set_campfire_hidden"): hud.set_campfire_hidden(true)
	refresh_gameplay_cursor()
	return true

func is_campfire_ui_active() -> bool:
	return is_instance_valid(_campfire_ui_owner)

func is_in_rest_state() -> bool:
	return state_machine.current == AdelStateMachine.State.REST

func set_campfire_cursor_ready(owner: Node, ready: bool) -> void:
	if _campfire_ui_owner != owner: return
	_campfire_cursor_ready = ready
	refresh_gameplay_cursor()

func end_campfire_ui(owner: Node) -> void:
	if _campfire_ui_owner != owner: return
	_campfire_ui_owner = null
	_campfire_cursor_ready = false
	var hud := _find_hud()
	if hud != null and hud.has_method("set_campfire_hidden"): hud.set_campfire_hidden(false)
	# Scene removal can run after another screen has selected its cursor mode.
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene != null and (scene == self or scene.is_ancestor_of(self)): refresh_gameplay_cursor()

func refresh_gameplay_cursor() -> void:
	if not is_inside_tree(): return
	if is_campfire_ui_active():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if _campfire_cursor_ready else Input.MOUSE_MODE_HIDDEN)
		return
	var visible_menu := false
	for path in ["Camera2D/UI_Layer/master_menu", "Camera2D/UI_Layer/PauseMenu"]:
		var menu := get_node_or_null(path) as Control
		visible_menu = visible_menu or (menu != null and menu.visible)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if visible_menu else Input.MOUSE_MODE_HIDDEN)

func prepare_to_exit_rest() -> void:
	# Keep Rest ownership through the exit fade, but restore position/camera now.
	global_position = _position_before_rest
	velocity = Vector2.ZERO
	presentation.play(&"idle")
	snap_feet_to_floor()

func enter_rest(face_left: bool) -> void:
	deflect_slow_motion.cancel()
	_position_before_rest = global_position
	state_machine.transition(AdelStateMachine.State.REST)
	velocity = Vector2.ZERO
	_playing_land_anim = false
	_set_facing_direction(-1 if face_left else 1)
	presentation.play(&"idle")

func play_rest_animation() -> void:
	spine_anim.play("RESET", 0.0, 1.0, true)
	spine_anim.advance(0) 
	spine_anim.play("rest", 0.0)

func exit_rest() -> void:
	state_machine.resume_locomotion()
	velocity = Vector2.ZERO
	global_position = _position_before_rest
	snap_feet_to_floor()

func restore_checkpoint_state(saved_position: Vector2, face_left: bool, keep_resting: bool = false) -> void:
	# exit_rest restores this anchor; update it before leaving the old state.
	_position_before_rest = saved_position
	global_position = saved_position
	if keep_resting:
		enter_rest(face_left)
	else:
		exit_rest()
		_set_facing_direction(-1 if face_left else 1)
		presentation.play(&"idle")
	velocity = Vector2.ZERO
	snap_feet_to_floor()

func snap_feet_to_floor(max_drop: float = 96.0) -> void:
	var col := $CollisionShape2D as CollisionShape2D
	if col == null or col.shape == null:
		return
	var half_h := _capsule_half_height(col)
	var feet := Vector2(col.global_position.x, col.global_position.y + half_h)
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		feet + Vector2(0, -4.0),
		feet + Vector2(0, max_drop)
	)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	global_position.y += hit.position.y - feet.y

func play_pickup_animation() -> void:
	if not is_on_floor() or not state_machine.can_begin_action(): return
	state_machine.transition(AdelStateMachine.State.PICKUP)
	velocity.x = 0.0
	presentation.play(&"loot")

func _play_combo_step() -> void:
	jump_hitbox.end_attack()
	var attack_direction: float = Input.get_axis("move_left", "move_right")
	if attack_direction != 0.0:
		_update_facing(attack_direction)

	state_machine.transition(AdelStateMachine.State.COMBO)
	velocity.x = 0
	_playing_land_anim = false 
	is_skidding = false
	velocity.x = facing_direction * 150.0
	if not is_on_floor():
		velocity.y = 0.0

	var attack_animation: StringName = combat.get_attack_anim_name()
	spine_anim.play(attack_animation)
	saber_hitbox.play_attack_window(attack_animation, combat.get_combo_damage())
	_arm_attack_interrupt(attack_animation)

func _advance_queued_combo() -> void:
	_attack_interrupt_token += 1
	_attack_interrupt_ready = false

	if combat.on_attack_anim_finished() == CombatComponent.AttackAction.START_COMBO:
		_play_combo_step()

func _cancel_combo_for_movement(direction: float) -> void:
	state_machine.resume_locomotion()
	_combo_reset_timer = 0.3
	_update_facing(direction)
	_update_ground_animation(direction)

func _arm_attack_interrupt(attack_animation: StringName) -> void:
	_attack_interrupt_token += 1
	_attack_interrupt_ready = false

	var token: int = _attack_interrupt_token
	var interrupt_time: float = ATTACK_INTERRUPT_TIME
	if combat.combo_step == 4:
		interrupt_time = ATTACK_4_INTERRUPT_TIME

	get_tree().create_timer(interrupt_time).timeout.connect(
		_on_attack_interrupt_ready.bind(token, attack_animation),
		CONNECT_ONE_SHOT
	)

func _on_attack_interrupt_ready(
	token: int,
	attack_animation: StringName
) -> void:
	if token != _attack_interrupt_token:
		return

	if state_machine.current != AdelStateMachine.State.COMBO:
		return

	if not is_doing_action:
		return

	_attack_interrupt_ready = true
	if combat.attack_queued:
		_advance_queued_combo()
		return

	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		_cancel_combo_for_movement(direction)

func _reset_combo() -> void:
	combat.reset_combo_if_idle(is_doing_action)

func _play_jump_attack() -> void:
	# Switching within ATTACK must also invalidate the preceding combo swing.
	_attack_interrupt_token += 1
	_attack_interrupt_ready = false
	saber_hitbox.stop_attack_window()
	combat.disable_attack_hitbox()
	jump_hitbox.begin_attack(jump_attack_damage)
	combat.start_jump_attack()
	state_machine.transition(AdelStateMachine.State.JUMP_HANG)
	velocity = Vector2.ZERO
	presentation.play(&"jump_attack(air)")

func _play_jump_attack_land() -> void:
	combat.begin_jump_attack_land()
	state_machine.transition(AdelStateMachine.State.JUMP_LAND)
	_playing_land_anim = false
	spine_anim.play("jump_attack(land)")
	jump_hitbox.set_damage_window(jump_attack_landing_active_time > 0.0)
	jump_hitbox.sample_damage()

func _cancel_jump_attack_land() -> void:
	combat.cancel_jump_attack_land()
	state_machine.resume_locomotion()

func _find_hud() -> Node:
	var own_hud := get_node_or_null("Camera2D/hud")
	if own_hud != null: return own_hud
	if not is_inside_tree(): return null
	var root := get_tree().current_scene
	if root == null:
		return null
	return root.find_child("hud", true, false)

#hàm nội bộ nhóm vật lý
func _get_move_speed_multiplier() -> float:
	var hud := _find_hud()
	if hud and hud.has_method("get_move_speed_multiplier"):
		return hud.get_move_speed_multiplier()
	return 1.0

func _perform_dash(dash_direction: float) -> void:
	if not has_action_stamina(): return
	var hud := _find_hud()
	if hud != null: hud.spend_stamina("dash", true)
	if combat.is_jump_attack_landing: _cancel_jump_attack_land()
	_dash_info = dash.start_dash(dash_direction, is_on_floor(), facing_direction)
	state_machine.transition(AdelStateMachine.State.DASH_ACTIVE)
	_playing_land_anim = false
	damage.is_invulnerable = true
	presentation.play(&"dash_air" if _dash_info.is_air else &"dash")
	ghost_trail.start()
	velocity.x = _dash_info.initial_speed * _dash_info.direction
	_dash_tween = create_tween()
	_dash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_dash_tween.tween_property(self, "velocity:x", _dash_info.direction * _dash_info.target_speed, DashComponent.DASH_TWEEN_DURATION)

func _capsule_half_height(col: CollisionShape2D) -> float:
	var capsule := col.shape as CapsuleShape2D
	if capsule == null:
		return 32.0
	var scale_y := col.global_transform.get_scale().y
	return capsule.height * 0.5 * scale_y

func _setup_enemy_passthrough() -> void:
	# Body collision stays off before, during, and after every dash.
	set_collision_mask_value(ENEMY_COLLISION_LAYER, false)
	get_tree().node_added.connect(_exclude_enemy_body)
	_exclude_existing_enemy_bodies(get_tree().root)

func _exclude_existing_enemy_bodies(node: Node) -> void:
	_exclude_enemy_body(node)
	for child in node.get_children():
		_exclude_existing_enemy_bodies(child)

func _exclude_enemy_body(node: Node) -> void:
	var body := node as CharacterBody2D
	if body == null or body == self or body.is_in_group("Player"):
		return
	var enemy_layer := 1 << (ENEMY_COLLISION_LAYER - 1)
	# The damage API also identifies legacy enemies still on the world layer.
	if (body.collision_layer & enemy_layer) == 0 and not body.is_in_group("Enemy") and not body.has_method("take_damage"):
		return
	# Both bodies ignore each other; their Area2D combat hitboxes remain active.
	add_collision_exception_with(body)
	body.add_collision_exception_with(self)

#hàm nội bộ nhóm đồ họa
func _update_facing(direction: float) -> void:
	if direction == 0.0:
		return
	_set_facing_direction(-1 if direction < 0 else 1)

func _set_facing_direction(direction: int) -> void:
	presentation.face(direction)

func _play_jump_start() -> void:
	presentation.jump_start()

func _play_jump_land() -> void:
	presentation.jump_land()

func _on_locomotion_jumped() -> void:
	if state_machine.is_in(AdelStateMachine.State.LOCOMOTION): state_machine.resume_locomotion()
	dash.reset_air_dash()
	_play_jump_start()

func _on_locomotion_landed() -> void:
	dash.reset_air_dash()
	combat.has_air_comboed = false
	if is_guarding or deflect_slow_motion.is_active:
		return
	if state_machine.current == AdelStateMachine.State.READY:
		return
	if combat.is_jump_attack_landing or combat.is_jump_attacking:
		return
	_play_jump_land()

func _update_ground_animation(direction: float) -> void:
	presentation.ground(direction)

func _update_air_animation() -> void:
	presentation.air()

func _on_spine_anim_finished(anim_name: StringName) -> void:
	if state_machine.is_in(AdelStateMachine.State.DEFENSE) or deflect_slow_motion.is_active or state_machine.is_in(AdelStateMachine.State.STAGGER): return
	if anim_name == "jump_attack(land)" and state_machine.current == AdelStateMachine.State.JUMP_LAND:
		_play_ready()
	elif anim_name == ANIM_JUMP_START and not is_on_floor():
		presentation.play(ANIM_JUMP_AIR)
	elif anim_name == ANIM_JUMP_LAND:
		_playing_land_anim = false
		_update_ground_animation(Input.get_axis("move_left", "move_right"))
	elif anim_name == "skid":
		is_skidding = false
		_update_ground_animation(Input.get_axis("move_left", "move_right"))
	elif anim_name == "loot" and state_machine.current == AdelStateMachine.State.PICKUP:
		state_machine.resume_locomotion()
		_update_ground_animation(Input.get_axis("move_left", "move_right"))
	elif anim_name == "saber_ready" and state_machine.current == AdelStateMachine.State.READY:
		state_machine.resume_locomotion()
		presentation.play(&"idle")
	elif anim_name.begins_with(combat.equipped_weapon.animation_prefix + "_attack_") and state_machine.current == AdelStateMachine.State.COMBO:
		_attack_interrupt_token += 1
		_attack_interrupt_ready = false
		match combat.on_attack_anim_finished():
			CombatComponent.AttackAction.START_COMBO: _play_combo_step()
			CombatComponent.AttackAction.FINISH_COMBO:
				_play_ready()
				_combo_reset_timer = 0.4

func _on_dodge_cooldown_timeout() -> void:
	dash.on_cooldown_timeout()

func _on_damage_staggered(knockback_velocity: Vector2) -> void:
	state_machine.transition(AdelStateMachine.State.KNOCKBACK)
	velocity = knockback_velocity
	_stagger_push_direction = signf(knockback_velocity.x) if not is_zero_approx(knockback_velocity.x) else -float(facing_direction)
	_stagger_distance_left = damage.active_knockback_distance
	_playing_land_anim = false
	_show_stagger_frame(0)

func _on_damage_knockback_finished() -> void:
	state_machine.transition(AdelStateMachine.State.STUN)
	velocity.x = 0.0
	_stagger_distance_left = 0.0
	_show_stagger_frame(1)

func _show_stagger_frame(frame_index: int) -> void:
	if not deflect_slow_motion.is_active: presentation.stagger(frame_index)

func _on_damage_stagger_recovered() -> void:
	_stagger_distance_left = 0.0
	if deflect_slow_motion.is_active:
		state_machine.transition(AdelStateMachine.State.DEFLECT_REACTION)
	else:
		_play_ready(true)

func configure_attack_hitbox(weapon: WeaponData) -> void:
	attack_hitbox.position = weapon.hitbox_offset

	var shape := attack_hitbox_shape.shape as RectangleShape2D
	if shape:
		shape.size = weapon.hitbox_size
func enable_attack_hitbox() -> void:
	combat.enable_attack_hitbox()


func disable_attack_hitbox() -> void:
	combat.disable_attack_hitbox()


func _try_begin_guard() -> void:
	if has_action_stamina() and state_machine.can_begin_action(): state_machine.transition(AdelStateMachine.State.DEFENSE_HOLD)

func _end_guard(play_release: bool = true) -> void:
	defense.end_guard()
	_defense_hit_pose_time_left = 0.0
	if deflect_slow_motion.is_active: return
	if state_machine.is_in(AdelStateMachine.State.STAGGER) or is_resting: return
	if play_release and not is_locked and state_machine.movement_enabled: _play_ready(true)
	else: state_machine.resume_locomotion()

func _update_defense(delta: float) -> void:
	if is_guarding and not has_action_stamina(): defense.end_guard(false)
	if not is_guarding:
		# A paid hit may consume the final point: keep its pose/recoil, without protection.
		if state_machine.is_in(AdelStateMachine.State.DEFENSE) and not deflect_slow_motion.is_active:
			_defense_hit_pose_time_left = maxf(_defense_hit_pose_time_left - delta, 0.0)
			if is_locked or damage.is_stunned or damage.is_touched_enemy:
				_end_guard(false)
			elif _defense_hit_pose_time_left <= 0.0 and not defense.guard_push_active:
				_end_guard()
		return
	# Poll release before movement locks; also recover when focus/input is lost.
	if damage.is_stunned or damage.is_touched_enemy or is_resting or is_locked:
		_end_guard(false)
		return
	if not Input.is_action_pressed("guard and deflect"):
		_end_guard()
		return
	defense.tick(delta)
	if deflect_slow_motion.is_active:
		return
	_defense_hit_pose_time_left = maxf(_defense_hit_pose_time_left - delta, 0.0)
	if _defense_hit_pose_time_left <= 0.0 and not defense.guard_push_active and state_machine.current != AdelStateMachine.State.DEFENSE_HOLD:
		state_machine.transition(AdelStateMachine.State.DEFENSE_HOLD)

func _play_defense_hit_pose(clip: StringName) -> void:
	if deflect_slow_motion.is_active and clip != ANIM_DEFLECT:
		return
	# Reaction timing is separate from the window measured since guard began.
	_defense_hit_pose_time_left = maxf(defense_hit_pose_duration, 0.05)
	state_machine.transition(AdelStateMachine.State.DEFLECT_REACTION if clip == ANIM_DEFLECT else AdelStateMachine.State.GUARD_REACTION)
	_show_defense_pose(clip)

func _show_defense_pose(clip: StringName) -> void:
	presentation.hold(clip)

func _on_deflect_slow_motion_finished() -> void:
	_defense_hit_pose_time_left = 0.0
	if damage.is_stunned:
		_show_stagger_frame(0 if damage.is_knocking_back else 1)
		return
	if damage.is_touched_enemy or is_resting:
		return
	if is_locked:
		_end_guard(false)
		return
	if is_guarding and has_action_stamina() and Input.is_action_pressed("guard and deflect"):
		if defense.guard_push_active:
			state_machine.transition(AdelStateMachine.State.GUARD_REACTION)
			_show_defense_pose(ANIM_GUARD)
		else:
			state_machine.transition(AdelStateMachine.State.DEFENSE_HOLD)
	else:
		_end_guard()

func _play_ready(final_frame_only: bool = false) -> void:
	_ready_final_frame = final_frame_only
	if state_machine.current == AdelStateMachine.State.READY:
		presentation.ready_pose(final_frame_only)
	else:
		state_machine.transition(AdelStateMachine.State.READY)

func _enter_player_state(state: AdelStateMachine.State) -> void:
	match state:
		AdelStateMachine.State.READY: presentation.ready_pose(_ready_final_frame)
		AdelStateMachine.State.DEFENSE:
			if not deflect_slow_motion.is_active: defense.begin_guard()
			_playing_land_anim = false
			is_skidding = false
			velocity.x = 0.0
		AdelStateMachine.State.DEFENSE_HOLD:
			_defense_hit_pose_time_left = 0.0
			_show_defense_pose(ANIM_DEFENSE)
		AdelStateMachine.State.DASH_ACTIVE: _dash_timer = 0.0
		AdelStateMachine.State.DASH_SKID:
			_dash_timer = 0.0
			presentation.play(&"dash skid")

func _exit_player_state(state: AdelStateMachine.State) -> void:
	match state:
		AdelStateMachine.State.ATTACK:
			_attack_interrupt_token += 1
			_attack_interrupt_ready = false
			combat.interrupt()
			saber_hitbox.stop_attack_window()
			jump_hitbox.end_attack()
			combat.disable_attack_hitbox()
		AdelStateMachine.State.DEFENSE:
			velocity.x = 0.0
			defense.end_guard()
			_defense_hit_pose_time_left = 0.0
		AdelStateMachine.State.DASH:
			if _dash_tween != null and _dash_tween.is_valid(): _dash_tween.kill()
			ghost_trail.stop()
			dash.end_dash()
			if not damage.is_stunned: damage.is_invulnerable = false


func _configure_stamina() -> void:
	var hud := _find_hud()
	if hud != null:
		hud.configure_stamina({"dash": dash_stamina_cost, "guard": guard_stamina_cost, "deflect": deflect_stamina_cost}, stamina_regen_delay, stamina_regen_per_second)

func blocks_stamina_regeneration() -> bool:
	return state_machine != null and (state_machine.is_in(AdelStateMachine.State.ATTACK) or state_machine.is_in(AdelStateMachine.State.DEFENSE) or deflect_slow_motion.is_active)

func _apply_stamina_exhaustion(hit_from_global: Vector2) -> void:
	# Share the full threshold reaction (push, stun, frames and iframe), without firing an HP threshold.
	deflect_slow_motion.cancel()
	var direction := signf(global_position.x - hit_from_global.x)
	if is_zero_approx(direction): direction = -float(facing_direction)
	damage.apply_stagger(Vector2(direction, 0.0))

func has_action_stamina() -> bool:
	var hud := _find_hud()
	return hud != null and hud.stamina > 0.0
