class_name JumpAttackVFX
extends Node2D
## Approved jump effect: short AIR arc, then a world-anchored downward crush.
## Geometry and materials age on the real clock, independently of animation/hit-stop.

const AIR_CLIP := &"jump_attack(air)"
const LAND_CLIP := &"jump_attack(land)"
const AIR_SHADER: Shader = preload("res://scenes/adel/components/jump_attack_air.gdshader")
const CRUSH_SHADER: Shader = preload("res://scenes/adel/components/jump_attack_crush.gdshader")
const GROUND_SHADER: Shader = preload("res://scenes/adel/components/jump_attack_ground_air.gdshader")

@export var enabled := true
@export_node_path("AnimationPlayer") var animation_player_path := NodePath("../AnimationPlayer")
@export_node_path("Sprite2D") var source_sprite_path := NodePath("../TestAttackSprite")
@export_group("Placement (source-frame pixels)")
@export var effect_offset_pixels := Vector2.ZERO
@export var effect_scale := Vector2.ONE
@export var floor_y_pixels := 923.0
## In gameplay, match the actual floor contact. Standalone animation rigs use floor_y_pixels.
@export var snap_to_floor := true
@export_group("Appearance")
@export var ink_texture: Texture2D = preload("res://asset/VFX/Adel/Saber/saber_attack_1.png")
@export_range(0.0, 1.0, 0.01) var air_attached_opacity := 0.96
@export_range(0.0, 1.0, 0.01) var air_residual_opacity := 0.78
@export_range(0.0, 1.0, 0.01) var landing_opacity := 0.96
@export_range(0.0, 1.0, 0.01) var ground_air_opacity := 0.82
@export_group("Lifetime (real seconds)")
@export_range(0.01, 0.5, 0.001, "suffix:s") var air_lifetime := 0.07
@export_range(0.0, 0.15, 0.001, "suffix:s") var crush_hold := 0.012
@export_range(0.02, 0.5, 0.001, "suffix:s") var crush_duration := 0.10
@export_range(0.05, 0.8, 0.001, "suffix:s") var ground_air_lifetime := 0.27
@export_range(1, 8, 1) var max_residuals := 3

var _player: AnimationPlayer
var _source: Sprite2D
var _body: CharacterBody2D
var _attached: MeshInstance2D
var _effects: Array[Dictionary] = []
var _markers: Dictionary = {}
var _clip: StringName
var _last_position := -1.0
var _emitted := false
var _air_born := -1
var _air_mesh: ArrayMesh

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 100
	_player = get_node_or_null(animation_player_path) as AnimationPlayer
	_source = get_node_or_null(source_sprite_path) as Sprite2D
	if _player == null or _source == null:
		push_error("JumpAttackVFX requires an AnimationPlayer and source Sprite2D.")
		set_process(false)
		return
	var cursor: Node = get_parent()
	while cursor != null:
		if cursor is CharacterBody2D:
			_body = cursor as CharacterBody2D
			break
		cursor = cursor.get_parent()
	_air_mesh = _build_air_mesh()
	_attached = _new_mesh("AirAttached", _air_mesh, AIR_SHADER)
	_setup_air(_attached, air_attached_opacity, 0.0)
	_markers[AIR_CLIP] = _read_frame_marker(AIR_CLIP, 1)
	_markers[LAND_CLIP] = _read_frame_marker(LAND_CLIP, 2)
	_player.animation_started.connect(_on_animation_started)

func _on_animation_started(clip: StringName) -> void:
	_clip = clip
	_emitted = false
	_last_position = -1.0
	_air_born = -1
	_attached.visible = false

func _process(_delta: float) -> void:
	if not enabled:
		clear_effects()
		return
	_sample_animation()
	_tick_effects(Time.get_ticks_usec())

func _sample_animation() -> void:
	_attached.visible = false
	var clip := StringName(_player.current_animation)
	if not _markers.has(clip) or not _source.is_visible_in_tree():
		return
	var position := _player.current_animation_position
	if clip != _clip or position + 0.00001 < _last_position:
		_on_animation_started(clip)
	_last_position = position
	var marker: float = _markers[clip]
	if marker < 0.0 or position + 0.00001 < marker:
		return
	var frame_transform := _source_frame_transform()
	if not _emitted:
		_emitted = true
		if clip == AIR_CLIP:
			_air_born = Time.get_ticks_usec()
			_spawn_air(frame_transform, _air_born)
		else:
			_spawn_landing(frame_transform, _landing_floor(frame_transform))
	if clip == AIR_CLIP and _air_born >= 0:
		var age := float(Time.get_ticks_usec() - _air_born) / 1000000.0
		_attached.visible = age < air_lifetime
		_attached.global_transform = frame_transform
		_attached.z_index = _source_depth() - 1
		(_attached.material as ShaderMaterial).set_shader_parameter("opacity", air_attached_opacity)

