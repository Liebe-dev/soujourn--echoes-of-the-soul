extends RefCounted
## Dispatch an attack to a receiver. A boolean response is authoritative.

static func try_apply(receiver: Node2D, amount: int, origin: Vector2) -> bool:
	if amount <= 0:
		return false
	if receiver is EnemyBase:
		return receiver.take_damage(amount, origin)

	# Older prototypes return void. Only observable HP loss confirms their hit.
	var before: Variant = receiver.get(&"current_health")
	var accepted: Variant = receiver.take_damage(amount, origin)
	if accepted is bool:
		return accepted
	if accepted != null or before == null or not is_instance_valid(receiver):
		return false
	var after: Variant = receiver.get(&"current_health")
	return after != null and after < before
