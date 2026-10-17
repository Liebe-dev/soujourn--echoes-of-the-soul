extends VBoxContainer
@onready var bindings = get_node("/root/InputBindings")
signal focus_targets_changed
const ROW := preload("res://scenes/UI/control_binding_row.tscn")

@onready var rows: VBoxContainer = $Scroll/ListMargin/Rows
@onready var status: Label = $Status
@onready var cancel_button: Button = $Footer/CancelBinding
@onready var reset_button: Button = $Footer/ResetDefaults
@onready var reset_dialog: ConfirmationDialog = $ResetConfirmation
var _rows: Dictionary = {}
var _capture_action: StringName = &""
var _capture_index := 0
var _pending_modifier: InputEventKey

func _ready() -> void:
	for definition in bindings.ACTIONS:
		var row := ROW.instantiate()
		row.get_node("Action").text = definition.label
		row.get_node("Primary").pressed.connect(start_capture.bind(definition.action, 0))
		row.get_node("Secondary").pressed.connect(start_capture.bind(definition.action, 1))
		row.get_node("Clear").pressed.connect(_clear.bind(definition.action))
		row.get_node("Reset").pressed.connect(_reset_one.bind(definition.action))
		rows.add_child(row)
		_rows[definition.action] = row
	cancel_button.pressed.connect(cancel_capture)
	reset_button.pressed.connect(func(): reset_dialog.popup_centered(Vector2i(600, 220)))
	reset_dialog.confirmed.connect(_reset_all)
	bindings.bindings_changed.connect(_refresh_rows)
	visibility_changed.connect(_on_visibility_changed)
	_refresh_rows()

func _refresh_rows() -> void:
	for action in _rows:
		var assigned: Array = bindings.get_bindings(action)
		var row: HBoxContainer = _rows[action]
		row.get_node("Primary").text = bindings.label_for(assigned[0])
		row.get_node("Secondary").text = bindings.label_for(assigned[1]) if assigned.size() > 1 else "Unassigned"
		row.get_node("Primary").tooltip_text = row.get_node("Primary").text
		row.get_node("Secondary").tooltip_text = row.get_node("Secondary").text
		row.get_node("Clear").disabled = assigned.size() < 2
	focus_targets_changed.emit()

func focus_targets() -> Array[Control]:
	var targets: Array[Control] = []
	if not is_visible_in_tree(): return targets
	for row in rows.get_children():
		for name in ["Primary", "Secondary", "Clear", "Reset"]:
			var button: Button = row.get_node(name)
			if not button.disabled: targets.append(button)
	if cancel_button.visible: targets.append(cancel_button)
	targets.append(reset_button)
	return targets

func is_capturing() -> bool:
	return not _capture_action.is_empty()

func start_capture(action: StringName, index: int) -> void:
	cancel_capture(false)
	_capture_action = action
	_capture_index = index
	_rows[action].get_node("Primary" if index == 0 else "Secondary").text = "Press input..."
	status.text = "Press a key or mouse button. Esc cancels."
	cancel_button.show()
	focus_targets_changed.emit()

func cancel_capture(show_message := true) -> void:
	var action := _capture_action
	var index := _capture_index
	_capture_action = &""
	_pending_modifier = null
	if not is_node_ready(): return
	cancel_button.hide()
	_refresh_rows()
	if show_message: status.text = "Binding cancelled."
	if not action.is_empty() and is_visible_in_tree():
		_rows[action].get_node("Primary" if index == 0 else "Secondary").grab_focus()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not is_capturing(): return
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.is_pressed() and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE):
		cancel_capture()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and cancel_button.get_global_rect().has_point(event.position):
		cancel_capture()
		return
	if event.is_echo(): return
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode else event.keycode
		if code in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			if event.is_pressed():
				_pending_modifier = event.duplicate()
				return
			if _pending_modifier != null:
				_save_binding(_pending_modifier)
			return
	if not event.is_pressed(): return
	if not (event is InputEventKey or event is InputEventMouseButton): return
	_save_binding(event)

func _save_binding(event: InputEvent) -> void:
	var problem: String = bindings.bind(_capture_action, _capture_index, event)
	if not problem.is_empty():
		status.text = problem + " Choose another input, or Esc to cancel."
		return
	cancel_capture(false)
	status.text = "Binding saved."

func _clear(action: StringName) -> void:
	var problem: String = bindings.clear_secondary(action)
	status.text = problem if not problem.is_empty() else "Secondary binding cleared."
	_rows[action].get_node("Secondary").grab_focus()

func _reset_one(action: StringName) -> void:
	var problem: String = bindings.reset_action(action)
	status.text = problem if not problem.is_empty() else "Default binding restored."
	_rows[action].get_node("Primary").grab_focus()

func _reset_all() -> void:
	cancel_capture(false)
	var problem: String = bindings.reset_defaults()
	status.text = problem if not problem.is_empty() else "All default controls restored."
	reset_button.grab_focus()

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		cancel_capture(false)
		reset_dialog.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and is_capturing():
		cancel_capture()