func _read_frame_marker(clip: StringName, frame: int) -> float:
	if not _player.has_animation(clip):
		return -1.0
	var animation := _player.get_animation(clip)
	var animation_root := _player.get_node_or_null(_player.root_node)
	if animation_root == null:
		return -1.0
	var frame_path := String(animation_root.get_path_to(_source)) + ":frame"
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_VALUE or not animation.track_is_enabled(track):
			continue
		if String(animation.track_get_path(track)) != frame_path:
			continue
		for key in animation.track_get_key_count(track):
			if int(animation.track_get_key_value(track, key)) == frame:
				return animation.track_get_key_time(track, key)
	return -1.0

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
	var frame := Transform2D(basis_x, basis_y, origin)
	var adjustment := Transform2D(Vector2(effect_scale.x, 0), Vector2(0, effect_scale.y), effect_offset_pixels)
	return _source.global_transform * frame * adjustment

func _landing_floor(frame_transform: Transform2D) -> float:
	if snap_to_floor and is_instance_valid(_body) and _body.is_on_floor():
		for index in range(_body.get_slide_collision_count()):
			var collision := _body.get_slide_collision(index)
			if collision.get_normal().dot(Vector2.UP) > 0.7:
				return (frame_transform.affine_inverse() * collision.get_position()).y
	return floor_y_pixels

func _source_depth() -> int:
	var depth := 0
	var cursor: Node = _source
	while cursor != null:
		if cursor is CanvasItem:
			depth += cursor.z_index
			if not cursor.z_as_relative:
				break
		cursor = cursor.get_parent()
	return clampi(depth, -4094, 4094)

func _new_mesh(node_name: String, mesh: ArrayMesh, shader: Shader) -> MeshInstance2D:
	var node := MeshInstance2D.new()
	node.name = node_name
	node.top_level = true
	node.z_as_relative = false
	node.mesh = mesh
	node.visible = false
	var mat := ShaderMaterial.new()
	mat.shader = shader
	node.material = mat
	add_child(node)
	return node

func _setup_air(node: MeshInstance2D, opacity: float, detail: float) -> void:
	var mat := node.material as ShaderMaterial
	mat.set_shader_parameter("ink_texture", ink_texture)
	mat.set_shader_parameter("opacity", opacity)
	mat.set_shader_parameter("detail_cutoff", detail)

func _reserve_effect() -> void:
	while _effects.size() >= max_residuals:
		_free_effect(_effects.pop_front())

func _spawn_air(frame_transform: Transform2D, born: int) -> void:
	_reserve_effect()
	var node := _new_mesh("AirResidual", _air_mesh, AIR_SHADER)
	_setup_air(node, air_residual_opacity, 0.10)
	node.global_transform = frame_transform
	node.z_index = _source_depth() - 1
	node.visible = true
	_effects.append({"kind": AIR_CLIP, "nodes": [node], "born": born, "life": air_lifetime})

func _spawn_landing(frame_transform: Transform2D, floor_y: float) -> void:
	_reserve_effect()
	var crush := _new_mesh("LandingCrush", _build_crush_mesh(0.0, floor_y), CRUSH_SHADER)
	var mat := crush.material as ShaderMaterial
	mat.set_shader_parameter("ink_texture", ink_texture)
	mat.set_shader_parameter("floor_y", floor_y)
	crush.global_transform = frame_transform
	crush.z_index = _source_depth() + 1
	crush.visible = true
	var ground := _new_mesh("GroundAir", _build_ground_mesh(), GROUND_SHADER)
	ground.global_transform = frame_transform * Transform2D(0.0, Vector2(170, 800 + floor_y - 923.0))
	ground.z_index = _source_depth() + 2
	ground.visible = true
	_effects.append({"kind": LAND_CLIP, "nodes": [crush, ground], "born": Time.get_ticks_usec(), "life": maxf(crush_hold + crush_duration + 0.013, ground_air_lifetime), "floor": floor_y})

