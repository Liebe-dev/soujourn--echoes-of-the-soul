extends Node
## Checkpoint saves. Slot 1 retains the legacy filename for compatibility.

const TITLE_SCENE := "res://scenes/UI/menu (2).tscn"
const NEW_GAME_SCENE := "res://scenes/Map 1/map_1_scene_2.tscn"
const LEGACY_SAVE_PATH := "user://soujourn_save.json"
const SAVE_VERSION := 1
const MAX_SAVE_SLOTS := 5

signal save_written(slot: int)
signal checkpoint_changed(checkpoint_id: String)

var pending_continue := false
var active_slot := 1
var last_error := ""
var _changing_scene := false
var _session_selected := false
var _data: Dictionary = _default_data()

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	var slot := get_first_loadable_slot()
	if slot > 0:
		load_from_slot(slot)
	else:
		PlayerProgress.read_from_save_data(_default_data())
	# A directly launched editor scene has not selected ownership of any disk slot.
	_session_selected = false

func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION, "scene_path": "", "checkpoint_id": "",
		"spawn_position": {"x": 0.0, "y": 0.0}, "hp": 100, "max_hp": 100,
		"flask_charges": 3, "max_flask_charges": 3, "facing_left": false,
		"saved_at": "", "level": 1, "exp": 0, "upgrade_points": 0,
		"hp_upgrades": 0, "stamina_upgrades": 0, "max_stamina": 100.0,
	}

func get_save_path(slot: int) -> String:
	return LEGACY_SAVE_PATH if slot == 1 else "user://soujourn_save_%d.json" % slot

func _valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= MAX_SAVE_SLOTS

func has_save_in_slot(slot: int) -> bool:
	return _valid_slot(slot) and (FileAccess.file_exists(get_save_path(slot)) or FileAccess.file_exists(get_save_path(slot) + ".bak"))

func has_save() -> bool:
	return get_first_loadable_slot() > 0

func get_first_occupied_slot() -> int:
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		if has_save_in_slot(slot): return slot
	return 0

func get_first_loadable_slot() -> int:
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		if not _read_slot_file(slot).is_empty(): return slot
	return 0

func get_slot_info(slot: int) -> Dictionary:
	if not has_save_in_slot(slot):
		return {"empty": true, "slot": slot, "loadable": false}
	var data := _read_slot_file(slot)
	if data.is_empty():
		return {"empty": false, "slot": slot, "loadable": false, "error": "Invalid save or missing scene"}
	return {
		"empty": false, "slot": slot, "loadable": true,
		"recovered": _read_valid_file(get_save_path(slot)).is_empty(),
		"checkpoint_id": data.checkpoint_id, "scene_path": data.scene_path,
		"hp": int(data.hp), "max_hp": int(data.max_hp), "saved_at": data.saved_at,
	}

func needs_save_confirmation(slot: int) -> bool:
	return has_save_in_slot(slot) and (slot != active_slot or not _session_selected)

func get_checkpoint_id() -> String:
	return str(_data.get("checkpoint_id", ""))

func start_new_game(slot: int, allow_overwrite: bool = false) -> bool:
	last_error = ""
	if _changing_scene or not _valid_slot(slot): return _fail("Cannot start this slot.")
	if has_save_in_slot(slot) and not allow_overwrite:
		return _fail("Confirm replacement of slot %d first." % slot)
	var packed := _load_scene(NEW_GAME_SCENE)
	if packed == null: return false
	var scene := packed.instantiate()
	var spawn := scene.get_node_or_null("SpawnPoint_Default") as Node2D
	if spawn == null:
		scene.free()
		return _fail("New game scene needs SpawnPoint_Default.")
	var data := _default_data()
	data.scene_path = NEW_GAME_SCENE
	data.checkpoint_id = "start"
	data.spawn_position = {"x": spawn.global_position.x, "y": spawn.global_position.y}
	data.saved_at = Time.get_datetime_string_from_system()
	var path := get_save_path(slot)
	var had_primary := FileAccess.file_exists(path)
	var previous_bytes := FileAccess.get_file_as_bytes(path) if had_primary else PackedByteArray()
	# Archive an explicitly replaced slot independently of the rotating backup.
	if has_save_in_slot(slot):
		var source := path if had_primary else path + ".bak"
		var archive := path + ".before-new-game-%d-%d.bak" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
		if DirAccess.copy_absolute(source, archive) != OK:
			scene.free()
			return _fail("Could not back up slot %d; replacement cancelled." % slot)
	if not _write_slot_to_disk(slot, data):
		scene.free()
		return false
	var previous_data := _data
	var previous_slot := active_slot
	var previous_selected := _session_selected
	_activate(data, slot)
	pending_continue = true
	_changing_scene = true
	get_tree().paused = false
	var error := get_tree().change_scene_to_node(scene)
	if error != OK:
		scene.free()
		_changing_scene = false
		pending_continue = false
		_activate(previous_data, previous_slot)
		_session_selected = previous_selected
		if had_primary:
			_replace_slot_bytes(slot, previous_bytes, false)
		else:
			DirAccess.remove_absolute(path)
		return _fail("Could not enter the new game. Previous save retained in backup.")
	save_written.emit(slot)
	return true

