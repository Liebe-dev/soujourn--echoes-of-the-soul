extends Node2D

const PLAYER_SCENE = preload("res://scenes/adel/playable_adel.tscn")

@onready var spawn_point = $SpawnPoint_Default
func _ready():
	spawn_player()
func spawn_player():
	var player = PLAYER_SCENE.instantiate()
	player.global_position = spawn_point.global_position
	add_child(player)
