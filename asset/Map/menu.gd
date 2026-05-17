extends Node2D

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://opening.tscn")


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://continue")


func _on_option_pressed() -> void:
	get_tree().change_scene_to_file("res://option")


func _on_quit_pressed() -> void:
	get_tree().quit()
