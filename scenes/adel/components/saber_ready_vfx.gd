class_name SaberReadyVFX
extends Node2D
## Approved quick flick. Inspect each current Ready resource, because the private
## final-pose-only variant must never emit a fictitious swing. Ages use real time.

const CLIP := &"saber_ready"
const SLASH_SHADER: Shader = preload("res://scenes/adel/components/saber_ready_slash.gdshader")

@export var enabled := true
@export_node_path("AnimationPlayer") var animation_player_path := NodePath("../AnimationPlayer")
@export_node_path("Sprite2D") var source_sprite_path := NodePath("../TestAttackSprite")
@export_group("Placement (source-frame pixels)")
@export var effect_offset_pixels := Vector2.ZERO
@export var effect_scale := Vector2.ONE
@export_group("Curve (four source-frame control points)")
@export var overhead_points := PackedVector2Array([Vector2(870,116), Vector2(955,60), Vector2(1100,170), Vector2(1145,260)])
@export var front_points := PackedVector2Array([Vector2(1110,225), Vector2(1220,320), Vector2(1340,665), Vector2(1210,755)])
@export_range(1.0, 600.0, 1.0) var overhead_width := 200.0
@export_range(1.0, 600.0, 1.0) var front_width := 235.0
@export_group("Appearance")
@export var ink_texture: Texture2D = preload("res://asset/VFX/Adel/Saber/saber_attack_1.png")
@export_range(0.0, 1.0, 0.01) var attached_opacity := 0.94
@export_range(0.0, 1.0, 0.01) var residual_opacity := 0.84
@export_group("Lifetime (real seconds)")
@export_range(0.001, 0.10, 0.001, "suffix:s") var attached_lifetime := 0.012
@export_range(0.02, 0.5, 0.001, "suffix:s") var residual_lifetime := 0.105
@export_range(1, 8, 1) var max_residuals := 3

var _player: AnimationPlayer
var _source: Sprite2D
var _overhead: MeshInstance2D
var _front: MeshInstance2D
var _front_mesh: ArrayMesh
var _animation: Animation
var _clip: StringName
var _markers := Vector2(-1, -1)
var _last_position := -1.0
var _overhead_born := -1
var _front_born := -1
var _motion_seen := false
var _emitted := false
var _residuals: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 100
	_player = get_node_or_null(animation_player_path) as AnimationPlayer
	_source = get_node_or_null(source_sprite_path) as Sprite2D
	if _player == null or _source == null or overhead_points.size() != 4 or front_points.size() != 4:
		push_error("SaberReadyVFX requires AnimationPlayer, Sprite2D and four points per curve.")
		set_process(false)
		return
	_overhead = _new_mesh("ReadyOverhead", _ribbon_mesh(overhead_points, overhead_width), attached_opacity, 0.04)
	_front_mesh = _ribbon_mesh(front_points, front_width)
	_front = _new_mesh("ReadyFrontAttached", _front_mesh, attached_opacity, 0.04)
	_player.animation_started.connect(_on_animation_started)

func _on_animation_started(clip: StringName) -> void:
	_clip = clip
	_last_position = -1.0
	_motion_seen = false
	_emitted = false
	_overhead_born = -1
	_front_born = -1
	_overhead.visible = false
	_front.visible = false
	_animation = _player.get_animation(CLIP) if clip == CLIP and _player.has_animation(CLIP) else null
	_markers = _read_markers(_animation)

func _read_markers(animation: Animation) -> Vector2:
	var markers := Vector2(-1, -1)
	if animation == null:
		return markers
	var animation_root := _player.get_node_or_null(_player.root_node)
	if animation_root == null:
		return markers
	var path := String(animation_root.get_path_to(_source)) + ":frame"
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_VALUE or not animation.track_is_enabled(track):
			continue
		if String(animation.track_get_path(track)) != path:
			continue
		for key in animation.track_get_key_count(track):
			var frame := int(animation.track_get_key_value(track, key))
			if frame == 1:
				markers.x = animation.track_get_key_time(track, key)
			elif frame == 2:
				markers.y = animation.track_get_key_time(track, key)
	return markers

func _process(_delta: float) -> void:
	if not enabled:
		clear_effects()
		return
	_sample_animation()
	_tick_residuals(Time.get_ticks_usec())

func _sample_animation() -> void:
	_overhead.visible = false
	_front.visible = false
	if StringName(_player.current_animation) != CLIP or not _source.is_visible_in_tree():
		return
	var animation := _player.get_animation(CLIP)
	var position := _player.current_animation_position
	if _clip != CLIP or animation != _animation or position + 0.00001 < _last_position:
		_on_animation_started(CLIP)
	_last_position = position
	if _markers.x < 0.0 or _markers.y <= _markers.x:
		return
	var now := Time.get_ticks_usec()
	var frame_transform := _source_frame_transform()
	if position + 0.00001 >= _markers.x and not _motion_seen:
		_motion_seen = true
		if position + 0.00001 < _markers.y:
			_overhead_born = now
	if position + 0.00001 >= _markers.y and not _emitted:
		_emitted = true
		_front_born = now
		_spawn_residual(frame_transform, now)
	if _overhead_born >= 0 and position + 0.00001 < _markers.y:
		_overhead.visible = float(now - _overhead_born) / 1000000.0 < attached_lifetime
		_overhead.global_transform = frame_transform
		_overhead.z_index = _source_depth() - 1
	if _front_born >= 0:
		_front.visible = float(now - _front_born) / 1000000.0 < attached_lifetime
		_front.global_transform = frame_transform
		_front.z_index = _source_depth() - 1
	for node: MeshInstance2D in [_overhead, _front]:
		(node.material as ShaderMaterial).set_shader_parameter("opacity", attached_opacity)