func _tick_effects(now_usec: int) -> void:
	for index in range(_effects.size() - 1, -1, -1):
		var record: Dictionary = _effects[index]
		var age := maxf(0.0, float(now_usec - int(record.born)) / 1000000.0)
		if age >= float(record.life):
			_free_effect(record)
			_effects.remove_at(index)
			continue
		if record.kind == AIR_CLIP:
			var mat := (record.nodes[0] as MeshInstance2D).material as ShaderMaterial
			var p := clampf(age / float(record.life), 0.0, 1.0)
			var head := 1.0 + 0.025 * (1.0 - pow(1.0 - p, 2.0))
			mat.set_shader_parameter("tail_phase", head - pow(1.0 - p, 2.2))
			mat.set_shader_parameter("head_phase", head)
			mat.set_shader_parameter("width_scale", lerpf(1.0, 0.025, pow(p, 0.72)))
			mat.set_shader_parameter("progress", p)
			continue
		var crush: MeshInstance2D = record.nodes[0]
		var progress := clampf((age - crush_hold) / maxf(crush_duration, 0.001), 0.0, 1.0)
		crush.visible = age < crush_hold + crush_duration + 0.013
		if crush.visible:
			crush.mesh = _build_crush_mesh(progress, float(record.floor))
			var mat := crush.material as ShaderMaterial
			mat.set_shader_parameter("crush", progress)
			mat.set_shader_parameter("age", age * 0.125 / maxf(crush_hold + crush_duration + 0.013, 0.001))
			mat.set_shader_parameter("opacity", landing_opacity)
		var ground: MeshInstance2D = record.nodes[1]
		ground.visible = age < ground_air_lifetime
		var ground_mat := ground.material as ShaderMaterial
		ground_mat.set_shader_parameter("age", age * 0.27 / maxf(ground_air_lifetime, 0.001))
		ground_mat.set_shader_parameter("opacity", ground_air_opacity)

func _free_effect(record: Dictionary) -> void:
	for node: MeshInstance2D in record.nodes:
		if is_instance_valid(node):
			node.queue_free()

func clear_effects() -> void:
	if is_instance_valid(_attached):
		_attached.visible = false
	for record in _effects:
		_free_effect(record)
	_effects.clear()
	_air_born = -1

func _build_crush_mesh(progress: float, floor_y: float) -> ArrayMesh:
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var height := pow(1.0 - progress, 2.0)
	var count := 260
	for i in range(count + 1):
		var u := lerpf(-0.04, 1.08, float(i) / count)
		var angle := lerpf(-0.83, 1.82, u)
		var radial := Vector2(cos(angle), sin(angle)) * Vector2(500, 473)
		var span := lerpf(280.0, 680.0, smoothstep(0.20, 0.90, u)) / 486.0
		for side: float in [0.0, 1.0]:
			var point: Vector2 = Vector2(950, 428) + radial * (1.0 + (side - 0.5) * span)
			point.y = floor_y - (floor_y - point.y) * height
			point.x = 1115.0 + (point.x - 1115.0) * (1.0 + progress * 0.15)
			vertices.append(point)
			uv.append(Vector2(u, side))
		if i < count:
			var base := i * 2
			indices.append_array(PackedInt32Array([base, base+1, base+2, base+1, base+3, base+2]))
	return _mesh_from_arrays(vertices, uv, indices)

func _build_air_mesh() -> ArrayMesh:
	var points: Array[Vector2] = [Vector2(880, 0), Vector2(1040, 90), Vector2(1230, 275), Vector2(1155, 410)]
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var count := 220
	for i in range(count + 1):
		var u := lerpf(-0.04, 1.08, float(i) / count)
		var v := 1.0 - u
		var point := points[0]*v*v*v + points[1]*3.0*v*v*u + points[2]*3.0*v*u*u + points[3]*u*u*u
		var tangent := ((points[1]-points[0])*3.0*v*v + (points[2]-points[1])*6.0*v*u + (points[3]-points[2])*3.0*u*u).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		vertices.append(point - normal * 105.0)
		vertices.append(point + normal * 105.0)
		uv.append(Vector2(u, 0))
		uv.append(Vector2(u, 1))
		if i < count:
			var base := i * 2
			indices.append_array(PackedInt32Array([base, base+1, base+2, base+1, base+3, base+2]))
	return _mesh_from_arrays(vertices, uv, indices)

func _build_ground_mesh() -> ArrayMesh:
	return _mesh_from_arrays(PackedVector2Array([Vector2.ZERO, Vector2(1460, 0), Vector2(0, 134), Vector2(1460, 134)]), PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, Vector2.ONE]), PackedInt32Array([0, 1, 2, 1, 3, 2]))

func _mesh_from_arrays(vertices: PackedVector2Array, uv: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
