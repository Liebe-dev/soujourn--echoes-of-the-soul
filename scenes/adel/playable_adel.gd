extends CharacterBody2D
const EnemyDebugSettings = preload("res://scenes/enemy/enemy_debug_settings.gd")
const PlayerVitals = preload("res://scenes/adel/components/player_vitals.gd")
const DarkSentinelState = preload("res://scenes/adel/components/dark_sentinel_state.gd")
const StaggerImpact = preload("res://scenes/adel/components/stagger_impact.gd")
@onready var dodge_cooldown = $DodgeCooldown
@onready var saber_skill: SaberWeaponSkill = $SaberSkill
@onready var spine_rig = $SpinePivot/SpineRig
@onready var spine_anim = $SpinePivot/SpineRig/AnimationPlayer
@onready var spine_pivot = $SpinePivot
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var saber_hitbox: SaberHitbox = $WeaponPivot/SaberHitbox
@onready var jump_hitbox: JumpAttackHitbox = $WeaponPivot/JumpAttackHitbox
@onready var weapon: WeaponData = $WeaponHolder/Saber
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var stats: StatsComponent = StatsComponent.new()
var vitals: RefCounted = PlayerVitals.new(self, stats)

@export_group("Dash")
@export_range(0.0, 5000.0, 10.0, "or_greater") var dash_speed: float = 2800.0
@export_range(0.0, 1000.0, 10.0, "or_greater") var dash_end_speed: float = 140.0
@export_range(0.01, 2.0, 0.01, "or_greater") var dash_active_duration: float = 0.3
@export_range(0.0, 2.0, 0.01, "or_greater") var dash_skid_duration: float = 0.2
@export var dash_iframe_window := Vector2(0.0, 0.3)

@export_group("Dark Sentinel")
@export_range(0.0, 100.0, 0.1, "or_greater", "suffix:%/s") var sentinel_hp_drain_percent: float = 2.0
@export_range(0.015, 10.0, 0.015, "suffix:s") var sentinel_entry_duration: float = 1.5
@export_range(0.001, 1.0, 0.001, "suffix:s") var sentinel_recovery_tick_interval: float = 0.015
@export_range(0.01, 100.0, 0.01, "suffix:%") var sentinel_recovery_percent: float = 1.0
var sentinel_state: RefCounted

@export_group("Air Attack")
@export_range(0.01, 1.0, 0.01) var air_attack_fall_speed_multiplier: float = 0.3
@export_range(0.0, 1.0, 0.005, "suffix:s") var air_attack_frame_pause_duration: float = 0.07

@export_group("Jump Attack")
@export_range(0, 10000, 1, "or_greater") var jump_attack_damage: int = 20
@export_range(0.0, 1.0, 0.01, "or_greater") var jump_attack_landing_active_time: float = 0.15

@export_group("Stagger Threshold")
@export_range(0.0, 500.0, 1.0, "or_greater") var stagger_knockback_distance: float = 72.0
@export_range(0.01, 2.0, 0.01, "or_greater") var stagger_knockback_duration: float = 0.3
@export_range(0.0, 5.0, 0.01, "or_greater") var stagger_stun_duration: float = 0.45

@export_group("Stagger Impact")
@export_range(0.0, 1.0, 0.01, "or_greater") var stagger_knockback_deceleration_duration: float = 0.2
@export var stagger_zoom_enabled: bool = true
@export_range(1.0, 3.0, 0.05, "or_greater") var stagger_zoom_multiplier: float = 1.5
@export_range(1.0, 3.0, 0.05, "or_greater") var stamina_exhaustion_zoom_multiplier: float = 1.3
@export_range(0.0, 2.0, 0.05, "or_greater") var stamina_exhaustion_slow_motion_duration_multiplier: float = 0.5
@export_range(0.0, 0.5, 0.01, "or_greater") var stagger_zoom_in_duration: float = 0.06
@export_range(0.0, 1.0, 0.01, "or_greater") var stagger_zoom_return_lead: float = 0.2
@export var stagger_slow_motion_enabled: bool = true
@export_range(0.01, 1.0, 0.01) var stagger_slow_motion_scale: float = 0.35
@export_range(0.0, 1.0, 0.01, "or_greater") var stagger_slow_motion_duration: float = 0.18