func return_to_title() -> bool:
	last_error = ""
	if _changing_scene: return false
	var packed := _load_scene(TITLE_SCENE)
	if packed == null: return false
	var was_paused := get_tree().paused
	get_tree().paused = false
	_changing_scene = true
	var error := get_tree().change_scene_to_packed(packed)
	if error != OK:
		_changing_scene = false
		get_tree().paused = was_paused
		return _fail("Could not open the title screen.")
	pending_continue = false
	CursorPolicy.set_visible(get_viewport(), true, true)
	return true

func restart_current_area() -> bool:
	last_error = ""
	if _changing_scene or get_tree().current_scene == null: return false
	var was_paused := get_tree().paused
	var was_pending := pending_continue
	pending_continue = _session_selected and get_tree().current_scene.scene_file_path == str(_data.get("scene_path", ""))
	_changing_scene = true
	get_tree().paused = false
	if get_tree().reload_current_scene() != OK:
		_changing_scene = false
		pending_continue = was_pending
		get_tree().paused = was_paused
		return _fail("Could not reload this area.")
	return true

func _on_scene_changed() -> void:
	_changing_scene = false
	if pending_continue:
		apply_continue_state.call_deferred()

func _activate(data: Dictionary, slot: int) -> void:
	_data = data
	active_slot = slot
	_session_selected = true
	PlayerProgress.read_from_save_data(data)

func _fail(message: String) -> bool:
	last_error = message
	return false

func _load_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path, "PackedScene"):
		_fail("Scene is unavailable: " + path)
		return null
	var packed := load(path) as PackedScene
	if packed == null: _fail("Could not load scene: " + path)
	return packed

func save_at_campfire(campfire: Node2D, slot: int = -1, allow_overwrite: bool = false) -> bool:
	last_error = ""
	var tree := campfire.get_tree()
	if tree == null or tree.current_scene == null: return _fail("No active game to save.")
	var player := _find_player(tree)
	if player == null: return _fail("No player found to save.")
	var scene_path: String = tree.current_scene.scene_file_path
	if scene_path.is_empty(): return _fail("Current scene has no file path.")
	var target_slot := active_slot if slot == -1 else slot
	if not _valid_slot(target_slot): return _fail("Invalid save slot.")
	if needs_save_confirmation(target_slot) and not allow_overwrite:
		return _fail("Confirm replacement of slot %d first." % target_slot)
	var data := _data.duplicate(true)
	var hp_info := _read_player_hp(tree)
	if player.has_method("snap_feet_to_floor"): player.snap_feet_to_floor()
	data["version"] = SAVE_VERSION
	data["scene_path"] = scene_path
	data["checkpoint_id"] = campfire.get_checkpoint_id()
	data["spawn_position"] = {"x": player.global_position.x, "y": player.global_position.y}
	data["hp"] = hp_info.hp
	data["max_hp"] = hp_info.max_hp
	var stats = _find_stats(tree)
	if stats != null:
		data["flask_charges"] = stats.flask_charges
		data["max_flask_charges"] = stats.max_flask_charges
	data["facing_left"] = player.global_position.x > campfire.global_position.x
	data["saved_at"] = Time.get_datetime_string_from_system()
	PlayerProgress.write_to_save_data(data)
	if not _write_slot_to_disk(target_slot, data): return false
	_data = data
	active_slot = target_slot
	_session_selected = true
	save_written.emit(target_slot)
	checkpoint_changed.emit(data.checkpoint_id)
	return true

func load_from_slot(slot: int) -> bool:
	last_error = ""
	var data := _read_slot_file(slot)
	if data.is_empty(): return _fail("Slot %d is empty, invalid, or its scene is unavailable." % slot)
	_activate(data, slot)
	return true

func continue_game(slot: int = -1) -> bool:
	var target_slot := slot
	if target_slot == -1:
		target_slot = active_slot if not _read_slot_file(active_slot).is_empty() else get_first_loadable_slot()
	return load_game_from_slot(target_slot)

