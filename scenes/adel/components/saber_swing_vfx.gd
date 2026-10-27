class_name SaberSwingVFX
extends Node2D
## Two layers: an attached strike and a short, world-anchored residual.
## Residual age deliberately uses wall time, never animation time or shader TIME.

const SLASH_SHADER: Shader = preload("res://scenes/adel/components/saber_slash.gdshader")
const ATTACKS := [&"saber_attack_1", &"saber_attack_2", &"saber_attack_3", &"saber_attack_4"]
const ARC_CENTERS := [Vector2(950, 450), Vector2(900, 480), Vector2(1110, 490), Vector2(905, 550)]
const ARC_RADII := [Vector2(620, 360), Vector2(625, 255), Vector2(550, 190), Vector2(705, 405)]
const ARC_STARTS := [1.98, 1.98, -2.8, -2.75]
const ARC_SWEEPS := [-3.03, -2.78, 3.15, 3.0]
const MOTION_PADDING_PIXELS := Vector2(320, 220)

@export var enabled := true
@export_node_path("AnimationPlayer") var animation_player_path := NodePath("../AnimationPlayer")
@export_node_path("Sprite2D") var source_sprite_path := NodePath("../TestAttackSprite")
@export_group("Appearance")
@export_range(0.0, 1.0, 0.01) var attached_opacity := 0.96
@export_range(0.0, 1.0, 0.01) var residual_opacity := 0.86
@export var effect_offset_pixels := Vector2.ZERO
@export var effect_scale := Vector2.ONE
@export var attack_textures: Array[Texture2D] = [
	preload("res://asset/VFX/Adel/Saber/saber_attack_1.png"),
	preload("res://asset/VFX/Adel/Saber/saber_attack_2.png"),
	preload("res://asset/VFX/Adel/Saber/saber_attack_3.png"),
	preload("res://asset/VFX/Adel/Saber/saber_attack_4.png"),
]
## Mapping from each complete texture into the original 1371 x 976 sprite frame.
## Black margins and soft glow remain intact; placements match the approved preview.
@export var texture_frame_rects: Array[Rect2] = [
	Rect2(647.1531, 2.1739, 1158.4567, 957.3913),
	Rect2(675.7747, 44.7316, 988.6629, 965.9564),
	Rect2(626.1668, 26.0688, 1151.3319, 804.4746),
	Rect2(336.5756, -13.9835, 1426.5598, 839.3178),
]
## Every array uses indices 0, 1, 2, 3 for saber_attack_1, 2, 3, 4.
## These transforms affect the artwork AND its moving arc, around each pivot.
@export_group("Per-attack placement (0=1, 1=2, 2=3, 3=4)")
@export var attack_offsets_pixels: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2(0, -80), Vector2(0, -60)]
@export var attack_scales: Array[Vector2] = [Vector2.ONE, Vector2.ONE, Vector2(1.38, 0.40), Vector2(1, 0.22)]
@export var attack_rotations_degrees: Array[float] = [0.0, 0.0, -1.0, 0.0]
## Attack 3 anchors the front tip, so extending X adds reach behind the actor.
@export var attack_pivots_pixels: Array[Vector2] = [Vector2(950, 450), Vector2(900, 480), Vector2(1660, 400), Vector2(905, 400)]
@export var attack_flip_h: Array[bool] = [false, false, false, false]
@export var attack_flip_v: Array[bool] = [true, false, false, false]
@export_group("Per-attack stroke and direction")
## Reverse both the painted head/tail and its travel along the same arc.
@export var attack_reverse_motion: Array[bool] = [false, false, true, false]
## 1.0 keeps the painted width; lower values thin the stroke without shortening it.
@export var attack_stroke_widths: Array[float] = [1.0, 1.0, 0.90, 0.75]
@export_group("Residual lifetime (real seconds)")
@export_range(0.05, 1.0, 0.01, "suffix:s") var residual_lifetime := 0.35
@export_range(0.05, 1.0, 0.01, "suffix:s") var finisher_residual_lifetime := 0.44
## Extra distance travelled by the head, as a fraction of the original arc.
@export_range(0.0, 0.20, 0.01) var residual_head_travel := 0.12
@export_range(1, 8, 1) var max_residuals := 3

