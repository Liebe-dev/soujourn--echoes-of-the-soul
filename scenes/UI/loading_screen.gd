extends CanvasLayer
## Lives outside the outgoing title so it can cover scene entry and state restore.

var last_error := ""
var _target_scene := ""
var _owns_pause := false
var _finishing := false
@onready var progress_bar: ProgressBar = $Root/Progress

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().scene_changed.connect(_on_scene_changed)

func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

func prepare_scene(path: String) -> PackedScene:
	progress_bar.value = 0.0
	# Submit the background and empty bar before starting any resource work.
	await _draw_frame()
	if not ResourceLoader.exists(path, "PackedScene"):
		last_error = "Scene is unavailable: " + path
		return null
	var error := ResourceLoader.load_threaded_request(path, "PackedScene")
	if error != OK:
		last_error = "Could not begin loading the game."
		return null
	while is_inside_tree():
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if not progress.is_empty(): progress_bar.value = maxf(progress_bar.value, float(progress[0]))
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var packed := ResourceLoader.load_threaded_get(path) as PackedScene
				if packed == null: last_error = "The loaded resource is not a game scene."
				progress_bar.value = 1.0
				await _draw_frame()
				return packed
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				last_error = "Could not load the game scene."
				return null
		await get_tree().process_frame
	return null

func watch_scene(path: String) -> void:
	_target_scene = path

func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.scene_file_path == _target_scene:
		# SaveManager restores the checkpoint by deferred call while we cover it.
		get_tree().paused = true
		_owns_pause = true

func _process(_delta: float) -> void:
	if not _owns_pause or _finishing: return
	var actor := get_tree().get_first_node_in_group("Player")
	if actor != null and actor.is_node_ready() and not SaveManager.pending_continue:
		_finishing = true
		_reveal_game()

func _reveal_game() -> void:
	progress_bar.value = 1.0
	await _draw_frame()
	get_tree().paused = false
	_owns_pause = false
	queue_free()

func _draw_frame() -> void:
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw

func _exit_tree() -> void:
	if _owns_pause: get_tree().paused = false
