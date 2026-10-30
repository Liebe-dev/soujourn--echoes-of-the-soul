class_name SaberHitSlashVFX
extends Node2D
## Accepted Saber hits only. Age uses unpaused wall time, independent of time_scale.

const SLASH_SHADER: Shader = preload("res://scenes/adel/components/saber_hit_slash.gdshader")
const ATTACKS := [&"saber_attack_1", &"saber_attack_2", &"saber_attack_3", &"saber_attack_4"]

@export var enabled := true
@export_node_path("Node2D") var hitbox_path := NodePath("../WeaponPivot/SaberHitbox")
@export_node_path("Sprite2D") var source_sprite_path := NodePath("../SpinePivot/SpineRig/TestAttackSprite")
@export_group("Appearance")
@export var tint := Color("#EDF3F7")
@export_range(0.0, 1.0, 0.01) var opacity := 1.0
@export_range(0.1, 4.0, 0.05) var length_scale := 1.30
@export var target_offset := Vector2.ZERO
@export var attack_widths: Array[float] = [118.0, 122.0, 124.0, 134.0]
@export var attack_axes_degrees: Array[float] = [-32.88, -11.79, -0.91, -0.92]
@export var attack_textures: Array[Texture2D] = [
	preload("res://asset/VFX/Adel/Hit/saber_hit_1.png"),
	preload("res://asset/VFX/Adel/Hit/saber_hit_2.png"),
	preload("res://asset/VFX/Adel/Hit/saber_hit_3.png"),
	preload("res://asset/VFX/Adel/Hit/saber_hit_4.png"),
]
@export_group("Lifetime (unpaused real seconds)")
@export_range(0.01, 1.0, 0.01, "suffix:s") var fade_duration := 0.20
@export_range(1, 64, 1) var max_marks := 24

var _hitbox: SaberHitbox
var _source: Sprite2D
var _marks: Array[Dictionary] = []
var _swing_holds: Dictionary = {}
var _clock_usec := 0
var _last_usec := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 200
	_last_usec = Time.get_ticks_usec()
	_hitbox = get_node_or_null(hitbox_path) as SaberHitbox
	_source = get_node_or_null(source_sprite_path) as Sprite2D
	if _hitbox == null or _source == null:
		push_error("SaberHitSlashVFX requires the Saber hitbox and authored attack sprite.")
		set_process(false)
		return
	_hitbox.target_hit.connect(_on_target_hit)

func _advance_clock(now_usec: int) -> int:
	var elapsed := maxi(now_usec - _last_usec, 0)
	_last_usec = now_usec
	if not get_tree().paused:
		_clock_usec += elapsed
	return _clock_usec

func _process(_delta: float) -> void:
	var now := _advance_clock(Time.get_ticks_usec())
	if not enabled:
		clear_effects()
		return
	_update_marks(now)
	for generation in _swing_holds.keys():
		if int(_swing_holds[generation]) <= now:
			_swing_holds.erase(generation)

func _on_target_hit(target: Node2D) -> void:
	if not enabled or not is_instance_valid(target): return
	var attack := _hitbox.get_active_attack_name()
	var index := ATTACKS.find(attack)
	if index < 0 or index >= attack_textures.size() or index >= attack_widths.size() or index >= attack_axes_degrees.size(): return
	var texture := attack_textures[index]
	if texture == null: return
	var now := _advance_clock(Time.get_ticks_usec())
	var generation := _hitbox.get_attack_generation()
	var anchor := target.global_position
	var hurtbox := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hurtbox != null and hurtbox.shape != null:
		anchor = hurtbox.global_transform * hurtbox.shape.get_rect().get_center()
	var local_anchor := target.to_local(anchor) + target_offset
	var owner_body := _hitbox.source_body
	var facing := -1.0 if int(owner_body.get("facing_direction")) < 0 else 1.0
	var sprite := Sprite2D.new()
	sprite.name = "SaberHit%d" % (index + 1)
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.top_level = true
	sprite.z_as_relative = false
	var material := ShaderMaterial.new()
	material.shader = SLASH_SHADER
	material.set_shader_parameter("ink_color", tint)
	material.set_shader_parameter("opacity", opacity)
	sprite.material = material
	add_child(sprite)
	var basis := _stroke_basis(index, facing, target.global_scale.abs())
	basis.origin = target.to_global(local_anchor)
	sprite.global_transform = basis
	sprite.z_index = _draw_depth()
	_marks.append({"sprite": sprite, "target": weakref(target), "anchor": local_anchor,
		"attack": attack, "generation": generation,
		"fade_start": maxi(now, int(_swing_holds.get(generation, now)))})
	while _marks.size() > maxi(max_marks, 1):
		var oldest: Dictionary = _marks.pop_front()
		(oldest.sprite as Sprite2D).queue_free()

func _stroke_basis(index: int, facing: float, target_scale: Vector2) -> Transform2D:
	var axis := Vector2.from_angle(deg_to_rad(attack_axes_degrees[index]))
	var extra := maxf(length_scale, 0.1) - 1.0
	var unit := maxf(attack_widths[index], 0.0) / attack_textures[index].get_width()
	var x := Vector2(1.0 + extra * axis.x * axis.x, extra * axis.x * axis.y)
	var y := Vector2(extra * axis.x * axis.y, 1.0 + extra * axis.y * axis.y)
	# Reflect the entire stretched stroke, so a left-facing diagonal keeps its width.
	x *= Vector2(facing, 1.0) * target_scale * unit
	y *= Vector2(facing, 1.0) * target_scale * unit
	return Transform2D(x, y, Vector2.ZERO)

func apply_hit_stop(attack: StringName, duration: float) -> void:
	if ATTACKS.find(attack) < 0 or duration <= 0.0 or _hitbox == null: return
	var now := _advance_clock(Time.get_ticks_usec())
	var generation := _hitbox.get_attack_generation()
	var deadline := now + int(duration * 1000000.0)
	_swing_holds[generation] = deadline
	for mark in _marks:
		if int(mark.generation) == generation:
			mark.fade_start = maxi(int(mark.fade_start), deadline)

func _update_marks(now_usec: int) -> void:
	for i in range(_marks.size() - 1, -1, -1):
		var mark: Dictionary = _marks[i]
		var sprite := mark.sprite as Sprite2D
		var target = (mark.target as WeakRef).get_ref()
		if is_instance_valid(target) and target.is_inside_tree():
			sprite.global_position = target.to_global(mark.anchor)
		var age := maxf(float(now_usec - int(mark.fade_start)) / 1000000.0, 0.0)
		var alpha := 1.0 - clampf(age / maxf(fade_duration, 0.001), 0.0, 1.0)
		(sprite.material as ShaderMaterial).set_shader_parameter("opacity", opacity * alpha)
		sprite.z_index = _draw_depth()
		if alpha <= 0.0:
			sprite.queue_free()
			_marks.remove_at(i)

func _draw_depth() -> int:
	# The approved sword trail is source depth - 1; enemy bodies are below both.
	var depth := 0
	var cursor: Node = _source
	while cursor != null:
		if cursor is CanvasItem:
			depth += cursor.z_index
			if not cursor.z_as_relative: break
		cursor = cursor.get_parent()
	return clampi(depth - 2, -4096, 4096)

func clear_effects() -> void:
	for mark in _marks:
		if is_instance_valid(mark.sprite): (mark.sprite as Sprite2D).queue_free()
	_marks.clear()
	_swing_holds.clear()
