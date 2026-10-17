extends Node
@onready var bindings = get_node("/root/InputBindings")
var checks := 0
var failures := 0
var menu
var controls
var settings

func _ready() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("CONTROLS ", "PASS " if ok else "FAIL ", label)

func frames(n := 3) -> void:
	for i in n: await get_tree().process_frame

func key_event(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event

func key(code: Key) -> void:
	var event := key_event(code)
	get_viewport().push_input(event, true)
	await frames(2)
	event.pressed = false
	get_viewport().push_input(event, true)
	await frames(2)

func click(button: Control) -> void:
	var pos := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	get_viewport().push_input(motion, true)
	await frames(2)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = pos
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await frames(2)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://controls-" + name + ".png")

func _run() -> void:
	if not OS.get_user_data_dir().contains("CodexEntrySave20261014-Controls"):
		get_tree().quit(2)
		return
	if "--verify-persisted" in OS.get_cmdline_user_args():
		check(bindings.get_bindings(&"weapon_skill")[0].physical_keycode == KEY_J, "new process loads saved binding")
		check(InputMap.event_is_action(key_event(KEY_J), "weapon_skill") and not InputMap.event_is_action(key_event(KEY_Q), "weapon_skill"), "loaded binding drives actual InputMap")
		bindings.reset_defaults()
		print("CONTROLS RESTART RESULT checks=", checks, " failures=", failures)
		get_tree().quit(1 if failures else 0)
		return
	bindings.reset_defaults()
	var save_path := SaveManager.get_save_path(1)
	var original_save := FileAccess.get_file_as_string(save_path) if FileAccess.file_exists(save_path) else "<missing>"
	menu = load("res://scenes/UI/title_screen.tscn").instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await frames()
	menu._show_main_menu()
	menu._on_option_pressed()
	settings = menu.settings_menu
	controls = settings.controls
	await frames(4)
	await click(settings.controls_btn)
	check(controls.is_visible_in_tree() and controls.rows.get_child_count() == 13, "Controls tab contains all 13 live actions")
	var panel: Control = settings.get_node("HBoxContainer")
	check(panel.size.x >= 1240 and panel.size.y >= 820, "Settings is enlarged")
	var view := get_viewport().get_visible_rect()
	check(view.encloses(panel.get_global_rect()), "Settings fits viewport")
	await capture("full")
	var row: Control = controls.rows.get_child(8)
	controls.get_node("Scroll").ensure_control_visible(row)
	await frames()
	await click(row.get_node("Primary"))
	check(controls.is_capturing(), "actual row click starts capture")
	await key(KEY_J)
	check(not controls.is_capturing() and controls.status.text == "Binding saved.", "actual key capture commits binding")
	check(InputMap.event_is_action(key_event(KEY_J), "weapon_skill") and not InputMap.event_is_action(key_event(KEY_Q), "weapon_skill"), "new binding replaces Q in actual InputMap")
	var config_before := FileAccess.get_file_as_string(bindings.CONFIG_PATH)
	await click(row.get_node("Primary"))
	await key(KEY_SPACE)
	check(controls.is_capturing() and controls.status.text.contains("Jump"), "duplicate key reports conflicting action")
	check(FileAccess.get_file_as_string(bindings.CONFIG_PATH) == config_before and InputMap.event_is_action(key_event(KEY_J), "weapon_skill"), "conflict preserves active map and saved file")
	await key(KEY_ESCAPE)
	check(not controls.is_capturing() and settings.visible and menu.state == menu.State.SETTINGS, "Esc cancels capture without closing Settings")
	await click(row.get_node("Secondary"))
	await key(KEY_K)
	check(bindings.get_bindings(&"weapon_skill").size() == 2 and InputMap.event_is_action(key_event(KEY_K), "weapon_skill"), "secondary binding also triggers same action")
	await click(row.get_node("Clear"))
	check(bindings.get_bindings(&"weapon_skill").size() == 1 and not InputMap.event_is_action(key_event(KEY_K), "weapon_skill"), "Clear removes secondary only")
	bindings.bind(&"run", 0, key_event(KEY_U))
	controls.start_capture(&"weapon_skill", 1)
	await key(KEY_CTRL)
	check(not controls.is_capturing() and InputMap.event_is_action(key_event(KEY_CTRL), "weapon_skill"), "standalone modifier binds when released")
	bindings.clear_secondary(&"weapon_skill")
	controls.start_capture(&"weapon_skill", 0)
	var modifier := key_event(KEY_CTRL)
	get_viewport().push_input(modifier, true)
	var chord := key_event(KEY_K)
	chord.ctrl_pressed = true
	get_viewport().push_input(chord, true)
	await frames()
	check(not controls.is_capturing() and bindings.get_bindings(&"weapon_skill")[0].ctrl_pressed, "modifier chord waits for the main key")
	modifier.pressed = false
	chord.pressed = false
	get_viewport().push_input(chord, true)
	get_viewport().push_input(modifier, true)
	await frames()
	controls.start_capture(&"attack", 0)
	get_viewport().push_input(_mouse(MOUSE_BUTTON_XBUTTON1), true)
	await frames()
	check(InputMap.event_is_action(_mouse(MOUSE_BUTTON_XBUTTON1), "attack"), "mouse side button can be captured")
	bindings.reset_action(&"attack")
	bindings.reset_action(&"run")
	await click(row.get_node("Reset"))
	check(InputMap.event_is_action(key_event(KEY_Q), "weapon_skill"), "per-action reset restores project binding")
	await click(row.get_node("Primary"))
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	get_viewport().push_input(wheel, true)
	await frames()
	check(controls.is_capturing() and controls.status.text.contains("wheel"), "wheel is rejected for held gameplay actions")
	await click(controls.cancel_button)
	check(not controls.is_capturing() and settings.visible, "Cancel binding button works without assigning its mouse click")
	check(not bindings.bind(&"weapon_skill", 0, key_event(KEY_ESCAPE)).is_empty(), "Escape remains reserved")
	check(bindings.bind(&"weapon_skill", 0, key_event(KEY_J)).is_empty(), "valid binding saves")
	bindings.reload_saved()
	check(bindings.get_bindings(&"weapon_skill")[0].physical_keycode == KEY_J, "ConfigFile reload restores saved binding")
	settings.close()
	menu._on_option_pressed()
	await click(settings.controls_btn)
	check(row.get_node("Primary").text.contains("J"), "reopened Controls displays current binding")
	for i in 25:
		await key(KEY_TAB)
		var owner := get_viewport().gui_get_focus_owner()
		check(owner != null and settings.is_ancestor_of(owner), "tab navigation stays within Settings " + str(i))
	# Invalid config data cannot poison the active map.
	var config := ConfigFile.new()
	config.set_value("controls", "version", 1)
	config.set_value("bindings", "weapon_skill", [{"kind": "key", "code": "bad"}])
	config.save(bindings.CONFIG_PATH)
	bindings.reload_saved()
	check(InputMap.event_is_action(key_event(KEY_Q), "weapon_skill"), "invalid stored event falls back safely")
	config.set_value("bindings", "weapon_skill", [{"kind": "key", "code": KEY_SPACE}])
	config.save(bindings.CONFIG_PATH)
	bindings.reload_saved()
	check(InputMap.event_is_action(key_event(KEY_Q), "weapon_skill"), "conflicting stored bindings fall back safely")
	await click(controls.reset_button)
	check(controls.reset_dialog.visible, "Restore defaults asks for confirmation")
	controls.reset_dialog.hide()
	controls.reset_dialog.confirmed.emit()
	check(bindings.get_bindings(&"weapon_skill")[0].physical_keycode == KEY_Q, "confirmed reset restores defaults")
	check(InputMap.event_is_action(_mouse(MOUSE_BUTTON_MIDDLE), "target_lock"), "target lock default remains middle mouse")
	check(bindings.bind(&"target_lock", 0, key_event(KEY_L)).is_empty() and InputMap.event_is_action(key_event(KEY_L), "target_lock"), "target lock is rebindable")
	var old_size := get_window().size
	var old_content := get_window().content_scale_size
	get_window().content_scale_size = Vector2i(960, 540)
	get_window().size = Vector2i(960, 540)
	await frames(8)
	check(get_viewport().get_visible_rect().encloses(panel.get_global_rect()), "enlarged Settings fits small viewport")
	await capture("small")
	get_window().content_scale_size = old_content
	get_window().size = old_size
	await frames(8)
	var final_save := FileAccess.get_file_as_string(save_path) if FileAccess.file_exists(save_path) else "<missing>"
	check(final_save == original_save, "control configuration never modifies checkpoint save")
	bindings.reset_defaults()
	# Leave one intentional setting for the separate restart verification process.
	bindings.bind(&"weapon_skill", 0, key_event(KEY_J))
	print("CONTROLS RESULT checks=", checks, " failures=", failures)
	get_tree().quit(1 if failures else 0)

func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event

