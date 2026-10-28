class_name SaberSkillVFX
extends Node2D
## Approved two-tooth brush artwork, consumed tail-first on a real-time clock.

const SHADER: Shader = preload("res://scenes/adel/components/saber_skill_arc.gdshader")

@export var enabled := true
@export_node_path("AnimationPlayer") var animation_player_path := NodePath("../AnimationPlayer")
@export_node_path("Sprite2D") var source_sprite_path := NodePath("../TestAttackSprite")
@export_group("Appearance")
@export var tint := Color("#ef241e")
@export var highlight_tint := Color("#f55d58")
@export_range(0.0, 1.0, 0.01) var dash_opacity := 1.0
@export_range(0.0, 1.0, 0.01) var slash_opacity := 1.0
@export_group("Lunge (source-frame pixels)")
@export var dash_offset_pixels := Vector2.ZERO
@export var dash_scale := Vector2.ONE
@export var dash_texture: Texture2D = preload("res://asset/VFX/Adel/Saber/skill_q_lunge.png")
@export var dash_frame_rect := Rect2(-120.0, 505.0, 1063.0, 181.77942)
@export_range(-10, 10, 1) var dash_z_offset := 1
@export_group("Recovery slash (source-frame pixels)")
@export var slash_offset_pixels := Vector2.ZERO
@export var slash_scale := Vector2.ONE
@export var slash_texture: Texture2D = preload("res://asset/VFX/Adel/Saber/skill_q_slash.png")
@export var slash_frame_rect := Rect2(64.18893, 40.96652, 1057.6809, 699.0335)
@export_range(-10, 10, 1) var slash_z_offset := -1
@export_group("Lifetime (real seconds)")
@export_range(0.0, 0.1, 0.001, "suffix:s") var slash_hold := 0.012
@export_range(0.01, 0.8, 0.001, "suffix:s") var slash_lifetime := 0.18

var _player: AnimationPlayer
var _source: Sprite2D
var _sprite_parent: Node2D
var _body: CharacterBody2D
var _skill: SaberWeaponSkill
var _dash: MeshInstance2D
var _slash: MeshInstance2D
var _full_dash: ArrayMesh
var _full_slash: ArrayMesh
var _dash_frame_local := Transform2D.IDENTITY
var _holding_dash := false
var _impact_born := -1
var _impact_duration := 0.0
var _slash_born := -1
var _dash_strip: Dictionary
var _slash_strip: Dictionary
static var _strip_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 100
	_player = get_node_or_null(animation_player_path) as AnimationPlayer
	_source = get_node_or_null(source_sprite_path) as Sprite2D
	if _player == null or _source == null or dash_texture == null or slash_texture == null or not dash_frame_rect.has_area() or not slash_frame_rect.has_area():
		push_error("SaberSkillVFX needs its source sprite, AnimationPlayer, artwork and positive frame rectangles.")
		set_process(false)
		return
	_sprite_parent = _source.get_parent() as Node2D
	var cursor: Node = get_parent()
	while cursor != null:
		if cursor is CharacterBody2D:
			_body = cursor as CharacterBody2D
			break
		cursor = cursor.get_parent()
	_dash_strip = _bake_strip(dash_texture)
	_slash_strip = _bake_strip(slash_texture)
	if _dash_strip.is_empty() or _slash_strip.is_empty():
		push_error("SaberSkillVFX artwork must contain a continuous opaque stroke.")
		set_process(false)
		return
	_full_dash = _build_dash_mesh()
	_full_slash = _build_slash_mesh()
	_dash = _new_mesh("SkillDash", _full_dash, dash_texture)
	_slash = _new_mesh("SkillRecoverySlash", _full_slash, slash_texture)
	# The parent Player finishes constructing its components after the rig is ready.
	_bind_skill.call_deferred()

func _bind_skill() -> void:
	if is_instance_valid(_skill) or not is_instance_valid(_body):
		return
	_skill = _body.get("saber_skill") as SaberWeaponSkill
	if _skill == null:
		return
	_skill.lunge_started.connect(_on_lunge_started)
	_skill.impact_confirmed.connect(_on_impact_confirmed)
	_skill.recovery_started.connect(_on_recovery_started)
	_skill.ended.connect(_on_skill_ended)

