extends Node
@onready var preferences = get_node("/root/VideoPreferences")
var checks := 0
var failures := 0
var menu
var settings
var video

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("VIDEO ", "PASS " if ok else "FAIL ", label)

func frames(count := 3) -> void:
	for i in count: await get_tree().process_frame

func wait_real(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func click(button: Control) -> void:
	var position := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	get_viewport().push_input(motion, true)
	await frames(2)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await frames(2)

func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await frames(2)

func select(option: OptionButton, index: int) -> void:
	option.select(index)
	option.item_selected.emit(index)
	await frames(2)

func config_bytes() -> String:
	return FileAccess.get_file_as_string(preferences.CONFIG_PATH) if FileAccess.file_exists(preferences.CONFIG_PATH) else "<missing>"

func capture(label: String) -> void:
	if preferences.is_headless(): return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://video-" + label + ".png")

func _run() -> void:
	if not OS.get_user_data_dir().contains("CodexEntrySave20261014-Video"):
		get_tree().quit(2)
		return
	await frames(4)
	if "--verify-saved" in OS.get_cmdline_user_args():
		check(preferences.confirmed.mode == "windowed" and preferences.confirmed.width == 960 and preferences.confirmed.height == 540, "new process loads confirmed display choice")
		check(Engine.max_fps == 120 and not preferences.confirmed.vsync, "new process applies saved performance options")
		if not preferences.is_headless(): check(get_window().mode == Window.MODE_WINDOWED and get_window().size == Vector2i(960, 540), "new process restores actual window geometry")
		if not preferences.is_headless(): check(DisplayServer.window_get_vsync_mode(get_window().get_window_id()) == DisplayServer.VSYNC_DISABLED, "saved VSync choice reaches display server")
		preferences.apply_settings(preferences.defaults())
		if preferences.pending: preferences.confirm()
		print("VIDEO RESTART RESULT checks=", checks, " failures=", failures)
		get_tree().quit(1 if failures else 0)
		return
	preferences.apply_settings(preferences.defaults())
	if preferences.pending: preferences.confirm()
	var original_checkpoint := FileAccess.get_file_as_string(SaveManager.get_save_path(1)) if FileAccess.file_exists(SaveManager.get_save_path(1)) else "<missing>"
	menu = load("res://scenes/UI/title_screen.tscn").instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await frames()
	menu._show_main_menu()
	menu._on_option_pressed()
	settings = menu.settings_menu
	video = settings.video
	await frames(4)
	await click(settings.video_btn)
	check(video.is_visible_in_tree(), "actual tab click opens Video")
	check(video.mode_select.item_count == 3 and video.fps_select.item_count == 5, "all planned display modes and FPS limits appear")
	check(video.apply_button.disabled and video.revert_button.disabled, "unchanged settings cannot be applied")
	check(video.resolution_select.disabled, "fullscreen modes use desktop resolution")
	for size in preferences.window_sizes():
		check(size.x <= preferences._window_limit().x and size.y <= preferences._window_limit().y, "window size fits usable display: " + str(size))
	await capture("page")
	var original: Dictionary = preferences.confirmed.duplicate(true)
	await select(video.fps_select, preferences.FPS_OPTIONS.find(120))
	check(preferences.confirmed == original and Engine.max_fps == original.max_fps, "selection stages changes without affecting runtime")
	await click(video.revert_button)
	check(video.apply_button.disabled and video._draft == original, "Revert discards staged changes")
	await select(video.fps_select, preferences.FPS_OPTIONS.find(120))
	await click(video.apply_button)
	check(not preferences.pending and preferences.confirmed.max_fps == 120 and Engine.max_fps == 120, "performance-only Apply saves immediately")
	var saved_before := config_bytes()
	var confirmed_before: Dictionary = preferences.confirmed.duplicate(true)
	var actual_before: Dictionary = preferences._capture_runtime()
	await select(video.mode_select, 0)
	check(not video.resolution_select.disabled, "windowed mode enables resolution")
	await select(video.resolution_select, video._resolutions.find(Vector2i(960, 540)))
	await click(video.apply_button)
	check(preferences.pending and video.confirmation_layer.visible, "display Apply opens confirmation overlay")
	check(preferences.confirmed == confirmed_before and config_bytes() == saved_before, "unconfirmed preview does not overwrite confirmed state or config")
	check(preferences.remaining_seconds() >= 14 and preferences.remaining_seconds() <= 15, "preview starts 15-second real-time countdown")
	check(not preferences.apply_settings(preferences.defaults()).is_empty(), "second Apply is rejected while confirming")
	await frames(6)
	if not preferences.is_headless(): check(get_window().mode == Window.MODE_WINDOWED and get_window().size == Vector2i(960, 540), "preview changes real window geometry")
	await capture("confirmation")
	await key(KEY_TAB)
	var owner := get_viewport().gui_get_focus_owner()
	check(owner == video.keep_button or owner == video.undo_button, "confirmation owns keyboard navigation")
	await key(KEY_ESCAPE)
	check(not preferences.pending and settings.visible and video.is_visible_in_tree(), "Esc reverts preview without closing Settings")
	check(preferences.confirmed == confirmed_before and config_bytes() == saved_before and Engine.max_fps == actual_before.fps, "revert restores state and performance without saving")
	if not preferences.is_headless(): check(get_window().mode == actual_before.mode and get_window().size == actual_before.size, "revert restores previous real window")
	await select(video.mode_select, 0)
	await select(video.resolution_select, video._resolutions.find(Vector2i(960, 540)))
	await click(video.apply_button)
	await click(video.keep_button)
	check(not preferences.pending and preferences.confirmed.mode == "windowed" and preferences.confirmed.width == 960, "Keep commits preview")
	check(config_bytes() != saved_before and FileAccess.file_exists(preferences.BACKUP_PATH), "confirmation saves with previous-config backup")
	check(get_window().content_scale_size == Vector2i(1920, 1080) and get_window().content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP, "window changes preserve design viewport and aspect")
	for mode_index in [1, 2]:
		var before: Dictionary = preferences.confirmed.duplicate(true)
		await select(video.mode_select, mode_index)
		await click(video.apply_button)
		await frames(6)
		check(preferences.pending and video.resolution_select.disabled, "fullscreen mode previews with desktop resolution: " + str(mode_index))
		if not preferences.is_headless(): check(get_window().mode == preferences._mode_for(preferences.MODES[mode_index]), "real fullscreen mode applied: " + str(mode_index))
		await click(video.undo_button)
		check(not preferences.pending and preferences.confirmed == before, "Revert button restores from fullscreen preview")
	# Timeout must be based on real time even with pause and slow motion.
	await select(video.mode_select, 1)
	await click(video.apply_button)
	var began := Time.get_ticks_msec()
	get_tree().paused = true
	Engine.time_scale = 0.01
	await wait_real(15.25)
	check(not preferences.pending and video.status.text.contains("restored"), "preview automatically reverts while paused and slowed")
	check(Time.get_ticks_msec() - began >= 15000, "confirmation waits actual 15 seconds")
	Engine.time_scale = 1.0
	get_tree().paused = false
	# A failed config commit restores the preview and keeps the old file.
	var stable_file := config_bytes()
	var stable: Dictionary = preferences.confirmed.duplicate(true)
	await select(video.mode_select, 1)
	await click(video.apply_button)
	var blocked := ProjectSettings.globalize_path(preferences.TEMP_PATH)
	check(DirAccess.make_dir_absolute(blocked) == OK, "isolated save-failure fixture created")
	var problem: String = preferences.confirm()
	check(not problem.is_empty() and not preferences.pending and preferences.confirmed == stable and config_bytes() == stable_file, "failed save rolls back preview and preserves confirmed config")
	DirAccess.remove_absolute(blocked)
	# Switching pages cannot leave an unconfirmed mode active.
	await select(video.mode_select, 1)
	await click(video.apply_button)
	settings._on_audio()
	check(not preferences.pending and not video.confirmation_layer.visible and preferences.confirmed == stable, "leaving Video reverts active preview")
	settings._on_video()
	await frames()
	await select(video.mode_select, 1)
	await click(video.apply_button)
	settings.close()
	check(not preferences.pending and not settings.visible and menu.state == menu.State.MAIN_MENU, "closing Settings reverts its preview")
	menu._on_option_pressed()
	settings._on_video()
	await frames(4)
	await click(video.defaults_button)
	check(video._draft == preferences.defaults() and preferences.confirmed == stable, "Restore defaults only stages until Apply")
	var invalid: Dictionary = preferences.normalize({"mode": "bad", "width": "invalid", "height": -1, "max_fps": 999, "vsync": "yes"})
	check(invalid == preferences.defaults(), "invalid settings normalize to safe defaults")
	var huge: Dictionary = preferences.normalize({"mode": "windowed", "width": 16384, "height": 16384})
	check(huge.width <= preferences._window_limit().x and huge.height <= preferences._window_limit().y, "saved size clamps when display is smaller")
	var final_checkpoint := FileAccess.get_file_as_string(SaveManager.get_save_path(1)) if FileAccess.file_exists(SaveManager.get_save_path(1)) else "<missing>"
	check(final_checkpoint == original_checkpoint, "video settings do not modify checkpoint saves")
	var leaving: Dictionary = preferences.confirmed.duplicate(true)
	leaving.mode = "borderless"
	preferences.apply_settings(leaving)
	menu.queue_free()
	await frames(4)
	check(not preferences.pending and preferences.confirmed == stable, "scene teardown reverts unconfirmed display state")
	# Seed the next process to prove persistence on startup.
	var seed: Dictionary = preferences.confirmed.duplicate(true)
	seed.mode = "windowed"
	seed.width = 960
	seed.height = 540
	seed.vsync = false
	seed.max_fps = 120
	preferences.apply_settings(seed)
	if preferences.pending: preferences.confirm()
	print("VIDEO RESULT checks=", checks, " failures=", failures)
	get_tree().quit(1 if failures else 0)

