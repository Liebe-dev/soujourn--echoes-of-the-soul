extends Node2D
## Session-only visualization of the real combat shapes; never changes physics.

const HITBOX_LAYERS := 8 | 16
const HURTBOX_LAYERS := 2 | 4
const HITBOX_COLOR := Color(1.0, 0.15, 0.2, 0.45)
const HURTBOX_COLOR := Color(0.15, 0.65, 1.0, 0.40)

static var hitboxes_visible := false
static var hurtboxes_visible := false

var _shapes: Dictionary[int, CollisionShape2D] = {}
var _was_enabled := false

static func shows_hitboxes() -> bool:
	return OS.is_debug_build() and hitboxes_visible

static func shows_hurtboxes() -> bool:
	return OS.is_debug_build() and hurtboxes_visible

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_as_relative = false
	z_index = 4095
	get_tree().node_added.connect(_track_shape)
	get_tree().node_removed.connect(_forget_shape)
	for node in get_tree().root.find_children("*", "CollisionShape2D", true, false):
		_track_shape(node)

func _track_shape(node: Node) -> void:
	if node is CollisionShape2D:
		_shapes[node.get_instance_id()] = node

func _forget_shape(node: Node) -> void:
	_shapes.erase(node.get_instance_id())

func _process(_delta: float) -> void:
	var enabled := shows_hitboxes() or shows_hurtboxes()
	if enabled or _was_enabled:
		queue_redraw()
	_was_enabled = enabled

func _draw() -> void:
	if not shows_hitboxes() and not shows_hurtboxes(): return
	var world_to_local := global_transform.affine_inverse()
	for shape_node: CollisionShape2D in _shapes.values():
		if shape_node.disabled or shape_node.shape == null or shape_node.is_queued_for_deletion(): continue
		if shape_node.get_viewport() != get_viewport(): continue
		var collider := shape_node.get_parent() as CollisionObject2D
		if collider == null: continue
		var color := Color.TRANSPARENT
		if collider is Area2D and (collider.collision_layer & HITBOX_LAYERS) != 0:
			# The legacy AttackHitbox keeps an enabled shape while monitoring is off.
			if shows_hitboxes() and collider.monitoring:
				color = HITBOX_COLOR
		elif collider is CharacterBody2D and (collider.collision_layer & HURTBOX_LAYERS) != 0 and collider.has_method("take_damage"):
			# Player/EnemyBase receive damage through their body colliders.
			if shows_hurtboxes():
				color = HURTBOX_COLOR
		if color.a == 0.0: continue
		draw_set_transform_matrix(world_to_local * shape_node.global_transform)
		shape_node.shape.draw(get_canvas_item(), color)
	draw_set_transform_matrix(Transform2D.IDENTITY)
