extends CharacterBody2D
const StateHooksController = preload("res://scenes/adel/components/player_state_hooks.gd")
const MovementController = preload("res://scenes/adel/components/player_movement.gd")
const AttackController = preload("res://scenes/adel/components/player_attack.gd")
const HitReactionController = preload("res://scenes/adel/components/player_hit_reaction.gd")
const RestController = preload("res://scenes/adel/components/player_rest.gd")
const DefenseInputController = preload("res://scenes/adel/components/player_defense_input.gd")
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
@onready var hit_slash_vfx: SaberHitSlashVFX = $SaberHitSlashVFX
@onready var player_blood: PlayerBlood = $PlayerBlood
@onready var battle_particles: BattleHitParticles = $BattleHitParticles
@onready var jump_hitbox: JumpAttackHitbox = $WeaponPivot/JumpAttackHitbox
@onready var weapon: WeaponData = $WeaponHolder/Saber
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var defense_input: RefCounted
var rest_ctl: RefCounted
var hit_ctl: RefCounted
var attack_ctl: RefCounted
var move_ctl: RefCounted
var states_ctl: RefCounted
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
	states_ctl = StateHooksController.new(self)
	move_ctl = MovementController.new(self)
	attack_ctl = AttackController.new(self)
	hit_ctl = HitReactionController.new(self)
	rest_ctl = RestController.new(self)
	defense_input = DefenseInputController.new(self)
	randomize()
	move_ctl._setup_enemy_passthrough()

	presentation = AdelAnimationComponent.new(self, spine_rig, spine_anim)
	locomotion = LocomotionComponent.new(self)
	locomotion.jumped.connect(move_ctl._on_locomotion_jumped)
	locomotion.landed.connect(move_ctl._on_locomotion_landed)

	combat = CombatComponent.new(
		self,
		locomotion,
		weapon,
		$AttackHitbox
	)

	damage = DamageComponent.new(self, stagger_knockback_distance, stagger_knockback_duration, stagger_stun_duration)
	damage.knockback_deceleration_duration = stagger_knockback_deceleration_duration
	damage.staggered.connect(hit_ctl._on_damage_staggered)
	damage.stagger_recovered.connect(hit_ctl._on_damage_stagger_recovered)
	damage.knockback_finished.connect(hit_ctl._on_damage_knockback_finished)

	stagger_impact = StaggerImpact.new()
	stagger_impact.name = "StaggerImpact"
	add_child(stagger_impact)
	deflect_slow_motion = DeflectSlowMotion.new()
	deflect_slow_motion.name = "DeflectSlowMotion"
	add_child(deflect_slow_motion)
	deflect_slow_motion.finished.connect(defense_input._on_deflect_slow_motion_finished)
	defense = DefenseComponent.new(deflect_window, deflect_delay)
	saber_hitbox.hit_confirmed.connect(hit_ctl._on_saber_hit_confirmed)
	player_blood.setup(stats, spine_rig)
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
	battle_particles.setup(self)
	if hud != null:
		# Gameplay owns the cooldown clock; HUD only receives presentation updates.
		saber_skill.cooldown_changed.connect(hud.set_weapon_ability_presentation)
		hud.set_weapon_ability_presentation(&"Q", saber_skill.cooldown_remaining, saber_skill.cooldown_total)
	_configure_stamina()
	PlayerProgress.changed.connect(_on_progress_changed)
	_on_progress_changed()
	vitals.refresh()
	spine_anim.animation_finished.connect(attack_ctl._on_spine_anim_finished)
	spine_anim.play("idle")
	rest_ctl.refresh_gameplay_cursor()

## AI reads the gameplay model, independent of the HUD being present.
func get_ai_health_ratio() -> float:
	return clampf(float(stats.hp) / maxi(stats.max_hp, 1), 0.0, 1.0)

func get_player_vitals() -> RefCounted:
	return vitals

func _unhandled_input(event: InputEvent) -> void:
	if is_sentinel_entering(): return
	if event.is_action_pressed("soul_heal"):
		vitals.begin_flask_use()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("debug_take_damage"):
		hit_ctl.take_damage(DEBUG_DAMAGE_AMOUNT, global_position + Vector2(80.0, 0.0))
		get_viewport().set_input_as_handled()
		return
	state_machine.handle_input(event)

