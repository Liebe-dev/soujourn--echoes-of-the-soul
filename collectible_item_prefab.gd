extends Node2D

#Gọi biến
@onready var interaction = $Interact
@onready var icon = $Icon
@onready var notifier = $VisibleOnScreenNotifier2D
var player : CharacterBody2D = null

@export var detection_radius: float = 150.0 #Khoảng cách có thể tương tác

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction.force_update_transform()
	if icon and interaction and notifier:
		#Chỉnh kích thước của notifier và vị trí của label Interact
		var sprite_size = icon.texture.get_size() * icon.scale
		var label_size = interaction.get_combined_minimum_size()
		notifier.rect = Rect2(icon.position, sprite_size)
		
		var target_pos = Vector2.ZERO
		target_pos.x = icon.position.x - (sprite_size.x / 2)
		target_pos.y = icon.position.y - (sprite_size.y / 2) - label_size.y - 10
		
		interaction.position = target_pos
		interaction.visible = false
		
		#Lấy instance của Player để tính toán khoảng cách
		player = get_tree().get_first_node_in_group("playableAdel") as CharacterBody2D
		notifier.screen_entered.connect(_on_screen_entered)
		notifier.screen_exited.connect(_on_screen_exited)
		
		#Chỉ chạy func process khi vật phẩm có ở trên màn hình
		if not notifier.is_on_screen():
			set_process(false)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player:
		return
	#Khoảng cách giữa Player và Item
	var distance = global_position.distance_to(player.position)
	if distance <= detection_radius:
		interaction.visible = true
		if Input.is_action_just_pressed("Interact"):
			#Nhặt xong thì xóa
			print("Picked up.")
			queue_free()
	else:
		interaction.visible = false

func _on_screen_entered() -> void:
	set_process(true)
func _on_screen_exited() -> void:
	set_process(false)
