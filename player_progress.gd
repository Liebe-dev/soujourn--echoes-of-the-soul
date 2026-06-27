extends Node
## Autoload: EXP, level-ups, and campfire stat upgrades (HP / stamina).

signal exp_changed(current_exp: int, exp_to_next: int, level: int)
signal level_up(new_level: int, points_gained: int)
signal upgrade_points_changed(points: int)
signal stats_upgraded

const BASE_MAX_HP := 100
const BASE_MAX_STAMINA := 100.0
const HP_PER_UPGRADE := 20
const STAMINA_PER_UPGRADE := 15.0
const EXP_PER_LEVEL_BASE := 100
const UPGRADE_POINTS_PER_LEVEL := 1

var level := 1
var exp := 0
var upgrade_points := 0
var hp_upgrades := 0
var stamina_upgrades := 0

func get_exp_to_next_level() -> int:
	return EXP_PER_LEVEL_BASE * level

func get_max_hp() -> int:
	return BASE_MAX_HP + hp_upgrades * HP_PER_UPGRADE

func get_max_stamina() -> float:
	return BASE_MAX_STAMINA + stamina_upgrades * STAMINA_PER_UPGRADE

func add_exp(amount: int) -> void:
	if amount <= 0:
		return

	exp += amount
	var leveled := false
	while exp >= get_exp_to_next_level():
		exp -= get_exp_to_next_level()
		level += 1
		upgrade_points += UPGRADE_POINTS_PER_LEVEL
		leveled = true
		level_up.emit(level, UPGRADE_POINTS_PER_LEVEL)
		upgrade_points_changed.emit(upgrade_points)

	exp_changed.emit(exp, get_exp_to_next_level(), level)
	if leveled:
		upgrade_points_changed.emit(upgrade_points)

func read_from_save_data(data: Dictionary) -> void:
	level = maxi(int(data.get("level", 1)), 1)
	exp = maxi(int(data.get("exp", 0)), 0)
	upgrade_points = maxi(int(data.get("upgrade_points", 0)), 0)
	hp_upgrades = maxi(int(data.get("hp_upgrades", 0)), 0)
	stamina_upgrades = maxi(int(data.get("stamina_upgrades", 0)), 0)

func write_to_save_data(data: Dictionary) -> void:
	data["level"] = level
	data["exp"] = exp
	data["upgrade_points"] = upgrade_points
	data["hp_upgrades"] = hp_upgrades
	data["stamina_upgrades"] = stamina_upgrades
	data["max_hp"] = get_max_hp()
	data["max_stamina"] = get_max_stamina()

func apply_to_hud(tree: SceneTree = null) -> void:
	var hud := _find_hud(tree if tree else get_tree())
	if hud == null:
		return

	var max_hp: int = int(hud.max_hp)
	hud.max_hp = get_max_hp()
	hud.hp = clampi(hud.hp + (hud.max_hp - max_hp), 0, hud.max_hp)

	hud.max_stamina = get_max_stamina()
	hud.stamina = clampf(hud.stamina, 0.0, hud.max_stamina)

	if hud.has_method("_recalc_flask_heal_amount"):
		hud._recalc_flask_heal_amount()
	if hud.has_method("sync_hp_display"):
		hud.sync_hp_display()
	if hud.has_method("sync_stamina_display"):
		hud.sync_stamina_display()

func try_upgrade_hp() -> bool:
	if upgrade_points <= 0:
		return false

	upgrade_points -= 1
	hp_upgrades += 1
	_apply_hp_upgrade()
	upgrade_points_changed.emit(upgrade_points)
	stats_upgraded.emit()
	return true

func try_upgrade_stamina() -> bool:
	if upgrade_points <= 0:
		return false

	upgrade_points -= 1
	stamina_upgrades += 1
	_apply_stamina_upgrade()
	upgrade_points_changed.emit(upgrade_points)
	stats_upgraded.emit()
	return true

