@tool
extends Control
## Screen-space layout and presentation; never equips weapons or executes abilities.

const REFERENCE_SIZE := Vector2(515, 214)
const SLOT_NAMES := ["Q", "E", "Skill1", "Skill2", "Skill3", "Skill4"]

@export_group("Sentinel Layout")
@export_range(0.25, 3.0, 0.05) var hud_scale: float = 1.0:
	set(value):
		hud_scale = value
		if is_node_ready(): _layout()
@export var screen_margin := Vector2(24, 24):
	set(value):
		screen_margin = value
		if is_node_ready(): _layout()
@export var reserved_top: float = 220.0:
	set(value):
		reserved_top = value
		if is_node_ready(): _layout()
@export_group("Editor Preview")
@export var preview_active: bool = false:
	set(value):
		preview_active = value
		if is_node_ready() and Engine.is_editor_hint(): visible = value

var sentinel_active := false
var exit_pending := false

func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()
	visible = preview_active if Engine.is_editor_hint() else sentinel_active

func set_active(active: bool) -> void:
	sentinel_active = active
	visible = active
	if not active:
		exit_pending = false
		for slot_name in SLOT_NAMES: get_node(slot_name).reset_presentation()

func set_exit_pending(pending: bool) -> void:
	exit_pending = pending and sentinel_active
	for slot_name in SLOT_NAMES: get_node(slot_name).set_exit_pending(exit_pending)

func set_ability_presentation(slot: StringName, remaining: float, total: float, affordable: bool = true, available: bool = true) -> void:
	var key := String(slot)
	if key in ["1", "2", "3", "4"]: key = "Skill" + key
	if key not in SLOT_NAMES: return
	get_node(key).set_presentation(remaining, total, affordable, available)

func _layout() -> void:
	# Editor scene switches can retain ready nodes outside the SceneTree.
	if not is_inside_tree() or not is_node_ready(): return
	var viewport_size := get_viewport_rect().size
	var margin := screen_margin.max(Vector2.ZERO)
	var available := Vector2(maxf(viewport_size.x - margin.x * 2.0, 1.0), maxf(viewport_size.y - margin.y - reserved_top, 1.0))
	var fit := minf(available.x / REFERENCE_SIZE.x, available.y / REFERENCE_SIZE.y)
	scale = Vector2.ONE * minf(maxf(hud_scale, 0.25), fit)
	position = Vector2(margin.x, viewport_size.y - margin.y - REFERENCE_SIZE.y * scale.y)
