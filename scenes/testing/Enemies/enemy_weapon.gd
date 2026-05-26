extends Node2D

@onready var hitbox = $Hitbox/CollisionShape2D
@onready var spec_hitbox = $SpecialHitbox/CollisionShape2D

var indicator : Sprite2D = null
var decision : int = 0
var decided : float = false

func _ready() -> void:
	randomize()
	indicator = %Indicator
	indicator.visible = true
	hitbox.disabled = true
	spec_hitbox.disabled = true

func _process(delta: float) -> void:
	if not decided:
		decided = true
		decision = randi_range(0, 1)
		if decision == 1:
			indicator.visible = true

func _on_timer_timeout() -> void:
	if hitbox.disabled and spec_hitbox.disabled:
		if decision == 0:
			hitbox.disabled = false
		else:
			spec_hitbox.disabled = false
			indicator.visible = false
	elif not hitbox.disabled or not spec_hitbox.disabled:
		hitbox.disabled = true
		spec_hitbox.disabled = true
		decided = false

func _on_hitbox_body_entered(body: Node2D) -> void:
	if "is_doing_action" in body and "is_guarding" in body:
		var enemy_direction = global_position.x - body.global_position.x
		var is_facing_enemy = false
		if (enemy_direction > 0 and body.facing_direction > 0):
			is_facing_enemy = true
		elif (enemy_direction <= 0 and body.facing_direction < 0):
			is_facing_enemy = true
		if body.is_guarding == true and is_facing_enemy and body.holding_duration <= 0.2 and decision == 0:
			print("player deflected the hit")
		elif body.is_guarding == true and is_facing_enemy and body.holding_duration > 0.2 and decision == 0:
			print("player blocked the hit")
		else:
			body.take_damage(20, global_position)
		body.is_doing_action = false
