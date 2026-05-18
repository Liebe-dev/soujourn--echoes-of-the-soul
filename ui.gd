extends Control

signal stagger_triggered(tier: int, floor_hp: int)
signal stagger_debuff_applied(debuff_id: String, level: int)

# ======================
#      STATS
# ======================
var max_hp := 100
var hp := 100
var max_flask_charges := 3
var flask_charges := 3
var max_stamina := 100.0
var stamina := 100.0
var flask_heal_per_use := 34

## Debuffs (extend with buffs dict later).
var bleeding_level := 0
var fracture_level := 0
var active_buffs: Dictionary = {}

const STAGGER_THRESHOLD_FRACS := [0.66, 0.33]
const STAGGER_LOCK_DURATION := 1.0
const BLEED_TICK_INTERVAL := 1.0
const BLEED_DPS := {1: 3, 2: 6}

var stagger_tiers_ready: Array[bool] = [true, true]
var stagger_lock_hp := -1
var stagger_lock_timer := 0.0
var _bleed_tick_timer := 0.0

const STAMINA_COST := {"attack": 20.0, "parry": 15.0, "deflect": 15.0}
const STAMINA_REGEN_PER_SEC := 28.0
const SCREEN_SHAKE_FLASK := 0.5
const SCREEN_SHAKE_STAGGER := 0.72
const FLASK_SHAKE_DECAY := 3.5

# ======================
#      NODES
# ======================
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

var in_combat := false
var hide_delay := 3.0
var hide_timer := 0.0
var is_hidden := false
var fade_tween: Tween

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
	modulate.a = 0.0
	is_hidden = true

func _process(delta: float) -> void:
	if stagger_lock_timer > 0.0:
		stagger_lock_timer = maxf(stagger_lock_timer - delta, 0.0)
		if stagger_lock_timer <= 0.0:
			stagger_lock_hp = -1

	_process_bleeding(delta)

	if not in_combat and stamina < max_stamina:
		stamina = minf(stamina + STAMINA_REGEN_PER_SEC * delta, max_stamina)
		sync_stamina_display()

	if in_combat:
		hide_timer += delta
		if hide_timer >= hide_delay:
			fade_out()
			in_combat = false
			hide_timer = 0.0

	_update_flask_shake(delta)

# ======================
#   DEBUFFS / BUFFS
# ======================
func has_bleeding() -> bool:
	return bleeding_level > 0

func has_fracture() -> bool:
	return fracture_level > 0

func clear_all_debuffs() -> void:
	bleeding_level = 0
	fracture_level = 0
	_bleed_tick_timer = 0.0
	sync_status_icons()

## Flask: removes all bleeding; fracture only −1 level (both can apply on one drink).
func _cure_debuffs_from_flask() -> void:
	if has_bleeding():
		bleeding_level = 0
		_bleed_tick_timer = 0.0
	if has_fracture():
		fracture_level -= 1
	sync_status_icons()

func get_damage_taken_multiplier() -> float:
	if fracture_level <= 0:
		return 1.0
	return 1.0 + 0.2 * fracture_level

func get_damage_dealt_multiplier() -> float:
	match fracture_level:
		0:
			return 1.0
		1:
			return 0.85
		2:
			return 0.8
		_:
			return 0.65

func get_move_speed_multiplier() -> float:
	if fracture_level >= 2:
		return 0.72
	return 1.0

func get_attack_speed_multiplier() -> float:
	if fracture_level >= 2:
		return 0.75
	return 1.0

func sync_status_icons() -> void:
	if debuff_bar:
		debuff_bar.set_effect("bleeding", bleeding_level, false)
		debuff_bar.set_effect("fracture", fracture_level, false)
	if buff_bar:
		buff_bar.clear_all()
		for buff_id in active_buffs.keys():
			buff_bar.set_effect(buff_id, int(active_buffs[buff_id]), true)

func _process_bleeding(delta: float) -> void:
	if bleeding_level <= 0:
		_bleed_tick_timer = 0.0
		return
	_bleed_tick_timer += delta
	if _bleed_tick_timer >= BLEED_TICK_INTERVAL:
		_bleed_tick_timer = 0.0
		var dps: int = BLEED_DPS.get(bleeding_level, 3)
		_apply_raw_hp_loss(dps, true)

func _apply_random_stagger_debuff() -> void:
	if randf() < 0.5:
		_apply_bleeding(1)
	else:
		_apply_fracture(1)

func _apply_bleeding(level: int) -> void:
	bleeding_level = maxi(bleeding_level, level)
	sync_status_icons()
	stagger_debuff_applied.emit("bleeding", bleeding_level)
	enter_combat()

func _apply_fracture(add_levels: int = 1) -> void:
	fracture_level = clampi(fracture_level + add_levels, 0, 3)
	sync_status_icons()
	stagger_debuff_applied.emit("fracture", fracture_level)
	enter_combat()

# ======================
#   FLASK
# ======================
func restore_flask_charges() -> void:
	flask_charges = max_flask_charges
	sync_flask_display()

func add_max_flask_charges(extra: int) -> void:
	max_flask_charges = maxi(max_flask_charges + extra, 1)
	flask_charges = mini(flask_charges + extra, max_flask_charges)
	_recalc_flask_heal_amount()
	sync_flask_display()

func _recalc_flask_heal_amount() -> void:
	flask_heal_per_use = maxi(1, int(ceil(float(max_hp) / float(max_flask_charges))))

func sync_flask_display() -> void:
	var percent := float(flask_charges) / float(max_flask_charges) if max_flask_charges > 0 else 0.0
	update_shader_value(soul_main, percent)
	update_shader_value(soul_delay, percent)
	if flask_uses_label:
		flask_uses_label.text = "x%d" % flask_charges

