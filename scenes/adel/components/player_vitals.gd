extends RefCounted
## Player owns the model and its clocks. Views may come and go independently.
signal changed(mask: int)
signal damage_received(result: Dictionary)
signal combat_activity
signal flask_started(duration: float)
signal flask_finished(result: Dictionary)
const HP := 1
const STAMINA := 2
const MARKERS := 4
const STATUS := 8
const FLASK := 16
const ALL := 31
const FLASK_DURATION := 0.9
var model: StatsComponent
var simulation_enabled := true
var flask_in_progress := false
var _flask_left := 0.0
var _body: CharacterBody2D

func _init(body: CharacterBody2D, stats: StatsComponent) -> void:
	_body = body
	model = stats

func refresh(mask: int = ALL) -> void:
	changed.emit(mask)

func tick(game_delta: float, actor_delta: float) -> void:
	if not simulation_enabled or model.hp <= 0: return
	var hit := model.tick(actor_delta, _body.is_skill_damage_immune() or _body.is_sentinel_entering())
	if hit.damage_taken > 0:
		refresh(HP)
		damage_received.emit(hit)
	if hit.died:
		_handle_death()
		return
	if model.regen_stamina(actor_delta, _body.blocks_stamina_regeneration()):
		refresh(STAMINA)
		combat_activity.emit()
	if flask_in_progress:
		_flask_left = maxf(_flask_left - game_delta, 0.0)
		if _flask_left <= 0.0:
			flask_in_progress = false
			var result := model.use_soul_flask()
			refresh()
			flask_finished.emit(result)

func apply_damage(amount: int, origin: Vector2 = Vector2.INF, skip_thresholds: bool = false) -> Dictionary:
	if _body.is_skill_finish_frozen() or _body.is_skill_damage_immune() or _body.is_sentinel_entering():
		return {"damage_taken": 0, "staggered": false, "died": false}
	var result := model.apply_damage(amount, origin, skip_thresholds)
	refresh(HP | MARKERS | STATUS)
	damage_received.emit(result)
	if result.died: _handle_death()
	return result

func spend_stamina(action: String, partial: bool = false) -> bool:
	var spent := model.spend_stamina(action, partial)
	if spent and model.has_stamina_cost(action):
		refresh(STAMINA)
		combat_activity.emit()
	return spent

func drain_hp_nonlethal(amount: int) -> int:
	var spent := model.drain_hp_nonlethal(amount)
	if spent > 0: refresh(HP)
	return spent

func spend_sentinel_hp(amount: int) -> bool:
	# Costs must be affordable and leave at least one HP. They never enter damage resolution.
	if not _body.is_sentinel_active() or _body.is_sentinel_entering() or _body.is_sentinel_exit_pending(): return false
	if amount < 0 or model.hp <= 0 or model.hp - amount < 1: return false
	drain_hp_nonlethal(amount)
	_body.sentinel_state.check_depletion()
	return true

func heal_to_full() -> void:
	model.heal_to_full()
	refresh()

func begin_flask_use() -> bool:
	if _body.is_sentinel_active() or flask_in_progress or not model.can_use_soul_flask(): return false
	flask_in_progress = true
	_flask_left = FLASK_DURATION
	flask_started.emit(FLASK_DURATION)
	return true

func cancel_transients() -> void:
	if not flask_in_progress: return
	flask_in_progress = false
	_flask_left = 0.0
	flask_finished.emit({"used": false})

func _handle_death() -> void:
	cancel_transients()
	_body.end_sentinel()
	SaveManager.respawn_at_checkpoint()
