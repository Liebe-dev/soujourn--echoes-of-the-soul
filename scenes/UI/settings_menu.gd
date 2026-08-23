
extends Control

@onready var general = $HBoxContainer/Content/General
@onready var video = $HBoxContainer/Content/Video
@onready var audio = $HBoxContainer/Content/Audio
@onready var controls = $HBoxContainer/Content/Controls

@onready var music_slider = $HBoxContainer/Content/Audio/MusicSlider
@onready var sfx_slider = $HBoxContainer/Content/Audio/SfxSlider

@onready var general_btn = $HBoxContainer/Sidebar/GeneralButton
@onready var video_btn = $HBoxContainer/Sidebar/VideoButton
@onready var audio_btn = $HBoxContainer/Sidebar/AudioButton
@onready var controls_btn = $HBoxContainer/Sidebar/ControlsButton
@onready var back_btn = $HBoxContainer/Sidebar/BackButton
func _ready():
	hide_all()
	general.visible = true
	highlight_button(general_btn)

	general_btn.pressed.connect(_on_general)
	video_btn.pressed.connect(_on_video)
	audio_btn.pressed.connect(_on_audio)
	controls_btn.pressed.connect(_on_controls)

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

func hide_all():
	general.visible = false
	video.visible = false
	audio.visible = false
	controls.visible = false

func reset_highlight():
	for b in [general_btn, video_btn, audio_btn, controls_btn]:
		b.modulate = Color(1,1,1)

func highlight_button(btn):
	reset_highlight()
	btn.modulate = Color(1,0.9,0.3)

func _on_general():
	hide_all()
	general.visible = true
	highlight_button(general_btn)

func _on_video():
	hide_all()
	video.visible = true
	highlight_button(video_btn)

func _on_audio():
	hide_all()
	audio.visible = true
	highlight_button(audio_btn)

func _on_controls():
	hide_all()
	controls.visible = true
	highlight_button(controls_btn)

func _on_music_changed(value):
	AudioServer.set_bus_volume_db(1, linear_to_db(value))

func _on_sfx_changed(value):
	AudioServer.set_bus_volume_db(2, linear_to_db(value))

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		
		get_viewport().set_input_as_handled()

func _on_back_button_pressed() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
