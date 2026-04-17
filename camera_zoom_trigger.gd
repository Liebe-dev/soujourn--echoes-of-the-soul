extends Area2D


@export var target_zoom: Vector2 = Vector2(2.0, 2.0)
@export var zoom_duration: float = 2.5

var _default_zoom: Vector2
var _tween: Tween

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var camera = body.get_node_or_null("Camera2D")
		
		if camera:
			_default_zoom = camera.zoom 
			
			if _tween and _tween.is_valid():
				_tween.kill()
				
			_tween = get_tree().create_tween()
			_tween.tween_property(camera, "zoom", target_zoom, zoom_duration) \
				.set_trans(Tween.TRANS_SINE) \
				.set_ease(Tween.EASE_OUT)
		var camera_def = create_tween()
		camera_def.tween_property(camera, "position", Vector2(600, 350), 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		var camera = body.get_node_or_null("Camera2D")
		
		if camera:
			if _tween and _tween.is_valid():
				_tween.kill()
				
			_tween = get_tree().create_tween()
			_tween.tween_property(camera, "zoom", _default_zoom, zoom_duration) \
				.set_trans(Tween.TRANS_SINE) \
				.set_ease(Tween.EASE_OUT)
