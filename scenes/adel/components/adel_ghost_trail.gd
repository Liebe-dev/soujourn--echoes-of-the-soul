class_name AdelGhostTrail
extends Node
## Owns dash trails and their lifetime, including scene/owner removal.
const INTERVAL := 0.05
const MAX_POOL := 24
const FADE_DURATION := 0.15
var _rig: Node2D
var _pool: Array[Node2D] = []
var _all: Array[Node2D] = []
var _generation := 0

func setup(rig: Node2D) -> void:
	_rig = rig
func start(duration: float = 0.25) -> void:
	_generation += 1
	_loop(duration, _generation)
func stop() -> void:
	_generation += 1
func _collect(node: Node, sprites: Array[Sprite2D]) -> void:
	if node is Sprite2D and node.visible: sprites.append(node)
	for child in node.get_children(): _collect(child, sprites)
func _spawn() -> void:
	var sprites: Array[Sprite2D] = []
	_collect(_rig, sprites)
	if sprites.is_empty(): return
	var ghost: Node2D
	while not _pool.is_empty() and ghost == null:
		var candidate: Node2D = _pool.pop_back()
		if is_instance_valid(candidate): ghost = candidate
	if ghost == null:
		ghost = Node2D.new()
		ghost.name = "GhostTrail"
		get_tree().current_scene.add_child(ghost)
		_all.append(ghost)
	ghost.visible = true
	ghost.modulate = Color(1, 1, 1, 0.6)
	for i in sprites.size():
		var src := sprites[i]
		var dst: Sprite2D
		if i < ghost.get_child_count(): dst = ghost.get_child(i) as Sprite2D
		else:
			dst = Sprite2D.new()
			dst.modulate = Color(0.2, 0.2, 0.2, 1.0)
			ghost.add_child(dst)
		dst.visible = true
		dst.texture = src.texture
		dst.hframes = src.hframes
		dst.vframes = src.vframes
		dst.frame = src.frame
		dst.flip_h = src.flip_h
		dst.flip_v = src.flip_v
		dst.global_transform = src.global_transform
	for i in range(sprites.size(), ghost.get_child_count()):
		ghost.get_child(i).visible = false
	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_recycle.bind(ghost))
func _recycle(ghost: Node2D) -> void:
	if not is_instance_valid(ghost): return
	ghost.visible = false
	if _pool.size() < MAX_POOL: _pool.append(ghost)
	else:
		_all.erase(ghost)
		ghost.queue_free()
func _loop(duration: float, generation: int) -> void:
	var elapsed := 0.0
	while elapsed < duration and generation == _generation and is_inside_tree():
		_spawn()
		await get_tree().create_timer(INTERVAL).timeout
		elapsed += INTERVAL
func _exit_tree() -> void:
	stop()
	for ghost in _all:
		if is_instance_valid(ghost): ghost.queue_free()
	_all.clear()
	_pool.clear()
