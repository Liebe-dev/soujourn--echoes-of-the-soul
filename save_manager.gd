extends Node
## Autoload: bench / campfire save points (Hollow Knight & Silksong style).

const LEGACY_SAVE_PATH := "user://soujourn_save.json"
const SAVE_VERSION := 1
const MAX_SAVE_SLOTS := 5

signal save_written(slot: int)
signal checkpoint_changed(checkpoint_id: String)

var pending_continue: bool = false
var active_slot: int = 1

var _data: Dictionary = _default_data()

func _ready() -> void:
	var slot := get_first_occupied_slot()
	if slot > 0:
		load_from_slot(slot)

func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"scene_path": "",
		"checkpoint_id": "",
		"spawn_position": {"x": 0.0, "y": 0.0},
		"hp": 100,
		"max_hp": 100,
		"flask_charges": 3,
		"max_flask_charges": 3,
		"facing_left": false,
		"saved_at": "",
	}

func get_save_path(slot: int) -> String:
	if slot == 1:
		return LEGACY_SAVE_PATH
	return "user://soujourn_save_%d.json" % slot

func has_save_in_slot(slot: int) -> bool:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return false
	return FileAccess.file_exists(get_save_path(slot))

func has_save() -> bool:
	return get_first_occupied_slot() > 0

func get_first_occupied_slot() -> int:
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		if has_save_in_slot(slot):
			return slot
	return 0

func get_slot_info(slot: int) -> Dictionary:
	if not has_save_in_slot(slot):
		return {"empty": true, "slot": slot}
	var data := _read_slot_file(slot)
	return {
		"empty": false,
		"slot": slot,
		"checkpoint_id": str(data.get("checkpoint_id", "")),
		"scene_path": str(data.get("scene_path", "")),
		"hp": int(data.get("hp", 100)),
		"max_hp": int(data.get("max_hp", 100)),
		"saved_at": str(data.get("saved_at", "")),
	}

func get_checkpoint_id() -> String:
	return str(_data.get("checkpoint_id", ""))

func save_at_campfire(campfire: Node2D, slot: int = -1) -> bool:
	var tree := campfire.get_tree()
	if tree == null or tree.current_scene == null:
		return false

	var player := _find_player(tree)
	if player == null:
		push_warning("SaveManager: no player found to save.")
		return false

	var scene_path: String = tree.current_scene.scene_file_path
	if scene_path.is_empty():
		push_warning("SaveManager: current scene has no file path.")
		return false

	var hp_info := _read_player_hp(tree)
	var spawn_pos := player.global_position
	if player.has_method("snap_feet_to_floor"):
		player.snap_feet_to_floor()
		spawn_pos = player.global_position

	_data["version"] = SAVE_VERSION
	_data["scene_path"] = scene_path
	_data["checkpoint_id"] = campfire.get_checkpoint_id()
	_data["spawn_position"] = {"x": spawn_pos.x, "y": spawn_pos.y}
	_data["hp"] = hp_info.hp
	_data["max_hp"] = hp_info.max_hp
	var hud := _find_hud(tree)
	if hud != null:
		_data["flask_charges"] = hud.flask_charges
		_data["max_flask_charges"] = hud.max_flask_charges
	_data["facing_left"] = player.global_position.x > campfire.global_position.x
	_data["saved_at"] = Time.get_datetime_string_from_system()

	var target_slot := slot if slot >= 1 and slot <= MAX_SAVE_SLOTS else active_slot
	if not _write_slot_to_disk(target_slot):
		return false

	active_slot = target_slot
	save_written.emit(target_slot)
	checkpoint_changed.emit(_data["checkpoint_id"])
	return true

func load_from_slot(slot: int) -> bool:
	if not has_save_in_slot(slot):
		return false
	var parsed := _read_slot_file(slot)
	if parsed.is_empty():
		return false
	_data = parsed
	active_slot = slot
	return true

