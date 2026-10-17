extends Node
## Confirmed video preferences only; previews never overwrite the last saved state.
signal settings_changed
signal preview_changed

const CONFIG_PATH := "user://video.cfg"
const BACKUP_PATH := "user://video.cfg.bak"
const TEMP_PATH := "user://video.cfg.tmp"
const CONFIRMATION_SECONDS := 15.0
const FPS_OPTIONS := [30, 60, 120, 144, 0]
const MODES := ["windowed", "borderless", "fullscreen"]
const DEFAULTS := {"mode": "borderless", "width": 1280, "height": 720, "vsync": true, "max_fps": 60}
const WINDOW_SIZES := [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]

var confirmed: Dictionary = {}
var pending := false
var last_error := ""
var _candidate: Dictionary = {}
var _snapshot: Dictionary = {}
var _deadline_msec := 0
var _last_countdown := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	confirmed = normalize(_read_saved())
	# Preserve the project's design viewport and keep its aspect at all window sizes.
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	_apply_full.call_deferred(confirmed)

func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"

func desktop_size() -> Vector2i:
	if is_headless(): return Vector2i(1920, 1080)
	return DisplayServer.screen_get_size(get_window().current_screen)

func _usable_rect() -> Rect2i:
	if is_headless(): return Rect2i(0, 0, 1920, 1040)
	var rect := DisplayServer.screen_get_usable_rect(get_window().current_screen)
	if rect.size.x <= 0 or rect.size.y <= 0: return Rect2i(Vector2i.ZERO, Vector2i(1280, 720))
	return rect

func _window_limit() -> Vector2i:
	return (_usable_rect().size - Vector2i(32, 64)).max(Vector2i(320, 180))

func normalize(raw: Dictionary) -> Dictionary:
	var value := DEFAULTS.duplicate(true)
	if raw.get("mode") is String and raw.mode in MODES: value.mode = raw.mode
	if raw.get("vsync") is bool: value.vsync = raw.vsync
	if raw.get("max_fps") is int and raw.max_fps in FPS_OPTIONS: value.max_fps = raw.max_fps
	if raw.get("width") is int and raw.get("height") is int and raw.width >= 320 and raw.height >= 180 and raw.width <= 16384 and raw.height <= 16384:
		value.width = raw.width
		value.height = raw.height
	var requested := Vector2(value.width, value.height)
	var limit := Vector2(_window_limit())
	var scale := minf(1.0, minf(limit.x / requested.x, limit.y / requested.y))
	value.width = maxi(320, int(requested.x * scale))
	value.height = maxi(180, int(requested.y * scale))
	return value

func window_sizes() -> Array[Vector2i]:
	var values: Array[Vector2i] = []
	var limit := _window_limit()
	for resolution in WINDOW_SIZES:
		if resolution.x <= limit.x and resolution.y <= limit.y: values.append(resolution)
	var saved := Vector2i(confirmed.get("width", 1280), confirmed.get("height", 720))
	if not values.has(saved): values.append(saved)
	values.sort_custom(func(a: Vector2i, b: Vector2i): return a.x < b.x if a.x != b.x else a.y < b.y)
	return values

func defaults() -> Dictionary:
	return normalize(DEFAULTS)

func remaining_seconds() -> int:
	return maxi(0, int(ceil((_deadline_msec - Time.get_ticks_msec()) / 1000.0))) if pending else 0

func apply_settings(requested: Dictionary) -> String:
	if pending: return "Confirm or revert the current display change first."
	last_error = ""
	var next := normalize(requested)
	if next == confirmed: return ""
	var display_changed: bool = next.mode != confirmed.mode or (next.mode == "windowed" and (next.width != confirmed.width or next.height != confirmed.height))
	if not display_changed:
		last_error = _save(next)
		if not last_error.is_empty(): return last_error
		confirmed = next
		_apply_performance(confirmed)
		settings_changed.emit()
		return ""
	_snapshot = _capture_runtime()
	_candidate = next
	pending = true
	_deadline_msec = Time.get_ticks_msec() + int(CONFIRMATION_SECONDS * 1000.0)
	_last_countdown = -1
	_apply_full(next)
	set_process(true)
	preview_changed.emit()
	return ""

