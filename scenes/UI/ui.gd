extends Control

@export_group("HUD Layout")
@export_range(0.25, 3.0, 0.05) var hud_scale: float = 1.25
@export var screen_margin: Vector2 = Vector2(24, 24)
@export var show_numeric_values: bool = false

const REFERENCE_SIZE := Vector2(629, 175)
@onready var hud_art: Control = $ScreenSpace/bar

signal stagger_triggered(tier: int, floor_hp: int)
signal stagger_debuff_applied(debuff_id: String, level: int)

var _stats: StatsComponent = StatsComponent.new()
var _stamina_actor: Node

#     STATS (facade → StatsComponent)
var max_hp: int:
	get:
		return _stats.max_hp
	set(value):
		_stats.max_hp = value

var hp: int:
	get:
		return _stats.hp
	set(value):
		_stats.hp = value

var max_flask_charges: int:
	get:
		return _stats.max_flask_charges
	set(value):
		_stats.max_flask_charges = value

var flask_charges: int:
	get:
		return _stats.flask_charges
	set(value):
		_stats.flask_charges = value

var max_stamina: float:
	get:
		return _stats.max_stamina
	set(value):
		_stats.max_stamina = value

var stamina: float:
	get:
		return _stats.stamina
	set(value):
		_stats.stamina = value

var flask_heal_per_use: int:
	get:
		return _stats.flask_heal_per_use
	set(value):
		_stats.flask_heal_per_use = value

var guard_damage_reduction: float:
	get:
		return _stats.guard_damage_reduction
	set(value):
		_stats.guard_damage_reduction = clampf(value, 0.0, 1.0)

# Debuffs
var bleeding_level: int:
	get:
		return _stats.bleeding_level
	set(value):
		_stats.bleeding_level = value

var fracture_level: int:
	get:
		return _stats.fracture_level
	set(value):
		_stats.fracture_level = value

var active_buffs: Dictionary:
	get:
		return _stats.active_buffs
	set(value):
		_stats.active_buffs = value

var stagger_tiers_ready: Array[bool]:
	get:
		return _stats.stagger_tiers_ready
	set(value):
		_stats.stagger_tiers_ready = value

var stagger_lock_hp: int:
	get:
		return _stats.stagger_lock_hp
	set(value):
		_stats.stagger_lock_hp = value

var stagger_lock_timer: float:
	get:
		return _stats.stagger_lock_timer
	set(value):
		_stats.stagger_lock_timer = value

const SCREEN_SHAKE_FLASK := 0.5
const SCREEN_SHAKE_STAGGER := 0.72
const FLASK_SHAKE_DECAY := 3.5

@onready var soul_flask: MarginContainer = $ScreenSpace/bar/soul_flask
@onready var soul_main: TextureRect = $ScreenSpace/bar/soul_flask/soul_main
@onready var soul_delay: TextureRect = $ScreenSpace/bar/soul_flask/soul_delay
@onready var flask_border: TextureRect = $ScreenSpace/bar/soul_flask/border
@onready var flask_uses_label: Label = $ScreenSpace/bar/soul_flask/flask_uses_label
@onready var hp_bar: TextureProgressBar = $ScreenSpace/bar/hp_bar_panel/hp_bar_wrap/hp_bar
@onready var hp_label: Label = $ScreenSpace/bar/hp_bar_panel/hp_label
@onready var stagger_marker_66: ColorRect = $ScreenSpace/bar/hp_bar_panel/hp_bar_wrap/stagger_markers/marker_66
@onready var stagger_marker_33: ColorRect = $ScreenSpace/bar/hp_bar_panel/hp_bar_wrap/stagger_markers/marker_33
@onready var stamina_bar: TextureProgressBar = $ScreenSpace/bar/hp_bar_panel/stamina_bar
@onready var stamina_label: Label = $ScreenSpace/bar/hp_bar_panel/stamina_label
@onready var debuff_bar: HBoxContainer = $ScreenSpace/bar/hp_bar_panel/status_panel/debuff_bar
@onready var buff_bar: HBoxContainer = $ScreenSpace/bar/hp_bar_panel/status_panel/buff_bar

const STAGGER_MARKER_READY := Color.WHITE
const STAGGER_MARKER_USED := Color(0.55, 0.55, 0.55, 0.45)

