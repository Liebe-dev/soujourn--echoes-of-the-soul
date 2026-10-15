@tool
extends Control

@export_group("Ultimate Appearance")
@export var meter_size := Vector2(132, 22):
	set(value):
		meter_size = value.max(Vector2(20, 10))
		if is_node_ready(): _refresh()
@export_range(0.0, 3.0, 0.05) var fire_speed: float = 0.35:
	set(value):
		fire_speed = value
		if is_node_ready(): _refresh()
@export_group("Editor Preview")
@export_range(0.0, 100.0, 1.0) var preview_charge: float = 100.0:
	set(value):
		preview_charge = value
		if is_node_ready() and Engine.is_editor_hint(): _refresh()

var charge := 0.0
var maximum := 100.0
var sentinel_active := false
var _visual_time := 0.0

func _ready() -> void:
	_refresh()

func _process(delta: float) -> void:
	_visual_time = fmod(_visual_time + delta, 4096.0)
	$Fill.material.set_shader_parameter("visual_time", _visual_time)

func set_charge(value: float, max_value: float = 100.0) -> void:
	maximum = maxf(max_value, 0.001)
	charge = clampf(value, 0.0, maximum)
	_refresh()

func set_active(active: bool) -> void:
	sentinel_active = active
	_refresh()

func is_ultimate_ready() -> bool:
	return not sentinel_active and charge >= maximum

func _refresh() -> void:
	if not is_node_ready(): return
	var ratio := preview_charge / 100.0 if Engine.is_editor_hint() else charge / maximum
	if sentinel_active: ratio = 0.0
	var full := ratio >= 1.0
	size = meter_size
	$Track.size = meter_size
	$Fill.position = Vector2(2, 2)
	$Fill.size = meter_size - Vector2(4, 4)
	$Fill.material.set_shader_parameter("progress", ratio)
	$Fill.material.set_shader_parameter("ready", full)
	$Fill.material.set_shader_parameter("fire_speed", fire_speed)
	$ClawsLeft.visible = full
	$ClawsRight.visible = full
	$Prompt.visible = full
	$ClawsLeft.position = Vector2(-16, (meter_size.y - 40.0) * 0.5)
	$ClawsRight.position = Vector2(meter_size.x - 8.0, (meter_size.y - 40.0) * 0.5)
	$Prompt.position = Vector2(meter_size.x + 25.0, -3.0)
