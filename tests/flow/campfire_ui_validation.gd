extends Node
var checks := 0
var failures := 0
var save_count := 0
var finish_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("CAMP UI ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 2) -> void:
	for i in count: await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func cursor(mode: int, label: String) -> void:
	# Headless DisplayServer cannot verify the native cursor mode.
	if DisplayServer.get_name() != "headless": check(Input.mouse_mode == mode, label)

func action(name: StringName) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventAction.new()
	event.action = name
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func fast(camp) -> void:
	camp.enter_fade_out_duration = 0.04
	camp.enter_fade_in_duration = 0.12
	camp.leave_fade_duration = 0.06
	camp.load_fade_duration = 0.06
	camp.title_fade_duration = 0.08

func ready_visit(camp, player) -> void:
	camp._rest_cooldown = 0.0
	camp._player = player
	camp._player_in_range = true
	await action(&"interact")
	await wait(0.22)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(3)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://campfire-ui-" + label + ".png")

func _run() -> void:
	if not OS.get_user_data_dir().contains("CodexCampfireUI20261015"):
		push_error("Refusing to modify real saves; use an isolated CodexCampfireUI20261015 project")
		get_tree().quit(2)
		return
	SaveManager.delete_save()
	SaveManager._data = SaveManager._default_data()
	PlayerProgress.read_from_save_data(SaveManager._data)
	SaveManager.save_written.connect(func(_slot): save_count += 1)
	var scene = load("res://scenes/Map 1/map_1_scene_2.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	await frames(4)
	var player = get_tree().get_first_node_in_group("Player")
	var hud = player.get_node("Camera2D/hud")
	var camp = scene.get_node("Campfire")
	var pause = player.get_node("Camera2D/UI_Layer/PauseMenu")
	var master = player.get_node("Camera2D/UI_Layer/master_menu")
	check(is_equal_approx(camp.enter_fade_out_duration, 0.7) and is_equal_approx(camp.enter_fade_in_duration, 2.0) and is_equal_approx(camp.leave_fade_duration, 0.5), "original transition durations retained as Inspector settings")
	cursor(Input.MOUSE_MODE_HIDDEN, "gameplay hides cursor without capture")
	fast(camp)
	player.position = Vector2(369, 836)
	await frames(4)
	camp._player = player
	camp._player_in_range = true
	camp.player_finished_rest.connect(func(): finish_count += 1)
	hud.modulate = Color.WHITE
	hud.hud_art.modulate = Color.WHITE
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_F
	echo.keycode = KEY_F
	echo.pressed = true
	echo.echo = true
	camp._unhandled_input(echo)
	check(not camp.is_ui_active(), "keyboard repeat alone cannot start a visit")
	await action(&"interact")
	check(camp._phase == camp.Phase.ENTERING and player.is_campfire_ui_active(), "real F input immediately acquires exclusive campfire session")
	check(player.is_resting and not hud.get_node("ScreenSpace").visible, "entry hides HUD and locks actor before first fade")
	check(not camp.rest_menu.visible and not player._campfire_cursor_ready, "entry keeps menu and cursor unavailable")
	cursor(Input.MOUSE_MODE_HIDDEN, "cursor stays hidden during entering fade")
	await action(&"ui_cancel")
	await action(&"toggle_master_menu")
	check(not get_tree().paused and not pause.visible and not master.visible, "Esc and inventory hotkey cannot pause entering campfire")
	for i in 8: camp._sit_and_save()
	for i in 8: camp._on_leave_pressed()
	check(camp._phase == camp.Phase.ENTERING, "entry spam cannot start another visit or exit early")
	await wait(0.06)
	check(camp._phase == camp.Phase.ENTERING and not camp.rest_menu.visible and not player._campfire_cursor_ready, "cursor/menu remain blocked through the fade-in half")
	await wait(0.16)
	check(camp.is_menu_ready() and camp.rest_menu.visible and player._campfire_cursor_ready, "menu and cursor unlock only when entry fade completes")
	check(save_count == 1, "repeated entry attempts save once")
	cursor(Input.MOUSE_MODE_VISIBLE, "ready campfire displays cursor")
	await capture("resting-no-hud")
	for i in 15: await action(&"interact")
	check(camp.is_menu_ready() and player.is_resting and camp.rest_menu.visible, "F never leaves a ready campfire")
	check(save_count == 1, "F spam does not autosave repeatedly")
	await action(&"ui_cancel")
	pause.pause_and_unpause()
	master._open_menu()
	check(not get_tree().paused and not pause.visible and not master.visible, "direct pause/master requests also respect campfire ownership")
	cursor(Input.MOUSE_MODE_VISIBLE, "blocked pause cannot capture or hide ready-menu cursor")
	hud.heal_to_full()
	hud.enter_combat()
	hud.stamina = 25
	hud._stats._stamina_regen_time_left = 0.0
	await wait(0.08)
	check(not hud.get_node("ScreenSpace").visible and hud.stamina > 25, "HUD stays hidden while healing/fade/stamina processing continue")
	camp.btn_relica.pressed.emit()
	check(camp._upgrade_menu.visible and not camp.rest_menu.visible, "upgrade button opens child menu")
	await action(&"ui_cancel")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	camp._upgrade_menu._unhandled_input(cancel)
	check(camp._upgrade_menu.visible and not get_tree().paused, "Esc cannot close upgrade menu or open pause during a visit")
	camp._upgrade_menu.close()
	check(camp.rest_menu.visible and camp.is_menu_ready(), "explicit Back returns from upgrade menu")
	camp.btn_save.pressed.emit()
	check(camp.save_slot_menu.visible and not camp.rest_menu.visible, "Save opens slot menu")
	await action(&"ui_cancel")
	check(camp.save_slot_menu.visible, "Esc cannot dismiss campfire save menu")
	camp._on_slot_menu_back_pressed()
	check(camp.rest_menu.visible, "slot Back explicitly restores rest menu")
	var data: Dictionary = SaveManager._data.duplicate(true)
	data.checkpoint_id = "other_slot"
	var file := FileAccess.open(SaveManager.get_save_path(2), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var slot2 := FileAccess.get_file_as_string(SaveManager.get_save_path(2))
	camp._on_slot_selected(2, false)
	check(camp._save_confirmation.visible and not camp._save_confirmation.dialog_close_on_escape, "replacement dialog has Esc closing disabled")
	var close_event := InputEventAction.new()
	close_event.action = "ui_close_dialog"
	close_event.pressed = true
	camp._save_confirmation.push_input(close_event)
	await frames()
	check(camp._save_confirmation.visible, "native confirmation keeps open on Escape action")
	camp._save_confirmation.canceled.emit()
	camp._save_confirmation.hide()
	check(camp._pending_save_slot == -1 and FileAccess.get_file_as_string(SaveManager.get_save_path(2)) == slot2, "explicit cancel clears replacement and preserves other slot")
	camp._load_from_slot(1)
	check(camp._phase == camp.Phase.LOADING and not camp.rest_menu.visible and not player._campfire_cursor_ready, "load immediately blocks menus and cursor")
	cursor(Input.MOUSE_MODE_HIDDEN, "same-scene load hides cursor during fade")
	await action(&"ui_cancel")
	await wait(0.18)
	check(camp.is_menu_ready() and player.is_resting and not get_tree().paused, "same-scene load returns to Rest after its fade")
	check(not hud.get_node("ScreenSpace").visible and player._campfire_cursor_ready, "load does not reveal HUD or lose menu cursor")
	cursor(Input.MOUSE_MODE_VISIBLE, "loaded campfire restores visible cursor")
	camp._on_slot_menu_back_pressed()
	camp.btn_leave.pressed.emit()
	check(camp._phase == camp.Phase.LEAVING and not camp.rest_menu.visible and not camp._upgrade_menu.visible, "Leave atomically hides every menu")
	check(not player._campfire_cursor_ready and not hud.get_node("ScreenSpace").visible, "exit fade keeps cursor and HUD hidden")
	cursor(Input.MOUSE_MODE_HIDDEN, "cursor hides immediately on Leave")
	for i in 12:
		camp._on_leave_pressed()
		camp._on_load_pressed()
		camp._on_save_pressed()
		camp._on_upgrade_menu_closed()
		camp._on_relica_pressed()
	await action(&"interact")
	await action(&"ui_cancel")
	check(camp._phase == camp.Phase.LEAVING and not camp.rest_menu.visible and not get_tree().paused, "leave/F/menu callback spam cannot resurrect UI or pause exit fade")
	await wait(0.08)
	check(camp.is_ui_active() and player.is_resting, "player and Esc stay locked until full exit fade completes")
	await wait(0.10)
	check(not camp.is_ui_active() and not player.is_campfire_ui_active() and not player.is_resting, "finished exit releases player and campfire ownership")
	check(hud.get_node("ScreenSpace").visible and not camp.rest_menu.visible and not camp.save_slot_menu.visible and not camp.load_slot_menu.visible, "exit restores HUD canvas without leftover menus")
	check(finish_count == 1, "Leave spam finishes once")
	cursor(Input.MOUSE_MODE_HIDDEN, "gameplay after campfire uses hidden-only cursor")
	await action(&"ui_cancel")
	check(get_tree().paused and pause.visible, "Esc works again after fully leaving campfire")
	cursor(Input.MOUSE_MODE_VISIBLE, "pause shows pointer for buttons")
	pause._on_resume_pressed()
	check(not get_tree().paused and not pause.visible, "Resume returns to gameplay")
	cursor(Input.MOUSE_MODE_HIDDEN, "Resume hides pointer without capturing it")
	master._open_menu()
	await wait(0.3)
	check(get_tree().paused and master.visible, "inventory can open again outside campfire")
	cursor(Input.MOUSE_MODE_VISIBLE, "inventory exposes pointer")
	master._close_menu()
	await wait(0.25)
	check(not get_tree().paused and not master.visible, "inventory closes cleanly")
	cursor(Input.MOUSE_MODE_HIDDEN, "inventory close returns hidden gameplay pointer")
	Engine.time_scale = 0.2
	await ready_visit(camp, player)
	check(camp.is_menu_ready() and player._campfire_cursor_ready, "campfire UI fade uses real time during global slow motion")
	await camp._stand_up()
	check(not camp.is_ui_active() and not player.is_resting, "exit UI also completes in real time during slow motion")
	Engine.time_scale = 1.0
	for cycle in 6:
		await ready_visit(camp, player)
		check(camp.is_menu_ready(), "repeated visit opens normally, cycle %d" % cycle)
		for i in 10: await action(&"interact")
		camp.btn_leave.pressed.emit()
		await action(&"ui_cancel")
		await wait(0.18)
		check(not camp.is_ui_active() and not camp.rest_menu.visible and not get_tree().paused and hud.get_node("ScreenSpace").visible, "stress visit ends with no ghost UI, cycle %d" % cycle)
	await ready_visit(camp, player)
	check(camp.is_menu_ready(), "final visit ready for title return")
	camp.btn_title.pressed.emit()
	check(camp._phase == camp.Phase.TITLE and not player._campfire_cursor_ready, "title transition hides pointer and rejects further visit actions")
	await action(&"ui_cancel")
	await get_tree().scene_changed
	await frames(4)
	check(get_tree().current_scene.scene_file_path == SaveManager.TITLE_SCENE and not get_tree().paused, "campfire returns to title without lingering pause")
	cursor(Input.MOUSE_MODE_VISIBLE, "title cursor stays visible after old campfire exits")
	check(SaveManager.continue_game(1), "Continue from campfire checkpoint succeeds")
	await get_tree().scene_changed
	await frames(4)
	player = get_tree().get_first_node_in_group("Player")
	hud = player.get_node("Camera2D/hud")
	camp = get_tree().current_scene.get_node("Campfire")
	fast(camp)
	check(not player.is_campfire_ui_active() and hud.get_node("ScreenSpace").visible and not camp.is_ui_active(), "Continue creates clean gameplay UI context")
	cursor(Input.MOUSE_MODE_HIDDEN, "Continue hides pointer in gameplay")
	camp._player = player
	camp._player_in_range = true
	camp._sit_and_save()
	await wait(0.02)
	player.exit_rest()
	await frames(4)
	await wait(0.20)
	check(not camp.is_ui_active() and not player.is_campfire_ui_active() and not camp.rest_menu.visible and hud.get_node("ScreenSpace").visible, "interrupted actor state cancels pending entry without delayed menu resurrection")
	camp._rest_cooldown = 0.0
	camp._player = player
	camp._player_in_range = true
	camp._sit_and_save()
	await wait(0.02)
	camp.queue_free()
	await frames(4)
	await wait(0.20)
	check(not player.is_campfire_ui_active() and not player.is_resting and hud.get_node("ScreenSpace").visible, "freeing campfire mid-entry releases actor and HUD safely")
	cursor(Input.MOUSE_MODE_HIDDEN, "destroyed campfire leaves hidden gameplay pointer")
	print("CAMP UI RESULT checks=", checks, " failures=", failures)
	get_tree().quit(1 if failures else 0)
