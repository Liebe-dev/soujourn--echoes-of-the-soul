class_name DeflectSlowMotion
extends Node
## Owns a global time-scale pulse and restores it on completion or owner removal.

signal finished

var is_active := false
var _previous_scale := 1.0
var _generation := 0

func start(scale: float = 0.6, duration: float = 0.2) -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if not is_active:
		_previous_scale = Engine.time_scale
	is_active = true
	_generation += 1
	Engine.time_scale = clampf(scale, 0.05, 1.0)
	# Duration is wall time, independent of the time scale this pulse changes.
	get_tree().create_timer(maxf(duration, 0.01), true, false, true).timeout.connect(
		_on_timeout.bind(_generation), CONNECT_ONE_SHOT
	)

func cancel() -> void:
	_generation += 1
	_restore_scale()

func _on_timeout(generation: int) -> void:
	if generation != _generation or not is_active:
		return
	_restore_scale()
	finished.emit()

func _restore_scale() -> void:
	if not is_active:
		return
	Engine.time_scale = _previous_scale
	is_active = false

func _exit_tree() -> void:
	cancel()