func continue_game(slot: int = -1) -> void:
	var target_slot := slot
	if target_slot < 1:
		target_slot = active_slot if has_save_in_slot(active_slot) else get_first_occupied_slot()
	if target_slot < 1 or not load_from_slot(target_slot):
		return
	var scene_path: String = _data.get("scene_path", "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("SaveManager: saved scene missing: %s" % scene_path)
		return
	pending_continue = true
	get_tree().change_scene_to_file(scene_path)

func load_game_from_slot(slot: int, keep_resting: bool = false) -> bool:
	if not load_from_slot(slot):
		return false
	var scene_path: String = _data.get("scene_path", "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("SaveManager: saved scene missing: %s" % scene_path)
		return false

	var tree := get_tree()
	var current_scene := tree.current_scene
	var current_path := current_scene.scene_file_path if current_scene else ""
	if current_path == scene_path:
		if keep_resting:
			apply_loaded_state_at_rest()
		else:
			pending_continue = true
			apply_continue_state()
		return true

	pending_continue = true
	tree.change_scene_to_file(scene_path)
	return true

func apply_loaded_state_at_rest() -> void:
	var player := _find_player(get_tree())
	if player == null:
		return

	var pos_dict: Dictionary = _data.get("spawn_position", {})
	player.global_position = Vector2(float(pos_dict.get("x", 0.0)), float(pos_dict.get("y", 0.0)))

	var anim: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if anim:
		var facing_left := bool(_data.get("facing_left", false))
		anim.flip_h = facing_left
		anim.scale.x = -1 if facing_left else 1
		anim.play("idle")

	if player.has_method("snap_feet_to_floor"):
		player.snap_feet_to_floor()

	_apply_hp_to_hud(get_tree(), int(_data.get("hp", 100)), int(_data.get("max_hp", 100)))

func apply_continue_state() -> void:
	if not pending_continue:
		return
	pending_continue = false

	var player := _find_player(get_tree())
	if player == null:
		return

	var pos_dict: Dictionary = _data.get("spawn_position", {})
	player.global_position = Vector2(float(pos_dict.get("x", 0.0)), float(pos_dict.get("y", 0.0)))

	var anim: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if anim:
		var facing_left := bool(_data.get("facing_left", false))
		anim.flip_h = facing_left
		anim.scale.x = -1 if facing_left else 1
		anim.play("idle")

	if player.has_method("exit_rest"):
		player.exit_rest()
	else:
		player.can_move = true

	if player.has_method("snap_feet_to_floor"):
		player.snap_feet_to_floor()

	_apply_hp_to_hud(get_tree(), int(_data.get("hp", 100)), int(_data.get("max_hp", 100)))

func respawn_at_checkpoint() -> void:
	if not has_save() or str(_data.get("scene_path", "")).is_empty():
		get_tree().change_scene_to_file("res://opening.tscn")
		return

	var scene_path: String = _data["scene_path"]
	if get_tree().current_scene.scene_file_path != scene_path:
		pending_continue = true
		_data["hp"] = _data.get("max_hp", 100)
		_write_slot_to_disk(active_slot)
		get_tree().change_scene_to_file(scene_path)
		return

	var player := _find_player(get_tree())
	if player:
		var pos_dict: Dictionary = _data.get("spawn_position", {})
		player.global_position = Vector2(float(pos_dict.get("x", 0.0)), float(pos_dict.get("y", 0.0)))
		if player.has_method("exit_rest"):
			player.exit_rest()
		if player.has_method("snap_feet_to_floor"):
			player.snap_feet_to_floor()

	heal_player_full(get_tree())
	_apply_hp_to_hud(get_tree(), int(_data.get("max_hp", 100)), int(_data.get("max_hp", 100)))

func heal_player_full(tree: SceneTree = null) -> void:
	var t := tree if tree else get_tree()
	var hud := _find_hud(t)
	if hud and hud.has_method("heal_to_full"):
		hud.heal_to_full()

func delete_save() -> void:
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		delete_save_slot(slot)
	_data = _default_data()
	active_slot = 1

func delete_save_slot(slot: int) -> void:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return
	var path := get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if active_slot == slot:
		_data = _default_data()

func _write_slot_to_disk(slot: int) -> bool:
	var path := get_save_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not write save slot %d." % slot)
		return false
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()
	return true

func _read_slot_file(slot: int) -> Dictionary:
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

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
	var hud := _find_hud(tree)
	if hud:
		return {"hp": hud.hp, "max_hp": hud.max_hp}
	return {"hp": int(_data.get("hp", 100)), "max_hp": int(_data.get("max_hp", 100))}

func _apply_hp_to_hud(tree: SceneTree, hp: int, max_hp: int) -> void:
	var hud := _find_hud(tree)
	if hud == null:
		return
	hud.max_hp = max_hp
	hud.hp = clampi(hp, 0, max_hp)
	if "max_flask_charges" in hud:
		hud.max_flask_charges = int(_data.get("max_flask_charges", hud.max_flask_charges))
	if "flask_charges" in hud:
		hud.flask_charges = clampi(
			int(_data.get("flask_charges", hud.max_flask_charges)),
			0,
			hud.max_flask_charges
		)
	if hud.has_method("_recalc_flask_heal_amount"):
		hud._recalc_flask_heal_amount()
	if "stamina" in hud and "max_stamina" in hud:
		hud.stamina = hud.max_stamina
	if hud.has_method("sync_hp_display"):
		hud.sync_hp_display()
	if hud.has_method("sync_flask_display"):
		hud.sync_flask_display()
	elif hud.has_method("sync_soul_display"):
		hud.sync_soul_display()
	if hud.has_method("clear_all_debuffs"):
		hud.clear_all_debuffs()
	if hud.has_method("sync_status_icons"):
		hud.sync_status_icons()
	if hud.has_method("sync_stamina_display"):
		hud.sync_stamina_display()
