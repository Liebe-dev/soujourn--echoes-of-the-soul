extends Control

var _is_transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func _ui_actor() -> Node:
	var node := get_parent()
	while node != null:
		if node.has_method("is_campfire_ui_active"): return node
		node = node.get_parent()
	return null

func _campfire_blocks_menu() -> bool:
	var actor := _ui_actor()
	return actor != null and actor.is_campfire_ui_active()

func _refresh_cursor() -> void:
	var actor := _ui_actor()
	if actor != null:
		actor.refresh_gameplay_cursor()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN)

func pause_and_unpause() -> void:
	if _is_transitioning or _campfire_blocks_menu(): return
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	_refresh_cursor()
	if visible:
		move_to_front()
		$VBoxContainer/resume.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if _campfire_blocks_menu(): return
	if not event.is_action_pressed("ui_cancel") or event.is_echo(): return
	var root := get_tree().current_scene
	for node_name in ["master_menu", "CampfireUpgradeMenu"]:
		var other := root.find_child(node_name, true, false) as Control if root != null else null
		if other != null and other.visible: return
	pause_and_unpause()
	var sound := get_node_or_null("zw") as AudioStreamPlayer
	if sound != null and sound.stream != null: sound.play()
	get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	if visible: pause_and_unpause()

func _on_restart_pressed() -> void:
	if _is_transitioning: return
	_is_transitioning = true
	if not SaveManager.restart_current_area():
		_is_transitioning = false
		push_warning(SaveManager.last_error)

func _on_quit_pressed() -> void:
	if _is_transitioning: return
	_is_transitioning = true
	var sound := get_node_or_null("c") as AudioStreamPlayer
	if sound != null and sound.stream != null: sound.play()
	$fade_trans.modulate.a = 0.0
	$fade_trans.show()
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($fade_trans, "modulate:a", 1.0, 0.35)
	await tween.finished
	if not SaveManager.return_to_title():
		_is_transitioning = false
		$fade_trans.hide()
		push_warning(SaveManager.last_error)
