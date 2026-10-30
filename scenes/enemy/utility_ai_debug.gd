extends Node2D
## Comparison scene only: live scores stay out of the normal game HUD.
@onready var utility_enemy = $UtilityEnemy
@onready var baseline_enemy = $FSMEnemy
@onready var readout: Label = $Debug/Readout

func _process(_delta: float) -> void:
	var text := "UTILITY AI (left) / FSM baseline (right)\nA/D: move | Space: jump | Left mouse: attack\n"
	if is_instance_valid(utility_enemy):
		text += "Utility state: %s | chosen: %s | HP: %d\n" % [utility_enemy.State.keys()[utility_enemy.state], utility_enemy.utility_action, utility_enemy.current_health]
		text += "Retreat: %.1fs / %.1fs | Threat: %.2f | Pressure: %.1fs | Counterattack: %s\n" % [utility_enemy.flee_time, utility_enemy.flee_max_duration, utility_enemy.get_flee_threat(), utility_enemy.flee_pressure_time, utility_enemy.counterattack_active]
		for action in utility_enemy.utility_scores:
			text += "%s: %.3f   " % [action, utility_enemy.utility_scores[action]]
		text += "\n"
		for key in utility_enemy.utility_considerations:
			text += "%s: %.2f   " % [key, utility_enemy.utility_considerations[key]]
	else:
		text += "Utility enemy defeated\n"
	if is_instance_valid(baseline_enemy):
		text += "\nFSM state: %s | HP: %d" % [baseline_enemy.State.keys()[baseline_enemy.state], baseline_enemy.current_health]
	readout.text = text
