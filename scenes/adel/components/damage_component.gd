class_name DamageComponent
extends RefCounted
## A15.3 — Damage reception / stagger reaction / invulnerability extracted from
## scenes/adel/playable_adel.gd.
##
## Owns the hit-reaction STATE (is_stunned / is_invulnerable / is_touched_enemy),
## the stagger/invulnerability TIMING, and the knockback DIRECTION math. It holds a
## reference to the owning CharacterBody2D (single source of truth for `velocity`
## and `global_position`).
##
## It does NOT own character stats (HP / stagger thresholds / debuffs) — those stay
## in StatsComponent (via the HUD's apply_damage). It does NOT apply knockback to
## velocity, set `can_move`, or play animation; those effects are applied by the
## coordinator in reaction to the `staggered` / `stagger_recovered` signals.

signal staggered(knockback_velocity: Vector2)
signal stagger_recovered
signal knockback_finished

# --- Damage/stagger tuning ---
const STAGGER_STUN_SEC := 0.45
const STAGGER_INVULN_SEC := 1.0
const STAGGER_KNOCKBACK_DISTANCE := 72.0
const STAGGER_KNOCKBACK_DURATION := 0.3
const HIT_INVULN_SEC := 0.2

# --- Hit-reaction state owned by DamageComponent ---
var is_stunned: bool = false
var is_knocking_back: bool = false
var is_invulnerable: bool = false
var is_touched_enemy: bool = false

var active_knockback_distance: float
var active_knockback_duration: float
var knockback_deceleration_duration: float = 0.2
var active_deceleration_duration: float = 0.0
var _knockback_elapsed: float = 0.0
var _active_stun_duration: float
var _active_invulnerability_duration: float

var _body: CharacterBody2D

var knockback_distance: float = STAGGER_KNOCKBACK_DISTANCE
var knockback_duration: float = STAGGER_KNOCKBACK_DURATION
var stun_duration: float = STAGGER_STUN_SEC

func _init(
	body: CharacterBody2D,
	distance: float = STAGGER_KNOCKBACK_DISTANCE,
	push_time: float = STAGGER_KNOCKBACK_DURATION,
	stun_time: float = STAGGER_STUN_SEC
) -> void:
	_body = body
	knockback_distance = maxf(distance, 0.0)
	knockback_duration = maxf(push_time, 0.01)
	stun_duration = maxf(stun_time, 0.0)

func can_take_damage() -> bool:
	return _has_live_body() and not is_invulnerable and not is_stunned and not (_body.has_method("is_skill_damage_immune") and _body.is_skill_damage_immune())

# --- Knockback direction (was _knockback_dir) ---
func compute_knockback_dir(hit_from_global: Vector2, facing_direction: int) -> Vector2:
	var direction := -float(facing_direction)
	if hit_from_global.is_finite():
		var difference := _body.global_position.x - hit_from_global.x
		if not is_zero_approx(difference): direction = signf(difference)
	return Vector2(direction, 0.0)

## Frame 0 owns the constant-speed phase; frame 1 contains the deceleration tail.
## Integrate the curve, rather than Euler-stepping velocity, to preserve distance at any FPS.
func consume_knockback_distance(delta: float) -> float:
	if not is_stunned or delta <= 0.0: return 0.0
	var previous := _knockback_elapsed
	_knockback_elapsed = minf(previous + delta, active_knockback_duration + active_deceleration_duration)
	var area := active_knockback_duration + active_deceleration_duration / 3.0
	return active_knockback_distance * (_motion_area(_knockback_elapsed) - _motion_area(previous)) / maxf(area, 0.000001)

func _motion_area(elapsed: float) -> float:
	var first := minf(elapsed, active_knockback_duration)
	if elapsed <= active_knockback_duration or active_deceleration_duration <= 0.0: return first
	var progress := clampf((elapsed - active_knockback_duration) / active_deceleration_duration, 0.0, 1.0)
	return first + active_deceleration_duration * (1.0 - pow(1.0 - progress, 3.0)) / 3.0

func stagger_duration() -> float:
	return active_knockback_duration + _active_stun_duration

# --- Stagger reaction (was _apply_stagger) ---
func apply_stagger(
	knockback_dir: Vector2,
	distance_override: float = -1.0,
	push_override: float = -1.0,
	stun_override: float = -1.0,
	invulnerability_override: float = -1.0
) -> void:
	if not _has_live_body() or (_body.has_method("is_skill_damage_immune") and _body.is_skill_damage_immune()):
		return
	active_knockback_distance = knockback_distance if distance_override < 0.0 else maxf(distance_override, 0.0)
	active_knockback_duration = knockback_duration if push_override < 0.0 else maxf(push_override, 0.01)
	_active_stun_duration = stun_duration if stun_override < 0.0 else maxf(stun_override, 0.0)
	_active_invulnerability_duration = STAGGER_INVULN_SEC if invulnerability_override < 0.0 else maxf(invulnerability_override, 0.0)
	active_deceleration_duration = minf(maxf(knockback_deceleration_duration, 0.0), _active_stun_duration)
	_knockback_elapsed = 0.0
	is_stunned = true
	is_knocking_back = true
	is_invulnerable = true
	var direction := signf(knockback_dir.x)
	if is_zero_approx(direction): direction = -float(_body.facing_direction) if "facing_direction" in _body else -1.0
	var speed := active_knockback_distance / (active_knockback_duration + active_deceleration_duration / 3.0)
	staggered.emit(Vector2(direction * speed, 0.0))
	_connect_timeout(active_knockback_duration, _on_knockback_end)

# --- Invulnerability window (was _start_invulnerability) ---
func start_invulnerability(duration: float) -> void:
	if not _has_live_body():
		return
	is_invulnerable = true
	_connect_timeout(duration, _end_invulnerability)

func _end_invulnerability() -> void:
	if not _has_live_body():
		return
	is_invulnerable = false

func _on_knockback_end() -> void:
	if not _has_live_body():
		return
	is_knocking_back = false
	knockback_finished.emit()
	if _active_stun_duration <= 0.0:
		_on_stagger_stun_end()
	else:
		_connect_timeout(_active_stun_duration, _on_stagger_stun_end)

func _on_stagger_stun_end() -> void:
	if not _has_live_body():
		return
	is_stunned = false
	stagger_recovered.emit()
	var remaining := maxf(_active_invulnerability_duration - active_knockback_duration - _active_stun_duration, 0.0)
	if remaining > 0.0:
		_connect_timeout(remaining, _end_invulnerability)
	else:
		_end_invulnerability()


func _has_live_body() -> bool:
	return is_instance_valid(_body) and _body.is_inside_tree() and not _body.is_queued_for_deletion()

func _connect_timeout(duration: float, callback: Callable) -> void:
	# Signals can remove the body synchronously; check again after emitting them.
	if not _has_live_body():
		return
	_body.get_node("/root/CombatTime").actor_timeout(_body, duration, callback)
