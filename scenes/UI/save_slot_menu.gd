extends Control
## Presentation only: the caller supplies summaries and owns save I/O.
signal slot_selected(slot: int, overwrite: bool)
signal cancelled

@export var slot_button_minimum_height := 52.0
@onready var slot_list: VBoxContainer = $Center/Panel/Margin/Contents/SlotList
@onready var status_label: Label = $Center/Panel/Margin/Contents/Status
@onready var back_button: Button = $Center/Panel/Margin/Contents/Back
@onready var confirmation: ConfirmationDialog = $OverwriteConfirmation
@onready var _title: Label = $Center/Panel/Margin/Contents/Title
var _mode: StringName = &"new"
var _summaries: Array[Dictionary] = []
var _pending_slot := -1
var _busy := false

func _ready() -> void:
	back_button.pressed.connect(_cancel)
	confirmation.confirmed.connect(_confirm)
	confirmation.canceled.connect(func(): _pending_slot = -1)

func open(mode: StringName, summaries: Array[Dictionary]) -> void:
	_mode = mode
	_summaries = summaries
	_pending_slot = -1
	confirmation.hide()
	modulate.a = 1.0
	_title.text = "New Game - Select Slot" if mode == &"new" else "Continue - Select Slot"
	status_label.text = "Existing slots require confirmation. Other slots will be preserved." if mode == &"new" else "Choose a save to continue. Unavailable saves are kept, not deleted."
	for child in slot_list.get_children():
		slot_list.remove_child(child)
		child.queue_free()
	for index in summaries.size():
		var info := summaries[index]
		var slot := index + 1
		var button := Button.new()
		button.custom_minimum_size.y = slot_button_minimum_height
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if info.get("empty", true):
			button.text = "Slot %d - Empty" % slot
		elif not info.get("loadable", false):
			button.text = "Slot %d - Invalid save / missing scene" % slot
		else:
			var prefix := "Backup: " if info.get("recovered", false) else ""
			button.text = "Slot %d - %s%s (%d/%d HP)" % [slot, prefix, info.checkpoint_id, info.hp, info.max_hp]
		button.pressed.connect(select_slot.bind(slot))
		slot_list.add_child(button)
	set_busy(false)
	show()
	back_button.grab_focus()

func set_busy(busy: bool) -> void:
	_busy = busy
	back_button.disabled = busy
	for index in slot_list.get_child_count():
		slot_list.get_child(index).disabled = busy or (_mode == &"continue" and not _summaries[index].get("loadable", false))
	if busy:
		_pending_slot = -1
		confirmation.hide()

func select_slot(slot: int) -> void:
	if _busy or not visible or confirmation.visible or slot < 1 or slot > _summaries.size(): return
	var info := _summaries[slot - 1]
	if _mode == &"continue" and not info.get("loadable", false): return
	if _mode == &"new" and not info.get("empty", true):
		_pending_slot = slot
		confirmation.dialog_text = "Start a new game in slot %d? This replaces only this slot and keeps a backup. Other slots will be preserved." % slot
		confirmation.popup_centered(Vector2i(560, 200))
	else:
		slot_selected.emit(slot, false)

func _confirm() -> void:
	var slot := _pending_slot
	_pending_slot = -1
	if not _busy and visible and slot > 0: slot_selected.emit(slot, true)

func close() -> void:
	_pending_slot = -1
	confirmation.hide()
	hide()

func _cancel() -> void:
	if not _busy: cancelled.emit()

func _input(event: InputEvent) -> void:
	if visible and not _busy and not confirmation.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()
