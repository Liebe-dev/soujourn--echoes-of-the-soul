class_name WeaponData
extends Node2D

@export_category("Identity")
@export var weapon_id: String = "saber"
@export var display_name: String = "Saber"

@export_category("Combat")
@export_range(0, 10000, 1, "or_greater") var damage: int = 1
@export_range(0.0, 10.0, 0.05, "or_greater") var combo_finisher_multiplier: float = 1.2
@export var stamina_cost: int = 0
@export var combo_length: int = 4

@export_category("Requirements and Scaling")
@export var requirements: Dictionary[StringName, int] = {}
@export var attribute_scaling: Dictionary[StringName, float] = {&"prowess": 1.0, &"strength": 1.0}

func meets_requirements(attributes: Dictionary) -> bool:
	for id in requirements:
		if not attributes.has(id) or int(attributes[id]) < maxi(requirements[id], 0): return false
	return true

func attack_multiplier(attributes: Dictionary, config: Resource) -> float:
	var bonus: float = attributes.get(&"prowess", 0) * config.prowess_attack * attribute_scaling.get(&"prowess", 0.0)
	bonus += attributes.get(&"strength", 0) * config.strength_attack * attribute_scaling.get(&"strength", 0.0)
	return maxf(0.0, 1.0 + bonus) * (1.0 if meets_requirements(attributes) else config.unmet_requirement_factor)

func requirement_text(attributes: Dictionary) -> String:
	var parts: PackedStringArray = []
	for id in requirements: parts.append("%s %d/%d" % [str(id).capitalize(), attributes.get(id, 0), requirements[id]])
	return "No requirements" if parts.is_empty() else ", ".join(parts)

@export_category("Animation")
@export var animation_prefix: String = "saber"
@export_category("Hitbox")
@export var hitbox_offset: Vector2 = Vector2.ZERO
@export var hitbox_size: Vector2 = Vector2.ZERO
@export_category("Attack Timing")
@export var attack_active_start: Array[float] = [0.10, 0.10, 0.10, 0.15]
@export var attack_active_end: Array[float] = [0.20, 0.20, 0.20, 0.30]
