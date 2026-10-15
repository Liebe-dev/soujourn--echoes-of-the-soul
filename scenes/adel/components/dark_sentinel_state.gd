extends RefCounted
## Owns drain and deferred exit. HUD remains a presentation adapter.
## tick() receives world/game delta, never actor-exempt or real-time delta.
const S = AdelStateMachine.State
var active := false
var exit_pending := false
var _fractional_drain := 0.0
var _body: CharacterBody2D
var _vitals: RefCounted
signal presentation_changed(active: bool, pending: bool)

func _init(body: CharacterBody2D, vitals: RefCounted) -> void:
	_body = body
	_vitals = vitals

func activate() -> bool:
	if active or _vitals.model.hp <= 0: return false
	active = true
	exit_pending = false
	_fractional_drain = 0.0
	presentation_changed.emit(true, false)
	return true

func finish() -> void:
	active = false
	exit_pending = false
	_fractional_drain = 0.0
	presentation_changed.emit(false, false)

func tick(delta: float) -> void:
	if not active: return
	if _vitals.model.hp <= 0:
		finish()
		return
	if not exit_pending:
		_fractional_drain += maxf(delta, 0.0) * maxf(_body.sentinel_hp_drain_percent, 0.0) * maxf(_vitals.model.max_hp, 0) / 100.0
		var whole := int(floor(_fractional_drain + 0.000001))
		if whole > 0:
			_fractional_drain = maxf(_fractional_drain - whole, 0.0)
			_vitals.drain_hp_nonlethal(whole)
		if _vitals.model.hp <= 1:
			exit_pending = true
			_body.combat.clear_attack_buffer()
			presentation_changed.emit(true, true)
	if exit_pending and not _action_in_progress(): finish()

func _action_in_progress() -> bool:
	var machine = _body.state_machine
	return machine.is_in(S.ATTACK) or machine.is_in(S.DASH) or machine.is_in(S.STAGGER) or machine.current in [S.CONTACT_REACTION, S.PICKUP, S.REST]