@export_group("Combat Input")
@export_range(0.0, 2.0, 0.01, "or_greater") var attack_defense_unlock_time: float = 0.6
@export_range(0.0, 2.0, 0.01, "or_greater") var attack_4_defense_unlock_time: float = 0.75
@export_range(0.0, 2.0, 0.01, "or_greater") var jump_attack_land_defense_unlock_time: float = 0.5
@export_range(0.0, 0.5, 0.01, "or_greater") var attack_input_buffer: float = 0.18

@export_group("Hit Stop")
@export var hit_stop_enabled: bool = true
@export_range(0.01, 1.0, 0.01) var hit_stop_scale: float = 0.05
@export_range(0.0, 0.5, 0.005, "or_greater") var attack_hit_stop_duration: float = 0.035
@export_range(0.0, 0.5, 0.005, "or_greater") var finisher_hit_stop_duration: float = 0.055
@export_range(0.0, 0.5, 0.005, "or_greater") var guard_hit_stop_duration: float = 0.025
@export_range(0.0, 0.5, 0.005, "or_greater") var deflect_hit_stop_duration: float = 0.065

@export_group("Defense")
@export_range(0.0, 1.0, 0.01, "or_greater") var deflect_delay: float = 0.1
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

var stagger_impact: Node
var _applying_stamina_exhaustion := false
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
var _attack_animation_rate := 1.0
var _skill_requested := false
var _guard_requires_release := false
var _guard_requested := false
var _guard_press_age := 0.0
var _defense_lock_left := 0.0
var _combo_visual_finished := false
var _jump_land_visual_finished := false

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
	damage.knockback_deceleration_duration = stagger_knockback_deceleration_duration
	damage.staggered.connect(_on_damage_staggered)
	damage.stagger_recovered.connect(_on_damage_stagger_recovered)
	damage.knockback_finished.connect(_on_damage_knockback_finished)

	stagger_impact = StaggerImpact.new()
	stagger_impact.name = "StaggerImpact"
	add_child(stagger_impact)
	deflect_slow_motion = DeflectSlowMotion.new()
	deflect_slow_motion.name = "DeflectSlowMotion"
	add_child(deflect_slow_motion)
	deflect_slow_motion.finished.connect(_on_deflect_slow_motion_finished)
	defense = DefenseComponent.new(deflect_window, deflect_delay)
	saber_hitbox.hit_confirmed.connect(_on_saber_hit_confirmed)
	dash = DashComponent.new(self, dodge_cooldown)

	ghost_trail = AdelGhostTrail.new()
	ghost_trail.name = "GhostTrailComponent"
	add_child(ghost_trail)
	ghost_trail.setup(spine_rig)
	state_machine = AdelStateMachine.new(self)
	state_machine.movement_enabled = _external_movement_enabled
	state_machine.externally_locked = _external_lock
	state_machine.resume_locomotion()
	sentinel_state = DarkSentinelState.new(self, vitals)
	var hud := _find_hud()
	if hud != null: sentinel_state.presentation_changed.connect(hud.present_sentinel)
	saber_skill.setup(self)
	_configure_stamina()
	PlayerProgress.apply_to_stats(stats)
	vitals.refresh()
	spine_anim.animation_finished.connect(_on_spine_anim_finished)
	spine_anim.play("idle")
	refresh_gameplay_cursor()
func get_player_vitals() -> RefCounted:
	return vitals

func _unhandled_input(event: InputEvent) -> void:
	if is_sentinel_entering(): return
	if event.is_action_pressed("soul_heal"):
		vitals.begin_flask_use()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("debug_take_damage"):
		take_damage(DEBUG_DAMAGE_AMOUNT, global_position + Vector2(80.0, 0.0))
		get_viewport().set_input_as_handled()
		return
	state_machine.handle_input(event)

func _handle_attack_input() -> void:
	if is_sentinel_entering() or _guard_requested or _skill_requested or is_sentinel_exit_pending(): return
	combat.attack_buffer_duration = attack_input_buffer
	if combat.should_cancel_jump_attack_land():
		_cancel_jump_attack_land()
	match combat.handle_attack_input(is_doing_action):
		CombatComponent.AttackAction.START_JUMP_ATTACK: _play_jump_attack()
		CombatComponent.AttackAction.START_COMBO: _play_combo_step()
		CombatComponent.AttackAction.QUEUE_COMBO:
			if _attack_interrupt_ready: _advance_queued_combo()

