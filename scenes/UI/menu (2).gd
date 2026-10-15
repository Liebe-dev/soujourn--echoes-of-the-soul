extends Node2D

@onready var press_start_label = $PressStartLabel
@onready var menu_buttons = $Control
@onready var fade_rect = $FadeRect
@onready var bgm_player = $BGMPlayer
@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound
@onready var start_sound = $StartSound
@onready var settings_menu = $SettingsMenu

var is_waiting_for_start = false
var blink_tween : Tween

var is_intro_playing = true
var bg_fade_tween : Tween
var text_fade_in_tween : Tween
var _is_transitioning := false
var _slot_mode := "new"
var _pending_slot := -1
var _slot_overlay: Control
var _slot_list: VBoxContainer
var _slot_title: Label
var _slot_status: Label
var _slot_back: Button
var _overwrite_confirmation: ConfirmationDialog

func _ready():
	CursorPolicy.set_visible(get_viewport(), true, true)
	_build_slot_menu()
	$Control/Continue.disabled = not SaveManager.has_save()
	menu_buttons.hide()
	press_start_label.hide()
	for btn in menu_buttons.get_children():
		# Nếu node đó đúng là một nút bấm (Button)
		if btn is Button:
			# Bắt tín hiệu "chuột lia vào" và nối nó với hàm phát âm thanh
			btn.mouse_entered.connect(_on_button_hovered)
	for btn in menu_buttons.get_children():
		# Nếu node đó đúng là một nút bấm (Button)
		if btn is Button:
			# Bắt tín hiệu "chuột lia vào" và nối nó với hàm phát âm thanh
			btn.pressed.connect(_on_button_click)
	if fade_rect:
		fade_rect.modulate.a = 1.0
		fade_rect.show()
		bg_fade_tween = create_tween()
		bg_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.8)
		await bg_fade_tween.finished
		
	if not is_intro_playing: return
	
	fade_rect.hide()
	
	press_start_label.modulate.a = 0.0 
	press_start_label.show()
	
	text_fade_in_tween = create_tween()
	text_fade_in_tween.tween_property(press_start_label, "modulate:a", 1.0, 1.0)
	await text_fade_in_tween.finished
	
	if not is_intro_playing: return
	
	start_blinking()
	is_waiting_for_start = true
	is_intro_playing = false 

func start_blinking():
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(press_start_label, "modulate:a", 0.0, 1.5)
	blink_tween.tween_property(press_start_label, "modulate:a", 1.0, 1.5)
func _input(event):
	if _is_transitioning or _overwrite_confirmation.visible: return
	if _slot_overlay.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_slot_menu()
			get_viewport().set_input_as_handled()
		return
	if settings_menu.visible:
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		if is_intro_playing:
			is_intro_playing = false
			
			if bg_fade_tween: bg_fade_tween.kill()
			if text_fade_in_tween: text_fade_in_tween.kill()
			
			fade_rect.hide()
			press_start_label.show()
			press_start_label.modulate.a = 1.0
			
			start_blinking()
			
			set_deferred("is_waiting_for_start", true)
			return
			
		if is_waiting_for_start:
			is_waiting_for_start = false
			start_sound.play()
			if blink_tween:
				blink_tween.kill()
				
			var text_fade_out = create_tween()
			text_fade_out.tween_property(press_start_label, "modulate:a", 0.0, 0.5) 
			await text_fade_out.finished 
			
			press_start_label.hide()
			
			menu_buttons.modulate.a = 0.0 
			menu_buttons.show()
			
			var menu_fade_in = create_tween()
			menu_fade_in.tween_property(menu_buttons, "modulate:a", 1.0, 0.8)
func _on_start_pressed() -> void:
	if not _is_transitioning: _open_slot_menu("new")

func _on_continue_pressed() -> void:
	if not _is_transitioning: _open_slot_menu("continue")

func _build_slot_menu() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SaveSlotLayer"
	layer.layer = 40
	add_child(layer)
	_slot_overlay = Control.new()
	_slot_overlay.name = "SlotOverlay"
	_slot_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_slot_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.04, 0.06, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slot_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slot_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 14)
	margin.add_child(contents)
	_slot_title = Label.new()
	_slot_title.add_theme_font_size_override("font_size", 28)
	contents.add_child(_slot_title)
	_slot_status = Label.new()
	_slot_status.custom_minimum_size.x = 580
	_slot_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contents.add_child(_slot_status)
	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override("separation", 10)
	contents.add_child(_slot_list)
	_slot_back = Button.new()
	_slot_back.text = "Back"
	_slot_back.custom_minimum_size.y = 48
	_slot_back.pressed.connect(_close_slot_menu)
	contents.add_child(_slot_back)
	_overwrite_confirmation = ConfirmationDialog.new()
	_overwrite_confirmation.title = "Replace save slot"
	_overwrite_confirmation.ok_button_text = "Replace"
	_overwrite_confirmation.confirmed.connect(_confirm_new_game)
	_overwrite_confirmation.canceled.connect(func(): _pending_slot = -1)
	add_child(_overwrite_confirmation)
	_slot_overlay.hide()

