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
@onready var cinematic_camera: Camera2D = $Camera2D

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
