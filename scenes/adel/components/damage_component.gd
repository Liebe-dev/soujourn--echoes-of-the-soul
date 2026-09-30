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

# --- Damage/stagger tuning ---
const STAGGER_STUN_SEC := 0.45
const STAGGER_INVULN_SEC := 1.0
const STAGGER_KNOCKBACK := 300.0
const HIT_INVULN_SEC := 0.2

# --- Hit-reaction state owned by DamageComponent ---
var is_stunned: bool = false
var is_invulnerable: bool = false
var is_touched_enemy: bool = false

var _body: CharacterBody2D

func _init(body: CharacterBody2D) -> void:
	_body = body

func can_take_damage() -> bool:
	return not is_invulnerable and not is_stunned

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
	is_stunned = true
	is_invulnerable = true
	staggered.emit(knockback_dir * STAGGER_KNOCKBACK)
	_body.get_tree().create_timer(STAGGER_STUN_SEC).timeout.connect(_on_stagger_stun_end, CONNECT_ONE_SHOT)

# --- Invulnerability window (was _start_invulnerability) ---
func start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	_body.get_tree().create_timer(duration).timeout.connect(_end_invulnerability, CONNECT_ONE_SHOT)

func _end_invulnerability() -> void:
	is_invulnerable = false

func _on_stagger_stun_end() -> void:
	is_stunned = false
	stagger_recovered.emit()
	var remaining := maxf(STAGGER_INVULN_SEC - STAGGER_STUN_SEC, 0.0)
	if remaining > 0.0:
		_body.get_tree().create_timer(remaining).timeout.connect(_end_invulnerability, CONNECT_ONE_SHOT)
	else:
		_end_invulnerability()
