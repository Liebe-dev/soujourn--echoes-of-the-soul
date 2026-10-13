extends HBoxContainer
## Compact row showing only currently active effects.

const SLOT_SCENE := preload("res://scenes/UI/status_icon_slot.tscn")

var _slots: Dictionary = {}

func set_effect(effect_id: String, level: int, is_buff: bool) -> void:
	if level <= 0:
		remove_effect(effect_id)
		return
	var slot: PanelContainer = _slots.get(effect_id)
	if slot == null:
		slot = SLOT_SCENE.instantiate()
		add_child(slot)
		_slots[effect_id] = slot
	visible = true
	if slot.has_method("configure"):
		slot.configure(effect_id, level, is_buff)

func remove_effect(effect_id: String) -> void:
	if not _slots.has(effect_id):
		return
	var slot: Node = _slots[effect_id]
	_slots.erase(effect_id)
	remove_child(slot)
	slot.queue_free()
	visible = not _slots.is_empty()

func clear_all() -> void:
	for id in _slots.keys():
		remove_effect(id)

func _ready() -> void:
	visible = not _slots.is_empty()
