class_name BattleHitParticles
extends Node2D
## Approved V3 bursts. Combat owns acceptance; this component only presents it.
## Top-level sprites stay in world space but remain owned by Player for cleanup.

const SHEET: Texture2D = preload("res://asset/VFX/Adel/Particles/blood_bone_sheet.png")
const CELLS_PATH := "res://asset/VFX/Adel/Particles/cells.json"
const PLAYER_PROFILE := 3

@export var enabled := true
@export_range(1, 512, 1) var max_particles := 96
@export_group("Profiles: Q tap, Q charge 1, Q charge 2, Player stagger")
@export var blood_counts: Array[int] = [4, 8, 10, 8]
@export var bone_counts: Array[int] = [2, 3, 5, 0]
@export var speeds: Array[float] = [720.0, 1080.0, 1560.0, 660.0]
@export var reaches: Array[float] = [165.0, 270.0, 405.0, 156.0]
@export var lifetimes: Array[float] = [0.42, 0.48, 0.55, 0.44]
@export_group("Appearance and motion (world pixels, unpaused real seconds)")
@export var spawn_half_extents := Vector2(12.0, 15.0)
@export var blood_base_size := Vector2(10.0, 16.0)
@export var bone_base_size := Vector2(10.0, 14.0)
@export_range(0.1, 5.0, 0.05) var size_multiplier := 1.5
@export_range(0.0, 0.9, 0.01) var motion_variation := 0.10
@export var main_angles_degrees := Vector2(0.0, 8.0)
@export var upward_angles_degrees := Vector2(8.0, 12.0)
@export var blood_gravity := 110.0
@export var bone_gravity := 240.0
@export var bone_motion_multiplier := 0.75
@export var bone_extra_lifetime := 0.10
@export var bone_spin := Vector2(-5.0, 5.0)
@export_range(0.001, 1.0, 0.001, "suffix:s") var fade_duration := 0.13
@export var q_anchor_ratio := Vector2(0.32, -0.08)
@export var player_anchor_offset := Vector2(0.0, -20.0)

var _actor: CharacterBody2D
var _hitbox: SaberHitbox
var _source: Sprite2D
var _body_sprites: Array[Sprite2D] = []
var _blood_cells: Array[Dictionary] = []
var _long_blood_cells: Array[Dictionary] = []
var _bone_cells: Array[Dictionary] = []
var _active: Array[Dictionary] = []
var _swing_holds: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _clock_usec := 0
var _last_usec := 0

func setup(actor: CharacterBody2D) -> void:
	if _actor != null: return
	_actor = actor
	_hitbox = actor.saber_hitbox
	_source = actor.spine_rig.get_node("TestAttackSprite") as Sprite2D
	for node in actor.spine_rig.get_node("Skeleton2D").find_children("*", "Sprite2D", true, false):
		_body_sprites.append(node as Sprite2D)
	_body_sprites.append(_source)
	for cell: Dictionary in JSON.parse_string(FileAccess.get_file_as_string(CELLS_PATH)):
		var rect: Array = cell.rect
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		texture.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		cell["texture"] = texture
		if cell.kind == "blood":
			_blood_cells.append(cell)
			if float(rect[2]) / float(rect[3]) > 1.6: _long_blood_cells.append(cell)
		else:
			_bone_cells.append(cell)
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 400
	_last_usec = Time.get_ticks_usec()
	_rng.randomize()
	# Setup follows SaberWeaponSkill.setup: consume its actual accepted hit-stop.
	actor.saber_skill.impact_confirmed.connect(_on_q_impact)
	_hitbox.target_hit.connect(_on_target_hit)

func _advance_clock(now_usec: int) -> int:
	if not get_tree().paused: _clock_usec += maxi(now_usec - _last_usec, 0)
	_last_usec = now_usec
	return _clock_usec

func _on_q_impact(seconds: float) -> void:
	if not enabled: return
	var now := _advance_clock(Time.get_ticks_usec())
	var generation := _hitbox.get_attack_generation()
	var deadline := now + int(maxf(seconds, 0.0) * 1000000.0)
	_swing_holds[generation] = deadline
	# Also safe if signal connection order changes in a future scene.
	for particle in _active:
		if not particle.player and int(particle.generation) == generation:
			particle.born = maxi(int(particle.born), deadline)

func _on_target_hit(target: Node2D) -> void:
	if not enabled or not is_instance_valid(target): return
	if _hitbox.get_active_attack_name() != &"saber_skill" or not _actor.saber_skill.is_active(): return
	if _actor.state_machine.current != AdelStateMachine.State.SKILL_IMPACT: return
	_spawn(target, clampi(_actor.saber_skill.tier, 0, 2), _actor.facing_direction)

## Called only by Player's accepted direct HP-stagger branch, after the reaction.
## Bleed, self-drain, stamina exhaustion and generic stagger signals cannot enter.
func add_player_stagger(knockback_velocity: Vector2) -> void:
	if enabled and is_instance_valid(_actor):
		_spawn(_actor, PLAYER_PROFILE, -1 if knockback_velocity.x < 0.0 else 1)

