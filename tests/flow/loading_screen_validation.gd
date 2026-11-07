extends Node

var checks := 0
var failures := 0
var active_loading: Node
var samples: Array[float] = []
var loading_frames := 0
var capturing := false
var captured := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _process(_delta: float) -> void:
	if not is_instance_valid(active_loading) or not active_loading.is_node_ready(): return
	loading_frames += 1
	var value: float = active_loading.progress_bar.value
	if samples.is_empty() or value != samples[-1]: samples.append(value)
	if not captured and not capturing and value > 0.25 and value < 1.0 and DisplayServer.get_name() != "headless":
		capturing = true
		_capture_loading()

func _capture_loading() -> void:
	await RenderingServer.frame_post_draw
	if is_instance_valid(active_loading):
		get_viewport().get_texture().get_image().save_png("res://loading-screen-ingame.png")
		captured = true
	capturing = false

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("LOADING ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 3) -> void:
	for _index in count: await get_tree().process_frame

func disk_files() -> Dictionary:
	var result: Dictionary = {}
	for file in DirAccess.get_files_at(OS.get_user_data_dir()):
		if file.begins_with("soujourn_save"):
			result[file] = FileAccess.get_file_as_bytes("user://" + file)
	return result

func _run() -> void:
	if not OS.get_user_data_dir().contains("Loading20261107"):
		get_tree().quit(2)
		return
	SaveManager.delete_save()
	var data: Dictionary = SaveManager._default_data()
	data.scene_path = SaveManager.NEW_GAME_SCENE
	data.checkpoint_id = "loading_fixture"
	data.spawn_position = {"x": 325.0, "y": 700.0}
	data.hp = 72
	check(SaveManager._write_slot_to_disk(2, data), "isolated Continue fixture created")
	var before := disk_files()
	var screen: Node = load("res://scenes/UI/loading_screen.tscn").instantiate()
	get_tree().root.add_child(screen)
	await frames()
	check(screen.get_node("Root/Background").texture.resource_path == "res://asset/BG/BG.png", "loading uses the requested original background")
	var bar: ProgressBar = screen.progress_bar
	check(bar.size == Vector2(280, 12) and bar.anchor_right == 1.0 and bar.anchor_bottom == 1.0 and not bar.show_percentage, "small bar is anchored at the bottom right without extra text")
	check(bar.get_theme_stylebox("fill").bg_color == Color.WHITE, "progress fill is white")
	var invalid: PackedScene = await screen.prepare_scene("res://missing-loading-fixture.tscn")
	check(invalid == null and not screen.last_error.is_empty() and not get_tree().paused, "failed resource preparation reports an error without pausing or changing scenes")
	screen.queue_free()
	await frames()
	get_tree().node_added.connect(func(node: Node) -> void:
		if node.name == &"LoadingScreen": active_loading = node
	)
	var menu: Node = load(SaveManager.TITLE_SCENE).instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	menu.game_fade_duration = 0.02
	menu._show_main_menu()
	menu._on_start_pressed()
	menu._on_start_pressed()
	await get_tree().scene_changed
	await frames(8)
	check(get_tree().current_scene.scene_file_path == SaveManager.NEW_GAME_SCENE and get_tree().get_first_node_in_group("Player") != null, "threaded New Game enters the real map")
	check(not is_instance_valid(active_loading) and not get_tree().paused and not SaveManager.pending_continue, "loading survives title removal and releases the restored game")
	check(SaveManager.active_slot == SaveManager.NO_SAVE_SLOT and disk_files() == before, "New Game loading preserves the unsaved-run contract and every old save")
	check(loading_frames > 2 and samples.size() >= 2 and samples[0] == 0.0 and samples[-1] == 1.0, "frames continue rendering while the resource reports actual progress")
	var monotonic := true
	for index in range(1, samples.size()):
		if samples[index] < samples[index - 1]: monotonic = false
	check(monotonic, "loading progress never moves backwards")
	print("LOADING SAMPLES ", samples, " frames=", loading_frames)
	SaveManager.return_to_title()
	await get_tree().scene_changed
	await frames(4)
	menu = get_tree().current_scene
	menu.game_fade_duration = 0.02
	menu._show_main_menu()
	menu._on_continue_pressed()
	menu._begin_selected_game(2, false)
	await get_tree().scene_changed
	await frames(8)
	var player: Node = get_tree().get_first_node_in_group("Player")
	check(SaveManager.active_slot == 2 and player.stats.hp == 72 and is_equal_approx(player.global_position.x, 325.0), "Continue restores the selected slot behind the loading screen")
	check(not is_instance_valid(active_loading) and not get_tree().paused and not SaveManager.pending_continue, "cached Continue also cleans up loading and unpauses")
	check(disk_files() == before, "Continue loading never rewrites any save")
	print("LOADING RESULT checks=", checks, " failures=", failures)
	get_tree().quit(1 if failures else 0)