var _flask_rest_position := Vector2.ZERO
var _flask_shake_time := 0.0
var _flask_shake_amount := 0.0

var _is_flask_draining := false
var _flask_shader_percent := 0.0
var _flask_drain_tween = null
const FLASK_DRAIN_DURATION := 0.9

var in_combat := false
var hide_delay := 3.0
var hide_timer := 0.0
var is_hidden := false
var fade_tween: Tween

#hàm hệ thống
func _ready() -> void:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.has_method("blocks_stamina_regeneration"):
			_stamina_actor = ancestor
			break
		ancestor = ancestor.get_parent()
	_layout_hud()
	get_viewport().size_changed.connect(_layout_hud)
	_flask_rest_position = soul_flask.position
	_recalc_flask_heal_amount()
	hp_bar.max_value = max_hp
	stamina_bar.max_value = max_stamina
	sync_hp_display()
	sync_flask_display()
	sync_stamina_display()
	sync_stagger_markers()
	sync_status_icons()
	stagger_triggered.connect(_on_stagger_triggered)
	PlayerProgress.apply_to_hud(get_tree())
	modulate.a = 0.0
	is_hidden = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("soul_heal"):
		use_soul_flask()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if is_instance_valid(_stamina_actor): delta = CombatTime.actor_delta(_stamina_actor, delta)
	var skill_immune: bool = is_instance_valid(_stamina_actor) and _stamina_actor.has_method("is_skill_damage_immune") and _stamina_actor.is_skill_damage_immune()
	# CanvasLayer has its own canvas; transfer the existing fade/flash tint.
	hud_art.modulate = modulate
	var tick_result := _stats.tick(delta, skill_immune)
	if tick_result.damage_taken > 0:
		sync_hp_display()
		if tick_result.flash_red:
			flash_red()
		enter_combat()
	if tick_result.died:
		SaveManager.respawn_at_checkpoint()
		return

	# Stamina timing follows actions, independently of HUD visibility/combat fade.
	var regen_blocked: bool = is_instance_valid(_stamina_actor) and _stamina_actor.blocks_stamina_regeneration()
	if _stats.regen_stamina(delta, regen_blocked):
		sync_stamina_display()
		enter_combat()

	if in_combat:
		hide_timer += delta
		if hide_timer >= hide_delay:
			fade_out()
			in_combat = false
			hide_timer = 0.0

	_update_flask_shake(delta)

	update_shader_value(soul_main, _flask_shader_percent)
	update_shader_value(soul_delay, _flask_shader_percent)

#hàm công khai nhóm sát thương
func set_campfire_hidden(hidden: bool) -> void:
	# ScreenSpace has a separate canvas; keep stats ticking while hiding its art.
	$ScreenSpace.visible = not hidden

func heal_to_full() -> void:
	_stats.heal_to_full()
	sync_stagger_markers()
	sync_flask_display()
	sync_status_icons()
	sync_hp_display()
	sync_stamina_display()
	fade_in()

func apply_damage(dmg: int, _hit_from_global: Vector2 = Vector2.INF, skip_stagger_thresholds: bool = false) -> Dictionary:
	if is_instance_valid(_stamina_actor) and _stamina_actor.has_method("is_skill_damage_immune") and _stamina_actor.is_skill_damage_immune():
		return {"damage_taken": 0, "staggered": false, "died": false, "flash_red": false}
	var result := _stats.apply_damage(dmg, _hit_from_global, skip_stagger_thresholds)

	if result.markers_changed:
		sync_stagger_markers()
	if result.debuff_id != "":
		sync_status_icons()
		stagger_debuff_applied.emit(result.debuff_id, result.debuff_level)
		enter_combat()
	if result.staggered:
		stagger_triggered.emit(result.stagger_tier, result.floor_hp)

	if result.damage_taken > 0:
		sync_hp_display()
		flash_red()
		enter_combat()

	if result.died:
		SaveManager.respawn_at_checkpoint()

	return result

func damage(dmg: int) -> void:
	apply_damage(dmg)

func enter_combat() -> void:
	in_combat = true
	hide_timer = 0.0
	fade_in()