func _new_mesh(node_name: String, geometry: ArrayMesh, artwork: Texture2D) -> MeshInstance2D:
	var node := MeshInstance2D.new()
	node.name = node_name
	node.top_level = true
	node.z_as_relative = false
	node.mesh = geometry
	node.texture = artwork
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	node.visible = false
	var material := ShaderMaterial.new()
	material.shader = SHADER
	node.material = material
	add_child(node)
	return node

func _on_lunge_started() -> void:
	clear_effects()
	if not enabled:
		return
	_dash_frame_local = _source.transform * _frame_basis()
	_holding_dash = true
	_dash.mesh = _full_dash
	_update_held_dash()

func _on_impact_confirmed(hit_stop_seconds: float) -> void:
	if not enabled or not _holding_dash:
		return
	# Current sprite is now skill_5. Use the cached skill_4 frame at contact position.
	_dash.global_transform = _dash_transform()
	_holding_dash = false
	_impact_duration = maxf(hit_stop_seconds, 0.0)
	_impact_born = Time.get_ticks_usec() if _impact_duration > 0.0 else -1
	_dash.visible = _impact_born >= 0

func _on_recovery_started(hit_confirmed: bool) -> void:
	if not enabled:
		return
	_holding_dash = false
	if not hit_confirmed or _impact_born < 0:
		_dash.visible = false
		_impact_born = -1
	_slash_born = Time.get_ticks_usec()
	_slash.mesh = _full_slash
	_slash.global_transform = _source.global_transform * _frame_basis() * _adjustment(slash_scale, slash_offset_pixels)
	_slash.z_index = clampi(_source_depth() + slash_z_offset, -4094, 4094)
	_slash.visible = _source.is_visible_in_tree()
	_set_appearance(_slash, slash_opacity)

func _on_skill_ended(interrupted: bool) -> void:
	_holding_dash = false
	if interrupted:
		clear_effects()
	elif _impact_born < 0:
		_dash.visible = false

func _process(_delta: float) -> void:
	if not is_instance_valid(_skill):
		_bind_skill()
	if not enabled:
		clear_effects()
		return
	if _holding_dash:
		_update_held_dash()
	_tick_effects(Time.get_ticks_usec())

func _update_held_dash() -> void:
	_dash.global_transform = _dash_transform()
	_dash.z_index = clampi(_source_depth() + dash_z_offset, -4094, 4094)
	_dash.visible = _source.is_visible_in_tree()
	_set_appearance(_dash, dash_opacity)

func _tick_effects(now_usec: int) -> void:
	if _impact_born >= 0:
		var progress := clampf(float(now_usec - _impact_born) / 1000000.0 / _impact_duration, 0.0, 1.0)
		_dash.visible = progress < 1.0
		if _dash.visible:
			_dash.mesh = _build_dash_mesh(progress)
			_set_appearance(_dash, dash_opacity)
		else:
			_impact_born = -1
	if _slash_born >= 0:
		var age := maxf(0.0, float(now_usec - _slash_born) / 1000000.0)
		var progress := clampf((age - slash_hold) / maxf(slash_lifetime - slash_hold, 0.001), 0.0, 1.0)
		_slash.visible = age < slash_lifetime
		if _slash.visible:
			_slash.mesh = _build_slash_mesh(progress)
			_set_appearance(_slash, slash_opacity)
		else:
			_slash_born = -1

func _set_appearance(node: MeshInstance2D, opacity: float) -> void:
	var material := node.material as ShaderMaterial
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("highlight_tint", highlight_tint)
	material.set_shader_parameter("opacity", opacity)

func _frame_basis() -> Transform2D:
	var rect := _source.get_rect()
	var origin := rect.position
	var x := Vector2.RIGHT
	var y := Vector2.DOWN
	if _source.flip_h:
		x = Vector2.LEFT
		origin.x += rect.size.x
	if _source.flip_v:
		y = Vector2.UP
		origin.y += rect.size.y
	return Transform2D(x, y, origin)

func _adjustment(size: Vector2, offset_pixels: Vector2) -> Transform2D:
	return Transform2D(Vector2(size.x, 0), Vector2(0, size.y), offset_pixels)

func _dash_transform() -> Transform2D:
	return _sprite_parent.global_transform * _dash_frame_local * _adjustment(dash_scale, dash_offset_pixels)