# ======================
#   STAGGER
# ======================
func restore_stagger_thresholds() -> void:
	stagger_tiers_ready = [true, true]
	stagger_lock_hp = -1
	stagger_lock_timer = 0.0
	sync_stagger_markers()

func sync_stagger_markers() -> void:
	if stagger_marker_66:
		stagger_marker_66.color = STAGGER_MARKER_READY if stagger_tiers_ready[0] else STAGGER_MARKER_USED
	if stagger_marker_33:
		stagger_marker_33.color = STAGGER_MARKER_READY if stagger_tiers_ready[1] else STAGGER_MARKER_USED

func _stagger_floor_hp(tier: int) -> int:
	return int(round(max_hp * STAGGER_THRESHOLD_FRACS[tier]))

func _on_stagger_triggered(_tier: int, _floor_hp: int) -> void:
	_trigger_impact_feedback(SCREEN_SHAKE_STAGGER)

func _resolve_stagger_crossing(prev_hp: int, target_hp: int, tier: int) -> Dictionary:
	var floor_hp := _stagger_floor_hp(tier)
	var out := {
		"target_hp": target_hp,
		"triggered": false,
		"skip_player_stagger": false,
		"floor_hp": floor_hp,
		"tier": tier,
	}
	if prev_hp <= floor_hp or target_hp > floor_hp:
		return out

	out.triggered = true
	stagger_tiers_ready[tier] = false
	sync_stagger_markers()

	if has_bleeding():
		out.target_hp = floor_hp
		out.skip_player_stagger = true
		stagger_lock_hp = -1
		stagger_lock_timer = 0.0
		_apply_bleeding(2)
		stagger_triggered.emit(tier, floor_hp)
		return out

	out.target_hp = floor_hp
	stagger_lock_hp = floor_hp
	stagger_lock_timer = STAGGER_LOCK_DURATION
	_apply_random_stagger_debuff()
	stagger_triggered.emit(tier, floor_hp)
	return out

# ======================
#   SHAKE
# ======================
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

# ======================
#   STAMINA
# ======================
func can_spend_stamina(action: String) -> bool:
	if not STAMINA_COST.has(action):
		return true
	return stamina >= STAMINA_COST[action]

func spend_stamina(action: String) -> bool:
	if not STAMINA_COST.has(action):
		return true
	var cost: float = STAMINA_COST[action]
	if stamina < cost:
		return false
	stamina -= cost
	sync_stamina_display()
	enter_combat()
	return true

func restore_stamina_full() -> void:
	stamina = max_stamina
	sync_stamina_display()

# ======================
#      HP
# ======================
func heal_to_full() -> void:
	hp = max_hp
	stamina = max_stamina
	restore_stagger_thresholds()
	restore_flask_charges()
	clear_all_debuffs()
	sync_hp_display()
	sync_flask_display()
	sync_stamina_display()
	fade_in()

func sync_hp_display() -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "HP %d / %d" % [hp, max_hp]

func sync_stamina_display() -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina
	stamina_label.text = "Stamina %d" % int(round(stamina))

func enter_combat() -> void:
	in_combat = true
	hide_timer = 0.0
	fade_in()

func _apply_raw_hp_loss(amount: int, from_bleed: bool = false) -> void:
	if amount <= 0 or hp <= 0:
		return
	hp = maxi(hp - amount, 0)
	sync_hp_display()
	if from_bleed:
		flash_red()
	enter_combat()
	if hp <= 0:
		SaveManager.respawn_at_checkpoint()

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

	var scaled_dmg := maxi(1, int(round(float(dmg) * get_damage_taken_multiplier())))
	var prev_hp := hp
	var target_hp := prev_hp - scaled_dmg

	if stagger_lock_timer > 0.0 and stagger_lock_hp >= 0 and not has_bleeding():
		target_hp = maxi(target_hp, stagger_lock_hp)

	for tier in STAGGER_THRESHOLD_FRACS.size():
		if not stagger_tiers_ready[tier]:
			continue
		var cross := _resolve_stagger_crossing(prev_hp, target_hp, tier)
		if cross.triggered:
			target_hp = cross.target_hp
			result.staggered = true
			result.stagger_tier = tier
			result.floor_hp = cross.floor_hp
			result.skip_player_stagger = cross.skip_player_stagger
			break

	hp = clampi(target_hp, 0, max_hp)
	result.damage_taken = prev_hp - hp

	if result.damage_taken > 0:
		sync_hp_display()
		flash_red()
		enter_combat()

	if hp <= 0:
		SaveManager.respawn_at_checkpoint()

	return result

func damage(dmg: int) -> void:
	apply_damage(dmg)

func has_any_debuff() -> bool:
	return has_bleeding() or has_fracture()

func use_soul_flask() -> void:
	if flask_charges <= 0:
		return
	if hp >= max_hp and not has_any_debuff():
		return

	flask_charges -= 1
	_cure_debuffs_from_flask()
	hp = mini(hp + flask_heal_per_use, max_hp)
	sync_hp_display()
	sync_flask_display()
	sync_status_icons()
	flash_heal()
	enter_combat()
	_trigger_impact_feedback(SCREEN_SHAKE_FLASK)

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("soul_heal"):
		use_soul_flask()
		get_viewport().set_input_as_handled()

## Future buffs: hud.apply_buff("name", level)
func apply_buff(buff_id: String, level: int = 1) -> void:
	active_buffs[buff_id] = level
	sync_status_icons()

func remove_buff(buff_id: String) -> void:
	active_buffs.erase(buff_id)
	if buff_bar:
		buff_bar.remove_effect(buff_id)