func restore_stagger_thresholds() -> void:
	_stats.restore_stagger_thresholds()
	sync_stagger_markers()


func restore_one_stagger_threshold() -> bool:
	var restored := _stats.restore_one_stagger_threshold()
	if restored:
		sync_stagger_markers()
	return restored


func has_used_stagger_threshold() -> bool:
	return _stats.has_used_stagger_threshold()

#hàm công khai nhóm hồi phục
func use_soul_flask() -> void:
	if not _stats.can_use_soul_flask():
		return
	if _is_flask_draining:
		return

	var target_percent := 0.0
	if max_flask_charges > 0:
		target_percent = float(max(flask_charges - 1, 0)) / float(max_flask_charges)

	_is_flask_draining = true
	_trigger_flask_shake()
	if _flask_drain_tween:
		_flask_drain_tween.kill()
		_flask_drain_tween = null

	var t := create_tween()
	_flask_drain_tween = t
	t.tween_property(self, "_flask_shader_percent", target_percent, FLASK_DRAIN_DURATION)
	t.tween_callback(Callable(self, "_on_flask_drain_complete"))

func restore_flask_charges() -> void:
	_stats.restore_flask_charges()
	sync_flask_display()

func add_max_flask_charges(extra: int) -> void:
	_stats.add_max_flask_charges(extra)
	sync_flask_display()

#hàm công khai nhóm thể lực
func can_spend_stamina(action: String) -> bool:
	return _stats.can_spend_stamina(action)

func spend_stamina(action: String, allow_partial: bool = false) -> bool:
	var spent := _stats.spend_stamina(action, allow_partial)
	if spent and _stats.has_stamina_cost(action):
		sync_stamina_display()
		enter_combat()
	return spent

func restore_stamina_full() -> void:
	_stats.restore_stamina_full()
	sync_stamina_display()

#hàm công khai nhóm hiệu ứng
func get_guard_damage_multiplier() -> float:
	return _stats.get_guard_damage_multiplier()

func get_damage_taken_multiplier() -> float:
	return _stats.get_damage_taken_multiplier()

func get_damage_dealt_multiplier() -> float:
	return _stats.get_damage_dealt_multiplier()

func get_move_speed_multiplier() -> float:
	return _stats.get_move_speed_multiplier()

func get_attack_speed_multiplier() -> float:
	return _stats.get_attack_speed_multiplier()

func has_bleeding() -> bool:
	return _stats.has_bleeding()

func has_fracture() -> bool:
	return _stats.has_fracture()

func has_any_debuff() -> bool:
	return _stats.has_any_debuff()

func clear_all_debuffs() -> void:
	_stats.clear_all_debuffs()
	sync_status_icons()

func apply_buff(buff_id: String, level: int = 1) -> void:
	_stats.apply_buff(buff_id, level)
	sync_status_icons()

func remove_buff(buff_id: String) -> void:
	_stats.remove_buff(buff_id)
	if buff_bar:
		buff_bar.remove_effect(buff_id)

#hàm công khai nhóm giao diện
func sync_hp_display() -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "HP %d / %d" % [hp, max_hp]
	fade_in()

func sync_stamina_display() -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina
	stamina_label.text = "Stamina %d" % int(round(stamina))
	fade_in()

func sync_flask_display() -> void:
	var percent := float(flask_charges) / float(max_flask_charges) if max_flask_charges > 0 else 0.0
	if not _is_flask_draining:
		_flask_shader_percent = percent
		update_shader_value(soul_main, _flask_shader_percent)
		update_shader_value(soul_delay, _flask_shader_percent)
	if flask_uses_label:
		flask_uses_label.text = "x%d" % flask_charges
	fade_in()

func sync_status_icons() -> void:
	if debuff_bar:
		debuff_bar.set_effect("bleeding", bleeding_level, false)
		debuff_bar.set_effect("fracture", fracture_level, false)
	if buff_bar:
		buff_bar.clear_all()
		for buff_id in active_buffs.keys():
			buff_bar.set_effect(buff_id, int(active_buffs[buff_id]), true)

