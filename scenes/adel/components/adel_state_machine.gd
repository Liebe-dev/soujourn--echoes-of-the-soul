class_name AdelStateMachine
extends RefCounted
## Hierarchical action ownership. Parents own shared input/physics and exit cleanup.
## Slow motion is an orthogonal effect; it does not replace the physical state.

enum State {
	ROOT, LOCOMOTION, GROUNDED, AIRBORNE, READY,
	ATTACK, COMBO, JUMP_ATTACK, JUMP_HANG, JUMP_FALL, JUMP_LAND,
	DEFENSE, DEFENSE_HOLD, GUARD_REACTION, DEFLECT_REACTION,
	DASH, DASH_ACTIVE, DASH_SKID,
	STAGGER, KNOCKBACK, STUN, CONTACT_REACTION, REST, PICKUP,
}
signal transitioned(previous: State, current: State)
const PARENT := {
	State.LOCOMOTION: State.ROOT, State.GROUNDED: State.LOCOMOTION,
	State.AIRBORNE: State.LOCOMOTION, State.READY: State.LOCOMOTION,
	State.ATTACK: State.ROOT, State.COMBO: State.ATTACK,
	State.JUMP_ATTACK: State.ATTACK, State.JUMP_HANG: State.JUMP_ATTACK,
	State.JUMP_FALL: State.JUMP_ATTACK, State.JUMP_LAND: State.ATTACK,
	State.DEFENSE: State.ROOT, State.DEFENSE_HOLD: State.DEFENSE,
	State.GUARD_REACTION: State.DEFENSE, State.DEFLECT_REACTION: State.DEFENSE,
	State.DASH: State.ROOT, State.DASH_ACTIVE: State.DASH, State.DASH_SKID: State.DASH,
	State.STAGGER: State.ROOT, State.KNOCKBACK: State.STAGGER, State.STUN: State.STAGGER,
	State.CONTACT_REACTION: State.ROOT, State.REST: State.ROOT, State.PICKUP: State.ROOT,
}
var current: State = State.ROOT
var movement_enabled := true
var externally_locked := false
var _body: CharacterBody2D

func _init(body: CharacterBody2D) -> void:
	_body = body

func is_in(state: State) -> bool:
	var cursor := current
	while true:
		if cursor == state: return true
		if cursor == State.ROOT: return false
		cursor = PARENT[cursor]
	return false

func _path(state: State) -> Array[State]:
	var result: Array[State] = [state]
	while state != State.ROOT:
		state = PARENT[state]
		result.push_front(state)
	return result

func transition(next: State) -> void:
	if current == next: return
	var previous := current
	var old_path := _path(current)
	var new_path := _path(next)
	var shared := 0
	while shared < mini(old_path.size(), new_path.size()) and old_path[shared] == new_path[shared]:
		shared += 1
	for i in range(old_path.size() - 1, shared - 1, -1):
		_body._exit_player_state(old_path[i])
	current = next
	for i in range(shared, new_path.size()):
		_body._enter_player_state(new_path[i])
	transitioned.emit(previous, current)

func resume_locomotion() -> void:
	transition(State.GROUNDED if _body.is_on_floor() else State.AIRBORNE)

func can_move() -> bool:
	if externally_locked or not movement_enabled or _body.deflect_slow_motion.is_active:
		return false
	return is_in(State.LOCOMOTION) or (current == State.JUMP_LAND and _body.combat.is_jump_attack_land_unlocked()) or is_in(State.DASH)

func is_doing_action() -> bool:
	return is_in(State.ATTACK) and not (current == State.JUMP_LAND and _body.combat.is_jump_attack_land_unlocked()) or is_in(State.DEFENSE) or current == State.PICKUP or (_body.deflect_slow_motion.is_active and not is_in(State.STAGGER))

func can_begin_action() -> bool:
	return is_in(State.LOCOMOTION) and can_move() and not _body.damage.is_touched_enemy and not _body.damage.is_stunned

func handle_input(event: InputEvent) -> void:
	if event.is_action("guard and deflect"):
		if event.is_action_pressed("guard and deflect") and not event.is_echo():
			_body._try_begin_guard()
		elif event.is_action_released("guard and deflect") and _body.is_guarding:
			_body._end_guard()
		_body.get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("attack"):
		if externally_locked or not movement_enabled or _body.deflect_slow_motion.is_active or _body.damage.is_stunned:
			return
		if is_in(State.LOCOMOTION) or is_in(State.ATTACK):
			_body._handle_attack_input()

func physics_update(delta: float) -> void:
	_body._update_defense(delta)
	# Highest priority physical reaction may coexist with a held Deflect visual.
	if _body.damage.is_stunned:
		transition(State.KNOCKBACK if _body.damage.is_knocking_back else State.STUN)
	elif _body.damage.is_touched_enemy:
		transition(State.CONTACT_REACTION)
	if is_in(State.STAGGER) or current == State.CONTACT_REACTION:
		_body._physics_hit_reaction(delta)
	elif current == State.REST:
		_body.velocity = Vector2.ZERO
	elif is_in(State.DEFENSE) or _body.deflect_slow_motion.is_active:
		_body._physics_defense(delta)
	elif is_in(State.DASH):
		_body._physics_dash(delta)
	elif is_in(State.ATTACK):
		_body._physics_attack(delta)
	elif current == State.PICKUP or externally_locked or not movement_enabled:
		_body._physics_locked(delta)
	else:
		_body._physics_locomotion(delta)
