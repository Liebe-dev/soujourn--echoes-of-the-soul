extends Node
## Autoload: bench / campfire save points (Hollow Knight & Silksong style).

const SAVE_PATH := "user://soujourn_save.json"
const SAVE_VERSION := 1

signal save_written
signal checkpoint_changed(checkpoint_id: String)

var pending_continue: bool = false

var _data: Dictionary = {
	"version": SAVE_VERSION,
	"scene_path": "",
	"checkpoint_id": "",
	"spawn_position": {"x": 0.0, "y": 0.0},
	"hp": 100,
	"max_hp": 100,
	"facing_left": false,
}

func _ready() -> void:
	if has_save():
		_load_from_disk()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_checkpoint_id() -> String:
	return str(_data.get("checkpoint_id", ""))

func save_at_campfire(campfire: Node2D) -> bool:
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
	_data["facing_left"] = player.global_position.x > campfire.global_position.x

	if not _write_to_disk():
		return false

	save_written.emit()
	checkpoint_changed.emit(_data["checkpoint_id"])
	return true

func continue_game() -> void:
	if not has_save():
		return
	if not _load_from_disk():
		return
	var scene_path: String = _data.get("scene_path", "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("SaveManager: saved scene missing: %s" % scene_path)
		return
	pending_continue = true
	get_tree().change_scene_to_file(scene_path)

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
		anim.flip_h = bool(_data.get("facing_left", false))
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
		_write_to_disk()
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
	_data = {
		"version": SAVE_VERSION,
		"scene_path": "",
		"checkpoint_id": "",
		"spawn_position": {"x": 0.0, "y": 0.0},
		"hp": 100,
		"max_hp": 100,
		"facing_left": false,
	}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func _write_to_disk() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not write save.")
		return false
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()
	return true

func _load_from_disk() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	_data = parsed
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
	if hud.has_method("sync_hp_display"):
		hud.sync_hp_display()
