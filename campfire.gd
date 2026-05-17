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

func _physics_process(_delta: float) -> void:
	if _is_player_resting or _player == null:
		return
	if rest_position and _player_in_range:
		_face_campfire()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or _player == null:
		return
	if not event.is_action_pressed("Interact"):
		return
	if _is_player_resting:
		_stand_up()
	else:
		_sit_and_save()

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

func _sit_and_save() -> void:
	if _player == null:
		return

	_is_player_resting = true
	prompt_panel.hide()
	player_started_rest.emit()

	var sit_pos := rest_position.global_position if rest_position else global_position
	var face_left := _player.global_position.x > global_position.x
	if _player.has_method("enter_rest"):
		_player.enter_rest(sit_pos, face_left)

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
	if prompt_label:
		prompt_label.text = rest_hint
	if _player_in_range:
		prompt_panel.show()
	else:
		prompt_panel.hide()
	player_finished_rest.emit()

func _face_campfire() -> void:
	if _player == null:
		return
	var anim: AnimatedSprite2D = _player.get_node_or_null("AnimatedSprite2D")
	if anim:
		anim.flip_h = _player.global_position.x > global_position.x

func _show_saved_flash(message: String = "Saved") -> void:
	saved_label.text = message
	saved_label.show()
	var tween := create_tween()
	tween.tween_property(saved_label, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.2)
	tween.tween_property(saved_label, "modulate:a", 0.0, 0.4)
	await tween.finished
	saved_label.hide()