func _source_frame_transform() -> Transform2D:
	var rect := _source.get_rect()
	var origin := rect.position
	var basis_x := Vector2.RIGHT
	var basis_y := Vector2.DOWN
	if _source.flip_h:
		basis_x = Vector2.LEFT
		origin.x += rect.size.x
	if _source.flip_v:
		basis_y = Vector2.UP
		origin.y += rect.size.y
	var adjustment := Transform2D(Vector2(effect_scale.x, 0), Vector2(0, effect_scale.y), effect_offset_pixels)
	return _source.global_transform * Transform2D(basis_x, basis_y, origin) * adjustment

func _source_depth() -> int:
	var depth := 0
	var cursor: Node = _source
	while cursor != null:
		if cursor is CanvasItem:
			depth += cursor.z_index
			if not cursor.z_as_relative:
				break
		cursor = cursor.get_parent()
	return clampi(depth, -4094, 4096)

func _new_mesh(node_name: String, mesh: ArrayMesh, opacity: float, detail: float) -> MeshInstance2D:
	var node := MeshInstance2D.new()
	node.name = node_name
	node.top_level = true
	node.z_as_relative = false
	node.mesh = mesh
	node.visible = false
	var mat := ShaderMaterial.new()
	mat.shader = SLASH_SHADER
	mat.set_shader_parameter("ink_texture", ink_texture)
	mat.set_shader_parameter("opacity", opacity)
	mat.set_shader_parameter("detail_cutoff", detail)
	node.material = mat
	add_child(node)
	return node

func _spawn_residual(frame_transform: Transform2D, born: int) -> void:
	while _residuals.size() >= maxi(1, max_residuals):
		var oldest: Dictionary = _residuals.pop_front()
		oldest.node.queue_free()
	var node := _new_mesh("ReadyResidual", _front_mesh, residual_opacity, 0.08)
	var mat := node.material as ShaderMaterial
	mat.set_shader_parameter("remnant_start", 0.65)
	mat.set_shader_parameter("remnant_end", 0.90)
	node.global_transform = frame_transform
	node.z_index = _source_depth() - 1
	node.visible = true
	_residuals.append({"node": node, "born": born, "life": maxf(residual_lifetime, 0.001)})

func _tick_residuals(now: int) -> void:
	for index in range(_residuals.size() - 1, -1, -1):
		var record: Dictionary = _residuals[index]
		var age := maxf(0.0, float(now - int(record.born)) / 1000000.0)
		if age >= float(record.life):
			record.node.queue_free()
			_residuals.remove_at(index)
			continue
		var p := clampf(age / float(record.life), 0.0, 1.0)
		var head := 1.0 + 0.035 * (1.0 - pow(1.0 - p, 2.0))
		var mat := (record.node as MeshInstance2D).material as ShaderMaterial
		mat.set_shader_parameter("tail_phase", head - pow(1.0 - p, 1.6))
		mat.set_shader_parameter("head_phase", head)
		mat.set_shader_parameter("width_scale", lerpf(1.0, 0.025, pow(p, 0.72)))
		mat.set_shader_parameter("progress", p)
		mat.set_shader_parameter("opacity", residual_opacity)

func clear_effects() -> void:
	for node: MeshInstance2D in [_overhead, _front]:
		if is_instance_valid(node):
			node.visible = false
	for record in _residuals:
		if is_instance_valid(record.node):
			record.node.queue_free()
	_residuals.clear()
	_overhead_born = -1
	_front_born = -1

func _ribbon_mesh(points: PackedVector2Array, width: float) -> ArrayMesh:
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var count := 260
	for i in range(count + 1):
		var u := lerpf(-0.04, 1.08, float(i) / count)
		var v := 1.0 - u
		var point := points[0]*v*v*v + points[1]*3.0*v*v*u + points[2]*3.0*v*u*u + points[3]*u*u*u
		var tangent := ((points[1]-points[0])*3.0*v*v + (points[2]-points[1])*6.0*v*u + (points[3]-points[2])*3.0*u*u).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		vertices.append(point - normal * width * 0.5)
		vertices.append(point + normal * width * 0.5)
		uv.append(Vector2(u, 0))
		uv.append(Vector2(u, 1))
		if i < count:
			var base := i * 2
			indices.append_array(PackedInt32Array([base, base+1, base+2, base+1, base+3, base+2]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
