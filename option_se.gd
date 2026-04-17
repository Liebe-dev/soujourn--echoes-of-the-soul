extends Button
@onready var hover_image = $OptionSe
var original_scale = Vector2.ONE
func _ready():
	hover_image.hide()
	original_scale = hover_image.scale
	hover_image.pivot_offset = hover_image.size / 2
# Called when the node enters the scene tree for the first time.
func _on_mouse_entered() -> void:
	hover_image.show()

func _on_mouse_exited() -> void:
	hover_image.hide()


func _on_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(hover_image, "scale", original_scale * 2.0, 1)