var _player: AnimationPlayer
var _source: Sprite2D
var _attached: Sprite2D
var _residuals: Array[Dictionary] = []
var _frame_markers: Dictionary = {}
var _clip: StringName
var _last_position := -1.0
var _emitted := false
var _attached_attack := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# AnimationPlayer applies its tracks before the attached layer is sampled.
	process_priority = 100
	_player = get_node_or_null(animation_player_path) as AnimationPlayer
	_source = get_node_or_null(source_sprite_path) as Sprite2D
	if _player == null or _source == null:
		push_error("SaberSwingVFX requires an AnimationPlayer and source Sprite2D.")
		set_process(false)
		return
	_attached = _new_sprite("AttachedSlash")
	_player.animation_started.connect(_on_animation_started)
	for attack in ATTACKS:
		_frame_markers[attack] = _read_markers(attack)

func _on_animation_started(clip: StringName) -> void:
	_clip = clip
	_emitted = false
	_last_position = -1.0
	_attached.visible = false

func _process(_delta: float) -> void:
	if not enabled:
		clear_effects()
		return
	_sample_animation()
	_tick_residuals(Time.get_ticks_usec())

func _sample_animation() -> void:
	var clip := StringName(_player.current_animation)
	var index := ATTACKS.find(clip)
	_attached.visible = false
	if index < 0 or not _source.is_visible_in_tree():
		return
	var position := _player.current_animation_position
	if clip != _clip or position + 0.00001 < _last_position:
		_on_animation_started(clip)
	_last_position = position
	var markers: Vector2 = _frame_markers[clip]
	if markers.x < 0.0:
		return
	var frame_transform := _source_frame_transform()
	if position + 0.00001 >= markers.x and not _emitted:
		_emitted = true
		_spawn_residual(index, frame_transform)
	if position + 0.00001 < markers.x or position + 0.00001 >= markers.y:
		return
	if _attached_attack != index:
		_configure_sprite(_attached, index, attached_opacity, 0.0, true)
		_attached_attack = index
	var texture_scale: Vector2 = _attached.get_meta(&"texture_scale")
	_attached.global_transform = frame_transform * _attack_transform(index) * Transform2D(Vector2(texture_scale.x, 0), Vector2(0, texture_scale.y), Vector2.ZERO)
	_attached.z_index = _source_depth() - 1
	_attached.visible = true
	(_attached.material as ShaderMaterial).set_shader_parameter("opacity", attached_opacity)
	(_attached.material as ShaderMaterial).set_shader_parameter("stroke_width", clampf(attack_stroke_widths[index], 0.05, 2.0))
	var arc := _arc_setup(index)
	(_attached.material as ShaderMaterial).set_shader_parameter("arc_start", arc.x)
	(_attached.material as ShaderMaterial).set_shader_parameter("arc_sweep", arc.y)
	(_attached.material as ShaderMaterial).set_shader_parameter("reverse_artwork", attack_reverse_motion[index])

func _attack_transform(index: int) -> Transform2D:
	var attack_scale := attack_scales[index]
	if attack_flip_h[index]:
		attack_scale.x *= -1.0
	if attack_flip_v[index]:
		attack_scale.y *= -1.0
	var angle := deg_to_rad(attack_rotations_degrees[index])
	var transform := Transform2D(Vector2(cos(angle), sin(angle)) * attack_scale.x, Vector2(-sin(angle), cos(angle)) * attack_scale.y, Vector2.ZERO)
	var pivot := attack_pivots_pixels[index]
	transform.origin = pivot + attack_offsets_pixels[index] - transform * pivot
	return transform

func _arc_setup(index: int) -> Vector2:
	var start: float = ARC_STARTS[index]
	var sweep: float = ARC_SWEEPS[index]
	if attack_reverse_motion[index]:
		start += sweep
		sweep = -sweep
	return Vector2(start, sweep)

func _read_markers(clip: StringName) -> Vector2:
	var markers := Vector2(-1.0, -1.0)
	if not _player.has_animation(clip):
		return markers
	var animation := _player.get_animation(clip)
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_VALUE or not animation.track_is_enabled(track):
			continue
		if String(animation.track_get_path(track)) != "TestAttackSprite:frame":
			continue
		for key in animation.track_get_key_count(track):
			var frame := int(animation.track_get_key_value(track, key))
			if frame == 1:
				markers.x = animation.track_get_key_time(track, key)
			elif frame == 2:
				markers.y = animation.track_get_key_time(track, key)
	return markers

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