func _physics_process(delta: float) -> void:
	if not get_tree().paused:
		vitals.tick(delta, CombatTime.actor_delta(self, delta))
		if not is_inside_tree() or is_queued_for_deletion(): return
		sentinel_state.tick(delta)
	delta = CombatTime.actor_delta(self, delta)
	_sync_attack_speed()
	_tick_attack_interrupt()
	var input_delta := 0.0 if CombatTime.is_hit_stopping() else delta
	if _guard_requires_release and not Input.is_action_pressed("guard and deflect"):
		_guard_requires_release = false
	if _skill_requested: _try_consume_weapon_skill()
	combat.tick_input_buffer(input_delta)
	_defense_lock_left = maxf(_defense_lock_left - delta * get_attack_speed_multiplier(), 0.0)
	if _guard_requested:
		if not Input.is_action_pressed("guard and deflect") or (not has_action_stamina() and not _dash_blocks_defense()) or is_locked or not state_machine.movement_enabled:
			_clear_guard_request()
		else:
			_guard_press_age += input_delta
			_try_consume_guard()
	if _combo_reset_timer > 0.0:
		_combo_reset_timer = maxf(_combo_reset_timer - delta, 0.0)
		if _combo_reset_timer <= 0.0: _reset_combo()
	state_machine.physics_update(delta)

func _physics_hit_reaction(delta: float) -> void:
	if damage.is_stunned:
		var travel := minf(_stagger_distance_left, damage.consume_knockback_distance(delta))
		velocity.x = _stagger_push_direction * travel / maxf(delta, 0.000001)
		_stagger_distance_left = maxf(_stagger_distance_left - travel, 0.0)
	else: velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	locomotion.apply_vertical_physics(delta)
	move_and_slide()
	if damage.is_touched_enemy and is_on_floor():
		damage.is_touched_enemy = false
		state_machine.resume_locomotion()

func _physics_defense(delta: float) -> void:
	_update_facing(Input.get_axis("move_left", "move_right"))
	velocity.x = defense.consume_guard_push(delta)
	locomotion.apply_vertical_physics(delta)
	move_and_slide()
	locomotion.update_ground_state()

func _physics_attack(delta: float) -> void:
	if combat.is_jump_attack_landing:
		combat.jump_attack_land_timer += delta * get_attack_speed_multiplier()
		jump_hitbox.set_damage_window(combat.jump_attack_land_timer < minf(jump_attack_landing_active_time, CombatComponent.JUMP_ATTACK_LAND_UNLOCK))
		if combat.is_jump_attack_land_unlocked() and can_move and not _guard_requested:
			_physics_locomotion(delta)
			return
	var direction := Input.get_axis("move_left", "move_right")
	if _attack_interrupt_ready and state_machine.current == AdelStateMachine.State.COMBO and direction != 0.0 and not combat.attack_queued and not _guard_requested and not _skill_requested:
		_cancel_combo_for_movement(direction)
		_physics_locomotion(delta)
		return
	_physics_locked(delta)
	if state_machine.is_in(AdelStateMachine.State.JUMP_ATTACK):
		state_machine.transition(AdelStateMachine.State.JUMP_HANG if combat.is_jump_attack_hanging else AdelStateMachine.State.JUMP_FALL)

func _physics_locked(delta: float) -> void:
	if combat.tick_air_attack_pause(spine_anim.current_animation_position, delta):
		velocity.y = 0.0
	elif not combat.apply_combat_air_physics(delta, air_attack_fall_speed_multiplier):
		locomotion.apply_vertical_physics(delta)
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
			if dash.is_dodging:
				dash.physics_update(delta)
				return

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
			if collider is EnemyBase and EnemyDebugSettings.is_ai_disabled(): continue
			if dash.is_dodging or damage.is_invulnerable or damage.is_touched_enemy:
				continue
			take_damage(ENEMY_CONTACT_DAMAGE, collider.global_position)
			break

func _physics_dash(delta: float) -> void:
	dash.physics_update(delta)

