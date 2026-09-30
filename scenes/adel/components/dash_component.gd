class_name DashComponent
extends RefCounted
## A15.4 — Dash/dodge extracted from scenes/adel/playable_adel.gd.
##
## Owns dash state (is_dodging / able_to_dodge / has_air_dashed), the dash decision
## (can_dash), dash direction/speed resolution, and the cooldown. It holds references
## to the LocomotionComponent (base walk speed) and the DodgeCooldown Timer.
##
## Does NOT own: CharacterBody2D.velocity (the coordinator applies it), animation,
## collision mask, invulnerability (owned by DamageComponent), ghost trail, or the FSM.

const DASH_SPEED_MULTIPLIER := 20.0
const DASH_TWEEN_DURATION := 0.3
const DASH_SKID_DURATION := 0.2

var is_dodging: bool = false
var able_to_dodge: bool = true
var has_air_dashed: bool = false

var _locomotion: LocomotionComponent
var _cooldown: Timer

func _init(locomotion: LocomotionComponent, cooldown: Timer) -> void:
	_locomotion = locomotion
	_cooldown = cooldown

# --- Whether a dash can start right now (includes the dodge input) ---
func can_dash(direction: float, is_on_floor: bool) -> bool:
	if not Input.is_action_just_pressed("dodge"):
		return false
	if is_dodging or not able_to_dodge:
		return false
	if is_on_floor:
		return direction != 0.0
	return not has_air_dashed

# --- Begin a dash: transition state and resolve direction/speed. ---
func start_dash(direction: float, is_on_floor: bool, facing_direction: int) -> Dictionary:
	var is_air := not is_on_floor
	is_dodging = true
	if is_air:
		has_air_dashed = true
	var dash_dir := direction
	if is_air and dash_dir == 0.0:
		dash_dir = facing_direction
	return {
		"is_air": is_air,
		"direction": dash_dir,
		"initial_speed": _locomotion.WALK_SPEED * DASH_SPEED_MULTIPLIER,
		"target_speed": _locomotion.WALK_SPEED,
	}

# --- End a dash: release state and begin cooldown. ---
func end_dash() -> void:
	is_dodging = false
	able_to_dodge = false
	_cooldown.start()

# --- Re-grant the air dash on jump/landing. ---
func reset_air_dash() -> void:
	has_air_dashed = false

# --- Cooldown finished. ---
func on_cooldown_timeout() -> void:
	able_to_dodge = true
