extends RefCounted
## Only terrain layers should be included in obstacle_mask (default: layer 1).
static func point(body: Node2D) -> Vector2:
	var shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape != null:
		return shape.global_transform * shape.shape.get_rect().get_center()
	return body.global_position

static func can_see(observer: CollisionObject2D, candidate: Node2D, obstacle_mask: int = 1) -> bool:
	if not is_instance_valid(candidate) or candidate.is_queued_for_deletion(): return false
	var excluded: Array[RID] = [observer.get_rid()]
	# Player bodies may also occupy the terrain layer; do not treat the target as a wall.
	if candidate is CollisionObject2D: excluded.append(candidate.get_rid())
	var query := PhysicsRayQueryParameters2D.create(point(observer), point(candidate), obstacle_mask, excluded)
	query.collide_with_areas = false
	query.hit_from_inside = true
	return observer.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
