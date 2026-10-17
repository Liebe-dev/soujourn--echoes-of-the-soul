extends Node2D
## Owns title navigation; SaveManager owns all save I/O.
enum State { INTRO, AWAITING_START, REVEALING_MENU, MAIN_MENU, SLOTS, SETTINGS, TRANSITIONING }

@export_group("Title Timing")
@export_range(0.0, 5.0, 0.05) var intro_fade_duration := 1.8
@export_range(0.0, 5.0, 0.05) var prompt_fade_duration := 1.0
@export_range(0.05, 5.0, 0.05) var prompt_blink_duration := 1.5
@export_range(0.0, 5.0, 0.05) var prompt_exit_duration := 0.5
@export_range(0.0, 5.0, 0.05) var menu_fade_duration := 0.8
@export_range(0.0, 5.0, 0.05) var game_fade_duration := 0.8
@export_range(0.0, 5.0, 0.05) var quit_fade_duration := 1.2
@export_range(0.0, 5.0, 0.05) var quit_audio_duration := 2.0

@onready var press_start_label: Label = $Interface/Root/PressStartLabel
@onready var menu_buttons: Control = $Interface/Root/MainMenu
@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect
@onready var bgm_player: AudioStreamPlayer = $Audio/Music
@onready var settings_menu = $Interface/Root/SettingsMenu
@onready var slot_menu = $Interface/Root/SaveSlotMenu
@onready var _start_button: Button = $Interface/Root/MainMenu/Start
@onready var _continue_button: Button = $Interface/Root/MainMenu/Continue
@onready var _option_button: Button = $Interface/Root/MainMenu/Option
@onready var _hover_sound: AudioStreamPlayer = $Audio/HoverSound
@onready var _click_sound: AudioStreamPlayer = $Audio/ClickSound
@onready var _start_sound: AudioStreamPlayer = $Audio/StartSound

var state: State = State.INTRO
var _slot_mode: StringName = &"new"
var _visual_tween: Tween

func _ready() -> void:
	CursorPolicy.set_visible(get_viewport(), true, true)
	slot_menu.slot_selected.connect(_begin_selected_game)
	slot_menu.cancelled.connect(_close_slot_menu)
	settings_menu.closed.connect(_on_settings_closed)
	for button in menu_buttons.get_children():
		button.highlighted.connect(_hover_sound.play)
		button.pressed.connect(_click_sound.play)
	_enter_state(State.INTRO)
	fade_rect.modulate.a = 1.0
	press_start_label.modulate.a = 0.0
	_visual_tween = create_tween()
	_visual_tween.tween_property(fade_rect, "modulate:a", 0.0, intro_fade_duration)
	_visual_tween.tween_callback(func():
		fade_rect.hide()
		press_start_label.show())
	_visual_tween.tween_property(press_start_label, "modulate:a", 1.0, prompt_fade_duration)
	_visual_tween.tween_callback(_show_prompt)

func _enter_state(next: State) -> void:
	if _visual_tween != null:
		_visual_tween.kill()
		_visual_tween = null
	state = next
	press_start_label.visible = next in [State.AWAITING_START, State.REVEALING_MENU]
	menu_buttons.visible = next in [State.MAIN_MENU, State.SETTINGS]
	fade_rect.visible = next in [State.INTRO, State.TRANSITIONING]
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP if next == State.TRANSITIONING else Control.MOUSE_FILTER_IGNORE
	if next != State.SETTINGS: settings_menu.hide()
	if next not in [State.SLOTS, State.TRANSITIONING]: slot_menu.close()
	for button in menu_buttons.get_children():
		button.disabled = next != State.MAIN_MENU or (button == _continue_button and not SaveManager.has_save())
		button.focus_mode = Control.FOCUS_ALL if not button.disabled else Control.FOCUS_NONE
	if next == State.MAIN_MENU:
		menu_buttons.modulate.a = 1.0

