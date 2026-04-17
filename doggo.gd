extends CharacterBody2D

@export var move_distance: float = 160.0
@onready var sprite = $AnimatedSprite2D

func _ready():
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	if sprite.animation == "fade_in":
		move_wobtear_forward()

func move_wobtear_forward():
	var _direction = 1
