extends Area2D

@export var checkpoint_id: String = "campfire_01"
@export var display_name: String = "Campfire"
@export_multiline var rest_hint: String = "Press F to rest"
@export var detect_radius: float = 96.0
@export var rest_offset: float = 60.0

@export_group("Transitions")
@export_range(0.01, 5.0) var enter_fade_out_duration := 0.7
@export_range(0.01, 5.0) var enter_fade_in_duration := 2.0
@export_range(0.01, 5.0) var leave_fade_duration := 0.5
@export_range(0.01, 5.0) var load_fade_duration := 0.5
@export_range(0.01, 5.0) var title_fade_duration := 0.8

enum Phase { IDLE, ENTERING, RESTING, LEAVING, LOADING, TITLE }
var _phase: Phase = Phase.IDLE
var _visit_generation := 0
var _transition_tween: Tween
var _previous_camera: Camera2D
var _is_player_resting: bool:
	get: return _phase != Phase.IDLE

signal player_started_rest
signal player_finished_rest

@onready var rest_position: Marker2D = $RestPosition
@onready var prompt_panel: PanelContainer = $PromptLayer/Prompt
@onready var prompt_label: Label = $PromptLayer/Prompt/MarginContainer/Label
@onready var saved_label: Label = $PromptLayer/SavedLabel
@onready var fire_particles: CPUParticles2D = $Visual/FireParticles
@onready var glow_light: PointLight2D = $Visual/GlowLight
@onready var transition_rect: ColorRect = $TransitionLayer/ColorRect
@onready var rest_menu: Control = $PromptLayer/RestMenu
@onready var btn_save: Button = $PromptLayer/RestMenu/save
@onready var btn_load: Button = $PromptLayer/RestMenu/load
@onready var btn_title: Button = $PromptLayer/RestMenu/title
@onready var btn_leave: Button = $PromptLayer/RestMenu/leave
@onready var btn_relica: Button = $PromptLayer/RestMenu/relica
@onready var load_slot_menu: Control = $PromptLayer/LoadSlotMenu
@onready var save_slot_menu: Control = $PromptLayer/SaveSlotMenu
@onready var cinematic_camera: Camera2D = $Camera2D

const UPGRADE_MENU_SCENE := preload("res://scenes/UI/campfire_upgrade_menu.tscn")
const REST_COOLDOWN_SEC := 0.35

var _player: CharacterBody2D
var _upgrade_menu: Control
var _player_in_range := false
var _rest_cooldown := 0.0
var _save_confirmation: ConfirmationDialog
var _pending_save_slot := -1
var _saved_flash_tween: Tween

#hàm hệ thống
func _ready() -> void:
	add_to_group("campfire")
	prompt_panel.hide()
	saved_label.hide()
	saved_label.modulate.a = 0.0
	
	if transition_rect:
		transition_rect.modulate.a = 0.0
	if rest_menu:
		rest_menu.hide()
	if load_slot_menu:
		load_slot_menu.hide()
	if save_slot_menu:
		save_slot_menu.hide()
		
	_setup_rest_menu_buttons()
	_setup_upgrade_menu()
	_save_confirmation = ConfirmationDialog.new()
	_save_confirmation.dialog_close_on_escape = false
	_save_confirmation.title = "Replace save slot"
	_save_confirmation.ok_button_text = "Replace"
	_save_confirmation.canceled.connect(func(): _pending_save_slot = -1)
	_save_confirmation.confirmed.connect(_confirm_save_slot)
	add_child(_save_confirmation)
	
	if cinematic_camera:
		cinematic_camera.enabled = false
		
	if prompt_label:
		prompt_label.text = rest_hint
	if checkpoint_id.is_empty():
		checkpoint_id = name.to_lower().replace(" ", "_")

func _physics_process(delta: float) -> void:
	if _rest_cooldown > 0.0:
		_rest_cooldown = maxf(_rest_cooldown - delta, 0.0)
	if is_ui_active():
		if not _player_is_live():
			_abort_visit()
		elif _player.has_method("is_campfire_ui_active") and not _player.is_campfire_ui_active():
			_abort_visit()
		elif _phase != Phase.TITLE and _player.has_method("is_in_rest_state") and not _player.is_in_rest_state():
			_abort_visit()
		return
	if _player_in_range and not _player_is_live():
		_player_in_range = false
		_player = null
		prompt_panel.hide()

