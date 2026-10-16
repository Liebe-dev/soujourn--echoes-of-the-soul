extends Control
const ChargedFinish = preload("res://scenes/adel/components/charged_skill_finish.gd")
const EnemyDebugSettings = preload("res://scenes/enemy/enemy_debug_settings.gd")
const SkillDebugSettings = preload("res://scenes/adel/components/skill_debug_settings.gd")

var _is_transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_setup_camera_settings()
	_setup_enemy_debug()
	_setup_skill_debug()

func _ui_actor() -> Node:
	var node := get_parent()
	while node != null:
		if node.has_method("is_campfire_ui_active"): return node
		node = node.get_parent()
	return null

func _campfire_blocks_menu() -> bool:
	var actor := _ui_actor()
	return actor != null and actor.is_campfire_ui_active()

func _refresh_cursor(center_mouse: bool = false) -> void:
	var actor := _ui_actor()
	if actor != null:
		actor.refresh_gameplay_cursor(center_mouse)
	else:
		CursorPolicy.set_visible(get_viewport(), visible, center_mouse)

func pause_and_unpause() -> void:
	if ChargedFinish.is_freezing(): return
	if _is_transitioning or _campfire_blocks_menu(): return
	if not get_tree().paused:
		var actor := _ui_actor()
		if actor != null: actor.clear_combat_input()
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	_refresh_cursor(visible)
	if visible:
		_sync_camera_settings()
		_sync_enemy_debug()
		_sync_skill_debug()
		move_to_front()
		$VBoxContainer/resume.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if ChargedFinish.is_freezing(): return
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


func _game_camera() -> Camera2D:
	var actor := _ui_actor()
	return actor.get_node_or_null("Camera2D") as Camera2D if actor != null else null

func _setup_camera_settings() -> void:
	if not has_node("VBoxContainer/CameraSettings"): return
	$VBoxContainer/CameraSettings/AutoReset.toggled.connect(_on_camera_auto_reset)
	$VBoxContainer/CameraSettings/ResetRow/Delay.value_changed.connect(_on_camera_delay)
	$VBoxContainer/CameraSettings/DeadzoneRow/Deadzone.value_changed.connect(_on_camera_deadzone)
	_sync_camera_settings()

func _sync_camera_settings() -> void:
	var camera := _game_camera()
	if camera == null or not camera.has_method("camera_preferences") or not has_node("VBoxContainer/CameraSettings"): return
	var settings: Dictionary = camera.camera_preferences()
	$VBoxContainer/CameraSettings/AutoReset.set_pressed_no_signal(settings.reset_enabled)
	$VBoxContainer/CameraSettings/ResetRow/Delay.set_value_no_signal(settings.reset_delay)
	$VBoxContainer/CameraSettings/ResetRow/Delay.editable = settings.reset_enabled
	$VBoxContainer/CameraSettings/DeadzoneRow/Deadzone.set_value_no_signal(settings.deadzone * 100.0)
	$VBoxContainer/CameraSettings/Status.text = ""

func _set_camera_setting(key: String, value: Variant) -> void:
	var camera := _game_camera()
	if camera == null or not camera.has_method("camera_preferences"): return
	var settings: Dictionary = camera.camera_preferences()
	settings[key] = value
	var error: Error = camera.apply_camera_preferences(settings)
	$VBoxContainer/CameraSettings/Status.text = "Camera settings saved" if error == OK else "Applied; could not save camera settings"

func _on_camera_auto_reset(value: bool) -> void:
	$VBoxContainer/CameraSettings/ResetRow/Delay.editable = value
	_set_camera_setting("reset_enabled", value)

func _on_camera_delay(value: float) -> void:
	_set_camera_setting("reset_delay", value)

func _on_camera_deadzone(value: float) -> void:
	_set_camera_setting("deadzone", value / 100.0)

func _setup_enemy_debug() -> void:
	var panel := get_node_or_null("VBoxContainer/EnemyDebug")
	if panel == null: return
	panel.visible = OS.is_debug_build()
	panel.get_node("DisableAI").toggled.connect(func(value: bool): EnemyDebugSettings.ai_disabled = value)
	panel.get_node("Immortal").toggled.connect(func(value: bool): EnemyDebugSettings.immortal = value)
	_sync_enemy_debug()

func _sync_enemy_debug() -> void:
	var panel := get_node_or_null("VBoxContainer/EnemyDebug")
	if panel == null: return
	panel.get_node("DisableAI").set_pressed_no_signal(EnemyDebugSettings.is_ai_disabled())
	panel.get_node("Immortal").set_pressed_no_signal(EnemyDebugSettings.is_immortal())

func _weapon_skill() -> Node:
	var actor := _ui_actor()
	return actor.get_node_or_null("SaberSkill") if actor != null else null

func _setup_skill_debug() -> void:
	var panel := get_node_or_null("VBoxContainer/SkillDebug")
	if panel == null: return
	panel.visible = OS.is_debug_build()
	panel.get_node("CooldownsEnabled").toggled.connect(_on_skill_cooldowns_toggled)
	_sync_skill_debug()

func _sync_skill_debug() -> void:
	var button := get_node_or_null("VBoxContainer/SkillDebug/CooldownsEnabled") as CheckButton
	if button == null: return
	var skill := _weapon_skill()
	button.disabled = not OS.is_debug_build() or skill == null or not skill.has_method("reset_cooldown")
	button.set_pressed_no_signal(SkillDebugSettings.are_cooldowns_enabled())

func _on_skill_cooldowns_toggled(enabled: bool) -> void:
	if not OS.is_debug_build() or not visible or not get_tree().paused or _is_transitioning or ChargedFinish.is_freezing(): return
	# Keep the session switch separate from the designer's cooldown durations.
	SkillDebugSettings.cooldowns_enabled = enabled
	if not enabled:
		var skill := _weapon_skill()
		if skill != null and skill.has_method("reset_cooldown"):
			skill.reset_cooldown()
	_sync_skill_debug()