func sync_stagger_markers() -> void:
	if stagger_marker_66:
		stagger_marker_66.color = STAGGER_MARKER_READY if stagger_tiers_ready[0] else STAGGER_MARKER_USED
	if stagger_marker_33:
		stagger_marker_33.color = STAGGER_MARKER_READY if stagger_tiers_ready[1] else STAGGER_MARKER_USED
	for marker in [stagger_marker_66, stagger_marker_33]:
		if marker:
			marker.get_node("Arrow").modulate = marker.color

func update_shader_value(node: CanvasItem, value: float) -> void:
	if node and node.material:
		node.material.set_shader_parameter("hp", value)

func flash_red() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1, 0.5, 0.5, 1), 0.05)
	t.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)

func flash_heal() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate", Color(0.75, 0.9, 1, 1), 0.05)
	t.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

func fade_in() -> void:
	if not is_hidden:
		return
	is_hidden = false
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.4)

func fade_out() -> void:
	if is_hidden:
		return
	is_hidden = true
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.6)

#hàm nội bộ nhóm sát thương và trạng thái
func _recalc_flask_heal_amount() -> void:
	_stats.recalc_flask_heal_amount()

#hàm nội bộ nhóm vfx
func _trigger_impact_feedback(screen_strength: float) -> void:
	var fx := _get_screen_effects()
	if fx and fx.has_method("trigger_impact_shake"):
		fx.trigger_impact_shake(screen_strength)
	_trigger_flask_shake()

func _trigger_flask_shake() -> void:
	_flask_shake_time = 0.0
	_flask_shake_amount = 1.0

func _update_flask_shake(delta: float) -> void:
	if _flask_shake_amount <= 0.0:
		soul_flask.position = _flask_rest_position
		_set_flask_border_shake(0.0, 0.0)
		return
	_flask_shake_time += delta
	_flask_shake_amount = maxf(_flask_shake_amount - delta * FLASK_SHAKE_DECAY, 0.0)
	var wobble := Vector2(
		sin(_flask_shake_time * 64.0),
		cos(_flask_shake_time * 58.0)
	) * _flask_shake_amount * 5.0
	soul_flask.position = _flask_rest_position + wobble
	_set_flask_border_shake(_flask_shake_time, _flask_shake_amount)

func _set_flask_border_shake(time: float, amount: float) -> void:
	if flask_border and flask_border.material:
		flask_border.material.set_shader_parameter("shake_time", time)
		flask_border.material.set_shader_parameter("shake_amount", amount)

func _get_screen_effects() -> Node:
	var root := get_tree().current_scene
	if root == null:
		return null
	return root.get_node_or_null("ScreenEffects")

#hàm tín hiệu
func _on_stagger_triggered(_tier: int, _floor_hp: int) -> void:
	_trigger_impact_feedback(SCREEN_SHAKE_STAGGER)

func _on_flask_drain_complete() -> void:
	_is_flask_draining = false
	_flask_drain_tween = null

	var flask_result := _stats.use_soul_flask()
	if not flask_result.used:
		return
	if flask_result.threshold_restored:
		sync_stagger_markers()
	sync_hp_display()
	sync_flask_display()
	sync_status_icons()
	flash_heal()
	enter_combat()
	_trigger_impact_feedback(SCREEN_SHAKE_FLASK)


func _layout_hud() -> void:
	var viewport_size := get_viewport_rect().size
	var margin := Vector2(maxf(screen_margin.x, 0.0), maxf(screen_margin.y, 0.0))
	var available := (viewport_size - margin * 2.0).max(Vector2.ONE)
	var fit := minf(available.x / REFERENCE_SIZE.x, available.y / REFERENCE_SIZE.y)
	hud_art.scale = Vector2.ONE * minf(maxf(hud_scale, 0.25), fit)
	hud_art.position = margin
	hp_label.visible = show_numeric_values
	stamina_label.visible = show_numeric_values
	flask_uses_label.visible = show_numeric_values
	hp_label.position = Vector2(8, -24)
	stamina_label.position = Vector2(374, 31)
	flask_uses_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flask_uses_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM


func configure_stamina(costs: Dictionary, delay: float, rate: float) -> void:
	_stats.stamina_costs = costs.duplicate()
	_stats.stamina_regen_delay = maxf(delay, 0.0)
	_stats.stamina_regen_per_second = maxf(rate, 0.0)