func load_game_from_slot(slot: int, keep_resting: bool = false) -> bool:
	last_error = ""
	if _changing_scene: return _fail("A scene transition is already running.")
	var data := _read_slot_file(slot)
	if data.is_empty(): return _fail("Slot %d is empty, invalid, or its scene is unavailable." % slot)
	var packed := _load_scene(str(data.scene_path))
	if packed == null: return false
	var previous_data := _data
	var previous_slot := active_slot
	_activate(data, slot)
	var current := get_tree().current_scene
	if current != null and current.scene_file_path == str(data.scene_path):
		if keep_resting:
			apply_loaded_state_at_rest()
		else:
			pending_continue = true
			apply_continue_state()
		return true
	pending_continue = true
	_changing_scene = true
	var was_paused := get_tree().paused
	get_tree().paused = false
	if get_tree().change_scene_to_packed(packed) != OK:
		_changing_scene = false
		pending_continue = false
		get_tree().paused = was_paused
		_activate(previous_data, previous_slot)
		return _fail("Could not enter the saved scene.")
	return true

func apply_loaded_state_at_rest() -> void:
	_restore_player(true)

func apply_continue_state() -> void:
	if not pending_continue: return
	if _restore_player(false): pending_continue = false

func _restore_player(keep_resting: bool) -> bool:
	if get_tree().current_scene == null: return false
	var player := _find_player(get_tree())
	if player == null: return false
	var pos: Dictionary = _data.get("spawn_position", {})
	var saved_position := Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
	var face_left := bool(_data.get("facing_left", false))
	if player.has_method("restore_checkpoint_state"):
		player.restore_checkpoint_state(saved_position, face_left, keep_resting)
	else:
		# Legacy actors can move in exit_rest(); apply position afterwards.
		if not keep_resting and player.has_method("exit_rest"): player.exit_rest()
		player.global_position = saved_position
		player.velocity = Vector2.ZERO
		var anim := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if anim:
			anim.flip_h = face_left
			anim.scale.x = -1 if face_left else 1
			anim.play("idle")
		if player.has_method("snap_feet_to_floor"): player.snap_feet_to_floor()
	PlayerProgress.apply_to_hud(get_tree())
	_apply_hp_to_hud(get_tree(), int(_data.get("hp", 100)), int(_data.get("max_hp", 100)))
	return true

func respawn_at_checkpoint() -> void:
	var current := get_tree().current_scene
	if current == null: return
	var saved_path := str(_data.get("scene_path", ""))
	if saved_path.is_empty() or not ResourceLoader.exists(saved_path, "PackedScene"):
		get_tree().reload_current_scene()
		return
	if current.scene_file_path != saved_path:
		var packed := _load_scene(saved_path)
		if packed == null: return
		_data = _data.duplicate(true)
		_data["hp"] = _data.get("max_hp", 100)
		pending_continue = true
		_changing_scene = true
		if get_tree().change_scene_to_packed(packed) != OK:
			pending_continue = false
			_changing_scene = false
		return
	_restore_player(false)
	heal_player_full(get_tree())
	_apply_hp_to_hud(get_tree(), int(_data.get("max_hp", 100)), int(_data.get("max_hp", 100)))

func heal_player_full(tree: SceneTree = null) -> void:
	var target := get_tree() if tree == null else tree
	var player := _find_player(target)
	if player != null and player.has_method("get_player_vitals"):
		player.get_player_vitals().heal_to_full()
	else:
		var hud := _find_hud(target)
		if hud and hud.has_method("heal_to_full"): hud.heal_to_full()

func delete_save() -> void:
	# Explicit legacy API only; New Game never calls this.
	for slot in range(1, MAX_SAVE_SLOTS + 1): delete_save_slot(slot)
	_data = _default_data()
	active_slot = 1

func delete_save_slot(slot: int) -> void:
	if not _valid_slot(slot): return
	for suffix in ["", ".bak"]:
		var path: String = get_save_path(slot) + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	if active_slot == slot: _data = _default_data()

func sync_progress_to_active_slot() -> bool:
	if needs_save_confirmation(active_slot): return _fail("Select a save slot before writing progression.")
	var data := _data.duplicate(true)
	PlayerProgress.write_to_save_data(data)
	if not _write_slot_to_disk(active_slot, data): return false
	_data = data
	return true

func _write_slot_to_disk(slot: int, candidate: Dictionary = {}) -> bool:
	var data := _data if candidate.is_empty() else candidate
	if not _valid_slot(slot): return _fail("Invalid save slot.")
	return _replace_slot_bytes(slot, JSON.stringify(data, "\t").to_utf8_buffer(), true)