func take_damage(dmg: int, hit_from_global: Vector2 = Vector2.INF) -> void:
	if is_skill_finish_frozen() or dmg <= 0 or is_skill_damage_immune() or not damage.can_take_damage():
		return

	var health = vitals

	# A depleted held stance cannot classify another hit before the next physics tick.
	if is_guarding and not has_action_stamina(): defense.end_guard(false)
	var defense_result := defense.classify_hit(global_position, facing_direction, hit_from_global)
	var exhausted := false
	if defense_result != DefenseComponent.HitResult.NONE:
		var action := "deflect" if defense_result == DefenseComponent.HitResult.DEFLECT else "guard"
		exhausted = not stats.can_spend_stamina(action)
		health.spend_stamina(action, true)
		# Finish this accepted reaction, but remove protection as soon as energy hits zero.
		if not has_action_stamina(): defense.end_guard(false)
	match defense_result:
		DefenseComponent.HitResult.DEFLECT:
			health.combat_activity.emit()
			if exhausted:
				_apply_stamina_exhaustion(hit_from_global)
			else:
				var impact_delay := _request_hit_stop(deflect_hit_stop_duration)
				deflect_slow_motion.start(deflect_slow_motion_scale, deflect_slow_motion_duration, impact_delay)
				_play_defense_hit_pose(ANIM_DEFLECT)
			return
		DefenseComponent.HitResult.GUARD:
			if not exhausted: _request_hit_stop(guard_hit_stop_duration)
			if not exhausted:
				defense.start_guard_push(guard_knockback_distance, guard_knockback_duration, -float(facing_direction))
				_play_defense_hit_pose(ANIM_GUARD)
			dmg = maxi(0, int(round(float(dmg) * stats.get_guard_damage_multiplier())))
			if dmg == 0:
				health.combat_activity.emit()
				if exhausted: _apply_stamina_exhaustion(hit_from_global)
				return
	var hit: Dictionary = health.apply_damage(dmg, hit_from_global, exhausted)
	# Damage can synchronously respawn or remove this Player from the tree.
	if hit.get("died", false):
		stagger_impact.cancel()
		var camera := get_node_or_null("Camera2D") as Camera2D
		if camera != null and camera.has_method("cancel_hit_stop_zoom"): camera.cancel_hit_stop_zoom()
		clear_combat_input()
		CombatTime.remove(self)
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
	return stats.get_damage_dealt_multiplier()

func scale_attack_damage(amount: int) -> int:
	# Both hitboxes apply the modifier once, at contact, including all Q tiers.
	return maxi(0, int(round(maxi(amount, 0) * get_damage_dealt_multiplier())))

func get_attack_speed_multiplier() -> float:
	return stats.get_attack_speed_multiplier()

func _sync_attack_speed() -> void:
	var normal_attack := state_machine.current in [AdelStateMachine.State.COMBO, AdelStateMachine.State.JUMP_HANG, AdelStateMachine.State.JUMP_FALL, AdelStateMachine.State.JUMP_LAND]
	var rate := get_attack_speed_multiplier() if normal_attack else 1.0
	if is_equal_approx(rate, _attack_animation_rate): return
	# Preserve other playback-speed owners; remove only our own previous factor.
	var ratio := rate / _attack_animation_rate
	spine_anim.speed_scale *= ratio
	saber_hitbox.hitbox_animation.speed_scale *= ratio
	_attack_animation_rate = rate

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
	refresh_gameplay_cursor(ready)

func end_campfire_ui(owner: Node) -> void:
	if _campfire_ui_owner != owner: return
	_campfire_ui_owner = null
	_campfire_cursor_ready = false
	var hud := _find_hud()
	if hud != null and hud.has_method("set_campfire_hidden"): hud.set_campfire_hidden(false)
	# Scene removal can run after another screen has selected its cursor mode.
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene != null and (scene == self or scene.is_ancestor_of(self)): refresh_gameplay_cursor()

