extends Area2D

@export var checkpoint_id: String = "campfire_01"
@export var display_name: String = "Campfire"
@export_multiline var rest_hint: String = "Press F to rest"

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
@onready var load_slot_menu: Control = $PromptLayer/LoadSlotMenu
@onready var save_slot_menu: Control = $PromptLayer/SaveSlotMenu
@onready var cinematic_camera: Camera2D = $Camera2D

const TITLE_SCENE := "res://asset/UI/menu.tscn"

var _player: CharacterBody2D
var _player_in_range := false
var _is_player_resting := false
var _rest_cooldown := 0.0
const REST_COOLDOWN_SEC := 0.35
@export var detect_radius: float = 96.0

func _ready() -> void:
	add_to_group("campfire")
	prompt_panel.hide()
	saved_label.hide()
	saved_label.modulate.a = 0.0
	
	# Đảm bảo màn hình không bị tối lúc mới vào game
	if transition_rect:
		transition_rect.modulate.a = 0.0
	if rest_menu:
		rest_menu.hide()
	if load_slot_menu:
		load_slot_menu.hide()
	if save_slot_menu:
		save_slot_menu.hide()
	_setup_rest_menu_buttons()
	if cinematic_camera:
		cinematic_camera.enabled = false
		
	if prompt_label:
		prompt_label.text = rest_hint
	if checkpoint_id.is_empty():
		checkpoint_id = name.to_lower().replace(" ", "_")

func get_checkpoint_id() -> String:
	return checkpoint_id

func _physics_process(delta: float) -> void:
	if _rest_cooldown > 0.0:
		_rest_cooldown = maxf(_rest_cooldown - delta, 0.0)
	if _is_player_resting:
		return

	if _player_in_range:
		if _player == null or not _player is Node2D or _player.global_position.distance_to(global_position) > detect_radius:
			_player_in_range = false
			_player = null
			prompt_panel.hide()

	if not _player_in_range:
		var candidate := _find_nearby_candidate()
		if candidate != null:
			_player = candidate
			_player_in_range = true
			if not _is_player_resting:
				prompt_panel.show()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or _player == null:
		return
	if _rest_cooldown > 0.0:
		return
	if not event.is_action_pressed("Interact"):
		return
		
	get_viewport().set_input_as_handled()
	if _is_player_resting:
		# Bạn có thể tắt tính năng "bấm F để đứng lên" vì bây giờ sẽ thoát bằng nút "Leave" trong RestMenu
		# Nhưng tôi vẫn giữ lại ở đây để bạn test
		_stand_up()
	else:
		_sit_and_save()

func _on_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("Player") or body.has_method("enter_rest")):
		return
	_player = body
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

func _sit_and_save() -> void:
	if _player == null:
		return

	_is_player_resting = true
	prompt_panel.hide()
	player_started_rest.emit()

	var face_left := _player.global_position.x > global_position.x
	if _player.has_method("enter_rest"):
		_player.enter_rest(Vector2.ZERO, face_left)

	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(transition_rect, "modulate:a", 1.0, 0.7)
	await fade_out_tween.finished
	
	if _player.has_method("play_rest_animation"):
		_player.play_rest_animation()
	var fixed_distance = 60.0

	if face_left:
		_player.global_position.x = global_position.x + fixed_distance
	else:
		_player.global_position.x = global_position.x - fixed_distance

	SaveManager.heal_player_full()
	SaveManager.save_at_campfire(self)
	
	if cinematic_camera:
		cinematic_camera.enabled = true
		cinematic_camera.global_position = global_position
		cinematic_camera.offset = Vector2(0, -70.0)
		cinematic_camera.make_current()
		cinematic_camera.global_position = global_position
		cinematic_camera.zoom = Vector2(3.0, 3.0) 
		cinematic_camera.make_current() 

	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(transition_rect, "modulate:a", 0.0, 2.0) 
	await fade_in_tween.finished

	if rest_menu:
		rest_menu.show()
	_show_saved_flash()

func _stand_up() -> void:
	if not _is_player_resting:
		return
		
	# Ẩn menu
	if rest_menu:
		rest_menu.hide()
	if load_slot_menu:
		load_slot_menu.hide()
	if save_slot_menu:
		save_slot_menu.hide()

	# 1. Fade màn hình tối đi (0.5 giây)
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(transition_rect, "modulate:a", 1.0, 0.5)
	await fade_out_tween.finished
	
	# (Màn hình đang tối) Trả lại quyền điều khiển
	_is_player_resting = false
	if _player and _player.has_method("exit_rest"):
		_player.exit_rest()
		
	# Tắt camera cinematic để Godot tự động trả về camera mặc định của người chơi
	if cinematic_camera:
		cinematic_camera.enabled = false
		
	_rest_cooldown = REST_COOLDOWN_SEC
	player_finished_rest.emit()

	# 2. Fade màn hình sáng trở lại (0.5 giây)
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(transition_rect, "modulate:a", 0.0, 0.5)
	await fade_in_tween.finished

	if _player_in_range:
		if prompt_label:
			prompt_label.text = rest_hint
		prompt_panel.show()


