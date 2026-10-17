extends VBoxContainer
signal focus_targets_changed
@onready var preferences = get_node("/root/VideoPreferences")
@onready var mode_select: OptionButton = $DisplayRows/ModeRow/Mode
@onready var resolution_select: OptionButton = $DisplayRows/ResolutionRow/Resolution
@onready var vsync_toggle: CheckButton = $PerformanceRows/VSync
@onready var fps_select: OptionButton = $PerformanceRows/FPSRow/FPS
@onready var apply_button: Button = $Footer/Apply
@onready var revert_button: Button = $Footer/Revert
@onready var defaults_button: Button = $Footer/Defaults
@onready var status: Label = $Status
@onready var confirmation_layer: CanvasLayer = $ConfirmationLayer
@onready var countdown_label: Label = $ConfirmationLayer/Overlay/Center/Panel/Margin/Contents/Countdown
@onready var keep_button: Button = $ConfirmationLayer/Overlay/Center/Panel/Margin/Contents/Buttons/Keep
@onready var undo_button: Button = $ConfirmationLayer/Overlay/Center/Panel/Margin/Contents/Buttons/Revert

var _draft: Dictionary = {}
var _resolutions: Array[Vector2i] = []
var _was_pending := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for text in ["Windowed", "Borderless", "Fullscreen"]: mode_select.add_item(text)
	for fps in preferences.FPS_OPTIONS: fps_select.add_item("Unlimited" if fps == 0 else str(fps) + " FPS")
	mode_select.item_selected.connect(_on_mode_selected)
	resolution_select.item_selected.connect(_on_resolution_selected)
	fps_select.item_selected.connect(_on_fps_selected)
	vsync_toggle.toggled.connect(_on_vsync_toggled)
	apply_button.pressed.connect(_apply)
	revert_button.pressed.connect(_discard)
	defaults_button.pressed.connect(_defaults)
	keep_button.pressed.connect(_keep)
	undo_button.pressed.connect(_undo)
	preferences.settings_changed.connect(_load_confirmed)
	preferences.preview_changed.connect(_on_preview_changed)
	visibility_changed.connect(_on_visibility_changed)
	_load_confirmed()

func _load_confirmed() -> void:
	_draft = preferences.confirmed.duplicate(true)
	_refresh_form()

func _refresh_form() -> void:
	mode_select.select(preferences.MODES.find(_draft.mode))
	vsync_toggle.set_pressed_no_signal(_draft.vsync)
	fps_select.select(preferences.FPS_OPTIONS.find(_draft.max_fps))
	resolution_select.clear()
	_resolutions = preferences.window_sizes()
	if _draft.mode == "windowed":
		var selected := Vector2i(_draft.width, _draft.height)
		if not _resolutions.has(selected): _resolutions.append(selected)
		for resolution in _resolutions: resolution_select.add_item("%d x %d" % [resolution.x, resolution.y])
		resolution_select.select(_resolutions.find(selected))
	else:
		var desktop: Vector2i = preferences.desktop_size()
		resolution_select.add_item("%d x %d (Desktop)" % [desktop.x, desktop.y])
	resolution_select.disabled = _draft.mode != "windowed" or preferences.pending
	mode_select.disabled = preferences.pending
	fps_select.disabled = preferences.pending
	vsync_toggle.disabled = preferences.pending
	apply_button.disabled = _draft == preferences.confirmed or preferences.pending
	revert_button.disabled = apply_button.disabled
	defaults_button.disabled = preferences.pending
	$DisplayHint.text = "Choose a window size. The game keeps its original aspect ratio." if _draft.mode == "windowed" else "Fullscreen modes use the current desktop resolution."
	focus_targets_changed.emit()

func _on_mode_selected(index: int) -> void:
	_draft.mode = preferences.MODES[index]
	_refresh_form()
	status.text = "Changes are not applied yet."

func _on_resolution_selected(index: int) -> void:
	_draft.width = _resolutions[index].x
	_draft.height = _resolutions[index].y
	_refresh_form()
	status.text = "Changes are not applied yet."

func _on_fps_selected(index: int) -> void:
	_draft.max_fps = preferences.FPS_OPTIONS[index]
	_refresh_form()
	status.text = "Changes are not applied yet."

func _on_vsync_toggled(enabled: bool) -> void:
	_draft.vsync = enabled
	_refresh_form()
	status.text = "Changes are not applied yet."

func _apply() -> void:
	var problem: String = preferences.apply_settings(_draft)
	if not problem.is_empty():
		status.text = problem
	elif preferences.pending:
		status.text = "Confirm the display change."
	else:
		status.text = "Video settings saved."
	_refresh_form()

func _discard() -> void:
	if preferences.pending: preferences.revert()
	_load_confirmed()
	status.text = "Unapplied changes discarded."

func _defaults() -> void:
	_draft = preferences.defaults()
	_refresh_form()
	status.text = "Defaults selected. Apply to save."

func _keep() -> void:
	var problem: String = preferences.confirm()
	status.text = problem if not problem.is_empty() else "Video settings saved."

func _undo() -> void:
	preferences.revert()
	status.text = "Previous settings restored."

func is_confirming() -> bool:
	return preferences.pending and is_visible_in_tree()

func popup_is_open() -> bool:
	return mode_select.get_popup().visible or resolution_select.get_popup().visible or fps_select.get_popup().visible

func _on_preview_changed() -> void:
	if not is_node_ready(): return
	confirmation_layer.visible = preferences.pending and is_visible_in_tree()
	if preferences.pending:
		countdown_label.text = "Keep these display settings?\nReverting in %d seconds." % preferences.remaining_seconds()
		if not _was_pending:
			_was_pending = true
			_refresh_form()
			keep_button.grab_focus()
	else:
		var was_pending := _was_pending
		_was_pending = false
		_load_confirmed()
		if was_pending and is_visible_in_tree():
			status.text = "Previous settings restored."
			mode_select.grab_focus()

func focus_targets() -> Array[Control]:
	var targets: Array[Control] = []
	if not is_visible_in_tree(): return targets
	if is_confirming(): return [keep_button, undo_button]
	for item in [mode_select, resolution_select, vsync_toggle, fps_select, apply_button, revert_button, defaults_button]:
		if not item.disabled: targets.append(item)
	return targets

func _input(event: InputEvent) -> void:
	if not is_confirming(): return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_undo()
	elif event.is_echo():
		get_viewport().set_input_as_handled()

func _on_visibility_changed() -> void:
	if not is_node_ready(): return
	if not is_visible_in_tree():
		if preferences.pending: preferences.revert()
		confirmation_layer.hide()
		_load_confirmed()
	else:
		_load_confirmed()
		status.text = "Choose settings, then Apply."

func _exit_tree() -> void:
	if not is_instance_valid(preferences): return
	if preferences.settings_changed.is_connected(_load_confirmed): preferences.settings_changed.disconnect(_load_confirmed)
	if preferences.preview_changed.is_connected(_on_preview_changed): preferences.preview_changed.disconnect(_on_preview_changed)
	if preferences.pending: preferences.revert()
