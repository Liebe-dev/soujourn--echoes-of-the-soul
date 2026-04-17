extends Area2D

@export_multiline var dialogue_text: String = "Mambo"
var player_in_range: bool = false

func _ready() -> void:
	# Cập nhật đường dẫn tới Label bên trong khung
	$DialogueBox/MarginContainer/Label.text = dialogue_text
	
	# Ẩn toàn bộ khung thoại lúc mới vào game
	$DialogueBox.hide() 

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		player_in_range = true
		$DialogueBox.show()
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		player_in_range = false
		$DialogueBox.hide() # Tự động cất khung thoại đi

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("Interact"):
		# Bật/tắt toàn bộ khung thoại
		$DialogueBox.visible = not $DialogueBox.visible
