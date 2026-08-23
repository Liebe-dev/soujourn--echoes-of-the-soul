extends Camera2D

@export var target: CharacterBody2D
@export var smooth_speed := 6.0
@export var look_ahead_distance := 120
@export var look_ahead_smooth := 4.0
@export var deadzone_size := Vector2(200,120)

var look_ahead := Vector2.ZERO

func _process(delta):

	if target == null:
		return

	var target_pos = target.global_position

	var velocity = target.velocity

	if abs(velocity.x) > 10:
		look_ahead.x = lerp(look_ahead.x, sign(velocity.x) * look_ahead_distance, look_ahead_smooth * delta)
	else:
		look_ahead.x = lerp(look_ahead.x, 0.0, look_ahead_smooth * delta)

	var cam_target = target_pos + look_ahead

	var diff = cam_target - global_position

	if abs(diff.x) < deadzone_size.x:
		cam_target.x = global_position.x

	if abs(diff.y) < deadzone_size.y:
		cam_target.y = global_position.y


	global_position = global_position.lerp(cam_target, smooth_speed * delta)

	global_position = global_position.round()
