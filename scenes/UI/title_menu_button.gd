extends Button
## Shared mouse/keyboard presentation for title buttons.
signal highlighted

@export_range(1.0, 3.0, 0.05) var pressed_scale := 2.0
@export_range(0.0, 2.0, 0.05) var pressed_duration := 1.0

@onready var highlight: TextureRect = $SelectionHighlight
var _base_scale := Vector2.ONE
var _press_tween: Tween

func _ready() -> void:
	_base_scale = highlight.scale
	highlight.pivot_offset = highlight.size * 0.5
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_entered.connect(_on_highlight_entered)
	mouse_exited.connect(_refresh_highlight)
	focus_entered.connect(_on_highlight_entered)
	focus_exited.connect(_refresh_highlight)
	visibility_changed.connect(_reset_presentation)
	pressed.connect(_animate_press)
	_refresh_highlight()

func _on_highlight_entered() -> void:
	if not disabled:
		highlighted.emit()
	_refresh_highlight()

func _refresh_highlight() -> void:
	highlight.visible = not disabled and is_visible_in_tree() and (is_hovered() or has_focus())
	if not highlight.visible:
		_reset_scale()

func _reset_scale() -> void:
	if _press_tween != null: _press_tween.kill()
	highlight.scale = _base_scale

func _reset_presentation() -> void:
	if not is_node_ready(): return
	_reset_scale()
	_refresh_highlight()

func _animate_press() -> void:
	_reset_scale()
	_press_tween = create_tween()
	_press_tween.tween_property(highlight, "scale", _base_scale * pressed_scale, pressed_duration)