func refresh_gameplay_cursor(center_mouse: bool = false) -> void:
	if not is_inside_tree(): return
	if is_campfire_ui_active():
		CursorPolicy.set_visible(get_viewport(), _campfire_cursor_ready, center_mouse)
		return
	var visible_menu := false
	for path in ["Camera2D/UI_Layer/master_menu", "Camera2D/UI_Layer/PauseMenu"]:
		var menu := get_node_or_null(path) as Control
		visible_menu = visible_menu or (menu != null and menu.visible)
	CursorPolicy.set_visible(get_viewport(), visible_menu, center_mouse)

func prepare_to_exit_rest() -> void:
	# Keep Rest ownership through the exit fade, but restore position/camera now.
	global_position = _position_before_rest
	velocity = Vector2.ZERO
	presentation.play(&"idle")
	snap_feet_to_floor()

func enter_rest(face_left: bool) -> void:
	_defense_lock_left = 0.0
	clear_combat_input()
	CombatTime.remove(self)
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
	if damage != null: damage.reset()
	vitals.cancel_transients()
	end_sentinel()
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
	_combo_visual_finished = false
	_defense_lock_left = attack_4_defense_unlock_time if combat.combo_step == 4 else attack_defense_unlock_time
	jump_hitbox.end_attack()
	var attack_direction: float = Input.get_axis("move_left", "move_right")
	if attack_direction != 0.0:
		_update_facing(attack_direction)

	state_machine.transition(AdelStateMachine.State.COMBO)
	_sync_attack_speed()
	velocity.x = 0
	_playing_land_anim = false 
	is_skidding = false
	velocity.x = facing_direction * 150.0 if is_on_floor() else 0.0

	var attack_animation: StringName = combat.get_attack_anim_name()
	combat.arm_air_attack_pause(presentation.sprite_frame_time(attack_animation, 1) if combat.combo_step <= 3 else -1.0, air_attack_frame_pause_duration)
	spine_anim.play(attack_animation)
	saber_hitbox.play_attack_window(attack_animation, combat.get_combo_damage())
	_arm_attack_interrupt()

func _advance_queued_combo() -> void:
	if is_sentinel_entering() or _guard_requested or _skill_requested or is_sentinel_exit_pending(): return
	_attack_interrupt_token += 1
	_attack_interrupt_ready = false

	if combat.on_attack_anim_finished() == CombatComponent.AttackAction.START_COMBO:
		_play_combo_step()

func _cancel_combo_for_movement(direction: float) -> void:
	state_machine.resume_locomotion()
	_combo_reset_timer = 0.3
	_update_facing(direction)
	_update_ground_animation(direction)

func _arm_attack_interrupt() -> void:
	_attack_interrupt_token += 1
	_attack_interrupt_ready = false

func _tick_attack_interrupt() -> void:
	if state_machine.current != AdelStateMachine.State.COMBO or _attack_interrupt_ready: return
	var interrupt_time: float = ATTACK_INTERRUPT_TIME
	if combat.combo_step == 4:
		interrupt_time = ATTACK_4_INTERRUPT_TIME
	if spine_anim.current_animation_position + 0.00001 >= interrupt_time:
		_on_attack_interrupt_ready(_attack_interrupt_token, combat.get_attack_anim_name())

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
	if direction != 0.0 and not _guard_requested and not _skill_requested:
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
	combat.start_jump_attack(spine_anim.get_animation(&"jump_attack(air)").length, true)
	state_machine.transition(AdelStateMachine.State.JUMP_HANG)
	velocity = Vector2.ZERO
	presentation.play(&"jump_attack(air)")

func _play_jump_attack_land() -> void:
	_jump_land_visual_finished = false
	_defense_lock_left = jump_attack_land_defense_unlock_time
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
	return stats.get_move_speed_multiplier()

