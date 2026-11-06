extends RefCounted
## Slot files, schema migration and backups. The caller owns scene transitions and active session state.

const LEGACY_SAVE_PATH := "user://soujourn_save.json"
const SAVE_VERSION := 2
const MAX_SAVE_SLOTS := 5
const DefaultConfig = preload("res://scenes/Mechanic/progression_config.tres")

static func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION, "scene_path": "", "checkpoint_id": "",
		"spawn_position": {"x": 0.0, "y": 0.0}, "hp": DefaultConfig.base_hp, "max_hp": DefaultConfig.base_hp,
		"flask_charges": 3, "max_flask_charges": 3, "facing_left": false,
		"saved_at": "", "level": 1, "exp": 0, "upgrade_points": 0,
		"attributes": DefaultConfig.empty_attributes(), "coin": 0, "soul": 0,
		"max_stamina": DefaultConfig.base_stamina,
	}

static func slot_path(slot: int) -> String:
	return LEGACY_SAVE_PATH if slot == 1 else "user://soujourn_save_%d.json" % slot

static func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= MAX_SAVE_SLOTS

static func has_slot(slot: int) -> bool:
	return is_valid_slot(slot) and (FileAccess.file_exists(slot_path(slot)) or FileAccess.file_exists(slot_path(slot) + ".bak"))

static func get_slot_info(slot: int, config: ProgressionConfig) -> Dictionary:
	if not has_slot(slot):
		return {"empty": true, "slot": slot, "loadable": false}
	var path := slot_path(slot)
	var data := _read_valid_file(path, config)
	var recovered := data.is_empty()
	if recovered:
		data = _read_valid_file(path + ".bak", config)
	if data.is_empty():
		return {"empty": false, "slot": slot, "loadable": false, "error": "Invalid save or missing scene"}
	return {
		"empty": false, "slot": slot, "loadable": true, "recovered": recovered,
		"checkpoint_id": data.checkpoint_id, "scene_path": data.scene_path,
		"hp": int(data.hp), "max_hp": int(data.max_hp), "saved_at": data.saved_at,
	}

static func write_slot(slot: int, data: Dictionary, config: ProgressionConfig) -> String:
	if not is_valid_slot(slot): return "Invalid save slot."
	return _replace_slot_bytes(slot, JSON.stringify(data, "\t").to_utf8_buffer(), config)

static func write_new_game(slot: int, data: Dictionary, config: ProgressionConfig) -> Dictionary:
	if not is_valid_slot(slot): return {"error": "Invalid save slot."}
	var path := slot_path(slot)
	var had_primary := FileAccess.file_exists(path)
	var previous_bytes := FileAccess.get_file_as_bytes(path) if had_primary else PackedByteArray()
	# An explicitly replaced slot keeps a permanent archive in addition to its rotating backup.
	if has_slot(slot):
		var source := path if had_primary else path + ".bak"
		var archive := path + ".before-new-game-%d-%d.bak" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
		if DirAccess.copy_absolute(source, archive) != OK:
			return {"error": "Could not back up slot %d; replacement cancelled." % slot}
	return {"error": write_slot(slot, data, config), "had_primary": had_primary, "previous_bytes": previous_bytes}

static func rollback_new_game(slot: int, previous: Dictionary) -> void:
	if previous.had_primary:
		_replace_slot_bytes(slot, previous.previous_bytes)
	else:
		DirAccess.remove_absolute(slot_path(slot))

static func delete_slot(slot: int) -> void:
	if not is_valid_slot(slot): return
	for suffix in ["", ".bak"]:
		var path: String = slot_path(slot) + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

static func _replace_slot_bytes(slot: int, bytes: PackedByteArray, backup_config: ProgressionConfig = null) -> String:
	var path := slot_path(slot)
	var temp := path + ".tmp"
	# A permanent migration archive survives later rotating checkpoint backups.
	if backup_config != null:
		var legacy_path := path
		if _read_valid_file(legacy_path, backup_config).is_empty(): legacy_path += ".bak"
		if FileAccess.file_exists(legacy_path):
			var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(legacy_path))
			var archive := path + ".before-stats-v2.bak"
			if raw is Dictionary and int(raw.get("version", 1)) == 1 and not FileAccess.file_exists(archive):
				if DirAccess.copy_absolute(legacy_path, archive) != OK:
					return "Could not archive the old progression save; save cancelled."
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return "Could not write slot %d; previous save retained." % slot
	file.store_buffer(bytes)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or FileAccess.get_file_as_bytes(temp) != bytes:
		DirAccess.remove_absolute(temp)
		return "Could not finish writing slot %d; previous save retained." % slot
	# Never replace a good backup with corrupt primary data.
	if backup_config != null and not _read_valid_file(path, backup_config).is_empty():
		var backup_temp := path + ".bak.tmp"
		if DirAccess.copy_absolute(path, backup_temp) != OK or DirAccess.rename_absolute(backup_temp, path + ".bak") != OK:
			DirAccess.remove_absolute(temp)
			return "Could not back up slot %d; save cancelled." % slot
	if DirAccess.rename_absolute(temp, path) != OK:
		DirAccess.remove_absolute(temp)
		return "Could not replace slot %d; previous save retained." % slot
	return ""

