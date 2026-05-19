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

	# If we have a cached player in range, validate they're still close enough.
	if _player_in_range:
		if _player == null or not _player is Node2D or _player.global_position.distance_to(global_position) > detect_radius:
			_player_in_range = false
			_player = null
			prompt_panel.hide()

		
	# Fallback: if nothing triggered Area2D, attempt to find a nearby player-like node
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
		
	# Lệnh này báo cho Godot biết: "Đống lửa đã nhận phím F rồi, đừng gửi phím F này cho ai khác nữa!"
	get_viewport().set_input_as_handled()
	if _is_player_resting:
		_stand_up()
	else:
		_sit_and_save()
func _on_body_entered(body: Node2D) -> void:
	# Accept any player-like body: prefer group "Player" or any body that provides `enter_rest()`
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

	await get_tree().create_timer(0.35).timeout

	SaveManager.heal_player_full()
	if SaveManager.save_at_campfire(self):
		await _show_saved_flash()
	else:
		await _show_saved_flash("Could not save")

	if _player_in_range and _is_player_resting:
		if prompt_label:
			prompt_label.text = "Press F to stand"
		prompt_panel.show()

func _stand_up() -> void:
	if not _is_player_resting:
		return
	_is_player_resting = false
	if _player and _player.has_method("exit_rest"):
		_player.exit_rest()
	_rest_cooldown = REST_COOLDOWN_SEC
	if prompt_label:
		prompt_label.text = rest_hint
	if _player_in_range:
		prompt_panel.show()
	else:
		prompt_panel.hide()
	player_finished_rest.emit()



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
	# radius in pixels to consider as 'in range'
	# use exported `detect_radius`
	
	var root := get_tree().current_scene
	if root == null:
		return null
	# First check nodes in Player group
	var players := get_tree().get_nodes_in_group("Player")
	for p in players:
		if not p is Node2D:
			continue
		if p.global_position.distance_to(global_position) <= detect_radius:
			return p

	# If none, scan scene for any node with enter_rest()
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
