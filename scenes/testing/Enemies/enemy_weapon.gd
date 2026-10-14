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
	# Normal and special attacks share Player-owned defense rules.
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(20, global_position)
