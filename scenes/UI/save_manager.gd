extends Node
## Checkpoint saves. Slot 1 retains the legacy filename for compatibility.

const TITLE_SCENE := "res://scenes/UI/title_screen.tscn"
const NEW_GAME_SCENE := "res://scenes/Map 1/map_1_scene_2.tscn"
const SlotStore = preload("res://scenes/Mechanic/save_slot_store.gd")
const LEGACY_SAVE_PATH := SlotStore.LEGACY_SAVE_PATH
const SAVE_VERSION := SlotStore.SAVE_VERSION
const MAX_SAVE_SLOTS := SlotStore.MAX_SAVE_SLOTS

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
	return SlotStore.default_data()

func get_save_path(slot: int) -> String:
	return SlotStore.slot_path(slot)

func has_save_in_slot(slot: int) -> bool:
	return SlotStore.has_slot(slot)

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
	return SlotStore.get_slot_info(slot, PlayerProgress.config)

func needs_save_confirmation(slot: int) -> bool:
	return has_save_in_slot(slot) and (slot != active_slot or not _session_selected)

func get_checkpoint_id() -> String:
	return str(_data.get("checkpoint_id", ""))

func start_new_game(slot: int, allow_overwrite: bool = false) -> bool:
	last_error = ""
	if _changing_scene or not SlotStore.is_valid_slot(slot): return _fail("Cannot start this slot.")
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
	var disk_change := SlotStore.write_new_game(slot, data, PlayerProgress.config)
	if not disk_change.error.is_empty():
		scene.free()
		return _fail(disk_change.error)
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
		SlotStore.rollback_new_game(slot, disk_change)
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
	if not SlotStore.is_valid_slot(target_slot): return _fail("Invalid save slot.")
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
	if not SlotStore.is_valid_slot(slot): return
	SlotStore.delete_slot(slot)
	if active_slot == slot: _data = _default_data()

func sync_progress_to_active_slot() -> bool:
	if needs_save_confirmation(active_slot): return _fail("Select a save slot before writing progression.")
	var data := _data.duplicate(true)
	PlayerProgress.write_to_save_data(data)
	if not _write_slot_to_disk(active_slot, data): return false
	_data = data
	return true

func commit_attribute_allocation(allocation: Dictionary) -> bool:
	last_error = ""
	if _changing_scene or needs_save_confirmation(active_slot):
		return _fail("Rest at a campfire and select a save slot before upgrading.")
	var candidate: Dictionary = PlayerProgress.allocation_candidate(allocation)
	if candidate.is_empty(): return _fail("Allocation is invalid or no longer affordable.")
	var data := _data.duplicate(true)
	PlayerProgress.write_to_save_data(data)
	data.merge(candidate, true)
	data.max_hp = PlayerProgress.config.max_hp(data.attributes)
	data.max_stamina = PlayerProgress.config.max_stamina(data.attributes)
	# Keep the checkpoint HP; spending points must not save a new location or heal.
	data.hp = mini(int(data.get("hp", data.max_hp)), int(data.max_hp))
	if not _write_slot_to_disk(active_slot, data): return false
	_data = data
	PlayerProgress.read_from_save_data(data)
	PlayerProgress.apply_to_hud()
	PlayerProgress.stats_upgraded.emit()
	save_written.emit(active_slot)
	return true

func _write_slot_to_disk(slot: int, candidate: Dictionary = {}) -> bool:
	var data := _data if candidate.is_empty() else candidate
	var error := SlotStore.write_slot(slot, data, PlayerProgress.config)
	return true if error.is_empty() else _fail(error)

func _read_slot_file(slot: int) -> Dictionary:
	return SlotStore.read_slot(slot, PlayerProgress.config)

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

func _apply_hp_to_hud(tree: SceneTree, hp: int, _max_hp: int) -> void:
	# Historical name retained for callers; restores the model without requiring a HUD.
	var stats = _find_stats(tree)
	if stats == null: return
	stats.max_hp = PlayerProgress.get_max_hp()
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