func _spawn(target: Node2D, profile: int, facing: int) -> void:
	if profile >= blood_counts.size() or profile >= bone_counts.size() or profile >= speeds.size() or profile >= reaches.size() or profile >= lifetimes.size(): return
	var now := _advance_clock(Time.get_ticks_usec())
	var player := profile == PLAYER_PROFILE
	var generation := _hitbox.get_attack_generation()
	var origin := target.global_position
	var shape := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape != null:
		origin = shape.global_transform * shape.shape.get_rect().get_center()
		var extent := shape.shape.get_rect().size * shape.global_scale.abs()
		origin += player_anchor_offset if player else extent * q_anchor_ratio * Vector2(facing, 1.0)
	var depth := player_back_depth() if player else canvas_depth(_source) - 3
	for kind in range(2):
		var count := maxi((blood_counts if kind == 0 else bone_counts)[profile], 0)
		var pool := _blood_cells if kind == 0 else _bone_cells
		if pool.is_empty(): continue
		for i in range(count):
			while _active.size() >= maxi(max_particles, 1):
				var oldest: Dictionary = _active.pop_front()
				(oldest.sprite as Sprite2D).free()
			var selection := _long_blood_cells if kind == 0 and i < count - 1 and not _long_blood_cells.is_empty() else pool
			var cell: Dictionary = selection[_rng.randi_range(0, selection.size() - 1)]
			var rect: Array = cell.rect
			var sprite := Sprite2D.new()
			sprite.texture = cell.texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			sprite.top_level = true
			sprite.z_as_relative = false
			sprite.z_index = clampi(depth, -4096, 4096)
			add_child(sprite)
			var size_range := blood_base_size if kind == 0 else bone_base_size
			sprite.scale = Vector2.ONE * _rng.randf_range(size_range.x, size_range.y) * size_multiplier / maxf(rect[2], rect[3])
			var accent := 1 if count >= 4 else 0
			var jitter := _rng.randf_range(0.2, 0.8)
			var angle := -lerpf(upward_angles_degrees.x, upward_angles_degrees.y, jitter) if accent == 1 and i == count - 1 else lerpf(main_angles_degrees.x, main_angles_degrees.y, (i + jitter) / float(count - accent))
			var direction := Vector2(facing * cos(deg_to_rad(angle)), sin(deg_to_rad(angle)))
			var start := origin + Vector2(_rng.randf_range(-spawn_half_extents.x, spawn_half_extents.x), _rng.randf_range(-spawn_half_extents.y, spawn_half_extents.y))
			var rotation := direction.angle() + PI - float(cell.axis) if kind == 0 else _rng.randf_range(-PI, PI)
			sprite.global_position = start
			sprite.rotation = rotation
			var multiplier := bone_motion_multiplier if kind == 1 else 1.0
			_active.append({"player": player, "kind": kind, "profile": profile, "generation": generation,
				"sprite": sprite, "origin": start, "direction": direction,
				"born": now if player else maxi(now, int(_swing_holds.get(generation, now))),
				"life": maxf(lifetimes[profile] + (bone_extra_lifetime if kind == 1 else 0.0), 0.001),
				"speed": maxf(speeds[profile], 0.0) * _rng.randf_range(1.0 - motion_variation, 1.0 + motion_variation) * multiplier,
				"reach": maxf(reaches[profile] * _rng.randf_range(1.0 - motion_variation, 1.0 + motion_variation) * multiplier, 0.001),
				"gravity": bone_gravity if kind == 1 else blood_gravity, "rotation": rotation,
				"spin": _rng.randf_range(bone_spin.x, bone_spin.y) if kind == 1 else 0.0})

func _process(_delta: float) -> void:
	if _actor == null: return
	var now := _advance_clock(Time.get_ticks_usec())
	if not enabled or _actor.stats.hp <= 0:
		clear_effects()
		return
	_update_particles(now)
	for generation in _swing_holds.keys():
		if int(_swing_holds[generation]) <= now: _swing_holds.erase(generation)

func _update_particles(now_usec: int) -> void:
	if _active.is_empty(): return
	var back_depth := player_back_depth()
	var q_depth := canvas_depth(_source) - 3
	for i in range(_active.size() - 1, -1, -1):
		var particle: Dictionary = _active[i]
		var sprite := particle.sprite as Sprite2D
		var age := maxf(float(now_usec - int(particle.born)) / 1000000.0, 0.0)
		if age >= float(particle.life):
			sprite.free()
			_active.remove_at(i)
			continue
		sprite.z_index = clampi(back_depth if particle.player else q_depth, -4096, 4096)
		var distance := float(particle.reach) * (1.0 - exp(-float(particle.speed) * age / float(particle.reach)))
		sprite.global_position = particle.origin + particle.direction * distance + Vector2(0.0, 0.5 * float(particle.gravity) * age * age)
		sprite.rotation = float(particle.rotation) + float(particle.spin) * age
		var fade := maxf(fade_duration, 0.001)
		sprite.modulate.a = 1.0 - clampf((age - (float(particle.life) - fade)) / fade, 0.0, 1.0)

func clear_effects() -> void:
	for particle in _active:
		if is_instance_valid(particle.sprite): (particle.sprite as Sprite2D).free()
	_active.clear()
	_swing_holds.clear()

func canvas_depth(item: CanvasItem) -> int:
	var depth := 0
	var cursor: Node = item
	while cursor != null:
		if cursor is CanvasItem:
			depth += cursor.z_index
			if not cursor.z_as_relative: break
		cursor = cursor.get_parent()
	return depth

func player_back_depth() -> int:
	var depth := canvas_depth(_actor)
	for sprite in _body_sprites:
		if is_instance_valid(sprite): depth = mini(depth, canvas_depth(sprite))
	return depth - 1
