extends Node
## Run only in a copied project with the documented isolated user directory.
const SlotStore = preload("res://scenes/Mechanic/save_slot_store.gd")

var checks := 0
var failures := 0
var save_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func frames(count: int = 3) -> void:
	for i in count: await get_tree().process_frame

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("ENTRY SAVE ", "PASS " if ok else "FAIL ", label)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(3)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://entry-save-" + label + ".png")

func bytes(slot: int) -> String:
	var path := SaveManager.get_save_path(slot)
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<missing>"

func slot_files() -> Dictionary:
	var files: Dictionary = {}
	for filename in DirAccess.get_files_at(OS.get_user_data_dir()):
		if filename.begins_with("soujourn_save"):
			files[filename] = FileAccess.get_file_as_bytes("user://" + filename)
	return files

func write_text(slot: int, text: String) -> void:
	var file := FileAccess.open(SaveManager.get_save_path(slot), FileAccess.WRITE)
	file.store_string(text)
	file.close()

func fixture(slot: int) -> Dictionary:
	var data: Dictionary = SaveManager._default_data()
	data.scene_path = SaveManager.NEW_GAME_SCENE
	data.checkpoint_id = "preserve_%d" % slot
	data.spawn_position = {"x": 300.0 + slot * 25, "y": 700.0}
	data.level = slot + 3
	data.exp = slot * 5
	data.attributes[&"vitality"] = 4
	data.max_hp = 140
	data.hp = 81
	data.flask_charges = 1
	data.facing_left = true
	data.custom_future_field = {"kept": true}
	return data

func actor():
	return get_tree().get_first_node_in_group("Player")

func reveal_title(menu) -> void:
	if menu.state == menu.State.MAIN_MENU: return
	for i in 2:
		var event := InputEventKey.new()
		event.keycode = KEY_SPACE
		event.pressed = true
		get_viewport().push_input(event, true)
		await frames(2)
	await get_tree().create_timer(menu.prompt_exit_duration + menu.menu_fade_duration + 0.1).timeout

