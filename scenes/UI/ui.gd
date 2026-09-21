extends Control

signal stagger_triggered(tier: int, floor_hp: int)
signal stagger_debuff_applied(debuff_id: String, level: int)

var _stats: StatsComponent = StatsComponent.new()

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

const STAGGER_THRESHOLD_FRACS := [0.66, 0.33]
const STAGGER_LOCK_DURATION := 1.0
const BLEED_TICK_INTERVAL := 1.0
const BLEED_DPS := {1: 3, 2: 6}

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

const STAMINA_COST := {"attack": 20.0, "parry": 15.0, "deflect": 15.0}
const STAMINA_REGEN_PER_SEC := 28.0
const SCREEN_SHAKE_FLASK := 0.5
const SCREEN_SHAKE_STAGGER := 0.72
const FLASK_SHAKE_DECAY := 3.5

@onready var soul_flask: MarginContainer = $bar/soul_flask
@onready var soul_main: TextureRect = $bar/soul_flask/soul_main
@onready var soul_delay: TextureRect = $bar/soul_flask/soul_delay
@onready var flask_border: TextureRect = $bar/soul_flask/border
@onready var flask_uses_label: Label = $bar/soul_flask/flask_uses_label
@onready var hp_bar: ProgressBar = $bar/hp_bar_panel/hp_bar_wrap/hp_bar
@onready var hp_label: Label = $bar/hp_bar_panel/hp_label
@onready var stagger_marker_66: ColorRect = $bar/hp_bar_panel/hp_bar_wrap/stagger_markers/marker_66
@onready var stagger_marker_33: ColorRect = $bar/hp_bar_panel/hp_bar_wrap/stagger_markers/marker_33
@onready var stamina_bar: ProgressBar = $bar/hp_bar_panel/stamina_bar
@onready var stamina_label: Label = $bar/hp_bar_panel/stamina_label
@onready var debuff_bar: HBoxContainer = $bar/hp_bar_panel/status_panel/debuff_bar
@onready var buff_bar: HBoxContainer = $bar/hp_bar_panel/status_panel/buff_bar

const STAGGER_MARKER_READY := Color(1, 0.82, 0.28, 0.95)
const STAGGER_MARKER_USED := Color(0.42, 0.4, 0.48, 0.55)

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
	var tick_result := _stats.tick(delta)
	if tick_result.damage_taken > 0:
		sync_hp_display()
		if tick_result.flash_red:
			flash_red()
		enter_combat()
	if tick_result.died:
		SaveManager.respawn_at_checkpoint()

	if not in_combat:
		if _stats.regen_stamina(delta):
			sync_stamina_display()

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
func heal_to_full() -> void:
	_stats.heal_to_full()
	sync_stagger_markers()
	sync_flask_display()
	sync_status_icons()
	sync_hp_display()
	sync_flask_display()
	sync_stamina_display()
	fade_in()

func apply_damage(dmg: int, _hit_from_global: Vector2 = Vector2.INF) -> Dictionary:
	var result := {
		"damage_taken": 0,
		"staggered": false,
		"stagger_tier": -1,
		"floor_hp": -1,
		"skip_player_stagger": false,
	}
	if dmg <= 0:
		return result

	var scaled_dmg := maxi(1, int(round(float(dmg) * _stats.get_damage_taken_multiplier())))
	var prev_hp := _stats.hp
	var target_hp := prev_hp - scaled_dmg

	if _stats.stagger_lock_timer > 0.0 and _stats.stagger_lock_hp >= 0 and not _stats.has_bleeding():
		target_hp = maxi(target_hp, _stats.stagger_lock_hp)

	for tier in _stats.STAGGER_THRESHOLD_FRACS.size():
		if not _stats.stagger_tiers_ready[tier]:
			continue
		var cross := _stats.resolve_stagger_crossing(prev_hp, target_hp, tier)
		if cross.triggered:
			target_hp = cross.target_hp
			result.staggered = true
			result.stagger_tier = tier
			result.floor_hp = cross.floor_hp
			result.skip_player_stagger = cross.skip_player_stagger
			if cross.markers_changed:
				sync_stagger_markers()
			if cross.debuff_id != "":
				sync_status_icons()
				stagger_debuff_applied.emit(cross.debuff_id, cross.debuff_level)
				enter_combat()
			stagger_triggered.emit(tier, cross.floor_hp)
			break

	_stats.hp = clampi(target_hp, 0, _stats.max_hp)
	result.damage_taken = prev_hp - _stats.hp

	if result.damage_taken > 0:
		sync_hp_display()
		flash_red()
		enter_combat()

	if _stats.hp <= 0:
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
	if flask_charges <= 0:
		return
	if hp >= max_hp and not has_any_debuff() and not has_used_stagger_threshold():
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

func spend_stamina(action: String) -> bool:
	var spent := _stats.spend_stamina(action)
	if spent and STAMINA_COST.has(action):
		sync_stamina_display()
		enter_combat()
	return spent

func restore_stamina_full() -> void:
	_stats.restore_stamina_full()
	sync_stamina_display()

#hàm công khai nhóm hiệu ứng
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


func _cure_debuffs_from_flask() -> void:
	_stats.cure_debuffs_from_flask()
	sync_status_icons()

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

	_stats.consume_flask_charge()
	_cure_debuffs_from_flask()
	_stats.heal_from_flask()
	restore_one_stagger_threshold()
	sync_hp_display()
	sync_flask_display()
	sync_status_icons()
	flash_heal()
	enter_combat()
	_trigger_impact_feedback(SCREEN_SHAKE_FLASK)
