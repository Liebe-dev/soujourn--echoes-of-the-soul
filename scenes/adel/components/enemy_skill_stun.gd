extends Node
## Temporary skill stun shared by current enemies and untouched legacy prototypes.
var remaining := 0.0
var _body: CharacterBody2D
var _physics_was_enabled := false
var _process_was_enabled := false
var _animations: Array = []
var _areas: Array = []
var _uses_ai_state := false

func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	if _body == null:
		queue_free()
		return
	_uses_ai_state = _body.has_method("apply_ai_stun")
	if _uses_ai_state:
		_body.apply_ai_stun(remaining)
		return
	_physics_was_enabled = _body.is_physics_processing()
	_process_was_enabled = _body.is_processing()
	_body.set_physics_process(false)
	_body.set_process(false)
	for node in _body.find_children("*", "AnimationPlayer", true, false):
		_animations.append([weakref(node), node.is_playing()])
		node.pause()
	for node in _body.find_children("*", "AnimatedSprite2D", true, false):
		_animations.append([weakref(node), node.is_playing()])
		node.pause()
	for node in _body.find_children("*", "Area2D", true, false):
		if (node.collision_layer & 16) == 0 and (node.collision_mask & 2) == 0: continue
		_areas.append([weakref(node), node.is_blocking_signals(), node.monitoring])
		node.set_block_signals(true)
		node.set_deferred("monitoring", false)

func extend(duration: float) -> void:
	if _uses_ai_state and is_instance_valid(_body):
		_body.apply_ai_stun(duration)
		remaining = _body.get_ai_stun_remaining()
		return
	remaining = maxf(remaining, duration)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_body) or _body.is_queued_for_deletion():
		queue_free()
		return
	if _body_is_dead():
		queue_free()
		return
	if _uses_ai_state:
		# The FSM owns timer, gravity and attack cleanup for supported enemies.
		remaining = _body.get_ai_stun_remaining()
		if not _body.is_ai_stunned(): queue_free()
		return
	# Combat remains frozen by global hit-stop; gravity still acts during stun.
	remaining -= delta
	_body.velocity.x = 0.0
	if not _body.is_on_floor(): _body.velocity += _body.get_gravity() * delta
	_body.move_and_slide()
	if remaining <= 0.0: queue_free()

func _body_is_dead() -> bool:
	return ("is_dead" in _body and _body.is_dead) or ("current_health" in _body and _body.current_health <= 0)

func _exit_tree() -> void:
	if _uses_ai_state: return
	if not is_instance_valid(_body) or not _body.is_inside_tree() or _body.is_queued_for_deletion(): return
	if _body_is_dead(): return
	_body.set_physics_process(_physics_was_enabled)
	_body.set_process(_process_was_enabled)
	for record in _animations:
		var node = record[0].get_ref()
		if is_instance_valid(node) and record[1]: node.play()
	for record in _areas:
		var node = record[0].get_ref()
		if is_instance_valid(node):
			node.set_block_signals(record[1])
			node.set_deferred("monitoring", record[2])