func _show_saved_flash(message: String = "Saved") -> void:
	saved_label.text = message
	saved_label.show()
	var tween := create_tween()
	tween.tween_property(saved_label, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.2)
	tween.tween_property(saved_label, "modulate:a", 0.0, 0.4)
	await tween.finished
	saved_label.hide()


func _setup_rest_menu_buttons() -> void:
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
		button.pressed.connect(_on_slot_selected.bind(slot, is_load_menu))
		slot_list.add_child(button)

	if not back_button.pressed.is_connected(_on_slot_menu_back_pressed):
		back_button.pressed.connect(_on_slot_menu_back_pressed)


func _format_slot_label(slot: int, is_load_menu: bool) -> String:
	var info := SaveManager.get_slot_info(slot)
	if info.get("empty", true):
		return "Slot %d - Empty" % slot
	var checkpoint := str(info.get("checkpoint_id", ""))
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
	if rest_menu:
		rest_menu.hide()
	if load_slot_menu:
		load_slot_menu.hide()
	if save_slot_menu:
		save_slot_menu.hide()
	_refresh_slot_menus()
	menu.show()


func _hide_slot_menus() -> void:
	if load_slot_menu:
		load_slot_menu.hide()
	if save_slot_menu:
		save_slot_menu.hide()
	if rest_menu and _is_player_resting:
		rest_menu.show()


func _on_save_pressed() -> void:
	if save_slot_menu:
		_show_slot_menu(save_slot_menu)


func _on_load_pressed() -> void:
	if load_slot_menu:
		_show_slot_menu(load_slot_menu)


func _on_leave_pressed() -> void:
	_hide_slot_menus()
	_stand_up()


func _on_title_pressed() -> void:
	_go_to_title()


func _on_slot_menu_back_pressed() -> void:
	_hide_slot_menus()


func _on_slot_selected(slot: int, is_load_menu: bool) -> void:
	if is_load_menu:
		_load_from_slot(slot)
	else:
		_save_to_slot(slot)


func _save_to_slot(slot: int) -> void:
	if SaveManager.save_at_campfire(self, slot):
		_hide_slot_menus()
		_show_saved_flash("Saved to slot %d" % slot)


func _load_from_slot(slot: int) -> void:
	if not SaveManager.has_save_in_slot(slot):
		_show_saved_flash("Slot %d is empty" % slot)
		return

	var fade_out_tween := create_tween()
	fade_out_tween.tween_property(transition_rect, "modulate:a", 1.0, 0.5)
	await fade_out_tween.finished

	var loaded := SaveManager.load_game_from_slot(slot, true)
	if not loaded:
		_show_saved_flash("Could not load slot %d" % slot)
		var fade_in_tween := create_tween()
		fade_in_tween.tween_property(transition_rect, "modulate:a", 0.0, 0.5)
		await fade_in_tween.finished
		_hide_slot_menus()
		return

	if SaveManager.pending_continue:
		return

	_hide_slot_menus()
	if _player and _player.has_method("play_rest_animation"):
		_player.play_rest_animation()

	var fade_in_tween := create_tween()
	fade_in_tween.tween_property(transition_rect, "modulate:a", 0.0, 0.5)
	await fade_in_tween.finished
	_show_saved_flash("Loaded slot %d" % slot)


func _go_to_title() -> void:
	var fade_out_tween := create_tween()
	fade_out_tween.tween_property(transition_rect, "modulate:a", 1.0, 0.8)
	await fade_out_tween.finished
	get_tree().change_scene_to_file(TITLE_SCENE)


func _find_nearby_candidate() -> Node2D:
	var root := get_tree().current_scene
	if root == null:
		return null
	var players := get_tree().get_nodes_in_group("Player")
	for p in players:
		if not p is Node2D:
			continue
		if p.global_position.distance_to(global_position) <= detect_radius:
			return p

	var stack: Array = [root]
	while stack.size() > 0:
		var n: Node = stack.pop_back() as Node
		for c in n.get_children():
			if c is Node:
				var node_c: Node = c
				if node_c.has_method("enter_rest") and node_c.global_position.distance_to(global_position) <= detect_radius:
					return node_c
				stack.push_back(node_c)
	return null
