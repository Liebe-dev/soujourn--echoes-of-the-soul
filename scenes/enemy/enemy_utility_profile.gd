extends Resource
## Response curves map normalized inputs to [0, 1]. Each enemy can own a profile.

@export_group("Response Curves")
@export var health_confidence: Curve = _curve([Vector2(0, 0), Vector2(0.2, 0.1), Vector2(0.6, 0.8), Vector2(1, 1)])
@export var flee_need: Curve = _curve([Vector2(0, 1), Vector2(0.2, 1), Vector2(0.6, 0), Vector2(1, 0)])
@export var player_weakness: Curve = _curve([Vector2(0, 1), Vector2(1, 0)])
@export var attack_distance: Curve = _curve([Vector2(0, 1), Vector2(1, 0.7)])
@export var threat_distance: Curve = _curve([Vector2(0, 1), Vector2(1, 0)])
@export var ally_support: Curve = _curve([Vector2(0, 0), Vector2(1, 1)])

@export_group("Action Weights")
@export_range(0.0, 1.0) var melee_weight := 1.0
@export_range(0.0, 1.0) var leap_weight := 0.9
@export_range(0.0, 1.0) var chase_weight := 0.65
@export_range(0.0, 1.0) var flee_weight := 1.0
@export_range(0.0, 1.0) var patrol_weight := 1.0
@export_range(0.0, 1.0) var idle_weight := 1.0
@export_range(1, 10) var full_support_allies := 3

static func _curve(points: Array[Vector2]) -> Curve:
	var result := Curve.new()
	for point in points: result.add_point(point)
	return result

static func response(curve: Curve, value: float) -> float:
	var normalized := clampf(value, 0.0, 1.0)
	if curve == null or curve.point_count == 0: return normalized
	return clampf(curve.sample(normalized), 0.0, 1.0)