func _source_depth() -> int:
	var depth := 0
	var cursor: Node = _source
	while cursor != null:
		if cursor is CanvasItem:
			depth += cursor.z_index
			if not cursor.z_as_relative:
				break
		cursor = cursor.get_parent()
	return depth

func clear_effects() -> void:
	_holding_dash = false
	_impact_born = -1
	_slash_born = -1
	if is_instance_valid(_dash):
		_dash.visible = false
	if is_instance_valid(_slash):
		_slash.visible = false

func _build_dash_mesh(progress: float = 0.0) -> ArrayMesh:
	return _build_art_mesh(_dash_strip, dash_frame_rect, false, progress, false)

func _build_slash_mesh(progress: float = 0.0) -> ArrayMesh:
	return _build_art_mesh(_slash_strip, slash_frame_rect, true, progress, true)

func _bake_strip(artwork: Texture2D) -> Dictionary:
	if _strip_cache.has(artwork):
		return _strip_cache[artwork]
	var image := artwork.get_image()
	if image == null or image.is_empty():
		return {}
	image.convert(Image.FORMAT_RGBA8)
	var size := image.get_size()
	var pixels := image.get_data()
	var edges := PackedVector2Array()
	var left := size.x
	var right := -1
	var top := size.y
	var bottom := -1
	for x in range(size.x):
		var first := size.y
		var last := -1
		for y in range(size.y):
			var alpha_index := (y * size.x + x) * 4 + 3
			if pixels[alpha_index] < 128:
				continue
			# Ignore detached one-pixel AI specks without changing the source PNG.
			var connected := (x > 0 and pixels[alpha_index - 4] >= 128) or (x + 1 < size.x and pixels[alpha_index + 4] >= 128) or (y > 0 and pixels[alpha_index - size.x * 4] >= 128) or (y + 1 < size.y and pixels[alpha_index + size.x * 4] >= 128)
			if not connected:
				continue
			first = mini(first, y)
			last = maxi(last, y)
		edges.append(Vector2(first - 1, last + 2))
		if last >= first:
			left = mini(left, x)
			right = maxi(right, x)
			top = mini(top, first)
			bottom = maxi(bottom, last)
	if right <= left or bottom <= top:
		return {}
	var strip := {"edges": edges, "bounds": Rect2(left, top, right - left + 1, bottom - top + 1), "size": Vector2(size)}
	_strip_cache[artwork] = strip
	return strip

func _build_art_mesh(strip: Dictionary, frame: Rect2, reverse: bool, progress: float, slash: bool) -> ArrayMesh:
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var edges: PackedVector2Array = strip["edges"]
	var bounds: Rect2 = strip["bounds"]
	var image_size: Vector2 = strip["size"]
	var start := pow(clampf(progress, 0.0, 1.0), 0.85)
	var count := 560
	var width_factor := pow(maxf(1.0 - progress, 0.0), 0.75) if slash else 1.0 - smoothstep(0.55, 1.0, progress)
	for i in range(count + 1):
		var u := float(i) / count
		var t := lerpf(start, 1.0, u)
		var along := 1.0 - t if reverse else t
		var x := lerpf(bounds.position.x, bounds.end.x, along)
		var sample_x := clampf(x, bounds.position.x, bounds.end.x - 1.0)
		var index := floori(sample_x)
		var edge := edges[index].lerp(edges[mini(index + 1, int(bounds.end.x) - 1)], sample_x - index)
		var image_top := Vector2(x, edge.x)
		var image_bottom := Vector2(x, edge.y)
		var frame_top := frame.position + (image_top - bounds.position) / bounds.size * frame.size
		var frame_bottom := frame.position + (image_bottom - bounds.position) / bounds.size * frame.size
		var center := (frame_top + frame_bottom) * 0.5
		var cap := smoothstep(0.0, 0.12, u) if progress > 0.0 else 1.0
		vertices.append(center + (frame_top - center) * cap * width_factor)
		vertices.append(center + (frame_bottom - center) * cap * width_factor)
		uv.append(image_top / image_size)
		uv.append(image_bottom / image_size)
		if i < count:
			var base := i * 2
			indices.append_array(PackedInt32Array([base, base+1, base+2, base+1, base+3, base+2]))
	return _mesh_from_arrays(vertices, uv, indices)

func _mesh_from_arrays(vertices: PackedVector2Array, uv: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
