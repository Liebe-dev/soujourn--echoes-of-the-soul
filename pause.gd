extends Control

var pause_toggle = false


func _ready() -> void:
	visible = false 


func pause_and_unpause():
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused

	if get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		move_to_front()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		pause_and_unpause()
		$zw.play()

func _on_resume_pressed() -> void:
	pause_and_unpause()


func _on_restart_pressed() -> void:
	pause_and_unpause()
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	$c.play()
	$fade_trans.show()
	$fade_trans/fade.play("fade_out")
	await $fade_trans/fade.animation_finished
	get_tree().change_scene_to_file("res://menu.tscn")
	