func _replace_slot_bytes(slot: int, bytes: PackedByteArray, make_backup: bool) -> bool:
	var path := get_save_path(slot)
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return _fail("Could not write slot %d; previous save retained." % slot)
	file.store_buffer(bytes)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or FileAccess.get_file_as_bytes(temp) != bytes:
		DirAccess.remove_absolute(temp)
		return _fail("Could not finish writing slot %d; previous save retained." % slot)
	# Never replace a good backup with corrupt primary data.
	if make_backup and not _read_valid_file(path).is_empty():
		var backup_temp := path + ".bak.tmp"
		if DirAccess.copy_absolute(path, backup_temp) != OK or DirAccess.rename_absolute(backup_temp, path + ".bak") != OK:
			DirAccess.remove_absolute(temp)
			return _fail("Could not back up slot %d; save cancelled." % slot)
	if DirAccess.rename_absolute(temp, path) != OK:
		DirAccess.remove_absolute(temp)
		return _fail("Could not replace slot %d; previous save retained." % slot)
	return true

func _read_slot_file(slot: int) -> Dictionary:
	if not _valid_slot(slot): return {}
	var path := get_save_path(slot)
	var data := _read_valid_file(path)
	return _read_valid_file(path + ".bak") if data.is_empty() else data

func _read_valid_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK: return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or not _valid_data(parsed): return {}
	var data := _default_data()
	data.merge(parsed, true)
	return data

func _valid_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _valid_data(data: Dictionary) -> bool:
	var version: Variant = data.get("version", SAVE_VERSION)
	if not _valid_number(version) or float(version) != SAVE_VERSION: return false
	var scene: Variant = data.get("scene_path", "")
	if not scene is String or not scene.begins_with("res://") or not ResourceLoader.exists(scene, "PackedScene"): return false
	var pos: Variant = data.get("spawn_position")
	if not pos is Dictionary or not _valid_number(pos.get("x")) or not _valid_number(pos.get("y")): return false
	for key in ["hp", "max_hp", "flask_charges", "max_flask_charges", "level", "exp", "upgrade_points", "hp_upgrades", "stamina_upgrades"]:
		if data.has(key):
			var value: Variant = data[key]
			if not _valid_number(value) or float(value) < 0 or floorf(float(value)) != float(value): return false
	if float(data.get("max_hp", 100)) < 1 or float(data.get("level", 1)) < 1: return false
	if data.has("max_stamina") and (not _valid_number(data.max_stamina) or float(data.max_stamina) < 0): return false
	if data.has("facing_left") and not data.facing_left is bool: return false
	for key in ["checkpoint_id", "saved_at"]:
		if data.has(key) and not data[key] is String: return false
	return true

func _find_player(tree: SceneTree) -> CharacterBody2D:
	var nodes := tree.get_nodes_in_group("Player")
	if nodes.is_empty():
		return null
	return nodes[0] as CharacterBody2D

func _find_hud(tree: SceneTree) -> Node:
	var root := tree.current_scene
	if root == null:
		return null
	var hud_layer := root.find_child("hud", true, false)
	return hud_layer

func _read_player_hp(tree: SceneTree) -> Dictionary:
	var stats = _find_stats(tree)
	if stats != null: return {"hp": stats.hp, "max_hp": stats.max_hp}
	return {"hp": int(_data.get("hp", 100)), "max_hp": int(_data.get("max_hp", 100))}

func _find_stats(tree: SceneTree):
	var player := _find_player(tree)
	if player != null and player.has_method("get_player_vitals"): return player.get_player_vitals().model
	var hud := _find_hud(tree)
	return hud._stats if hud != null and "_stats" in hud else null

func _apply_hp_to_hud(tree: SceneTree, hp: int, max_hp: int) -> void:
	# Historical name retained for callers; restores the model without requiring a HUD.
	var stats = _find_stats(tree)
	if stats == null: return
	stats.max_hp = maxi(max_hp, PlayerProgress.get_max_hp())
	stats.hp = clampi(hp, 0, stats.max_hp)
	stats.max_flask_charges = maxi(1, int(_data.get("max_flask_charges", stats.max_flask_charges)))
	stats.flask_charges = clampi(int(_data.get("flask_charges", stats.max_flask_charges)), 0, stats.max_flask_charges)
	stats.recalc_flask_heal_amount()
	stats.max_stamina = PlayerProgress.get_max_stamina()
	stats.stamina = stats.max_stamina
	stats.clear_all_debuffs()
	var player := _find_player(tree)
	if player != null and player.has_method("get_player_vitals"): player.get_player_vitals().refresh()
	else:
		var hud := _find_hud(tree)
		if hud != null:
			for method in [&"sync_hp_display", &"sync_flask_display", &"sync_status_icons", &"sync_stamina_display"]:
				if hud.has_method(method): hud.call(method)