func _perform_dash(dash_direction: float) -> void:
	if not dash.can_start(dash_direction, is_on_floor()) or not has_action_stamina() or is_sentinel_exit_pending() or is_sentinel_entering(): return
	if combat.is_jump_attack_landing: _cancel_jump_attack_land()
	if dash.start_dash(dash_direction, is_on_floor(), facing_direction): _playing_land_anim = false

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
	if is_sentinel_entering() or saber_skill.is_active(): return
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
	if is_sentinel_entering() or saber_skill.is_active(): return
	if state_machine.is_in(AdelStateMachine.State.DEFENSE) or deflect_slow_motion.is_active or state_machine.is_in(AdelStateMachine.State.STAGGER): return
	if anim_name == &"jump_attack(air)" and combat.is_jump_attacking:
		combat.finish_jump_attack_hang()
		return
	if anim_name == "jump_attack(land)" and state_machine.current == AdelStateMachine.State.JUMP_LAND:
		_jump_land_visual_finished = true
		_defense_lock_left = maxf(jump_attack_land_defense_unlock_time - spine_anim.get_animation(anim_name).length, 0.0)
		if _try_consume_guard(): return
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
		_combo_visual_finished = true
		var unlock := attack_4_defense_unlock_time if combat.combo_step == 4 else attack_defense_unlock_time
		_defense_lock_left = maxf(unlock - spine_anim.get_animation(anim_name).length, 0.0)
		if _try_consume_guard(): return
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
	var falling_velocity := maxf(velocity.y, 0.0)
	state_machine.transition(AdelStateMachine.State.KNOCKBACK)
	velocity = Vector2(knockback_velocity.x, falling_velocity)
	_stagger_push_direction = signf(knockback_velocity.x) if not is_zero_approx(knockback_velocity.x) else -float(facing_direction)
	_stagger_distance_left = damage.active_knockback_distance
	_playing_land_anim = false
	_show_stagger_frame(0)
	stagger_impact.start(get_node_or_null("Camera2D"), damage.stagger_duration(), {
		"zoom_enabled": stagger_zoom_enabled, "zoom_multiplier": stamina_exhaustion_zoom_multiplier if _applying_stamina_exhaustion else stagger_zoom_multiplier,
		"zoom_in_duration": stagger_zoom_in_duration, "return_lead": stagger_zoom_return_lead,
		"slow_motion_enabled": stagger_slow_motion_enabled,
		"slow_motion_scale": stagger_slow_motion_scale,
		"slow_motion_duration": stagger_slow_motion_duration * stamina_exhaustion_slow_motion_duration_multiplier if _applying_stamina_exhaustion else stagger_slow_motion_duration,
	})

func _on_damage_knockback_finished() -> void:
	state_machine.transition(AdelStateMachine.State.STUN)
	# Frame 1 begins now; horizontal motion decelerates for the configured tail.
	_show_stagger_frame(1)

func _show_stagger_frame(frame_index: int) -> void:
	if not deflect_slow_motion.is_active: presentation.stagger(frame_index)

func _on_damage_stagger_recovered() -> void:
	_stagger_distance_left = 0.0
	velocity.x = 0.0
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


func cancel_weapon_skill_request() -> void:
	_skill_requested = false

func request_weapon_skill() -> void:
	if _skill_requested or saber_skill.is_active() or _weapon_skill_input_blocked(): return
	if not state_machine.is_in(AdelStateMachine.State.LOCOMOTION) and not state_machine.is_in(AdelStateMachine.State.DASH) and not state_machine.is_in(AdelStateMachine.State.DEFENSE) and state_machine.current != AdelStateMachine.State.COMBO: return
	_skill_requested = true
	combat.clear_attack_buffer()
	_clear_guard_request()
	_try_consume_weapon_skill()

func release_weapon_skill() -> void:
	cancel_weapon_skill_request()
	saber_skill.release()

func _weapon_skill_input_blocked() -> bool:
	return is_locked or not state_machine.movement_enabled or damage.is_stunned or damage.is_touched_enemy or is_sentinel_exit_pending() or is_sentinel_entering() or is_campfire_ui_active() or get_tree().paused

func _try_consume_weapon_skill() -> bool:
	if not _skill_requested: return false
	if not Input.is_action_pressed("weapon_skill") or _weapon_skill_input_blocked():
		cancel_weapon_skill_request()
		return false
	# Only a fresh accepted press creates intent; holding Q cannot auto-repeat.
	if state_machine.is_in(AdelStateMachine.State.DASH) or state_machine.current == AdelStateMachine.State.COMBO: return false
	if not state_machine.is_in(AdelStateMachine.State.LOCOMOTION) and not state_machine.is_in(AdelStateMachine.State.DEFENSE): return false
	if saber_skill.begin(true):
		_guard_requires_release = Input.is_action_pressed("guard and deflect")
		return true
	return false

