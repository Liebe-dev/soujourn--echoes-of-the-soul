extends Node
## Sole owner of combat time-scale pulses. Durations use unpaused wall time.
signal effect_finished(owner: Object, lane: StringName)
var _effects: Dictionary = {}
var _base_scale := 1.0
var _last_usec := 0
var _owns_scale := false
var _actor_exemptions: Dictionary = {}
var _actor_timeouts: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_usec = Time.get_ticks_usec()

func request(owner: Node, lane: StringName, scale: float, duration: float, delay: float = 0.0) -> float:
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or duration <= 0.0: return 0.0
	if _effects.is_empty():
		_base_scale = Engine.time_scale
		_owns_scale = true
		_last_usec = Time.get_ticks_usec()
	var key := str(owner.get_instance_id()) + ":" + String(lane)
	# Repeated impact requests take the larger remainder, never sum or shorten it.
	if lane == &"hit_stop" and _effects.has(key):
		duration = maxf(duration, _effects[key].left)
		scale = minf(scale, _effects[key].scale)
	# Replace this lane; simultaneous contacts never add their durations together.
	_effects[key] = {"owner": weakref(owner), "lane": lane, "scale": clampf(scale, 0.01, 1.0), "left": duration, "delay": maxf(delay, 0.0)}
	_apply_scale()
	return duration

func remove(owner: Node, lane: StringName = &"") -> void:
	for key in _effects.keys():
		var effect: Dictionary = _effects[key]
		if effect.owner.get_ref() == owner and (lane == &"" or effect.lane == lane): _effects.erase(key)
	_apply_scale()

func is_hit_stopping() -> bool:
	for effect in _effects.values():
		if effect.lane == &"hit_stop" and effect.delay <= 0.0: return true
	return false

func _process(_delta: float) -> void:
	_refresh_actor_timers()
	_tick_actor_timeouts(_delta)
	var now := Time.get_ticks_usec()
	var elapsed := float(now - _last_usec) / 1000000.0
	_last_usec = now
	if _effects.is_empty(): return
	if get_tree().paused:
		Engine.time_scale = _base_scale
		return
	var finished: Array = []
	for key in _effects.keys():
		var effect: Dictionary = _effects[key]
		var owner = effect.owner.get_ref()
		if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion():
			_effects.erase(key)
			continue
		var active_elapsed := maxf(elapsed - effect.delay, 0.0)
		effect.delay = maxf(effect.delay - elapsed, 0.0)
		effect.left -= active_elapsed
		if effect.left <= 0.0:
			finished.append([owner, effect.lane])
			_effects.erase(key)
	_apply_scale()
	for item in finished:
		if is_instance_valid(item[0]) and not item[0].is_queued_for_deletion(): effect_finished.emit(item[0], item[1])

func _apply_scale() -> void:
	if not _owns_scale: return
	if _effects.is_empty():
		Engine.time_scale = _base_scale
		_owns_scale = false
		return
	var scale := _base_scale
	if not get_tree().paused:
		for effect in _effects.values():
			if effect.delay <= 0.0: scale = minf(scale, effect.scale)
	Engine.time_scale = scale

func _exit_tree() -> void:
	if not _effects.is_empty(): Engine.time_scale = _base_scale

func set_actor_exempt(actor: Node, enabled: bool) -> void:
	if not is_instance_valid(actor): return
	var id := actor.get_instance_id()
	if enabled:
		if _actor_exemptions.has(id): return
		var timers: Array = []
		for timer in actor.find_children("*", "Timer", true, false):
			timers.append([weakref(timer), timer.ignore_time_scale])
		_actor_exemptions[id] = {"owner": weakref(actor), "timers": timers}
	else:
		if not _actor_exemptions.has(id): return
		for record in _actor_exemptions[id].timers:
			var timer = record[0].get_ref()
			if is_instance_valid(timer): timer.ignore_time_scale = record[1]
		_actor_exemptions.erase(id)
	_refresh_actor_timers()

func actor_delta(actor: Node, delta: float) -> float:
	if not is_instance_valid(actor) or not _actor_exemptions.has(actor.get_instance_id()) or is_hit_stopping(): return delta
	return delta * _base_scale / maxf(Engine.time_scale, 0.01)

func actor_timeout(actor: Node, seconds: float, callback: Callable) -> void:
	_actor_timeouts.append({"owner": weakref(actor), "left": maxf(seconds, 0.0), "callback": callback})

func _tick_actor_timeouts(delta: float) -> void:
	if get_tree().paused: return
	var pending := _actor_timeouts
	_actor_timeouts = []
	var finished: Array[Callable] = []
	for timer in pending:
		var actor = timer.owner.get_ref()
		if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion(): continue
		timer.left -= actor_delta(actor, delta)
		if timer.left <= 0.0:
			if timer.callback.is_valid(): finished.append(timer.callback)
		else: _actor_timeouts.append(timer)
	for callback in finished: callback.call()

func _refresh_actor_timers() -> void:
	for id in _actor_exemptions.keys():
		var record: Dictionary = _actor_exemptions[id]
		var actor = record.owner.get_ref()
		if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion():
			_actor_exemptions.erase(id)
			continue
		for timer_record in record.timers:
			var timer = timer_record[0].get_ref()
			if is_instance_valid(timer): timer.ignore_time_scale = not is_hit_stopping()