func _physics_process(delta: float) -> void:
	if not get_tree().paused:
		vitals.tick(delta, CombatTime.actor_delta(self, delta))
		if not is_inside_tree() or is_queued_for_deletion(): return
		sentinel_state.tick(delta)
	delta = CombatTime.actor_delta(self, delta)
	attack_ctl._sync_attack_speed()
	attack_ctl._tick_attack_interrupt()
	var input_delta := 0.0 if CombatTime.is_hit_stopping() else delta
	if _guard_requires_release and not Input.is_action_pressed("guard and deflect"):
		_guard_requires_release = false
	combat.tick_input_buffer(input_delta)
	_defense_lock_left = maxf(_defense_lock_left - delta * get_attack_speed_multiplier(), 0.0)
	if _guard_requested:
		if not Input.is_action_pressed("guard and deflect") or (not has_action_stamina() and not defense_input._dash_blocks_defense()) or is_locked or not state_machine.movement_enabled:
			defense_input._clear_guard_request()
		else:
			_guard_press_age += input_delta
	defense_input._consume_buffered_combat_input()
	if _combo_reset_timer > 0.0:
		_combo_reset_timer = maxf(_combo_reset_timer - delta, 0.0)
		if _combo_reset_timer <= 0.0: attack_ctl._reset_combo()
	state_machine.physics_update(delta)

func change_weapon(new_weapon: WeaponData) -> void:
	combat.change_weapon(new_weapon)
	_refresh_weapon_requirements()

func _on_progress_changed() -> void:
	PlayerProgress.apply_to_stats(stats, stamina_regen_per_second)
	vitals.refresh()
	_refresh_weapon_requirements()

func can_use_weapon_skill() -> bool:
	return combat != null and combat.equipped_weapon != null and combat.equipped_weapon.meets_requirements(PlayerProgress.attributes)

func _refresh_weapon_requirements() -> void:
	var hud := _find_hud()
	if hud == null: return
	var loadout := hud.get_node_or_null("ScreenSpace/WeaponLoadout")
	if loadout == null: return
	var slot := loadout.get_node_or_null("Q")
	if slot != null:
		var current = combat.equipped_weapon
		slot.set_requirement_lock(not can_use_weapon_skill(), current.requirement_text(PlayerProgress.attributes) if current != null else "No weapon")

func get_damage_dealt_multiplier() -> float:
	var factor := stats.get_damage_dealt_multiplier()
	if combat != null and combat.equipped_weapon != null:
		factor *= combat.equipped_weapon.attack_multiplier(PlayerProgress.attributes, PlayerProgress.config)
	if is_sentinel_active(): factor *= PlayerProgress.config.sentinel_damage(PlayerProgress.attributes)
	return factor

func scale_attack_damage(amount: int) -> int:
	# Both hitboxes apply the modifier once, at contact, including all Q tiers.
	return maxi(0, int(round(maxi(amount, 0) * get_damage_dealt_multiplier())))

func get_attack_speed_multiplier() -> float:
	return stats.get_attack_speed_multiplier()

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

func _update_ground_animation(direction: float) -> void:
	presentation.ground(direction)

func _update_air_animation() -> void:
	presentation.air()

func _on_dodge_cooldown_timeout() -> void:
	dash.on_cooldown_timeout()

func enable_attack_hitbox() -> void:
	combat.enable_attack_hitbox()


func disable_attack_hitbox() -> void:
	combat.disable_attack_hitbox()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: defense_input.clear_combat_input()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and is_node_ready(): rest_ctl.refresh_gameplay_cursor.call_deferred(true)

func _exit_tree() -> void:
	CombatTime.remove(self)

func _configure_stamina() -> void:
	stats.stamina_costs = {"dash": dash_stamina_cost, "guard": guard_stamina_cost, "deflect": deflect_stamina_cost}
	stats.stamina_regen_delay = stamina_regen_delay
	stats.stamina_regen_per_second = stamina_regen_per_second

func blocks_stamina_regeneration() -> bool:
	return state_machine != null and (state_machine.is_in(AdelStateMachine.State.ATTACK) or state_machine.is_in(AdelStateMachine.State.DEFENSE) or deflect_slow_motion.is_active or is_sentinel_entering())

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

func is_skill_finish_frozen() -> bool:
	return saber_skill != null and saber_skill.is_finish_freezing()

