@tool
extends Control
## View only: gameplay supplies remaining/total seconds; this node owns no timer or input.

@export var icon: Texture2D:
	set(value):
		icon = value
		if is_node_ready(): $Icon.texture = value
@export_group("Cooldown Appearance")
@export_range(0.0, 1.0, 0.01) var cooldown_opacity := 0.6:
	set(value):
		cooldown_opacity = value
		if is_node_ready(): _refresh()
@export var ready_border_color := Color.WHITE:
	set(value):
		ready_border_color = value
		if is_node_ready(): _refresh()
@export var cooldown_border_color := Color(0.5, 0.5, 0.5, 1.0):
	set(value):
		cooldown_border_color = value
		if is_node_ready(): _refresh()

var remaining := 0.0
var total := 0.0
var _border: StyleBoxFlat
var requirement_locked := false

func set_requirement_lock(locked: bool, reason: String = "") -> void:
	requirement_locked = locked
	mouse_filter = Control.MOUSE_FILTER_PASS if locked else Control.MOUSE_FILTER_IGNORE
	tooltip_text = ("Insufficient attributes: " if locked else "") + reason
	_refresh()

func _ready() -> void:
	_border = $Frame.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	$Frame.add_theme_stylebox_override("panel", _border)
	$Cooldown.material = $Cooldown.material.duplicate()
	$Icon.texture = icon
	_refresh()

func set_presentation(seconds_left: float, duration: float) -> void:
	remaining = maxf(seconds_left, 0.0)
	total = maxf(duration, 0.0)
	_refresh()

func _refresh() -> void:
	if not is_node_ready() or _border == null: return
	var cooling := remaining > 0.0 and total > 0.0
	var ratio := clampf(remaining / total, 0.0, 1.0) if cooling else 0.0
	_border.border_color = cooldown_border_color if cooling else ready_border_color
	$Cooldown.visible = cooling
	$Cooldown.material.set_shader_parameter("remaining_ratio", ratio)
	$Cooldown.material.set_shader_parameter("overlay_opacity", cooldown_opacity)
	$Icon.modulate = Color(0.35, 0.35, 0.35, 1) if requirement_locked else Color.WHITE
	$Remaining.visible = cooling or requirement_locked
	$Remaining.text = "LOCK" if requirement_locked else ("%.1fs" % (ceil(remaining * 10.0) / 10.0) if cooling else "")