func _dash_blocks_defense() -> bool:
	return state_machine.is_in(AdelStateMachine.State.DASH)

func _try_begin_guard() -> void:
	if _guard_requires_release or _skill_requested or _guard_requested or is_guarding: return
	if (not has_action_stamina() and not _dash_blocks_defense()) or is_locked or not state_machine.movement_enabled or damage.is_stunned or damage.is_touched_enemy or deflect_slow_motion.is_active: return
	if not state_machine.is_in(AdelStateMachine.State.LOCOMOTION) and not state_machine.is_in(AdelStateMachine.State.DASH) and state_machine.current not in [AdelStateMachine.State.COMBO, AdelStateMachine.State.JUMP_LAND] and not state_machine.is_in(AdelStateMachine.State.JUMP_ATTACK): return
	_guard_requested = true
	_guard_press_age = 0.0
	combat.clear_attack_buffer()
	_try_consume_guard()

func _try_consume_guard() -> bool:
	if _guard_requires_release or _skill_requested: return false
	if not _guard_requested or is_guarding or not has_action_stamina() or is_locked or not state_machine.movement_enabled or damage.is_stunned or damage.is_touched_enemy or deflect_slow_motion.is_active: return false
	# Hold through dash/skid only; cooldown restricts the next dash, not defense.
	if _dash_blocks_defense(): return false
	if state_machine.current == AdelStateMachine.State.COMBO:
		var unlock := attack_4_defense_unlock_time if combat.combo_step == 4 else attack_defense_unlock_time
		if not _combo_visual_finished and spine_anim.current_animation_position + 0.00001 < unlock: return false
		if _combo_visual_finished and _defense_lock_left > 0.00001: return false
	elif state_machine.current == AdelStateMachine.State.JUMP_LAND:
		if not _jump_land_visual_finished and spine_anim.current_animation_position + 0.00001 < jump_attack_land_defense_unlock_time: return false
		if _jump_land_visual_finished and _defense_lock_left > 0.00001: return false
	elif not state_machine.can_begin_action() or _defense_lock_left > 0.00001:
		return false
	state_machine.transition(AdelStateMachine.State.DEFENSE_HOLD)
	return true

func _clear_guard_request() -> void:
	_guard_requested = false
	_guard_press_age = 0.0

func clear_combat_input() -> void:
	if saber_skill != null: saber_skill.cancel_impact_feedback()
	cancel_weapon_skill_request()
	_clear_guard_request()
	if combat != null: combat.clear_attack_buffer()
	if is_guarding: _end_guard(false)
	if saber_skill != null and saber_skill.is_active(): saber_skill.abort()

func _release_guard_input() -> void:
	_guard_requires_release = false
	_clear_guard_request()
	if is_guarding: _end_guard()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: clear_combat_input()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and is_node_ready(): refresh_gameplay_cursor.call_deferred(true)

func _request_hit_stop(duration: float, camera_zoom: bool = true) -> float:
	if not hit_stop_enabled or duration <= 0.0: return 0.0
	var accepted := CombatTime.request(self, &"hit_stop", hit_stop_scale, duration)
	if accepted > 0.0 and camera_zoom:
		var camera := get_node_or_null("Camera2D") as Camera2D
		if camera != null and camera.has_method("play_hit_stop_zoom"): camera.play_hit_stop_zoom()
	return accepted

func _on_saber_hit_confirmed(attack_name: StringName) -> void:
	if attack_name == &"saber_skill": return
	_request_hit_stop(finisher_hit_stop_duration if attack_name == &"saber_attack_4" else attack_hit_stop_duration, false)

func _exit_tree() -> void:
	CombatTime.remove(self)

func _end_guard(play_release: bool = true) -> void:
	_clear_guard_request()
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
	defense.sync_press_age(_guard_press_age)
	if deflect_slow_motion.is_active:
		return
	_defense_hit_pose_time_left = maxf(_defense_hit_pose_time_left - delta, 0.0)
	if _defense_hit_pose_time_left <= 0.0 and not defense.guard_push_active and state_machine.current != AdelStateMachine.State.DEFENSE_HOLD:
		state_machine.transition(AdelStateMachine.State.DEFENSE_HOLD)

