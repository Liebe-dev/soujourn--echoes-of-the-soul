extends Control
const Config = preload("res://scenes/Mechanic/progression_config.gd")
const STATS := "MainPanel/MarginContainer/HBoxContainer/LeftColumn/Stats/VBoxContainer/"
const WALLET := "MainPanel/MarginContainer/HBoxContainer/LeftColumn/Coin_Soul/VBoxContainer/"

func _ready() -> void:
	PlayerProgress.changed.connect(update_character_stats)
	visibility_changed.connect(update_character_stats)
	update_character_stats()

func update_character_stats() -> void:
	if not is_node_ready(): return
	get_node(STATS + "LV_EXP/lv_value").text = str(PlayerProgress.level)
	get_node(STATS + "LV_EXP/exp_value").text = "%d / %d" % [PlayerProgress.exp, PlayerProgress.get_exp_to_next_level()]
	get_node(STATS + "MainStatsGrid/hp value").text = str(PlayerProgress.get_max_hp())
	get_node(STATS + "MainStatsGrid/sp_value").text = "%.0f" % PlayerProgress.get_max_stamina()
	get_node(STATS + "MainStatsGrid/mp_value").text = "Pending"
	for i in Config.ATTRIBUTES.size():
		var id: StringName = Config.ATTRIBUTES[i]
		get_node(STATS + "SubStatsGrid/" + str(id) + "_label").tooltip_text = Config.DESCRIPTIONS[i]
		get_node(STATS + "SubStatsGrid/" + str(id) + "_label").mouse_filter = Control.MOUSE_FILTER_PASS
		get_node(STATS + "SubStatsGrid/" + str(id) + "_value").text = str(PlayerProgress.attributes[id])
	get_node(WALLET + "coin/coin_value").text = str(PlayerProgress.coin)
	get_node(WALLET + "soul/soul_value").text = str(PlayerProgress.soul)
	$MainPanel/MarginContainer/HBoxContainer/LeftColumn/Name/NameLabel.text = "Adel"
	$UpgradePointsLabel.text = "Upgrade points: %d — allocate at a campfire" % PlayerProgress.upgrade_points