func refresh_character_menu_ui(root: Node) -> void:
	if root == null:
		return

	var hud := _find_hud(get_tree())
	var lv_value: Label = root.get_node_or_null(
		"MainPanel/MarginContainer/HBoxContainer/LeftColumn/Stats/VBoxContainer/LV_EXP/lv_value"
	)
	var exp_value: Label = root.get_node_or_null(
		"MainPanel/MarginContainer/HBoxContainer/LeftColumn/Stats/VBoxContainer/LV_EXP/exp_value"
	)
	var hp_value: Label = root.get_node_or_null(
		"MainPanel/MarginContainer/HBoxContainer/LeftColumn/Stats/VBoxContainer/MainStatsGrid/hp value"
	)
	var sp_value: Label = root.get_node_or_null(
		"MainPanel/MarginContainer/HBoxContainer/LeftColumn/Stats/VBoxContainer/MainStatsGrid/sp_value"
	)
	var points_label: Label = root.get_node_or_null("UpgradePointsLabel")

	if lv_value:
		lv_value.text = str(level)
	if exp_value:
		exp_value.text = "%d / %d" % [exp, get_exp_to_next_level()]
	if hp_value:
		hp_value.text = str(hud.max_hp if hud else get_max_hp())
	if sp_value:
		var max_stamina: int = hud.max_stamina if hud else get_max_stamina()
		sp_value.text = str(int(round(max_stamina)))
	if points_label:
		points_label.text = "Upgrade Points: %d  (spend at campfire)" % upgrade_points

func refresh_upgrade_menu_ui(root: Node) -> void:
	if root == null:
		return

	var hud := _find_hud(get_tree())
	var level_label: Label = root.get_node_or_null("Panel/MarginContainer/VBox/Header/LevelValue")
	var exp_label: Label = root.get_node_or_null("Panel/MarginContainer/VBox/Header/ExpValue")
	var points_label: Label = root.get_node_or_null("Panel/MarginContainer/VBox/Header/PointsValue")
	var hp_label: Label = root.get_node_or_null("Panel/MarginContainer/VBox/Stats/HPRow/CurrentValue")
	var stamina_label: Label = root.get_node_or_null("Panel/MarginContainer/VBox/Stats/StaminaRow/CurrentValue")
	var hp_btn: Button = root.get_node_or_null("Panel/MarginContainer/VBox/Stats/HPRow/UpgradeButton")
	var stamina_btn: Button = root.get_node_or_null("Panel/MarginContainer/VBox/Stats/StaminaRow/UpgradeButton")

	if level_label:
		level_label.text = str(level)
	if exp_label:
		exp_label.text = "%d / %d" % [exp, get_exp_to_next_level()]
	if points_label:
		points_label.text = str(upgrade_points)
	if hp_label:
		hp_label.text = "%d  (+ %d next)" % [
			hud.max_hp if hud else get_max_hp(),
			HP_PER_UPGRADE,
		]
	if stamina_label:
		var max_stamina: int = hud.max_stamina if hud else get_max_stamina()
		stamina_label.text = "%d  (+ %d next)" % [
			int(round(max_stamina)),
			int(STAMINA_PER_UPGRADE),
		]
	if hp_btn:
		hp_btn.disabled = upgrade_points <= 0
	if stamina_btn:
		stamina_btn.disabled = upgrade_points <= 0

func _apply_hp_upgrade() -> void:
	var hud := _find_hud(get_tree())
	if hud == null:
		return

	var max_hp: int = hud.max_hp
	hud.max_hp = get_max_hp()
	hud.hp = clampi(hud.hp + (hud.max_hp - max_hp), 0, hud.max_hp)
	if hud.has_method("_recalc_flask_heal_amount"):
		hud._recalc_flask_heal_amount()
	if hud.has_method("sync_hp_display"):
		hud.sync_hp_display()

func _apply_stamina_upgrade() -> void:
	var hud := _find_hud(get_tree())
	if hud == null:
		return

	var old_max := int(hud.max_stamina)
	hud.max_stamina = get_max_stamina()
	hud.stamina = clampf(hud.stamina + (hud.max_stamina - old_max), 0.0, hud.max_stamina)
	if hud.has_method("sync_stamina_display"):
		hud.sync_stamina_display()

func _find_hud(tree: SceneTree) -> Node:
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene.find_child("hud", true, false)
