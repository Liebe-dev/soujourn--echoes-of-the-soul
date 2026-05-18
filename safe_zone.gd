extends Area2D
## Restores stagger thresholds when the player enters. Place in level as Area2D.

func _ready() -> void:
	add_to_group("safe_zone")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	var hud := _find_hud(body.get_tree())
	if hud and hud.has_method("restore_stagger_thresholds"):
		hud.restore_stagger_thresholds()

func _find_hud(tree: SceneTree) -> Node:
	var root := tree.current_scene
	if root == null:
		return null
	return root.find_child("hud", true, false)