func _new_sprite(node_name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.top_level = true
	sprite.z_as_relative = false
	sprite.centered = false
	sprite.visible = false
	add_child(sprite)
	return sprite

func _configure_sprite(sprite: Sprite2D, index: int, opacity: float, detail: float, expand_motion_quad: bool = false) -> void:
	var texture := attack_textures[index]
	var placement := texture_frame_rects[index]
	# Offsets are texture pixels, before the texture-to-frame scale is applied.
	# This keeps every original pixel and the soft rim in the approved position.
	sprite.texture = texture
	sprite.offset = placement.position * texture.get_size() / placement.size
	sprite.region_enabled = expand_motion_quad
	if expand_motion_quad:
		# A reversed head can travel beyond the original bitmap's black margin.
		# Expand the destination quad while keeping its UV/native-frame mapping.
		var padding := MOTION_PADDING_PIXELS * texture.get_size() / placement.size
		sprite.region_rect = Rect2(-padding, texture.get_size() + padding * 2.0)
		sprite.region_filter_clip_enabled = false
		sprite.offset -= padding
	var material := ShaderMaterial.new()
	material.shader = SLASH_SHADER
	material.set_shader_parameter("texture_frame_origin", placement.position)
	material.set_shader_parameter("texture_frame_size", placement.size)
	material.set_shader_parameter("arc_center", ARC_CENTERS[index])
	material.set_shader_parameter("arc_radii", ARC_RADII[index])
	var arc := _arc_setup(index)
	material.set_shader_parameter("arc_start", arc.x)
	material.set_shader_parameter("arc_sweep", arc.y)
	material.set_shader_parameter("reverse_artwork", attack_reverse_motion[index])
	material.set_shader_parameter("stroke_width", clampf(attack_stroke_widths[index], 0.05, 2.0))
	material.set_shader_parameter("motion_progress", 0.0)
	material.set_shader_parameter("tail_phase", 0.0)
	material.set_shader_parameter("head_phase", 1.0)
	material.set_shader_parameter("width_scale", 1.0)
	material.set_shader_parameter("opacity", opacity)
	material.set_shader_parameter("detail_cutoff", detail)
	sprite.material = material
	sprite.set_meta(&"texture_scale", placement.size / texture.get_size())

func _spawn_residual(index: int, frame_transform: Transform2D) -> void:
	while _residuals.size() >= max_residuals:
		var oldest: Dictionary = _residuals.pop_front()
		oldest.sprite.queue_free()
	var sprite := _new_sprite("ResidualSlash")
	_configure_sprite(sprite, index, residual_opacity, 0.10, true)
	var texture_scale: Vector2 = sprite.get_meta(&"texture_scale")
	sprite.global_transform = frame_transform * _attack_transform(index) * Transform2D(Vector2(texture_scale.x, 0), Vector2(0, texture_scale.y), Vector2.ZERO)
	sprite.z_index = _source_depth() - 2
	sprite.visible = true
	_residuals.append({"sprite": sprite, "born": Time.get_ticks_usec(), "life": finisher_residual_lifetime if index == 3 else residual_lifetime})

func _tick_residuals(now_usec: int) -> void:
	for index in range(_residuals.size() - 1, -1, -1):
		var record: Dictionary = _residuals[index]
		var age := float(now_usec - int(record.born)) / 1000000.0
		var progress := clampf(age / float(record.life), 0.0, 1.0)
		var sprite: Sprite2D = record.sprite
		if progress >= 1.0:
			sprite.queue_free()
			_residuals.remove_at(index)
			continue
		var material := sprite.material as ShaderMaterial
		var shape := _motion_shape(progress)
		material.set_shader_parameter("motion_progress", progress)
		material.set_shader_parameter("tail_phase", shape.x)
		material.set_shader_parameter("head_phase", shape.y)
		material.set_shader_parameter("width_scale", shape.z)
		material.set_shader_parameter("opacity", residual_opacity)

func _motion_shape(progress: float) -> Vector3:
	var phase := clampf(progress, 0.0, 1.0)
	var head := 1.0 + residual_head_travel * (1.0 - (1.0 - phase) * (1.0 - phase))
	var remaining_length := 1.0 - smoothstep(0.10, 1.0, phase)
	var tail := head - remaining_length
	var width := lerpf(1.0, 0.025, smoothstep(0.06, 1.0, phase))
	return Vector3(tail, head, width)

func clear_effects() -> void:
	if is_instance_valid(_attached):
		_attached.visible = false
	for record in _residuals:
		if is_instance_valid(record.sprite):
			record.sprite.queue_free()
	_residuals.clear()
