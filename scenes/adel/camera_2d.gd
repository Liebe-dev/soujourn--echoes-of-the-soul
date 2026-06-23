extends Camera2D

@export_category("Camera Settings")
@export var follow_speed_x: float = 5.0
@export var follow_speed_y: float = 5.0 

@export_category("Lookahead (Nhìn trước)")
@export var lookahead_distance: float = 120.0
@export var lookahead_speed: float = 2.5

@export_category("Deadzone (Vùng chết)")
@export var vertical_deadzone: float = 60.0 

var target: CharacterBody2D
var _current_lookahead: float = 0.0
var _target_y: float = 0.0 

func _ready() -> void:
	top_level = true
	enabled = true
	
	if get_parent() is CharacterBody2D:
		target = get_parent()
		global_position = target.global_position
		_target_y = global_position.y

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var target_pos = target.global_position

	var dir = 1
	if "facing_direction" in target:
		dir = target.facing_direction
		
	var desired_lookahead = dir * lookahead_distance
	_current_lookahead = lerp(_current_lookahead, desired_lookahead, lookahead_speed * delta)
	
	var target_x = target_pos.x + _current_lookahead
	var ideal_center_y = target_pos.y - 30.0 
	

	if target.has_method("is_on_floor") and target.is_on_floor():
		_target_y = lerp(_target_y, ideal_center_y, follow_speed_y * 0.5 * delta)
	else:
		var diff_y = target_pos.y - _target_y
	
		if diff_y < -vertical_deadzone:
			_target_y = target_pos.y + vertical_deadzone
		elif diff_y > vertical_deadzone:
			_target_y = target_pos.y - vertical_deadzone
	var new_x = lerp(global_position.x, target_x, follow_speed_x * delta)
	var new_y = lerp(global_position.y, _target_y, follow_speed_y * delta)
	
	global_position = Vector2(new_x, new_y)
