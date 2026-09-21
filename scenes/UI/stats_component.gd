extends RefCounted
class_name StatsComponent
## D1.1 — Model stats tách khỏi scenes/UI/ui.gd.
##
## - Chỉ chứa state + logic stats (HP / stamina / flask / debuff / stagger).
## - KHÔNG phụ thuộc node, scene hay autoload: không get_tree(), không SaveManager,
##   không sync_*/flash_*/enter_combat/fade_* — side-effect hiển thị do ui.gd lo ở D1.3.
## - Chưa được wire (dead code) cho tới D1.2/D1.3.

# --- State ---
var max_hp: int = 100
var hp: int = 100
var max_flask_charges: int = 3
var flask_charges: int = 3
var max_stamina: float = 100.0
var stamina: float = 100.0
var flask_heal_per_use: int = 34

# Debuffs
var bleeding_level: int = 0
var fracture_level: int = 0
var active_buffs: Dictionary = {}

const STAGGER_THRESHOLD_FRACS := [0.66, 0.33]
const STAGGER_LOCK_DURATION := 1.0
const BLEED_TICK_INTERVAL := 1.0
const BLEED_DPS := {1: 3, 2: 6}

var stagger_tiers_ready: Array[bool] = [true, true]
var stagger_lock_hp: int = -1
var stagger_lock_timer: float = 0.0
var _bleed_tick_timer: float = 0.0

const STAMINA_COST := {"attack": 20.0, "parry": 15.0, "deflect": 15.0}
const STAMINA_REGEN_PER_SEC := 28.0

# --- Tick (thay cho khối stagger-lock + _process_bleeding trong _process của ui.gd) ---
func tick(delta: float) -> Dictionary:
	if stagger_lock_timer > 0.0:
		stagger_lock_timer = maxf(stagger_lock_timer - delta, 0.0)
		if stagger_lock_timer <= 0.0:
			stagger_lock_hp = -1
	return _process_bleeding(delta)

func regen_stamina(delta: float) -> bool:
	if stamina >= max_stamina:
		return false
	stamina = minf(stamina + STAMINA_REGEN_PER_SEC * delta, max_stamina)
	return true

# --- Damage ---
func heal_to_full() -> void:
	hp = max_hp
	stamina = max_stamina
	restore_stagger_thresholds()
	restore_flask_charges()
	clear_all_debuffs()

func restore_stagger_thresholds() -> void:
	stagger_tiers_ready = [true, true]
	stagger_lock_hp = -1
	stagger_lock_timer = 0.0

func restore_one_stagger_threshold() -> bool:
	for tier in range(STAGGER_THRESHOLD_FRACS.size() - 1, -1, -1):
		if stagger_tiers_ready[tier]:
			continue
		stagger_tiers_ready[tier] = true
		stagger_lock_hp = -1
		stagger_lock_timer = 0.0
		return true
	return false

func has_used_stagger_threshold() -> bool:
	for tier_ready in stagger_tiers_ready:
		if not tier_ready:
			return true
	return false

# --- Recovery ---
func restore_flask_charges() -> void:
	flask_charges = max_flask_charges

func add_max_flask_charges(extra: int) -> void:
	max_flask_charges = maxi(max_flask_charges + extra, 1)
	flask_charges = mini(flask_charges + extra, max_flask_charges)
	recalc_flask_heal_amount()

func consume_flask_charge() -> void:
	flask_charges -= 1

func cure_debuffs_from_flask() -> void:
	if has_bleeding():
		bleeding_level = 0
		_bleed_tick_timer = 0.0
	if has_fracture():
		fracture_level -= 1

func heal_from_flask() -> void:
	hp = mini(hp + flask_heal_per_use, max_hp)

func recalc_flask_heal_amount() -> void:
	flask_heal_per_use = maxi(1, int(ceil(float(max_hp) / float(max_flask_charges))))

# --- Stamina ---
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
	return true

func restore_stamina_full() -> void:
	stamina = max_stamina

