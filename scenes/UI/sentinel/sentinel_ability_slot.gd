@tool
extends Control
## Presentation only. Costs, timers and input are owned by the future ability controller.

@export var icon: Texture2D:
	set(value):
		icon = value
		if is_node_ready(): $Icon.texture = value
@export var key_label: String = "1":
	set(value):
		key_label = value
		if is_node_ready(): $Key.text = value

var _remaining := 0.0
var _total := 0.0
var _affordable := true
var _available := true
var _exit_pending := false

func _ready() -> void:
	$Icon.texture = icon
	$Key.text = key_label
	resized.connect(_refresh)
	_refresh()

func set_presentation(remaining: float, total: float, affordable: bool = true, available: bool = true) -> void:
	_remaining = maxf(remaining, 0.0)
	_total = maxf(total, 0.0)
	_affordable = affordable
	_available = available
	_refresh()

func set_exit_pending(pending: bool) -> void:
	_exit_pending = pending
	_refresh()

func reset_presentation() -> void:
	_exit_pending = false
	set_presentation(0.0, 0.0)

func _refresh() -> void:
	if not is_node_ready(): return
	var blocked := not _available or not _affordable or _exit_pending
	$Icon.modulate = Color(0.45, 0.45, 0.45, 1.0) if blocked else Color.WHITE
	$Key.modulate = Color(0.7, 0.36, 0.36, 1.0) if blocked else Color.WHITE
	var ratio := clampf(_remaining / _total, 0.0, 1.0) if _total > 0.0 else 0.0
	$Cooldown.visible = ratio > 0.0
	$Cooldown.size = Vector2(size.x, size.y * ratio)
	$Remaining.visible = _remaining > 0.0
	$Remaining.text = str(int(ceil(_remaining)))