func confirm() -> String:
	if not pending: return ""
	if Time.get_ticks_msec() >= _deadline_msec:
		revert()
		return "Confirmation expired. Previous settings restored."
	if not is_headless() and get_window().mode != _mode_for(_candidate.mode):
		revert()
		return "The display mode could not be applied. Previous settings restored."
	last_error = _save(_candidate)
	if not last_error.is_empty():
		var problem := last_error
		revert()
		last_error = problem
		return problem
	confirmed = _candidate.duplicate(true)
	_finish_preview()
	settings_changed.emit()
	return ""

func revert() -> void:
	if not pending: return
	_restore_runtime(_snapshot)
	_finish_preview()
	settings_changed.emit()

func _finish_preview() -> void:
	pending = false
	_candidate.clear()
	_snapshot.clear()
	set_process(false)
	preview_changed.emit()

func _process(_delta: float) -> void:
	if not pending: return
	if Time.get_ticks_msec() >= _deadline_msec:
		revert()
	elif remaining_seconds() != _last_countdown:
		_last_countdown = remaining_seconds()
		preview_changed.emit()

func _mode_for(mode: String) -> Window.Mode:
	if mode == "fullscreen": return Window.MODE_EXCLUSIVE_FULLSCREEN
	if mode == "borderless": return Window.MODE_FULLSCREEN
	return Window.MODE_WINDOWED

func _apply_performance(value: Dictionary) -> void:
	Engine.max_fps = value.max_fps
	if not is_headless():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value.vsync else DisplayServer.VSYNC_DISABLED, get_window().get_window_id())

func _apply_full(value: Dictionary) -> void:
	if not is_headless():
		var window := get_window()
		var wanted := _mode_for(value.mode)
		# Leave fullscreen before changing window geometry, then enter the requested mode.
		if window.mode != wanted or value.mode == "windowed":
			window.mode = Window.MODE_WINDOWED
			window.borderless = false
		if value.mode == "windowed":
			var normalized := normalize(value)
			window.size = Vector2i(normalized.width, normalized.height)
			var usable := _usable_rect()
			window.position = usable.position + (usable.size - window.size) / 2
		window.mode = wanted
	_apply_performance(value)

func _capture_runtime() -> Dictionary:
	var window := get_window()
	return {"mode": window.mode, "size": window.size, "position": window.position, "screen": window.current_screen, "borderless": window.borderless, "fps": Engine.max_fps, "vsync": DisplayServer.window_get_vsync_mode(window.get_window_id()) if not is_headless() else DisplayServer.VSYNC_ENABLED}

func _restore_runtime(value: Dictionary) -> void:
	Engine.max_fps = value.fps
	if is_headless(): return
	var window := get_window()
	window.mode = Window.MODE_WINDOWED
	window.borderless = value.borderless
	var screen_count := DisplayServer.get_screen_count()
	window.current_screen = clampi(value.screen, 0, maxi(0, screen_count - 1))
	window.size = value.size
	window.position = value.position
	window.mode = value.mode
	DisplayServer.window_set_vsync_mode(value.vsync, window.get_window_id())

func _read_saved() -> Dictionary:
	for path in [CONFIG_PATH, BACKUP_PATH]:
		if not FileAccess.file_exists(path): continue
		var config := ConfigFile.new()
		if config.load(path) != OK or config.get_value("video", "version", 0) != 1: continue
		var value: Variant = config.get_value("video", "settings", {})
		if value is Dictionary: return value
	return DEFAULTS.duplicate(true)

func _save(value: Dictionary) -> String:
	var config := ConfigFile.new()
	config.set_value("video", "version", 1)
	config.set_value("video", "settings", value)
	if config.save(TEMP_PATH) != OK: return "Could not save video settings. Previous settings restored."
	var target := ProjectSettings.globalize_path(CONFIG_PATH)
	var backup := ProjectSettings.globalize_path(BACKUP_PATH)
	var temporary := ProjectSettings.globalize_path(TEMP_PATH)
	var had_previous := FileAccess.file_exists(CONFIG_PATH)
	if had_previous:
		if FileAccess.file_exists(BACKUP_PATH) and DirAccess.remove_absolute(backup) != OK: return "Could not update video settings backup."
		if DirAccess.rename_absolute(target, backup) != OK: return "Could not preserve previous video settings."
	if DirAccess.rename_absolute(temporary, target) != OK:
		if had_previous: DirAccess.rename_absolute(backup, target)
		return "Could not save video settings. Previous settings restored."
	return ""