func _open_slot_menu(mode: String) -> void:
	_slot_mode = mode
	_pending_slot = -1
	is_intro_playing = false
	is_waiting_for_start = false
	for tween in [blink_tween, bg_fade_tween, text_fade_in_tween]:
		if tween != null and tween.is_valid(): tween.kill()
	press_start_label.hide()
	fade_rect.hide()
	menu_buttons.hide()
	_slot_title.text = "New Game - Select Slot" if mode == "new" else "Continue - Select Slot"
	_slot_status.text = "Existing slots require confirmation. Other slots will be preserved." if mode == "new" else "Choose a save to continue. Unavailable saves are kept, not deleted."
	for child in _slot_list.get_children():
		_slot_list.remove_child(child)
		child.queue_free()
	for slot in range(1, SaveManager.MAX_SAVE_SLOTS + 1):
		var info := SaveManager.get_slot_info(slot)
		var button := Button.new()
		button.custom_minimum_size.y = 52
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if info.get("empty", true):
			button.text = "Slot %d - Empty" % slot
		elif not info.get("loadable", false):
			button.text = "Slot %d - Invalid save / missing scene" % slot
		else:
			var prefix := "Backup: " if info.get("recovered", false) else ""
			button.text = "Slot %d - %s%s (%d/%d HP)" % [slot, prefix, info.checkpoint_id, info.hp, info.max_hp]
		button.disabled = mode == "continue" and not info.get("loadable", false)
		button.pressed.connect(_on_slot_selected.bind(slot))
		_slot_list.add_child(button)
	_slot_overlay.show()
	_slot_back.disabled = false
	_slot_back.grab_focus()

func _close_slot_menu() -> void:
	if _is_transitioning: return
	_pending_slot = -1
	_overwrite_confirmation.hide()
	_slot_overlay.hide()
	menu_buttons.modulate.a = 1.0
	menu_buttons.show()
	$Control/Continue.disabled = not SaveManager.has_save()
	$Control/Start.grab_focus()

func _on_slot_selected(slot: int) -> void:
	if _is_transitioning or _overwrite_confirmation.visible: return
	if _slot_mode == "new" and SaveManager.has_save_in_slot(slot):
		_pending_slot = slot
		_overwrite_confirmation.dialog_text = "Start a new game in slot %d? This replaces only this slot and keeps a backup. Other slots will be preserved." % slot
		_overwrite_confirmation.popup_centered(Vector2i(560, 200))
	else:
		_begin_selected_game(slot, false)

func _confirm_new_game() -> void:
	var slot := _pending_slot
	_pending_slot = -1
	if slot > 0: _begin_selected_game(slot, true)

func _begin_selected_game(slot: int, overwrite: bool) -> void:
	if _is_transitioning: return
	_is_transitioning = true
	_slot_back.disabled = true
	for button in _slot_list.get_children(): button.disabled = true
	var original_volume: float = bgm_player.volume_db
	fade_rect.modulate.a = 0.0
	fade_rect.show()
	# The selection layer sits above FadeRect; fade it too while blocking input.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_slot_overlay, "modulate:a", 0.0, 0.8)
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	tween.tween_property(bgm_player, "volume_db", -50.0, 0.8)
	await tween.finished
	var entered: bool = SaveManager.start_new_game(slot, overwrite) if _slot_mode == "new" else SaveManager.continue_game(slot)
	if not entered:
		_is_transitioning = false
		fade_rect.hide()
		bgm_player.volume_db = original_volume
		_slot_overlay.modulate.a = 1.0
		_open_slot_menu(_slot_mode)
		_slot_status.text = SaveManager.last_error

func _on_option_pressed() -> void:
	if _is_transitioning: return
	settings_menu.show()
	settings_menu.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_quit_pressed() -> void:
	if _is_transitioning: return
	_is_transitioning = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	fade_rect.show() 
	
	var tween = create_tween()
	tween.set_parallel(true) 
	
	tween.tween_property($Control/Continue, "modulate:a", 0.0, 0.8)
	tween.tween_property($Control/Option, "modulate:a", 0.0, 0.8)
	tween.tween_property($Control/Start, "modulate:a", 0.0, 0.8)
	tween.tween_property(bgm_player, "volume_db", -50.0, 2)
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.2)
	
	await tween.finished
	get_tree().quit()
func _on_button_hovered():
	hover_sound.play()
	
func _on_button_click():
	click_sound.play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and is_node_ready():
		CursorPolicy.set_visible(get_viewport(), true, true)
