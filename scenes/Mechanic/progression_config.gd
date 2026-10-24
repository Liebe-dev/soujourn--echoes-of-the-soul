class_name ProgressionConfig
extends Resource
## Contributions use authored actor/weapon values as their base.
const ATTRIBUTES := [&"vitality", &"prowess", &"strength", &"agility", &"resistance", &"arts_compatibility", &"dark_arts_assimilation", &"faith"]
const LABELS := ["Vitality", "Prowess", "Strength", "Agility", "Resistance", "Arts Compatibility", "Dark Arts Assimilation", "Faith"]
const DESCRIPTIONS := [
	"Increases maximum HP.", "Increases attack through weapon scaling.",
	"Combines HP and weapon attack.", "Increases stamina and stamina regeneration.",
	"Increases HP. Enemy debuff resistance awaits supported debuffs; never affects Bleed/Fracture.",
	"Pending Arts: mana regeneration and magic damage.",
	"Increases Sentinel damage; milestones reduce upkeep. Ultimate gain and skill 1-4 costs await those systems.",
	"Pending Divine Arts: cooldown reduction and effect duration. Does not affect weapon Q/E."]

@export_group("Level and Resources")
@export_range(1, 100, 1, "or_greater") var points_per_level: int = 5
@export_range(1, 10000, 1, "or_greater") var base_hp: int = 100
@export_range(1.0, 10000.0, 1.0, "or_greater") var base_stamina: float = 100.0
@export_range(1, 10000, 1, "or_greater") var exp_per_level_base: int = 100
@export_group("Attribute Contributions")
@export var vitality_hp: float = 10.0
@export var strength_hp: float = 4.0
@export var resistance_hp: float = 2.0
@export var agility_stamina: float = 4.0
@export var agility_regen: float = 0.28
@export var prowess_attack: float = 0.02
@export var strength_attack: float = 0.012
@export_group("Dark Sentinel")
@export var assimilation_damage: float = 0.003
@export_range(1, 100, 1, "or_greater") var upkeep_step: int = 10
@export_range(0.0, 1.0, 0.01) var upkeep_reduction_per_step: float = 0.05
@export_range(0.0, 1.0, 0.01) var upkeep_reduction_cap: float = 0.5
@export_group("Equipment")
@export_range(0.0, 1.0, 0.01) var unmet_requirement_factor: float = 0.2

func empty_attributes() -> Dictionary:
	var result := {}
	for id in ATTRIBUTES: result[id] = 0
	return result

func max_hp(attributes: Dictionary) -> int:
	return maxi(1, int(round(base_hp + attributes.get(&"vitality", 0) * vitality_hp + attributes.get(&"strength", 0) * strength_hp + attributes.get(&"resistance", 0) * resistance_hp)))

func max_stamina(attributes: Dictionary) -> float:
	return maxf(1.0, base_stamina + attributes.get(&"agility", 0) * agility_stamina)

func stamina_regen(attributes: Dictionary, actor_base: float) -> float:
	return maxf(0.0, actor_base + attributes.get(&"agility", 0) * agility_regen)

func sentinel_damage(attributes: Dictionary) -> float:
	return maxf(0.0, 1.0 + attributes.get(&"dark_arts_assimilation", 0) * assimilation_damage)

func sentinel_upkeep(attributes: Dictionary) -> float:
	var steps := floorf(float(attributes.get(&"dark_arts_assimilation", 0)) / maxi(upkeep_step, 1))
	return 1.0 - clampf(steps * upkeep_reduction_per_step, 0.0, upkeep_reduction_cap)