# --- Status effects ---
func get_damage_taken_multiplier() -> float:
	if fracture_level <= 0:
		return 1.0
	return 1.0 + 0.2 * fracture_level

func get_damage_dealt_multiplier() -> float:
	match fracture_level:
		0: return 1.0
		1: return 0.85
		2: return 0.8
		_: return 0.65

func get_move_speed_multiplier() -> float:
	if fracture_level >= 2:
		return 0.72
	return 1.0

func get_attack_speed_multiplier() -> float:
	if fracture_level >= 2:
		return 0.75
	return 1.0

func has_bleeding() -> bool:
	return bleeding_level > 0

func has_fracture() -> bool:
	return fracture_level > 0

func has_any_debuff() -> bool:
	return has_bleeding() or has_fracture()

func clear_all_debuffs() -> void:
	bleeding_level = 0
	fracture_level = 0
	_bleed_tick_timer = 0.0

func apply_buff(buff_id: String, level: int = 1) -> void:
	active_buffs[buff_id] = level

func remove_buff(buff_id: String) -> void:
	active_buffs.erase(buff_id)

# --- Internal: damage & status ---
func _apply_raw_hp_loss(amount: int, from_bleed: bool = false) -> Dictionary:
	var out := {"damage_taken": 0, "died": false, "flash_red": from_bleed}
	if amount <= 0 or hp <= 0:
		return out
	var prev := hp
	hp = maxi(hp - amount, 0)
	out.damage_taken = prev - hp
	out.died = hp <= 0
	return out

func _process_bleeding(delta: float) -> Dictionary:
	var out := {"damage_taken": 0, "died": false, "flash_red": false}
	if bleeding_level <= 0:
		_bleed_tick_timer = 0.0
		return out
	_bleed_tick_timer += delta
	if _bleed_tick_timer >= BLEED_TICK_INTERVAL:
		_bleed_tick_timer = 0.0
		var dps: int = BLEED_DPS.get(bleeding_level, 3)
		return _apply_raw_hp_loss(dps, true)
	return out

func _apply_random_stagger_debuff() -> Dictionary:
	if randf() < 0.5:
		return _apply_bleeding(1)
	return _apply_fracture(1)

func _apply_bleeding(level: int) -> Dictionary:
	bleeding_level = maxi(bleeding_level, level)
	return {"debuff_id": "bleeding", "level": bleeding_level}

func _apply_fracture(add_levels: int = 1) -> Dictionary:
	fracture_level = clampi(fracture_level + add_levels, 0, 3)
	return {"debuff_id": "fracture", "level": fracture_level}

# --- Internal: stagger ---
func resolve_stagger_crossing(prev_hp: int, target_hp: int, tier: int) -> Dictionary:
	var floor_hp := _stagger_floor_hp(tier)
	var out := {
		"target_hp": target_hp,
		"triggered": false,
		"skip_player_stagger": false,
		"floor_hp": floor_hp,
		"tier": tier,
		"markers_changed": false,
		"debuff_id": "",
		"debuff_level": 0,
	}
	if prev_hp <= floor_hp or target_hp > floor_hp:
		return out

	out.triggered = true
	stagger_tiers_ready[tier] = false
	out.markers_changed = true

	if has_bleeding():
		out.target_hp = floor_hp
		out.skip_player_stagger = true
		stagger_lock_hp = -1
		stagger_lock_timer = 0.0
		var bleed := _apply_bleeding(2)
		out.debuff_id = bleed["debuff_id"]
		out.debuff_level = bleed["level"]
		return out

	out.target_hp = floor_hp
	stagger_lock_hp = floor_hp
	stagger_lock_timer = STAGGER_LOCK_DURATION
	var debuff := _apply_random_stagger_debuff()
	out.debuff_id = debuff["debuff_id"]
	out.debuff_level = debuff["level"]
	return out

func _stagger_floor_hp(tier: int) -> int:
	return int(round(max_hp * STAGGER_THRESHOLD_FRACS[tier]))