func _run() -> void:
	if not OS.get_user_data_dir().contains("CodexEntrySave20261014"):
		push_error("Refusing to modify real user saves; run in isolated test project")
		get_tree().quit(2)
		return
	SaveManager.delete_save()
	SaveManager.save_written.connect(func(_slot): save_count += 1)
	write_text(1, JSON.stringify(fixture(1)))
	write_text(2, JSON.stringify(fixture(2)))
	var original1 := bytes(1)
	var original2 := bytes(2)
	SaveManager._session_selected = false
	check(SaveManager.needs_save_confirmation(1) and not SaveManager.sync_progress_to_active_slot() and bytes(1) == original1, "direct editor launch cannot auto-overwrite an unselected existing slot")
	var menu = load(SaveManager.TITLE_SCENE).instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await frames()
	check(ResourceLoader.exists(SaveManager.NEW_GAME_SCENE) and ResourceLoader.exists(SaveManager.TITLE_SCENE), "both centralized entry/title destinations load")
	await reveal_title(menu)
	var before_new := slot_files()
	menu._on_start_pressed()
	check(menu.state == menu.State.TRANSITIONING and not menu.slot_menu.visible, "New Game immediately transitions without a slot picker")
	menu._on_start_pressed()
	await get_tree().scene_changed
	await frames(5)
	check(get_tree().current_scene.scene_file_path == SaveManager.NEW_GAME_SCENE, "New Game enters actual map scene")
	check(SaveManager.active_slot == SaveManager.NO_SAVE_SLOT and not SaveManager.has_active_save_slot() and save_count == 0, "new run has no disk slot and emits no save event")
	check(slot_files() == before_new, "New Game preserves every primary, backup and archive without creating files")
	check(PlayerProgress.level == 1 and PlayerProgress.exp == 0 and PlayerProgress.attributes[&"vitality"] == 0, "New Game resets progression in memory")
	check(actor() != null and is_equal_approx(actor().global_position.x, 175.0) and not SaveManager.pending_continue, "dynamic Adel receives initial spawn after scene_changed")
	await capture("new-game-unsaved")
	check(not SaveManager.sync_progress_to_active_slot(), "progression cannot silently select a disk slot for a new run")
	PlayerProgress.upgrade_points = 1
	check(not SaveManager.commit_attribute_allocation({&"vitality": 1}) and PlayerProgress.upgrade_points == 1, "unsaved allocation requires a campfire slot without spending points")
	PlayerProgress.upgrade_points = 0
	actor().global_position.x += 200
	SaveManager.respawn_at_checkpoint()
	check(is_equal_approx(actor().global_position.x, 175.0) and SaveManager.active_slot == SaveManager.NO_SAVE_SLOT, "unsaved death returns to this run's start rather than an old save")
	check(SaveManager.restart_current_area(), "unsaved run can restart its area")
	await get_tree().scene_changed
	await frames(5)
	check(is_equal_approx(actor().global_position.x, 175.0) and slot_files() == before_new, "unsaved restart retains its in-memory start without disk writes")
	var pause = actor().get_node("Camera2D/UI_Layer/PauseMenu")
	pause.pause_and_unpause()
	check(get_tree().paused and pause.visible, "pause opens in playable scene")
	await capture("pause-menu")
	pause._on_resume_pressed()
	check(not get_tree().paused and not pause.visible, "resume clears pause")
	pause.pause_and_unpause()
	await pause._on_quit_pressed()
	await frames(5)
	check(get_tree().current_scene.scene_file_path == SaveManager.TITLE_SCENE and not get_tree().paused, "pause Return to Title opens actual title and unpauses tree")
	check(bytes(1) == original1 and bytes(2) == original2, "returning to title preserves saves")
	menu = get_tree().current_scene
	await reveal_title(menu)
	await menu._on_start_pressed()
	await frames(5)
	var first_camp = get_tree().current_scene.get_node("Campfire")
	first_camp._player = actor()
	first_camp._player_in_range = true
	await first_camp._sit_and_save()
	check(first_camp.is_menu_ready() and slot_files() == before_new and save_count == 0 and not first_camp.saved_label.visible, "first campfire heals and opens its menu without auto-saving or claiming Saved")
	first_camp._on_save_pressed()
	check(first_camp.save_slot_menu.visible, "campfire Save offers slot selection")
	await capture("first-save-slots")
	first_camp._on_slot_menu_back_pressed()
	check(slot_files() == before_new and not SaveManager.has_active_save_slot(), "cancelling first slot selection leaves the run unsaved")
	first_camp._on_save_pressed()
	first_camp._on_slot_selected(1, false)
	check(first_camp._save_confirmation.visible and bytes(1) == original1, "first save to an occupied slot requires confirmation")
	first_camp._save_confirmation.canceled.emit()
	first_camp._save_confirmation.hide()
	check(slot_files() == before_new and not SaveManager.has_active_save_slot(), "cancelling overwrite preserves the unsaved run and all saves")
	var first_save_data: Dictionary = SaveManager._data.duplicate(true)
	var first_save_temp: String = SaveManager.get_save_path(3) + ".tmp"
	DirAccess.make_dir_absolute(first_save_temp)
	first_camp._on_slot_selected(3, false)
	check(not SaveManager.has_active_save_slot() and SaveManager._data == first_save_data and save_count == 0, "failed first save does not claim a slot or replace the in-memory start")
	check(slot_files() == before_new, "failed first save preserves every disk slot")
	DirAccess.remove_absolute(first_save_temp)
	first_camp._on_slot_selected(3, false)
	check(SaveManager.active_slot == 3 and SaveManager.has_active_save_slot() and save_count == 1 and SaveManager.get_checkpoint_id() == first_camp.get_checkpoint_id(), "choosing an empty campfire slot creates the first save and claims it")
	check(bytes(1) == original1 and bytes(2) == original2 and SaveManager._read_slot_file(3).level == 1, "first save contains the fresh run and preserves other slots")
	SaveManager.return_to_title()
	await get_tree().scene_changed
	await frames(5)
	menu = get_tree().current_scene
	await reveal_title(menu)
	menu._on_continue_pressed()
	check(menu.slot_menu.visible and menu.slot_menu.slot_list.get_child(3).disabled, "Continue offers slots and disables empty ones")
	await menu._begin_selected_game(1, false)
	await frames(5)
	var player = actor()
	var hud = player.get_node("Camera2D/hud")
	check(get_tree().current_scene.scene_file_path == SaveManager.NEW_GAME_SCENE and SaveManager.active_slot == 1, "Continue selected slot enters saved map")
	check(is_equal_approx(player.global_position.x, 325.0), "saved position survives exit_rest instead of resetting to origin")
	check(player.facing_direction == -1 and is_zero_approx(player.velocity.x), "saved facing and horizontal motion restore")
	check(PlayerProgress.level == 4 and PlayerProgress.exp == 5 and PlayerProgress.attributes[&"vitality"] == 4, "Continue restores progression")
	check(hud.hp == 81 and hud.max_hp == 140 and hud.flask_charges == 1, "Continue restores HP/flask into actual HUD")
	check(bytes(1) == original1 and bytes(2) == original2, "Continue reads without rewriting any slot")
	player.global_position.x += 75
	hud.hp = 10
	pause = player.get_node("Camera2D/UI_Layer/PauseMenu")
	pause.pause_and_unpause()
	pause._on_restart_pressed()
	await get_tree().scene_changed
	await frames(5)
	player = actor()
	hud = player.get_node("Camera2D/hud")
	check(not get_tree().paused and is_equal_approx(player.global_position.x, 325.0) and hud.hp == 81 and hud.max_hp == 140, "Restart Area reloads checkpoint and progression without remaining paused")
	check(bytes(1) == original1 and bytes(2) == original2, "restart reads checkpoint without rewriting saves")
	var camp = get_tree().current_scene.get_node("Campfire")
	camp._player = player
	camp._player_in_range = true
	await camp._sit_and_save()
	check(SaveManager.get_checkpoint_id() == "preserve_1" and hud.hp == hud.max_hp and bytes(1) == original1, "resting on a loaded run heals without auto-saving")
	camp._on_save_pressed()
	camp._on_slot_selected(1, false)
	check(SaveManager.get_checkpoint_id() == "campfire_01", "explicit campfire slot selection saves the checkpoint")
	check(bytes(2) == original2 and SaveManager._data.custom_future_field.kept, "campfire preserves other slot and unknown save fields")
	var before1 := bytes(1)
	var before_data: Dictionary = SaveManager._data.duplicate(true)
	var blocked_temp: String = SaveManager.get_save_path(1) + ".tmp"
	DirAccess.make_dir_absolute(blocked_temp)
	PlayerProgress.exp += 1
	check(not SaveManager.sync_progress_to_active_slot(), "failed temporary write returns failure")
	check(bytes(1) == before1 and SaveManager._data == before_data, "failed write preserves primary and checkpoint memory")
	DirAccess.remove_absolute(blocked_temp)
	check(not SaveManager.save_at_campfire(camp, 2) and bytes(2) == original2, "API protects an occupied unrelated slot")
	camp._on_slot_selected(2, false)
	check(camp._save_confirmation.visible and bytes(2) == original2, "campfire Save As requests replacement confirmation")
	camp._save_confirmation.canceled.emit()
	camp._save_confirmation.hide()
	check(camp._pending_save_slot == -1 and bytes(2) == original2, "cancel campfire replacement clears pending choice without writes")
	camp._on_slot_selected(2, false)
	camp._save_confirmation.hide()
	camp._confirm_save_slot()
	check(SaveManager.active_slot == 2 and bytes(2) != original2 and bytes(1) == before1, "confirmed Save As replaces only target slot")
	check(FileAccess.get_file_as_string(SaveManager.get_save_path(2) + ".bak") == original2, "replaced slot has byte-exact backup")
	check(SaveManager.sync_progress_to_active_slot(), "progression writes to selected active slot")
	check(bytes(1) == before1, "upgrade synchronization preserves previous slot")
	check(SaveManager.load_game_from_slot(1, true), "load same scene succeeds while resting")
	check(player.state_machine.current == AdelStateMachine.State.REST and is_equal_approx(player.global_position.x, float(before_data.spawn_position.x)), "resting load restores anchor and keeps Rest state")
	await camp._stand_up()
	check(is_equal_approx(player.global_position.x, float(before_data.spawn_position.x)), "standing after load does not revert to old rest anchor")
	player.global_position.x += 200
	hud.hp = 10
	SaveManager.respawn_at_checkpoint()
	check(is_equal_approx(player.global_position.x, float(before_data.spawn_position.x)) and hud.hp == hud.max_hp, "same-scene death restores checkpoint and full health")
	write_text(4, "{broken")
	var previous_slot: int = SaveManager.active_slot
	var previous_progress: int = PlayerProgress.level
	check(not SaveManager.get_slot_info(4).loadable, "corrupt save is occupied but unavailable")
	check(not SaveManager.load_game_from_slot(4) and SaveManager.active_slot == previous_slot and PlayerProgress.level == previous_progress, "failed load does not change active session")
	check(bytes(4) == "{broken", "invalid save is never deleted by inspecting/loading")
	var invalid := fixture(5)
	invalid.spawn_position = []
	write_text(5, JSON.stringify(invalid))
	check(not SaveManager.get_slot_info(5).loadable, "wrong spawn type rejected without script error")
	invalid = fixture(5)
	invalid.scene_path = "res://opening.tscn"
	write_text(5, JSON.stringify(invalid))
	check(not SaveManager.get_slot_info(5).loadable, "missing saved scene disables Continue")
	invalid = fixture(5)
	invalid.hp = "invalid"
	check(not SlotStore.is_valid_data(invalid), "wrong numeric types rejected")
	invalid = fixture(5)
	invalid.version = 99
	check(not SlotStore.is_valid_data(invalid), "unsupported future schema rejected")
	var legacy := fixture(5)
	legacy.erase("version")
	for key in ["attributes", "coin", "soul"]: legacy.erase(key)
	legacy.hp_upgrades = 2
	legacy.stamina_upgrades = 0
	write_text(5, JSON.stringify(legacy))
	check(SaveManager.get_slot_info(5).loadable, "legacy filename and missing version remain compatible")
	write_text(1, "{broken primary")
	check(SaveManager.get_slot_info(1).recovered and SaveManager.load_from_slot(1), "valid backup recovers corrupt primary")
	check(bytes(1) == "{broken primary", "backup recovery is read-only until next save")
	check(SaveManager.get_first_loadable_slot() > 0 and SaveManager.has_save(), "valid slot search skips invalid slots")
	get_tree().change_scene_to_file("res://scenes/enemy/spine_enemy_test.tscn")
	await get_tree().scene_changed
	await frames(5)
	SaveManager.respawn_at_checkpoint()
	await get_tree().scene_changed
	await frames(5)
	player = actor()
	hud = player.get_node("Camera2D/hud")
	camp = get_tree().current_scene.get_node("Campfire")
	check(get_tree().current_scene.scene_file_path == SaveManager.NEW_GAME_SCENE and is_equal_approx(player.global_position.x, 325.0) and hud.hp == hud.max_hp, "cross-scene death returns to real map checkpoint with full HP")
	check(bytes(1) == "{broken primary", "cross-scene respawn does not overwrite saved progress")
	SaveManager.return_to_title()
	await frames(5)
	check(get_tree().current_scene.scene_file_path == SaveManager.TITLE_SCENE and not get_tree().paused, "central title return after cross-scene respawn succeeds")
	menu = get_tree().current_scene
	await reveal_title(menu)
	menu._on_continue_pressed()
	check(menu.slot_menu.slot_list.get_child(3).disabled and not menu.slot_menu.slot_list.get_child(0).disabled, "UI distinguishes bad slot from recovered backup")
	await menu._begin_selected_game(4, false)
	check(get_tree().current_scene == menu and menu.slot_menu.visible and menu.state != menu.State.TRANSITIONING and menu.slot_menu.status_label.text == SaveManager.last_error, "failed Continue restores interactive menu and displays reason")
	check(bytes(4) == "{broken", "failed menu transition preserves invalid data")
	menu._close_slot_menu()
	await reveal_title(menu)
	var before_another_run := slot_files()
	await menu._on_start_pressed()
	await frames(5)
	check(SaveManager.active_slot == SaveManager.NO_SAVE_SLOT and PlayerProgress.level == 1, "another New Game drops previous slot ownership and resets progression")
	check(slot_files() == before_another_run, "another New Game leaves valid, corrupt, backup and archive files byte-exact")
	var original_legacy := bytes(5)
	var replacement := SlotStore.write_new_game(5, fixture(5), PlayerProgress.config)
	var replaced_legacy: bool = replacement.error.is_empty() and bytes(5) != original_legacy
	if replacement.error.is_empty(): SlotStore.rollback_new_game(5, replacement)
	check(replaced_legacy and bytes(5) == original_legacy, "new-game rollback restores the exact legacy primary")
	SaveManager.delete_save_slot(4)
	var created := SlotStore.write_new_game(4, fixture(4), PlayerProgress.config)
	var created_primary: bool = created.error.is_empty() and SaveManager.has_save_in_slot(4)
	if created.error.is_empty(): SlotStore.rollback_new_game(4, created)
	check(created_primary and not SaveManager.has_save_in_slot(4), "new-game rollback removes a newly created primary")
	SaveManager.delete_save()
	SaveManager.return_to_title()
	await get_tree().scene_changed
	await frames(5)
	menu = get_tree().current_scene
	await reveal_title(menu)
	check(menu.get_node("Interface/Root/MainMenu/Continue").disabled, "Continue is disabled when no saved slot exists")
	var before_empty_run := slot_files()
	await menu._on_start_pressed()
	await frames(5)
	check(actor() != null and not SaveManager.has_save() and not SaveManager.has_active_save_slot() and slot_files() == before_empty_run, "New Game also enters an empty-save profile without creating a save")
	SaveManager.return_to_title()
	await get_tree().scene_changed
	await frames(5)
	menu = get_tree().current_scene
	await reveal_title(menu)
	check(menu.get_node("Interface/Root/MainMenu/Continue").disabled and slot_files() == before_empty_run, "leaving an unsaved run keeps Continue disabled and preserves the empty profile")
	print("ENTRY SAVE RESULT checks=", checks, " failures=", failures)
	get_tree().quit(1 if failures else 0)
