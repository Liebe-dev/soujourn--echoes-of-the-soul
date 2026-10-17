extends Control
signal closed

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

@export_group("Settings Layout")
@export var panel_size := Vector2(1240, 820)
@export_range(0.0, 120.0, 1.0) var screen_margin := 40.0

@onready var general: Control = $HBoxContainer/Content/General
@onready var video: Control = $HBoxContainer/Content/Video
@onready var audio: Control = $HBoxContainer/Content/Audio
@onready var controls: Control = $HBoxContainer/Content/Controls
@onready var music_slider: HSlider = $HBoxContainer/Content/Audio/MusicSlider
@onready var sfx_slider: HSlider = $HBoxContainer/Content/Audio/SfxSlider
@onready var general_btn: Button = $HBoxContainer/Sidebar/GeneralButton
@onready var video_btn: Button = $HBoxContainer/Sidebar/VideoButton
@onready var audio_btn: Button = $HBoxContainer/Sidebar/AudioButton
@onready var controls_btn: Button = $HBoxContainer/Sidebar/ControlsButton
@onready var back_btn: Button = $HBoxContainer/Sidebar/BackButton

func _ready() -> void:
	general_btn.pressed.connect(_on_general)
	video_btn.pressed.connect(_on_video)
	audio_btn.pressed.connect(_on_audio)
	controls_btn.pressed.connect(_on_controls)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	visibility_changed.connect(_on_visibility_changed)
	resized.connect(_layout_window)
	controls.focus_targets_changed.connect(_refresh_focus)
	video.focus_targets_changed.connect(_refresh_focus)
	_show_page(general, general_btn)
	_sync_audio()
	_layout_window.call_deferred()

func _layout_window() -> void:
	var available := (size - Vector2.ONE * screen_margin * 2.0).max(Vector2.ONE)
	var design := panel_size.max($HBoxContainer.get_combined_minimum_size()).max(Vector2.ONE)
	var ratio := minf(1.0, minf(available.x / design.x, available.y / design.y))
	$HBoxContainer.size = design
	$HBoxContainer.scale = Vector2.ONE * ratio
	$HBoxContainer.position = (size - design * ratio) * 0.5

func open() -> void:
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sync_audio()
	_refresh_focus()
	general_btn.grab_focus()

func close() -> void:
	hide()
	closed.emit()

func _on_visibility_changed() -> void:
	if visible and is_node_ready():
		_sync_audio()
		_refresh_focus()
		general_btn.grab_focus()

func _show_page(page: Control, selected: Button) -> void:
	for item in [general, video, audio, controls]: item.visible = item == page
	for button in [general_btn, video_btn, audio_btn, controls_btn]:
		button.modulate = Color(1, 0.9, 0.3) if button == selected else Color.WHITE
	_refresh_focus()
	_layout_window.call_deferred()

func _refresh_focus() -> void:
	var targets: Array[Control] = [general_btn, video_btn, audio_btn, controls_btn, back_btn]
	if audio.visible:
		if music_slider.editable: targets.append(music_slider)
		if sfx_slider.editable: targets.append(sfx_slider)
	if controls.is_visible_in_tree(): targets.append_array(controls.focus_targets())
	if video.is_visible_in_tree(): targets.append_array(video.focus_targets())
	if video.is_confirming(): targets = video.focus_targets()
	for index in targets.size():
		var current := targets[index]
		var previous := current.get_path_to(targets[posmod(index - 1, targets.size())])
		var next := current.get_path_to(targets[(index + 1) % targets.size()])
		current.focus_previous = previous
		current.focus_next = next
		current.focus_neighbor_top = previous
		current.focus_neighbor_bottom = next
		if current is Button:
			current.focus_neighbor_left = previous
			current.focus_neighbor_right = next

func _sync_audio() -> void:
	for pair in [[MUSIC_BUS, music_slider], [SFX_BUS, sfx_slider]]:
		var index := AudioServer.get_bus_index(pair[0])
		var slider: HSlider = pair[1]
		slider.editable = index >= 0
		slider.focus_mode = Control.FOCUS_ALL if slider.editable else Control.FOCUS_NONE
		if index >= 0:
			slider.set_value_no_signal(0.0 if AudioServer.is_bus_mute(index) else db_to_linear(AudioServer.get_bus_volume_db(index)))

func _set_volume(bus: StringName, value: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0: return
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))

func _on_music_changed(value: float) -> void:
	_set_volume(MUSIC_BUS, value)

func _on_sfx_changed(value: float) -> void:
	_set_volume(SFX_BUS, value)

func _on_general() -> void:
	_show_page(general, general_btn)

func _on_video() -> void:
	_show_page(video, video_btn)

func _on_audio() -> void:
	_show_page(audio, audio_btn)

func _on_controls() -> void:
	_show_page(controls, controls_btn)

func _input(event: InputEvent) -> void:
	if controls.is_capturing() or controls.reset_dialog.visible: return
	if video.is_confirming() or video.popup_is_open(): return
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _on_back_button_pressed() -> void:
	close()
