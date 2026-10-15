class_name DeflectSlowMotion
extends Node
## Deflect pose lifetime; CombatTime arbitrates its scale with hit-stop.
signal finished
var is_active := false
var _time: Node

func _ready() -> void:
	_time = get_node("/root/CombatTime")
	_time.effect_finished.connect(_on_effect_finished)

func start(scale: float = 0.6, duration: float = 0.2, delay: float = 0.0) -> void:
	if not is_inside_tree() or is_queued_for_deletion(): return
	is_active = true
	_time.request(self, &"deflect", scale, maxf(duration, 0.01), delay)

func cancel() -> void:
	is_active = false
	if is_instance_valid(_time): _time.remove(self, &"deflect")

func _on_effect_finished(owner: Object, lane: StringName) -> void:
	if owner != self or lane != &"deflect" or not is_active: return
	is_active = false
	finished.emit()

func _exit_tree() -> void:
	cancel()
