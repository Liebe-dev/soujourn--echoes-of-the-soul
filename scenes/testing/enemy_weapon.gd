extends Node2D

@onready var hitbox = $Hitbox/CollisionShape2D

func _ready() -> void:
	hitbox.disabled = true

func _process(delta: float) -> void:
	pass

func _on_timer_timeout() -> void:
	hitbox.disabled = !hitbox.disabled

func _on_hitbox_body_entered(body: Node2D) -> void:
	if "is_guarding" in body:
		var enemy_direction = global_position.x - body.global_position.x
		var is_facing_enemy = false
		if (enemy_direction > 0 and body.facing_direction > 0):
			is_facing_enemy = true
		elif (enemy_direction <= 0 and body.facing_direction < 0):
			is_facing_enemy = true
		if body.is_guarding == true and is_facing_enemy:
			print("player blocked the hit")
		elif body.has_method("take_damage"):
			body.take_damage(12, global_position)
