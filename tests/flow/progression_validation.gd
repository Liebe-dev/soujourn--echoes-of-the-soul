extends Node
const Config = preload("res://scenes/Mechanic/progression_config.gd")
const Debug = preload("res://scenes/enemy/enemy_debug_settings.gd")
var checks := 0
var failures := 0

class Target:
	extends Node2D
	var current_health := 10000
	func take_damage(amount: int, _origin: Vector2) -> bool:
		current_health -= amount
		return amount > 0

func _ready() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PROGRESSION ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 3) -> void:
	for i in count: await get_tree().process_frame

func write(slot: int, data: Dictionary) -> void:
	var file := FileAccess.open(SaveManager.get_save_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(4)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://progression-" + label + ".png")

func _run() -> void:
	print("PROGRESSION USER DIR ", OS.get_user_data_dir())
	if not OS.get_user_data_dir().contains("CodexEntrySave20261014-Stats"):
		get_tree().quit(2)
		return
	if "--read-progress" in OS.get_cmdline_user_args():
		check(PlayerProgress.upgrade_points == 19, "restart retains spent points without compensation")
		check(PlayerProgress.attributes[&"vitality"] == 1 and PlayerProgress.attributes[&"agility"] == 1, "restart restores attributes")
		check(PlayerProgress.coin == 9 and PlayerProgress.soul == 4, "restart restores independent balances")
		check(SaveManager._data.version == 2, "restart uses schema 2")
		print("PROGRESSION RESTART RESULT checks=", checks, " failures=", failures)
		get_tree().quit(1 if failures else 0)
		return
	SaveManager.delete_save()
	var blank := SaveManager._default_data()
	PlayerProgress.read_from_save_data(blank)
	PlayerProgress.add_exp(650)
	check(PlayerProgress.level == 4 and PlayerProgress.exp == 50 and PlayerProgress.upgrade_points == 15, "multi-level EXP grants five points per level")
	var original_config: Resource = PlayerProgress.config
	PlayerProgress.config = original_config.duplicate()
	PlayerProgress.config.points_per_level = 3
	PlayerProgress.add_exp(350)
	check(PlayerProgress.level == 5 and PlayerProgress.upgrade_points == 18, "changed level award affects future level only")
	PlayerProgress.config = original_config
	PlayerProgress.read_from_save_data(blank)
	check(PlayerProgress.attributes.size() == 8 and PlayerProgress.get_max_hp() == 100 and PlayerProgress.get_max_stamina() == 100, "new game starts with eight zero investments")
	var attrs: Dictionary = original_config.empty_attributes()
	attrs[&"vitality"] = 2
	attrs[&"strength"] = 3
	attrs[&"resistance"] = 4
	attrs[&"agility"] = 5
	check(original_config.max_hp(attrs) == 140 and original_config.max_stamina(attrs) == 120, "mixed attributes produce expected HP/stamina")
	check(is_equal_approx(original_config.stamina_regen(attrs, 33.0), 34.4), "Agility adds to authored actor regeneration")
	var legacy := blank.duplicate(true)
	legacy.version = 1
	for key in ["attributes", "coin", "soul"]: legacy.erase(key)
	legacy.scene_path = SaveManager.NEW_GAME_SCENE
	legacy.level = 4
	legacy.exp = 5
	legacy.upgrade_points = 6
	legacy.hp_upgrades = 2
	legacy.stamina_upgrades = 1
	legacy.max_hp = 140
	legacy.hp = 81
	legacy.max_stamina = 115.0
	legacy.custom_future_field = {"kept": true}
	write(1, legacy)
	var path: String = SaveManager.get_save_path(1)
	var original_bytes := FileAccess.get_file_as_bytes(path)
	var migrated: Dictionary = SaveManager._read_slot_file(1)
	check(migrated.version == 2 and migrated.upgrade_points == 21 and migrated.hp == 81 and migrated.max_hp == 100, "migration refunds investments and preserves extra points and current HP")
	check(FileAccess.get_file_as_bytes(path) == original_bytes, "reading legacy save never writes disk")
	check(SaveManager._read_slot_file(1).upgrade_points == 21, "repeated legacy read does not duplicate compensation")
	var bad := migrated.duplicate(true)
	bad.attributes[&"vitality"] = -1
	check(not SaveManager._valid_data(bad), "negative attributes rejected")
	bad = migrated.duplicate(true)
	bad.coin = 0.5
	check(not SaveManager._valid_data(bad), "fractional currency rejected")
	bad = migrated.duplicate(true)
	bad.attributes[&"unknown"] = 1
	check(not SaveManager._valid_data(bad), "unknown attributes rejected")
	bad = legacy.duplicate(true)
	bad.points_per_level = 3
	check(not SaveManager._valid_data(bad), "custom legacy award schema rejected instead of guessing")
	bad = legacy.duplicate(true)
	bad.level = 9007199254740991
	write(5, bad)
	check(SaveManager._read_slot_file(5).is_empty(), "migration exceeding exact JSON integer range is rejected")
	check(SaveManager.load_from_slot(1), "legacy slot activates in memory")
	check(not PlayerProgress.migration_message.is_empty(), "migration notice available")
	check(PlayerProgress.add_currency(11, 7) and not PlayerProgress.add_currency(-1, 0), "wallet grants both currencies and rejects negative grants")
	check(not PlayerProgress.try_spend_currency(12, 1) and PlayerProgress.coin == 11 and PlayerProgress.soul == 7, "insufficient transaction has no partial debit")
	check(PlayerProgress.try_spend_currency(2, 3) and PlayerProgress.coin == 9 and PlayerProgress.soul == 4, "wallet spends independent balances")
	check(PlayerProgress.add_currency(PlayerProgress.MAX_SAVED_INTEGER - 9, 0) and not PlayerProgress.add_currency(1, 0) and PlayerProgress.coin == PlayerProgress.MAX_SAVED_INTEGER and PlayerProgress.try_spend_currency(PlayerProgress.MAX_SAVED_INTEGER - 9, 0), "wallet preserves exact JSON limit without overflow or partial grant")
	Debug.ai_disabled = true
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	await frames(5)
	var player = get_tree().get_first_node_in_group("Player")
	player.set_physics_process(false)
	player.vitals.simulation_enabled = false
	player.stats.hp = 47
	player.stats.stamina = 31.0
	var weapon = player.combat.equipped_weapon
	check(weapon.damage == 20 and player.stamina_regen_per_second == 33 and player.saber_skill.tap_cooldown == 4 and player.saber_skill.charged_cooldown == 6 and player.saber_skill.full_cooldown == 8, "existing combat tuning preserved")
	var menu = load("res://scenes/UI/campfire_upgrade_menu.tscn").instantiate()
	var layer := CanvasLayer.new()
	layer.layer = 120
	scene.add_child(layer)
	layer.add_child(menu)
	menu.open()
	menu._rows[&"vitality"].plus.pressed.emit()
	menu._rows[&"agility"].plus.pressed.emit()
	check(PlayerProgress.upgrade_points == 21 and player.stats.max_hp == 100 and FileAccess.get_file_as_bytes(path) == original_bytes, "preview neither spends points nor writes save nor changes Player")
	menu.close()
	menu.open()
	check(menu._spent() == 0 and PlayerProgress.attributes[&"vitality"] == 0, "closing discards preview")
	menu._adjust(&"vitality", 1)
	menu._adjust(&"agility", 1)
	await capture("allocation")
	var blocked := path + ".tmp"
	DirAccess.make_dir_absolute(blocked)
	menu._confirm()
	check(PlayerProgress.upgrade_points == 21 and player.stats.hp == 47 and menu._spent() == 2 and FileAccess.get_file_as_bytes(path) == original_bytes, "write failure retains points, Player, draft and original save")
	DirAccess.remove_absolute(blocked)
	menu._confirm()
	check(PlayerProgress.upgrade_points == 19 and PlayerProgress.attributes[&"vitality"] == 1 and PlayerProgress.attributes[&"agility"] == 1, "confirm commits exactly allocated attributes")
	check(player.stats.max_hp == 110 and player.stats.hp == 47 and player.stats.max_stamina == 104 and player.stats.stamina == 31, "upgrade changes maxima without healing")
	check(is_equal_approx(player.stats.stamina_regen_per_second, 33.28), "upgrade preserves scene regen baseline")
	var archived := path + ".before-stats-v2.bak"
	check(FileAccess.get_file_as_bytes(archived) == original_bytes, "permanent migration archive preserves original bytes")
	menu._confirm()
	check(PlayerProgress.upgrade_points == 19, "duplicate confirmation cannot consume twice")
	PlayerProgress.apply_to_hud()
	PlayerProgress.apply_to_hud()
	check(is_equal_approx(player.stats.stamina_regen_per_second, 33.28) and player.stats.max_hp == 110, "reapplying derived stats never stacks")
	check(SaveManager.sync_progress_to_active_slot() and FileAccess.get_file_as_bytes(archived) == original_bytes, "later saves retain permanent legacy archive")
	var stored: Dictionary = SaveManager._read_slot_file(1)
	check(stored.upgrade_points == 19 and stored.coin == 9 and stored.soul == 4 and stored.custom_future_field.kept, "version 2 roundtrip retains points, wallet and unknown metadata")
	check(SaveManager.load_from_slot(1) and PlayerProgress.upgrade_points == 19, "version 2 never receives migration compensation again")
	var second := blank.duplicate(true)
	second.scene_path = SaveManager.NEW_GAME_SCENE
	write(2, second)
	SaveManager.load_from_slot(2)
	check(PlayerProgress.coin == 0 and PlayerProgress.soul == 0 and PlayerProgress.attributes[&"vitality"] == 0, "slot wallets and attributes are independent")
	SaveManager.load_from_slot(1)
	SaveManager._session_selected = false
	check(not SaveManager.commit_attribute_allocation({&"vitality": 1}), "editor scene without slot ownership cannot save upgrades")
	SaveManager._session_selected = true
	check(PlayerProgress.allocation_candidate({&"faith": 20}).is_empty() and PlayerProgress.allocation_candidate({&"bad": 1}).is_empty() and PlayerProgress.allocation_candidate({&"faith": -1}).is_empty(), "invalid or unaffordable allocations rejected")
	PlayerProgress.attributes[&"prowess"] = 10
	PlayerProgress.attributes[&"strength"] = 5
	check(is_equal_approx(weapon.attack_multiplier(PlayerProgress.attributes, original_config), 1.26), "weapon scaling combines Prowess/Strength once")
	weapon.requirements.assign({&"strength": 6, &"faith": 1})
	check(is_equal_approx(weapon.attack_multiplier(PlayerProgress.attributes, original_config), 0.252), "multiple missing requirements apply 20 percent once")
	player._on_progress_changed()
	check(not player.saber_skill.begin() and not player.saber_skill.is_cooling_down() and not player._skill_requested, "locked Q cannot start animation or cooldown")
	var q = player.get_node("Camera2D/hud/ScreenSpace/WeaponLoadout/Q")
	check(q.requirement_locked and q.get_node("Remaining").text == "LOCK", "HUD distinguishes unmet requirements from cooldown")
	var other := WeaponData.new()
	check(other.meets_requirements(PlayerProgress.attributes), "another weapon evaluates requirements independently")
	other.free()
	PlayerProgress.attributes[&"strength"] = 6
	PlayerProgress.attributes[&"faith"] = 1
	player._on_progress_changed()
	check(player.can_use_weapon_skill() and not q.requirement_locked, "meeting threshold immediately unlocks own skill")
	player.saber_skill.allow_airborne = true
	check(player.saber_skill.begin(), "eligible Q retains normal entry")
	player.saber_skill.cancel()
	weapon.requirements.clear()
	PlayerProgress.attributes[&"dark_arts_assimilation"] = 10
	player.stats.fracture_level = 2
	check(player.scale_attack_damage(100) == int(round(100.0 * 1.272 * 0.8)), "Fracture combines with scaling exactly once")
	PlayerProgress.attributes[&"resistance"] = 100
	player._on_progress_changed()
	check(player.stats.fracture_level == 2 and player.stats.get_damage_dealt_multiplier() == 0.8, "Resistance never changes Fracture")
	player.stats.fracture_level = 0
	player.begin_sentinel()
	player.sentinel_state.tick(player.sentinel_entry_duration)
	check(player.scale_attack_damage(100) == int(round(100.0 * 1.272 * 1.03)), "active Sentinel adds assimilation once")
	var target := Target.new()
	scene.add_child(target)
	var expected: int = player.scale_attack_damage(100)
	player.saber_hitbox.play_attack_window(&"saber_attack_1", 100)
	player.saber_hitbox._on_hitbox_body_entered(target)
	player.saber_hitbox._on_hitbox_body_entered(target)
	check(target.current_health == 10000 - expected, "real Saber contact applies attribute/Sentinel scaling once and prevents duplicate hits")
	player.saber_hitbox.begin_skill_window(100)
	player.saber_hitbox._on_hitbox_body_entered(target)
	check(target.current_health == 10000 - expected * 2, "real Q hitbox uses the same damage scaling")
	player.saber_hitbox.stop_attack_window()
	player.jump_hitbox.begin_attack(100)
	player.jump_hitbox.set_damage_window(true)
	player.jump_hitbox._try_hit_body(target)
	player.jump_hitbox._try_hit_body(target)
	check(target.current_health == 10000 - expected * 3, "real jump hitbox scales once per target")
	player.jump_hitbox.end_attack()
	check(is_equal_approx(original_config.sentinel_upkeep(PlayerProgress.attributes), 0.95), "assimilation milestone reduces upkeep")
	PlayerProgress.attributes[&"dark_arts_assimilation"] = 1000
	check(is_equal_approx(original_config.sentinel_upkeep(PlayerProgress.attributes), 0.5), "Sentinel upkeep reduction respects cap")
	player.end_sentinel()
	var before_coin: int = PlayerProgress.coin
	var before_soul: int = PlayerProgress.soul
	var enemy = load("res://scenes/enemy/enemy_base.gd").new()
	enemy.coin_reward = 8
	enemy.soul_reward = 2
	enemy.exp_reward = 0
	enemy.die()
	enemy.die()
	check(PlayerProgress.coin == before_coin + 8 and PlayerProgress.soul == before_soul + 2, "enemy rewards once even with repeated death callbacks")
	await frames()
	menu.close()
	var character = load("res://scenes/UI/character_menu.tscn").instantiate()
	layer.add_child(character)
	check(character.get_node(character.WALLET + "coin/coin_value").text == str(PlayerProgress.coin) and character.get_node(character.STATS + "SubStatsGrid/vitality_value").text == "1", "Character reads real wallet and attributes")
	PlayerProgress.add_currency(1, 0)
	check(character.get_node(character.WALLET + "coin/coin_value").text == str(PlayerProgress.coin), "open Character updates on wallet changes")
	await capture("character")
	character.hide()
	var master = player.get_node("Camera2D/UI_Layer/master_menu")
	master._open_menu()
	await get_tree().create_timer(0.3, true, false, true).timeout
	check(master.visible and get_tree().paused, "actual Character menu retains pause/input ownership")
	await capture("character-menu")
	master.switch_tab(1)
	await get_tree().create_timer(0.3, true, false, true).timeout
	var equipment = master.get_node("Equipment_menu")
	check(equipment.get_node("WeaponDetails").text.contains("Saber") and equipment.get_node("WeaponDetails").text.contains("Left hand empty"), "Equipment shows current weapon requirements and scaling without inventing left equipment")
	await capture("equipment")
	master._close_menu()
	await get_tree().create_timer(0.3, true, false, true).timeout
	menu.open()
	get_window().mode = Window.MODE_WINDOWED
	get_window().content_scale_size = Vector2i(960, 540)
	get_window().size = Vector2i(960, 540)
	await frames(5)
	check(menu.panel.get_global_rect().size.x <= get_viewport().get_visible_rect().size.x and menu.panel.position.y >= 0, "upgrade panel fits small viewport")
	menu.body.get_node("Scroll").scroll_vertical = 1000
	await frames()
	menu._rows[&"faith"].plus.pressed.emit()
	check(menu._draft.get(&"faith", 0) == 1, "eighth attribute remains usable through the scroll panel")
	await capture("small")
	print("PROGRESSION RESULT checks=", checks, " failures=", failures)
	get_tree().quit(1 if failures else 0)
