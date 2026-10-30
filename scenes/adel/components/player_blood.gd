class_name PlayerBlood
extends Node
## One persistent wound group per accepted HP stagger; presentation never owns HP.

const BLOOD_SHADER: Shader = preload("res://scenes/adel/components/player_blood.gdshader")
const ATLAS: Texture2D = preload("res://asset/VFX/Adel/Blood/player_blood_atlas.png")
const MAPPING_PATH := "res://asset/VFX/Adel/Blood/player_blood_mapping.json"
const FACE_SITE := 4
const FACE_SAMPLE := 2

@export var enabled := true:
	set(value):
		enabled = value
		if not value: clear_blood()
@export var tint := Color("#850505")
@export_range(0.0, 1.0, 0.01) var opacity := 0.8
@export_group("Lifetime (unpaused real seconds)")
@export_range(0.1, 10.0, 0.1, "suffix:s") var recovery_fade := 3.0
@export_range(120.0, 180.0, 1.0, "suffix:s") var unrecovered_timeout := 150.0
@export_range(1, 4, 1) var max_groups := 4

var groups: Array[Dictionary] = []
var mapping: Dictionary = {}
var _bindings: Array[Dictionary] = []
var _cells: Array[Rect2] = []
var _model: StatsComponent
var _rng := RandomNumberGenerator.new()
var _clock_usec := 0
var _last_usec := 0

func setup(model: StatsComponent, rig: Node2D) -> void:
	_model = model
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 300
	_last_usec = Time.get_ticks_usec()
	_rng.randomize()
	mapping = JSON.parse_string(FileAccess.get_file_as_string(MAPPING_PATH))
	for cell in mapping.atlas_cells:
		_cells.append(Rect2(cell[0], cell[1], cell[2], cell[3]))
	for definition in mapping.rig:
		var sprite := rig.get_node(definition.path) as Sprite2D
		_add_binding(sprite, int(definition.site), definition)
	_add_binding(rig.get_node("TestAttackSprite") as Sprite2D, -1, {})
	_model.stagger_threshold_restored.connect(_on_threshold_restored)
	# Property/frame changes have completed by this point, including held poses.
	RenderingServer.frame_pre_draw.connect(sync_visuals)

func _add_binding(sprite: Sprite2D, site: int, definition: Dictionary) -> void:
	var material := ShaderMaterial.new()
	material.shader = BLOOD_SHADER
	material.set_shader_parameter("blood_atlas", ATLAS)
	_bindings.append({"sprite": sprite, "site": site, "definition": definition,
		"material": material, "original": sprite.material, "key": ""})

func _advance_clock(now_usec: int) -> int:
	var elapsed := maxi(now_usec - _last_usec, 0)
	_last_usec = now_usec
	if not get_tree().paused: _clock_usec += elapsed
	return _clock_usec

func _process(_delta: float) -> void:
	var now := _advance_clock(Time.get_ticks_usec())
	if not enabled:
		clear_blood()
		return
	_update_groups(now)
	sync_visuals()

func add_stagger(tier: int) -> void:
	if not enabled or tier < 0 or tier >= _model.stagger_tiers_ready.size(): return
	var now := _advance_clock(Time.get_ticks_usec())
	var first := _rng.randi_range(0, 3)
	var second := (first + _rng.randi_range(1, 3)) % 4
	groups.append({"tier": tier, "sites": [first, second],
		"samples": [_rng.randi_range(0, 7), _rng.randi_range(0, 7)],
		"born": now, "fade_start": -1, "alpha": 1.0})
	while groups.size() > clampi(max_groups, 1, 4): groups.pop_front()
	sync_visuals()

func _on_threshold_restored(tier: int) -> void:
	var now := _advance_clock(Time.get_ticks_usec())
	for group in groups:
		if int(group.tier) == tier and int(group.fade_start) < 0:
			group.fade_start = now

func _update_groups(now_usec: int) -> void:
	for i in range(groups.size() - 1, -1, -1):
		var group: Dictionary = groups[i]
		var timeout := int(group.born) + int(unrecovered_timeout * 1000000.0)
		if now_usec >= timeout and int(group.fade_start) < 0: group.fade_start = timeout
		if int(group.fade_start) >= 0:
			group.alpha = 1.0 - clampf(float(now_usec - int(group.fade_start)) / maxf(recovery_fade * 1000000.0, 1.0), 0.0, 1.0)
			if float(group.alpha) <= 0.0: groups.remove_at(i)

