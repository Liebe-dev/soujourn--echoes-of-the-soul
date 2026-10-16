@tool
extends Control
## Normal-form loadout view. Item slots and left-hand equipment are presentation placeholders.
const REFERENCE_SIZE := Vector2(234, 99)
@export_group("Weapon Layout")
@export_range(0.25, 3.0, 0.05) var hud_scale := 1.0:
	set(value):
		hud_scale = value
		if is_node_ready(): _layout()
@export var screen_margin := Vector2(24, 24):
	set(value):
		screen_margin = value
		if is_node_ready(): _layout()
@export var reserved_top := 220.0:
	set(value):
		reserved_top = value
		if is_node_ready(): _layout()
@export_group("Weapon Appearance")
@export var right_weapon: Texture2D:
	set(value):
		right_weapon = value
		if is_node_ready(): $RightWeaponArtwork.texture = value
@export var left_weapon: Texture2D:
	set(value):
		left_weapon = value
		if is_node_ready(): $LeftWeaponArtwork.texture = value
@export_range(0.0, 1.0, 0.01) var inset_opacity := 0.32:
	set(value):
		inset_opacity = value
		if is_node_ready(): $Inset.material.set_shader_parameter("inset_opacity", value)

func _ready() -> void:
	$Inset.material = $Inset.material.duplicate()
	$Inset.material.set_shader_parameter("inset_opacity", inset_opacity)
	$RightWeaponArtwork.texture = right_weapon
	$LeftWeaponArtwork.texture = left_weapon
	get_viewport().size_changed.connect(_layout)
	_layout()

func set_ability_presentation(slot: StringName, remaining: float, total: float) -> void:
	if slot not in [&"Q", &"E"]: return
	var ability := get_node_or_null(NodePath(slot))
	if ability != null: ability.set_presentation(remaining, total)

func _layout() -> void:
	if not is_inside_tree() or not is_node_ready(): return
	var viewport_size := get_viewport_rect().size
	var margin := screen_margin.max(Vector2.ZERO)
	var available := Vector2(maxf(viewport_size.x - margin.x * 2.0, 1.0), maxf(viewport_size.y - margin.y - reserved_top, 1.0))
	var fit := minf(available.x / REFERENCE_SIZE.x, available.y / REFERENCE_SIZE.y)
	scale = Vector2.ONE * minf(maxf(hud_scale, 0.25), fit)
	position = Vector2(margin.x, viewport_size.y - margin.y - REFERENCE_SIZE.y * scale.y)