#delegates to defense_input
func cancel_weapon_skill_request() -> void: defense_input.cancel_weapon_skill_request()
func request_weapon_skill() -> void: defense_input.request_weapon_skill()
func release_weapon_skill() -> void: defense_input.release_weapon_skill()
func _try_begin_guard() -> void: defense_input._try_begin_guard()
func clear_combat_input() -> void: defense_input.clear_combat_input()
func _release_guard_input() -> void: defense_input._release_guard_input()
func _end_guard(play_release: bool = true) -> void: defense_input._end_guard(play_release)
func _update_defense(delta: float) -> void: defense_input._update_defense(delta)
func _play_defense_hit_pose(clip: StringName) -> void: defense_input._play_defense_hit_pose(clip)
func consume_skill_finish_input(action: StringName, direction: float) -> void: defense_input.consume_skill_finish_input(action, direction)

#delegates to rest_ctl
func begin_campfire_ui(owner: Node) -> bool: return rest_ctl.begin_campfire_ui(owner)
func is_campfire_ui_active() -> bool: return rest_ctl.is_campfire_ui_active()
func is_in_rest_state() -> bool: return rest_ctl.is_in_rest_state()
func set_campfire_cursor_ready(owner: Node, ready: bool) -> void: rest_ctl.set_campfire_cursor_ready(owner, ready)
func end_campfire_ui(owner: Node) -> void: rest_ctl.end_campfire_ui(owner)
func refresh_gameplay_cursor(center_mouse: bool = false) -> void: rest_ctl.refresh_gameplay_cursor(center_mouse)
func prepare_to_exit_rest() -> void: rest_ctl.prepare_to_exit_rest()
func enter_rest(face_left: bool) -> void: rest_ctl.enter_rest(face_left)
func play_rest_animation() -> void: rest_ctl.play_rest_animation()
func exit_rest() -> void: rest_ctl.exit_rest()
func restore_checkpoint_state(saved_position: Vector2, face_left: bool, keep_resting: bool = false) -> void: rest_ctl.restore_checkpoint_state(saved_position, face_left, keep_resting)
func snap_feet_to_floor(max_drop: float = 96.0) -> void: rest_ctl.snap_feet_to_floor(max_drop)
func play_pickup_animation() -> void: rest_ctl.play_pickup_animation()
func _capsule_half_height(col: CollisionShape2D) -> float: return rest_ctl._capsule_half_height(col)

#delegates to hit_ctl
func take_damage(dmg: int, hit_from_global: Vector2 = Vector2.INF) -> void: hit_ctl.take_damage(dmg, hit_from_global)
func _apply_stamina_exhaustion(hit_from_global: Vector2) -> void: hit_ctl._apply_stamina_exhaustion(hit_from_global)
func _on_damage_stagger_recovered() -> void: hit_ctl._on_damage_stagger_recovered()
func _request_hit_stop(duration: float, camera_zoom: bool = true) -> float: return hit_ctl._request_hit_stop(duration, camera_zoom)
func _physics_hit_reaction(delta: float) -> void: hit_ctl._physics_hit_reaction(delta)

#delegates to attack_ctl
func _handle_attack_input() -> void: attack_ctl._handle_attack_input()
func _play_combo_step() -> void: attack_ctl._play_combo_step()
func _advance_queued_combo() -> void: attack_ctl._advance_queued_combo()
func _tick_attack_interrupt() -> void: attack_ctl._tick_attack_interrupt()
func _play_jump_attack() -> void: attack_ctl._play_jump_attack()
func _play_jump_attack_land() -> void: attack_ctl._play_jump_attack_land()
func _cancel_jump_attack_land() -> void: attack_ctl._cancel_jump_attack_land()
func _physics_attack(delta: float) -> void: attack_ctl._physics_attack(delta)
func _physics_locked(delta: float) -> void: attack_ctl._physics_locked(delta)
func _on_spine_anim_finished(anim_name: StringName) -> void: attack_ctl._on_spine_anim_finished(anim_name)
func _sync_attack_speed() -> void: attack_ctl._sync_attack_speed()
func _play_ready(final_frame_only: bool = false) -> void: attack_ctl._play_ready(final_frame_only)

#delegates to move_ctl
func _physics_defense(delta: float) -> void: move_ctl._physics_defense(delta)
func _physics_locomotion(delta: float) -> void: move_ctl._physics_locomotion(delta)
func _physics_dash(delta: float) -> void: move_ctl._physics_dash(delta)
func _perform_dash(dash_direction: float) -> void: move_ctl._perform_dash(dash_direction)

#delegates to states_ctl
func _enter_player_state(state: AdelStateMachine.State) -> void: states_ctl._enter_player_state(state)
func _exit_player_state(state: AdelStateMachine.State) -> void: states_ctl._exit_player_state(state)
