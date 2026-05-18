extends Node2D

@export var weapon_type: String = "longsword"
#Vũ khí: greatsword, longsword, machete, knife, ranged, spear, shield
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D 
func _ready() -> void:
	if hitbox_shape:
		hitbox_shape.disabled = true
	
	var player = get_parent().get_parent()
	if player and player.has_signal("player_attacked"):
		player.player_attacked.connect(_on_player_attacked)

func _on_player_attacked() -> void:
	match weapon_type:
		"longsword":
			#Chạy anim đánh
			print("attacked")
			if hitbox_shape.disabled:
				hitbox_shape.disabled = false
				await get_tree().create_timer(0.2).timeout
				hitbox_shape.disabled = true

func _on_hitbox_body_entered(body: CharacterBody2D) -> void:
	if body.has_method("take_damage"):
		print("enemy took damage")
