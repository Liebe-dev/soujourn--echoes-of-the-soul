extends Node
signal exp_changed(current_exp: int, exp_to_next: int, level: int)
signal level_up(new_level: int, points_gained: int)
signal upgrade_points_changed(points: int)
signal stats_upgraded
signal changed
signal wallet_changed(coin: int, soul: int)

const MAX_SAVED_INTEGER := 9007199254740991
const Config = preload("res://scenes/Mechanic/progression_config.gd")
var config: Resource = preload("res://scenes/Mechanic/progression_config.tres")
var total_play_time: float = 0.0
var level := 1
var exp := 0
var upgrade_points := 0
var attributes: Dictionary = config.empty_attributes()
var coin := 0
var soul := 0
var migration_message := ""

func get_exp_to_next_level() -> int:
	return maxi(config.exp_per_level_base, 1) * level

func get_max_hp() -> int: return config.max_hp(attributes)
func get_max_stamina() -> float: return config.max_stamina(attributes)

func add_exp(amount: int) -> void:
	if amount <= 0: return
	exp += amount
	while exp >= get_exp_to_next_level():
		exp -= get_exp_to_next_level()
		level += 1
		var gained: int = maxi(config.points_per_level, 1)
		upgrade_points += gained
		level_up.emit(level, gained)
	upgrade_points_changed.emit(upgrade_points)
	exp_changed.emit(exp, get_exp_to_next_level(), level)
	changed.emit()

func add_currency(coin_amount: int, soul_amount: int) -> bool:
	if coin_amount < 0 or soul_amount < 0 or coin_amount > MAX_SAVED_INTEGER - coin or soul_amount > MAX_SAVED_INTEGER - soul: return false
	coin += coin_amount
	soul += soul_amount
	wallet_changed.emit(coin, soul)
	changed.emit()
	return true

func try_spend_currency(coin_amount: int, soul_amount: int) -> bool:
	if coin_amount < 0 or soul_amount < 0 or coin < coin_amount or soul < soul_amount: return false
	coin -= coin_amount
	soul -= soul_amount
	wallet_changed.emit(coin, soul)
	changed.emit()
	return true

func read_from_save_data(data: Dictionary) -> void:
	level = maxi(int(data.get("level", 1)), 1)
	exp = maxi(int(data.get("exp", 0)), 0)
	upgrade_points = maxi(int(data.get("upgrade_points", 0)), 0)
	attributes = config.empty_attributes()
	var stored: Dictionary = data.get("attributes", {})
	for id in Config.ATTRIBUTES: attributes[id] = maxi(int(stored.get(id, 0)), 0)
	coin = maxi(int(data.get("coin", 0)), 0)
	soul = maxi(int(data.get("soul", 0)), 0)
	migration_message = str(data.get("migration_message", ""))
	upgrade_points_changed.emit(upgrade_points)
	wallet_changed.emit(coin, soul)
	exp_changed.emit(exp, get_exp_to_next_level(), level)
	changed.emit()

func write_to_save_data(data: Dictionary) -> void:
	data["version"] = 2
	data["level"] = level
	data["exp"] = exp
	data["upgrade_points"] = upgrade_points
	data["attributes"] = attributes.duplicate()
	data["coin"] = coin
	data["soul"] = soul
	data["max_hp"] = get_max_hp()
	data["max_stamina"] = get_max_stamina()
	data["migration_message"] = migration_message
	data.erase("hp_upgrades")
	data.erase("stamina_upgrades")

func allocation_candidate(allocation: Dictionary) -> Dictionary:
	var next := attributes.duplicate()
	var total := 0
	for id in allocation:
		var value: Variant = allocation[id]
		if not id in Config.ATTRIBUTES or not value is int or value < 0 or value > upgrade_points: return {}
		total += value
		if total > upgrade_points: return {}
		next[id] += value
	if total <= 0: return {}
	return {"attributes": next, "upgrade_points": upgrade_points - total}

func apply_to_hud(tree: SceneTree = null) -> void:
	var target := tree if tree else get_tree()
	for player in target.get_nodes_in_group("Player"):
		if player.has_method("get_player_vitals"):
			apply_to_stats(player.get_player_vitals().model, player.stamina_regen_per_second)
			player.get_player_vitals().refresh()

func apply_to_stats(model: StatsComponent, actor_base_regen: float = 28.0) -> void:
	# Preserve current resources: upgrading is not a heal. Derived values never stack.
	model.max_hp = get_max_hp()
	model.hp = clampi(model.hp, 0, model.max_hp)
	model.max_stamina = get_max_stamina()
	model.stamina = clampf(model.stamina, 0.0, model.max_stamina)
	model.stamina_regen_per_second = config.stamina_regen(attributes, actor_base_regen)
	model.recalc_flask_heal_amount()

func _ready() -> void: process_mode = Node.PROCESS_MODE_ALWAYS
func _process(delta: float) -> void: total_play_time += delta

func get_formatted_time() -> String:
	var seconds := int(total_play_time)
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds % 3600) / 60, seconds % 60]
