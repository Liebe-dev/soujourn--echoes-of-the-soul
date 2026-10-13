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
	return _has_live_body() and not is_invulnerable and not is_stunned

# --- Knockback direction (was _knockback_dir) ---
func compute_knockback_dir(hit_from_global: Vector2, facing_direction: int) -> Vector2:
	if hit_from_global != Vector2.INF:
		var dir := _body.global_position - hit_from_global
		if dir.length_squared() > 0.01:
			var dir_normal := dir.normalized()
			if abs(dir_normal.x) < 0.1:
				dir_normal.x = -facing_direction
			dir_normal.y = randf_range(-0.2, -0.7)
			return dir_normal
	return Vector2(1.0 if facing_direction < 0 else -1.0, -0.2).normalized()

# --- Stagger reaction (was _apply_stagger) ---
func apply_stagger(knockback_dir: Vector2) -> void:
	if not _has_live_body():
		return
	is_stunned = true
	is_knocking_back = true
	is_invulnerable = true
	staggered.emit(knockback_dir * (knockback_distance / knockback_duration))
	_connect_timeout(knockback_duration, _on_knockback_end)

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
	_connect_timeout(stun_duration, _on_stagger_stun_end)

func _on_stagger_stun_end() -> void:
	if not _has_live_body():
		return
	is_stunned = false
	stagger_recovered.emit()
	var remaining := maxf(STAGGER_INVULN_SEC - knockback_duration - stun_duration, 0.0)
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
	_body.get_tree().create_timer(duration).timeout.connect(callback, CONNECT_ONE_SHOT)