static func read_slot(slot: int, config: ProgressionConfig) -> Dictionary:
	if not is_valid_slot(slot): return {}
	var path := slot_path(slot)
	var data := _read_valid_file(path, config)
	return _read_valid_file(path + ".bak", config) if data.is_empty() else data

static func _read_valid_file(path: String, config: ProgressionConfig) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK: return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or not is_valid_data(parsed): return {}
	var migrated := _migrate_data(parsed, config)
	if not is_valid_data(migrated): return {}
	var data := default_data()
	data.merge(migrated, true)
	data.max_hp = config.max_hp(data.attributes)
	data.max_stamina = config.max_stamina(data.attributes)
	data.hp = mini(int(data.hp), int(data.max_hp))
	return data

static func _migrate_data(parsed: Dictionary, config: ProgressionConfig) -> Dictionary:
	var data := parsed.duplicate(true)
	if int(data.get("version", 1)) == 1:
		var levels := maxi(int(data.get("level", 1)) - 1, 0)
		# Version 1 awarded one point/level. Preserve all extra/debug points too.
		var refund := int(data.get("hp_upgrades", 0)) + int(data.get("stamina_upgrades", 0))
		var compensation := maxi(config.points_per_level - 1, 0) * levels
		data.upgrade_points = int(data.get("upgrade_points", 0)) + refund + compensation
		data.attributes = config.empty_attributes()
		data.coin = 0
		data.soul = 0
		data.migration_message = "Legacy HP/stamina upgrades refunded; level points adjusted. Reallocate at a campfire. Current HP is clamped to the new maximum."
		data.version = SAVE_VERSION
		data.erase("hp_upgrades")
		data.erase("stamina_upgrades")
	return data

static func _valid_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func is_valid_data(data: Dictionary) -> bool:
	var version: Variant = data.get("version", 1)
	if not _valid_number(version) or float(version) not in [1.0, 2.0]: return false
	var scene: Variant = data.get("scene_path", "")
	if not scene is String or not scene.begins_with("res://") or not ResourceLoader.exists(scene, "PackedScene"): return false
	var pos: Variant = data.get("spawn_position")
	if not pos is Dictionary or not _valid_number(pos.get("x")) or not _valid_number(pos.get("y")): return false
	for key in ["hp", "max_hp", "flask_charges", "max_flask_charges", "level", "exp", "upgrade_points", "hp_upgrades", "stamina_upgrades"]:
		if data.has(key):
			var value: Variant = data[key]
			if not _valid_count(value): return false
	if float(data.get("max_hp", 100)) < 1 or float(data.get("level", 1)) < 1: return false
	if data.has("max_stamina") and (not _valid_number(data.max_stamina) or float(data.max_stamina) < 0): return false
	if data.has("facing_left") and not data.facing_left is bool: return false
	for key in ["checkpoint_id", "saved_at"]:
		if data.has(key) and not data[key] is String: return false
	if int(version) == 2:
		var attributes: Variant = data.get("attributes")
		if not attributes is Dictionary or attributes.size() != ProgressionConfig.ATTRIBUTES.size(): return false
		for id in ProgressionConfig.ATTRIBUTES:
			if not _valid_count(attributes.get(id)): return false
		for key in ["coin", "soul", "upgrade_points"]:
			if not _valid_count(data.get(key)): return false
		if data.has("migration_message") and not data.migration_message is String: return false
	else:
		# Reject mixed/custom schemas rather than silently discard their data.
		for key in ["attributes", "coin", "soul", "points_per_level"]:
			if data.has(key): return false
	return true

static func _valid_count(value: Variant) -> bool:
	return _valid_number(value) and float(value) >= 0.0 and floorf(float(value)) == float(value) and float(value) <= 9007199254740991.0
