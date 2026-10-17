extends Node
## Run on an isolated copy; exercises real viewport input and audio buses.
var checks := 0
var failures := 0
var menu

func _ready() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("TITLE ", "PASS " if ok else "FAIL ", label)

func frames(count := 3) -> void:
	for i in count: await get_tree().process_frame

func key(code: Key, echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	get_viewport().push_input(event, true)
	await frames(2)
	event.pressed = false
	event.echo = false
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

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://title-refactor-" + label + ".png")

func _run() -> void:
	if not OS.get_user_data_dir().contains("CodexEntrySave20261014"):
		get_tree().quit(2)
		return
	menu = load("res://scenes/UI/title_screen.tscn").instantiate()
	menu.prompt_exit_duration = 0.02
	menu.menu_fade_duration = 0.02
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await frames(3)
	await key(KEY_SPACE, true)
	check(menu.state == menu.State.INTRO, "key repeat cannot skip intro")
	await key(KEY_SPACE)
	check(menu.state == menu.State.AWAITING_START, "first press skips intro to prompt")
	await key(KEY_SPACE)
	await get_tree().create_timer(0.15).timeout
	var start: Button = menu.get_node("Interface/Root/MainMenu/Start")
	var option: Button = menu.get_node("Interface/Root/MainMenu/Option")
	check(menu.state == menu.State.MAIN_MENU and start.has_focus(), "main menu starts with Start focused")
	check(start.highlight.visible, "keyboard focus shows selection image")
	check(menu.fade_rect.get_global_rect() == get_viewport().get_visible_rect(), "transition rect matches viewport")
	await capture("main")
	await click(option)
	check(menu.state == menu.State.SETTINGS and menu.settings_menu.visible, "actual click opens Settings")
	check(menu.settings_menu.general_btn.has_focus(), "Settings takes initial keyboard focus")
	for button in menu.menu_buttons.get_children():
		check(button.disabled and button.focus_mode == Control.FOCUS_NONE, "background button locked: " + button.name)
	for i in 7:
		await key(KEY_UP)
		var owner := get_viewport().gui_get_focus_owner()
		check(owner != null and menu.settings_menu.is_ancestor_of(owner), "Settings navigation stays inside modal " + str(i))
	menu._on_start_pressed()
	menu._on_continue_pressed()
	menu._on_quit_pressed()
	check(menu.state == menu.State.SETTINGS and not menu.slot_menu.visible, "background handlers cannot start slots or quit from Settings")
	await click(menu.settings_menu.general_btn)
	await key(KEY_ENTER)
	check(menu.state == menu.State.SETTINGS and not menu.slot_menu.visible, "Enter in Settings cannot trigger background action")
	var music := AudioServer.get_bus_index("Music")
	var sfx := AudioServer.get_bus_index("SFX")
	check(music >= 0 and sfx >= 0 and music != sfx, "named Music/SFX buses exist")
	check(menu.bgm_player.bus == &"Music" and menu.get_node("Audio/ClickSound").bus == &"SFX", "title players route to correct buses")
	menu.settings_menu._on_audio()
	await frames()
	check(is_equal_approx(menu.settings_menu.music_slider.value, db_to_linear(AudioServer.get_bus_volume_db(music))), "slider initializes from actual bus volume")
	menu.settings_menu.music_slider.value = 0.25
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(music)), 0.25) and is_zero_approx(AudioServer.get_bus_volume_db(sfx)), "music slider changes Music independently")
	menu.settings_menu.sfx_slider.value = 0.5
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(sfx)), 0.5), "SFX slider changes SFX")
	menu.settings_menu.music_slider.value = 0.0
	check(AudioServer.is_bus_mute(music), "zero slider mutes Music")
	menu.settings_menu.music_slider.value = 0.75
	check(not AudioServer.is_bus_mute(music), "raising slider unmutes Music")
	AudioServer.move_bus(sfx, music)
	music = AudioServer.get_bus_index("Music")
	menu.settings_menu._on_music_changed(0.4)
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(music)), 0.4), "volume survives audio bus reorder")
	AudioServer.move_bus(AudioServer.get_bus_index("SFX"), 2)
	await capture("settings")
	await key(KEY_ESCAPE)
	check(menu.state == menu.State.MAIN_MENU and option.has_focus(), "Esc closes Settings and restores Option focus")
	await click(option)
	check(is_equal_approx(menu.settings_menu.music_slider.value, 0.4), "reopening Settings resyncs bus volume")
	await click(menu.settings_menu.back_btn)
	check(menu.state == menu.State.MAIN_MENU and option.has_focus(), "Back closes Settings and restores focus")
	await click(start)
	check(menu.state == menu.State.SLOTS and menu.slot_menu.visible, "actual Start click opens extracted slot scene")
	check(menu.slot_menu.slot_list.get_child_count() == SaveManager.MAX_SAVE_SLOTS, "slot scene renders every save summary")
	await capture("slots")
	await key(KEY_ESCAPE)
	check(menu.state == menu.State.MAIN_MENU and start.has_focus(), "slot Esc returns to Start focus")
	check(start.highlight.scale == start.get("_base_scale"), "return resets pressed highlight scale")
	# Enter during reveal cannot launch a hidden menu action.
	menu.prompt_exit_duration = 0.3
	menu.menu_fade_duration = 0.3
	menu._show_prompt()
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	get_viewport().push_input(accept, true)
	await frames(2)
	check(menu.state == menu.State.REVEALING_MENU, "mapped ui_accept advances prompt")
	accept.pressed = false
	get_viewport().push_input(accept, true)
	await key(KEY_ENTER)
	await get_tree().create_timer(0.7).timeout
	check(menu.state == menu.State.MAIN_MENU and not menu.slot_menu.visible, "presses during reveal do not open slots")
	for bus in ["Music", "SFX"]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), 0.0)
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), false)
	menu.menu_fade_duration = 0.02
	menu.quit_fade_duration = 0.02
	menu.quit_audio_duration = 0.02
	menu._on_quit_pressed()
	check(menu.state == menu.State.TRANSITIONING and menu.fade_rect.mouse_filter == Control.MOUSE_FILTER_STOP, "quit locks input and starts transition")
	print("TITLE RESULT checks=", checks, " failures=", failures)
	if failures: get_tree().quit(1)
	# Successful runs must exit through the title's own quit tween.
	get_tree().create_timer(2.0).timeout.connect(func(): get_tree().quit(2))