func clear_blood() -> void:
	groups.clear()
	for binding in _bindings:
		if is_instance_valid(binding.sprite): binding.sprite.material = binding.original
		binding.key = ""

func _vector(value: Array) -> Vector2:
	return Vector2(value[0], value[1])

func _specs(binding: Dictionary) -> Array:
	var sprite := binding.sprite as Sprite2D
	if int(binding.site) < 0:
		var sheet: Dictionary = mapping.fbf.get(sprite.texture.resource_path.get_file(), {})
		if sheet.is_empty() or int(sheet.hframes) != sprite.hframes: return []
		return sheet.frames.get(str(sprite.frame), [])
	var definition: Dictionary = binding.definition
	var size := sprite.texture.get_size()
	var specs: Array = [{}, {}, {}, {}, {}]
	specs[int(binding.site)] = {"center": definition.center, "size": definition.size, "angle": definition.angle, "region": []}
	var spec: Dictionary = specs[int(binding.site)].duplicate()
	var center := _vector(spec.center) * size
	var extent := _vector(spec.size) * size
	spec.center = [center.x, center.y]
	spec.size = [extent.x, extent.y]
	specs[int(binding.site)] = spec
	return specs

func sync_visuals() -> void:
	if groups.is_empty() or not enabled or (_model != null and _model.hp <= 0):
		clear_blood()
		return
	for binding in _bindings:
		var sprite := binding.sprite as Sprite2D
		if not is_instance_valid(sprite) or sprite.texture == null: continue
		var specs := _specs(binding)
		var material := binding.material as ShaderMaterial
		if specs.size() != 5:
			sprite.material = binding.original
			continue
		sprite.material = material
		material.set_shader_parameter("blood_tint", tint)
		material.set_shader_parameter("source_size", sprite.texture.get_size())
		material.set_shader_parameter("frame_origin", Vector2(sprite.frame_coords) * sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes))
		material.set_shader_parameter("filter_material", int(binding.site) < 0)
		var geometry_key := "%s:%d:%d" % [sprite.texture.resource_path, sprite.hframes, sprite.frame]
		if geometry_key != binding.key:
			var counts := PackedInt32Array([0,0,0,0,0])
			var points := PackedVector2Array()
			points.resize(60)
			for site in range(5):
				if specs[site].is_empty(): continue
				var region: Array = specs[site].get("region", [])
				counts[site] = mini(region.size(), 12)
				for point in range(counts[site]): points[site * 12 + point] = _vector(region[point])
			material.set_shader_parameter("region_counts", counts)
			material.set_shader_parameter("region_points", points)
			binding.key = geometry_key
		var poses := PackedVector4Array()
		var inks := PackedVector4Array()
		var styles := PackedVector4Array()
		var face_alpha := 0.0
		for group in groups:
			face_alpha = maxf(face_alpha, float(group.alpha))
			for index in range(2):
				_append_mark(specs, int(group.sites[index]), int(group.samples[index]), float(group.alpha), poses, inks, styles)
		_append_mark(specs, FACE_SITE, FACE_SAMPLE, face_alpha, poses, inks, styles)
		material.set_shader_parameter("mark_count", poses.size())
		poses.resize(9)
		inks.resize(9)
		styles.resize(9)
		material.set_shader_parameter("mark_pose", poses)
		material.set_shader_parameter("mark_ink", inks)
		material.set_shader_parameter("mark_style", styles)

func _append_mark(specs: Array, site: int, sample: int, alpha: float, poses: PackedVector4Array, inks: PackedVector4Array, styles: PackedVector4Array) -> void:
	var spec: Dictionary = specs[site]
	if spec.is_empty(): return
	var limit := _vector(spec.size)
	if limit.x <= 0.0 or limit.y <= 0.0: return # Fully occluded cheek retains wound state.
	var cell := _cells[sample]
	var factor := minf(limit.x / cell.size.x, limit.y / cell.size.y)
	var center := _vector(spec.center)
	var fitted := cell.size * factor
	poses.append(Vector4(center.x, center.y, fitted.x, fitted.y))
	var atlas_size := ATLAS.get_size()
	inks.append(Vector4(cell.position.x / atlas_size.x, cell.position.y / atlas_size.y, cell.size.x / atlas_size.x, cell.size.y / atlas_size.y))
	styles.append(Vector4(deg_to_rad(float(spec.angle)), opacity * alpha, site, 0))

func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(sync_visuals): RenderingServer.frame_pre_draw.disconnect(sync_visuals)
	clear_blood()