func _input(event: InputEvent) -> void:
	if not is_ui_active(): return
	# Block these before GUI/unhandled handlers, including during either fade.
	if event.is_action("interact") or event.is_action("ui_cancel") or event.is_action("ui_close_dialog") or event.is_action("toggle_master_menu"):
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo(): return
	if is_ui_active():
		get_viewport().set_input_as_handled()
		return
	if not _player_in_range or not _player_is_live() or _rest_cooldown > 0.0 or get_tree().paused: return
	get_viewport().set_input_as_handled()
	_sit_and_save()

func get_checkpoint_id() -> String:
	return checkpoint_id

func is_ui_active() -> bool:
	return _phase != Phase.IDLE

func is_menu_ready() -> bool:
	return _phase == Phase.RESTING

func _player_is_live() -> bool:
	return is_instance_valid(_player) and _player.is_inside_tree() and not _player.is_queued_for_deletion()

func _visit_is_live(generation: int, phase: Phase) -> bool:
	return is_inside_tree() and not is_queued_for_deletion() and _visit_generation == generation and _phase == phase and _player_is_live()

func _fade_to(alpha: float, duration: float, generation: int, phase: Phase) -> bool:
	if not _visit_is_live(generation, phase): return false
	if _transition_tween != null and _transition_tween.is_valid(): _transition_tween.kill()
	_transition_tween = create_tween().set_ignore_time_scale(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_transition_tween.tween_property(transition_rect, "modulate:a", alpha, duration)
	# A finite timer still wakes a cancelled visit, unlike awaiting a killed Tween.
	await get_tree().create_timer(duration, true, false, true).timeout
	if not _visit_is_live(generation, phase): return false
	if _transition_tween != null and _transition_tween.is_valid(): _transition_tween.kill()
	_transition_tween = null
	transition_rect.modulate.a = alpha
	return true

func _hide_all_menus() -> void:
	for menu in [rest_menu, load_slot_menu, save_slot_menu, _upgrade_menu]:
		if is_instance_valid(menu): menu.hide()
	if is_instance_valid(_upgrade_menu): _upgrade_menu.panel.hide()
	if is_instance_valid(_save_confirmation): _save_confirmation.hide()
	_pending_save_slot = -1

func _set_cursor_ready(ready: bool) -> void:
	if _player_is_live() and _player.has_method("set_campfire_cursor_ready"):
		_player.set_campfire_cursor_ready(self, ready)

func _restore_camera() -> void:
	if is_instance_valid(cinematic_camera): cinematic_camera.enabled = false
	if is_instance_valid(_previous_camera) and _previous_camera.is_inside_tree(): _previous_camera.make_current()

func _release_visit() -> void:
	if _player_is_live() and _player.has_method("end_campfire_ui"):
		_player.end_campfire_ui(self)

func _abort_visit() -> void:
	_visit_generation += 1
	_phase = Phase.IDLE
	if _transition_tween != null and _transition_tween.is_valid(): _transition_tween.kill()
	_transition_tween = null
	_hide_all_menus()
	saved_label.hide()
	transition_rect.modulate.a = 0.0
	_restore_camera()
	_release_visit()
	_rest_cooldown = REST_COOLDOWN_SEC

func _exit_tree() -> void:
	_visit_generation += 1
	_phase = Phase.IDLE
	var scene := get_tree().current_scene
	if _player_is_live() and scene != null and scene.is_ancestor_of(_player) and _player.is_in_rest_state():
		_player.exit_rest()
	# Do not let this old scene write a cursor mode over the next title/game scene.
	_release_visit()

func _sit_and_save() -> void:
	if _phase != Phase.IDLE or not _player_is_live() or get_tree().paused: return
	if not _player.has_method("begin_campfire_ui") or not _player.begin_campfire_ui(self): return
	_visit_generation += 1
	var generation := _visit_generation
	_phase = Phase.ENTERING
	_previous_camera = get_viewport().get_camera_2d()
	_hide_all_menus()
	prompt_panel.hide()
	saved_label.hide()
	player_started_rest.emit()
	var face_left := _player.global_position.x > global_position.x
	_player.enter_rest(face_left)
	if not await _fade_to(1.0, enter_fade_out_duration, generation, Phase.ENTERING): return
	_player.play_rest_animation()
	_player.global_position.x = global_position.x + rest_offset if face_left else global_position.x - rest_offset
	SaveManager.heal_player_full()
	var saved := SaveManager.save_at_campfire(self)
	var result_message := "Saved" if saved else SaveManager.last_error
	if cinematic_camera:
		cinematic_camera.enabled = true
		cinematic_camera.global_position = global_position
		cinematic_camera.offset = Vector2(0, -70.0)
		cinematic_camera.zoom = Vector2(3.0, 3.0)
		cinematic_camera.make_current()
	if not await _fade_to(0.0, enter_fade_in_duration, generation, Phase.ENTERING): return
	_phase = Phase.RESTING
	rest_menu.show()
	_set_cursor_ready(true)
	_show_saved_flash(result_message)

func _stand_up() -> void:
	if _phase != Phase.RESTING or not _player_is_live(): return
	_phase = Phase.LEAVING
	var generation := _visit_generation
	_set_cursor_ready(false)
	_hide_all_menus()
	saved_label.hide()
	if not await _fade_to(1.0, leave_fade_duration, generation, Phase.LEAVING): return
	_player.prepare_to_exit_rest()
	_restore_camera()
	if not await _fade_to(0.0, leave_fade_duration, generation, Phase.LEAVING): return
	_player.exit_rest()
	_phase = Phase.IDLE
	_release_visit()
	_rest_cooldown = REST_COOLDOWN_SEC
	player_finished_rest.emit()
	_hide_all_menus()
	if _player_in_range:
		prompt_label.text = rest_hint
		prompt_panel.show()

#hàm nội bộ nhóm UI và hiệu ứng
func _setup_rest_menu_buttons() -> void:
	if btn_relica:
		btn_relica.text = "Upgrade Stats"
		btn_relica.pressed.connect(_on_relica_pressed)
	if btn_save:
		btn_save.pressed.connect(_on_save_pressed)
	if btn_load:
		btn_load.pressed.connect(_on_load_pressed)
	if btn_title:
		btn_title.pressed.connect(_on_title_pressed)
	if btn_leave:
		btn_leave.pressed.connect(_on_leave_pressed)
	if load_slot_menu:
		_populate_slot_menu(load_slot_menu, true)
	if save_slot_menu:
		_populate_slot_menu(save_slot_menu, false)

func _setup_upgrade_menu() -> void:
	_upgrade_menu = UPGRADE_MENU_SCENE.instantiate()
	_upgrade_menu.name = "CampfireUpgradeMenu"
	$PromptLayer.add_child(_upgrade_menu)
	_upgrade_menu.hide()
	if _upgrade_menu.has_signal("closed"):
		_upgrade_menu.closed.connect(_on_upgrade_menu_closed)

func _show_saved_flash(message: String = "Saved") -> void:
	if _saved_flash_tween and _saved_flash_tween.is_valid():
		_saved_flash_tween.kill()
	saved_label.text = message
	saved_label.show()
	saved_label.modulate.a = 1.0
	_saved_flash_tween = create_tween()
	_saved_flash_tween.tween_interval(1.2)
	_saved_flash_tween.tween_property(saved_label, "modulate:a", 0.0, 0.4)
	_saved_flash_tween.tween_callback(saved_label.hide)

func _populate_slot_menu(menu: Control, is_load_menu: bool) -> void:
	var slot_list: VBoxContainer = menu.get_node_or_null("SlotList")
	var back_button: Button = menu.get_node_or_null("Back")
	if slot_list == null or back_button == null:
		return

	for child in slot_list.get_children():
		child.queue_free()

	for slot in range(1, SaveManager.MAX_SAVE_SLOTS + 1):
		var button := Button.new()
		button.custom_minimum_size = Vector2(340, 48)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _format_slot_label(slot, is_load_menu)
		button.disabled = is_load_menu and not SaveManager.get_slot_info(slot).get("loadable", false)
		button.pressed.connect(_on_slot_selected.bind(slot, is_load_menu))
		slot_list.add_child(button)

	if not back_button.pressed.is_connected(_on_slot_menu_back_pressed):
		back_button.pressed.connect(_on_slot_menu_back_pressed)

func _format_slot_label(slot: int, is_load_menu: bool) -> String:
	var info := SaveManager.get_slot_info(slot)
	if info.get("empty", true):
		return "Slot %d - Empty" % slot
	if not info.get("loadable", false): return "Slot %d - Invalid save / missing scene" % slot
	var checkpoint := str(info.get("checkpoint_id", ""))
	if info.get("recovered", false): checkpoint = "Backup: " + checkpoint
	if checkpoint.is_empty():
		checkpoint = "Unknown checkpoint"
	var hp := int(info.get("hp", 0))
	var max_hp := int(info.get("max_hp", 100))
	if is_load_menu:
		return "Slot %d - %s (%d/%d HP)" % [slot, checkpoint, hp, max_hp]
	return "Slot %d - %s" % [slot, checkpoint]

func _refresh_slot_menus() -> void:
	if load_slot_menu:
		_populate_slot_menu(load_slot_menu, true)
	if save_slot_menu:
		_populate_slot_menu(save_slot_menu, false)

func _show_slot_menu(menu: Control) -> void:
	if not is_menu_ready(): return
	if rest_menu:
		rest_menu.hide()
	if load_slot_menu:
		load_slot_menu.hide()
	if save_slot_menu:
		save_slot_menu.hide()
	_refresh_slot_menus()
	menu.show()

func _hide_slot_menus() -> void:
	if not is_menu_ready():
		_hide_all_menus()
		return
	if load_slot_menu:
		load_slot_menu.hide()
	if save_slot_menu:
		save_slot_menu.hide()
	if _upgrade_menu:
		_upgrade_menu.hide()
	if rest_menu and _is_player_resting:
		rest_menu.show()

#hàm nội bộ nhóm hệ thống
func _save_to_slot(slot: int, allow_overwrite: bool = false) -> void:
	if not is_menu_ready(): return
	if SaveManager.save_at_campfire(self, slot, allow_overwrite):
		_hide_slot_menus()
		_show_saved_flash("Saved to slot %d" % slot)
	else:
		_show_saved_flash(SaveManager.last_error)

func _confirm_save_slot() -> void:
	if not is_menu_ready(): return
	var slot := _pending_save_slot
	_pending_save_slot = -1
	if slot > 0: _save_to_slot(slot, true)

func _load_from_slot(slot: int) -> void:
	if not is_menu_ready(): return
	if not SaveManager.get_slot_info(slot).get("loadable", false):
		_show_saved_flash("Slot %d is unavailable" % slot)
		return
	_phase = Phase.LOADING
	var generation := _visit_generation
	_set_cursor_ready(false)
	_hide_all_menus()
	if not await _fade_to(1.0, load_fade_duration, generation, Phase.LOADING): return
	var loaded := SaveManager.load_game_from_slot(slot, true)
	var result_message := "Loaded slot %d" % slot if loaded else SaveManager.last_error
	if loaded and SaveManager.pending_continue: return
	if loaded: _player.play_rest_animation()
	if not await _fade_to(0.0, load_fade_duration, generation, Phase.LOADING): return
	_phase = Phase.RESTING
	rest_menu.show()
	_set_cursor_ready(true)
	_show_saved_flash(result_message)

func _go_to_title() -> void:
	if not is_menu_ready(): return
	_phase = Phase.TITLE
	var generation := _visit_generation
	_set_cursor_ready(false)
	_hide_all_menus()
	if not await _fade_to(1.0, title_fade_duration, generation, Phase.TITLE): return
	if not SaveManager.return_to_title():
		_phase = Phase.RESTING
		transition_rect.modulate.a = 0.0
		rest_menu.show()
		_set_cursor_ready(true)
		_show_saved_flash(SaveManager.last_error)

#hàm tín hiệu
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	_player = body as CharacterBody2D
	_player_in_range = true
	if not _is_player_resting:
		prompt_panel.show()

func _on_body_exited(body: Node2D) -> void:
	if body != _player:
		return
	if _is_player_resting:
		return
	_player_in_range = false
	_player = null
	prompt_panel.hide()

func _on_relica_pressed() -> void:
	if not is_menu_ready(): return
	if _upgrade_menu == null:
		return
	if rest_menu:
		rest_menu.hide()
	if load_slot_menu:
		load_slot_menu.hide()
	if save_slot_menu:
		save_slot_menu.hide()
	_upgrade_menu.open(self)

func _on_upgrade_menu_closed() -> void:
	if rest_menu and is_menu_ready():
		rest_menu.show()

func _on_save_pressed() -> void:
	if save_slot_menu:
		_show_slot_menu(save_slot_menu)

func _on_load_pressed() -> void:
	if load_slot_menu:
		_show_slot_menu(load_slot_menu)

func _on_leave_pressed() -> void:
	_stand_up()

func _on_title_pressed() -> void:
	_go_to_title()

func _on_slot_menu_back_pressed() -> void:
	_hide_slot_menus()

func _on_slot_selected(slot: int, is_load_menu: bool) -> void:
	if not is_menu_ready() or _save_confirmation.visible: return
	if is_load_menu:
		_load_from_slot(slot)
	else:
		if SaveManager.needs_save_confirmation(slot):
			_pending_save_slot = slot
			_save_confirmation.dialog_text = "Replace slot %d with the current game? Other slots will be preserved." % slot
			_save_confirmation.popup_centered(Vector2i(520, 180))
		else:
			_save_to_slot(slot)
