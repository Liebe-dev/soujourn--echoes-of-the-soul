extends RefCounted
## Owns entry, recovery, nonlethal drain and deferred exit in world/game time.
const S = AdelStateMachine.State
var active := false
var entering := false
var exit_pending := false
var _fractional_drain := 0.0
var _entry_elapsed := 0.0
var _recovery_ticks := 0
var _fractional_heal := 0.0
var _entry_immunity_token := 0
var _body: CharacterBody2D
var _vitals: RefCounted
signal presentation_changed(active: bool, pending: bool)

func _init(body: CharacterBody2D, vitals: RefCounted) -> void:
	_body = body
	_vitals = vitals

func activate() -> bool:
	if active or _vitals.model.hp <= 0: return false
	active = true
	entering = true
	exit_pending = false
	_fractional_drain = 0.0
	_entry_elapsed = 0.0
	_recovery_ticks = 0
	_fractional_heal = 0.0
	_vitals.model.suspend_stagger_thresholds()
	_vitals.cancel_transients()
	_body.damage.cancel_hit_reaction()
	_body.deflect_slow_motion.cancel()
	_body.state_machine.transition(S.SENTINEL_ENTRY)
	_entry_immunity_token = _body.damage.grant_invulnerability(&"sentinel_entry")
	_vitals.refresh()
	presentation_changed.emit(true, false)
	return true

func finish() -> void:
	if not active: return
	active = false
	entering = false
	exit_pending = false
	_fractional_drain = 0.0
	_release_entry()
	_vitals.model.resume_stagger_thresholds()
	_vitals.refresh()
	presentation_changed.emit(false, false)

func _release_entry() -> void:
	_body.damage.release_invulnerability(&"sentinel_entry", _entry_immunity_token)
	_entry_immunity_token = 0
	if _body.state_machine.current == S.SENTINEL_ENTRY:
		_body.state_machine.resume_locomotion()

func tick(delta: float) -> void:
	if not active: return
	if _vitals.model.hp <= 0:
		finish()
		return
	var elapsed := maxf(delta, 0.0)
	if entering:
		var duration := maxf(_body.sentinel_entry_duration, 0.015)
		var consumed := minf(elapsed, maxf(duration - _entry_elapsed, 0.0))
		_entry_elapsed += consumed
		elapsed -= consumed
		var ticks := int(floor((_entry_elapsed + 0.000001) / maxf(_body.sentinel_recovery_tick_interval, 0.001)))
		var count := maxi(ticks - _recovery_ticks, 0)
		_recovery_ticks = ticks
		_fractional_heal += count * _vitals.model.max_hp * _body.sentinel_recovery_percent / 100.0
		var whole := int(floor(_fractional_heal + 0.000001))
		_fractional_heal = maxf(_fractional_heal - whole, 0.0)
		_vitals.model.hp = mini(_vitals.model.max_hp, _vitals.model.hp + whole)
		_vitals.model.stamina = minf(_vitals.model.max_stamina, _vitals.model.stamina + count * _vitals.model.max_stamina * _body.sentinel_recovery_percent / 100.0)
		if _entry_elapsed + 0.000001 >= duration:
			# Guarantee full recovery at the boundary, including integer HP rounding.
			_vitals.model.hp = _vitals.model.max_hp
			_vitals.model.stamina = _vitals.model.max_stamina
			entering = false
			_release_entry()
		_vitals.refresh(_vitals.HP | _vitals.STAMINA)
		if entering: return
	if not exit_pending:
		_fractional_drain += elapsed * maxf(_body.sentinel_hp_drain_percent, 0.0) * maxf(_vitals.model.max_hp, 0) / 100.0
		var whole := int(floor(_fractional_drain + 0.000001))
		if whole > 0:
			_fractional_drain = maxf(_fractional_drain - whole, 0.0)
			_vitals.drain_hp_nonlethal(whole)
	check_depletion()

func check_depletion() -> void:
	if not active or entering: return
	if not exit_pending and _vitals.model.hp <= 1:
		exit_pending = true
		_body.combat.clear_attack_buffer()
		_body.cancel_weapon_skill_request()
		presentation_changed.emit(true, true)
	if exit_pending and not _action_in_progress(): finish()

func _action_in_progress() -> bool:
	var machine = _body.state_machine
	return machine.is_in(S.ATTACK) or machine.is_in(S.DASH) or machine.is_in(S.STAGGER) or machine.current in [S.CONTACT_REACTION, S.PICKUP, S.REST]