func _play_defense_hit_pose(clip: StringName) -> void:
	if deflect_slow_motion.is_active and clip != ANIM_DEFLECT:
		return
	# Reaction timing is separate from the window measured since the original press.
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
	_sync_attack_speed()
	if state in [AdelStateMachine.State.STAGGER, AdelStateMachine.State.REST, AdelStateMachine.State.PICKUP, AdelStateMachine.State.DASH, AdelStateMachine.State.CONTACT_REACTION, AdelStateMachine.State.SENTINEL_ENTRY]: clear_combat_input()
	match state:
		AdelStateMachine.State.SENTINEL_ENTRY:
			velocity = Vector2.ZERO
			_playing_land_anim = false
			is_skidding = false
			presentation.play(&"idle")
		AdelStateMachine.State.READY: presentation.ready_pose(_ready_final_frame)
		AdelStateMachine.State.DEFENSE:
			combat.combo_step = 0
			combat.clear_attack_buffer()
			if not deflect_slow_motion.is_active: defense.begin_guard(_guard_press_age)
			_playing_land_anim = false
			is_skidding = false
			velocity.x = 0.0
		AdelStateMachine.State.DEFENSE_HOLD:
			_defense_hit_pose_time_left = 0.0
			_show_defense_pose(ANIM_DEFENSE)

func _exit_player_state(state: AdelStateMachine.State) -> void:
	match state:
		AdelStateMachine.State.STAGGER: stagger_impact.cancel()
		AdelStateMachine.State.SKILL: saber_skill.cancel()
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
			dash.end_dash()


func _configure_stamina() -> void:
	stats.stamina_costs = {"dash": dash_stamina_cost, "guard": guard_stamina_cost, "deflect": deflect_stamina_cost}
	stats.stamina_regen_delay = stamina_regen_delay
	stats.stamina_regen_per_second = stamina_regen_per_second

func blocks_stamina_regeneration() -> bool:
	return state_machine != null and (state_machine.is_in(AdelStateMachine.State.ATTACK) or state_machine.is_in(AdelStateMachine.State.DEFENSE) or deflect_slow_motion.is_active or is_sentinel_entering())

func _apply_stamina_exhaustion(hit_from_global: Vector2) -> void:
	# Share the full threshold reaction (push, stun, frames and iframe), without firing an HP threshold.
	deflect_slow_motion.cancel()
	var direction := signf(global_position.x - hit_from_global.x)
	if is_zero_approx(direction): direction = -float(facing_direction)
	# The staggered signal is synchronous; scope the visual override to this call.
	_applying_stamina_exhaustion = true
	damage.apply_stagger(Vector2(direction, 0.0))
	_applying_stamina_exhaustion = false

func has_action_stamina() -> bool:
	return stats.stamina > 0.0

func begin_sentinel() -> bool:
	return sentinel_state != null and sentinel_state.activate()

func end_sentinel() -> void:
	if sentinel_state != null: sentinel_state.finish()

func is_sentinel_active() -> bool:
	return sentinel_state != null and sentinel_state.active

func is_sentinel_entering() -> bool:
	return sentinel_state != null and sentinel_state.entering

func is_sentinel_exit_pending() -> bool:
	return sentinel_state != null and sentinel_state.exit_pending

func is_skill_damage_immune() -> bool:
	return saber_skill != null and saber_skill.is_dashing()

func consume_skill_finish_input(action: StringName, direction: float) -> void:
	if get_tree().paused or is_locked or damage.is_stunned or is_sentinel_exit_pending() or is_sentinel_entering() or is_campfire_ui_active(): return
	if not state_machine.can_begin_action(): return
	match action:
		&"attack": _handle_attack_input()
		&"weapon_skill":
			if saber_skill.begin():
				_guard_requires_release = Input.is_action_pressed("guard and deflect")
				if not Input.is_action_pressed("weapon_skill"): saber_skill.release()
		&"guard and deflect":
			if Input.is_action_pressed("guard and deflect"):
				_guard_requires_release = false
				_try_begin_guard()
		&"dodge": _perform_dash(direction)
		&"jump": locomotion.perform_buffered_jump()
		&"soul_heal": vitals.begin_flask_use()

func is_skill_finish_frozen() -> bool:
	return saber_skill != null and saber_skill.is_finish_freezing()