func _show_prompt() -> void:
	_enter_state(State.AWAITING_START)
	press_start_label.modulate.a = 1.0
	_visual_tween = create_tween().set_loops()
	_visual_tween.tween_property(press_start_label, "modulate:a", 0.0, prompt_blink_duration)
	_visual_tween.tween_property(press_start_label, "modulate:a", 1.0, prompt_blink_duration)

func _input(event: InputEvent) -> void:
	if state not in [State.INTRO, State.AWAITING_START] or event.is_echo(): return
	var accepted := ((event is InputEventKey or event is InputEventMouseButton) and event.is_pressed()) or event.is_action_pressed("ui_accept")
	if not accepted: return
	get_viewport().set_input_as_handled()
	if state == State.INTRO:
		_show_prompt()
	else:
		_reveal_main_menu()

func _reveal_main_menu() -> void:
	_enter_state(State.REVEALING_MENU)
	_start_sound.play()
	_visual_tween = create_tween()
	_visual_tween.tween_property(press_start_label, "modulate:a", 0.0, prompt_exit_duration)
	_visual_tween.tween_callback(func():
		press_start_label.hide()
		menu_buttons.modulate.a = 0.0
		menu_buttons.show())
	_visual_tween.tween_property(menu_buttons, "modulate:a", 1.0, menu_fade_duration)
	_visual_tween.tween_callback(_show_main_menu)

func _show_main_menu(focus_button: Button = null) -> void:
	_enter_state(State.MAIN_MENU)
	if focus_button == null: focus_button = _start_button
	focus_button.grab_focus()

func _on_start_pressed() -> void:
	if state == State.MAIN_MENU: _open_slot_menu(&"new")

func _on_continue_pressed() -> void:
	if state == State.MAIN_MENU and not _continue_button.disabled: _open_slot_menu(&"continue")

func _open_slot_menu(mode: StringName) -> void:
	_slot_mode = mode
	_enter_state(State.SLOTS)
	var summaries: Array[Dictionary] = []
	for slot in range(1, SaveManager.MAX_SAVE_SLOTS + 1):
		summaries.append(SaveManager.get_slot_info(slot))
	slot_menu.open(mode, summaries)

func _close_slot_menu() -> void:
	if state == State.SLOTS: _show_main_menu()

func _begin_selected_game(slot: int, overwrite: bool) -> void:
	if state != State.SLOTS: return
	_enter_state(State.TRANSITIONING)
	slot_menu.set_busy(true)
	var original_volume := bgm_player.volume_db
	fade_rect.modulate.a = 0.0
	_visual_tween = create_tween().set_parallel(true)
	_visual_tween.tween_property(slot_menu, "modulate:a", 0.0, game_fade_duration)
	_visual_tween.tween_property(fade_rect, "modulate:a", 1.0, game_fade_duration)
	_visual_tween.tween_property(bgm_player, "volume_db", -50.0, game_fade_duration)
	await _visual_tween.finished
	var entered: bool = SaveManager.start_new_game(slot, overwrite) if _slot_mode == &"new" else SaveManager.continue_game(slot)
	if not entered:
		bgm_player.volume_db = original_volume
		_open_slot_menu(_slot_mode)
		slot_menu.status_label.text = SaveManager.last_error

func _on_option_pressed() -> void:
	if state != State.MAIN_MENU: return
	_enter_state(State.SETTINGS)
	settings_menu.open()

func _on_settings_closed() -> void:
	if state == State.SETTINGS: _show_main_menu(_option_button)

func _on_quit_pressed() -> void:
	if state != State.MAIN_MENU: return
	_enter_state(State.TRANSITIONING)
	menu_buttons.show()
	fade_rect.modulate.a = 0.0
	_visual_tween = create_tween().set_parallel(true)
	_visual_tween.tween_property(menu_buttons, "modulate:a", 0.0, menu_fade_duration)
	_visual_tween.tween_property(bgm_player, "volume_db", -50.0, quit_audio_duration)
	_visual_tween.tween_property(fade_rect, "modulate:a", 1.0, quit_fade_duration)
	_visual_tween.chain().tween_callback(get_tree().quit)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and is_node_ready():
		CursorPolicy.set_visible(get_viewport(), true, true)
