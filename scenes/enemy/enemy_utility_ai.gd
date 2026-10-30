extends RefCounted
## Pure scoring/selection: the enemy supplies only currently perceived facts.
const Profile = preload("res://scenes/enemy/enemy_utility_profile.gd")
const ACTIONS: Array[StringName] = [&"idle", &"patrol", &"chase", &"leap", &"melee", &"flee"]
var scores: Dictionary = {}
var considerations: Dictionary = {}

func evaluate(context: Dictionary, profile: Profile) -> Dictionary:
	scores.clear()
	considerations.clear()
	for action in ACTIONS: scores[action] = 0.0
	var confidence := Profile.response(profile.health_confidence, context.health)
	var need := Profile.response(profile.flee_need, context.health)
	var weakness := Profile.response(profile.player_weakness, context.player_health)
	var support := Profile.response(profile.ally_support, float(context.allies) / maxi(profile.full_support_allies, 1))
	# Weighted sum for aggression, then multiply independent action considerations.
	var aggression := 0.55 * confidence + 0.25 * weakness + 0.2 * support
	considerations = {&"confidence": confidence, &"flee_need": need,
		&"player_weakness": weakness, &"ally_support": support, &"aggression": aggression}
	if not context.has_target:
		var progress := clampf(float(context.phase_progress), 0.0, 1.0)
		if context.resting:
			scores[&"idle"] = profile.idle_weight * (0.95 - 0.8 * progress)
			scores[&"patrol"] = profile.patrol_weight * (0.15 + 0.8 * progress)
		else:
			scores[&"idle"] = profile.idle_weight * (0.1 + 0.85 * progress)
			scores[&"patrol"] = profile.patrol_weight * (0.95 - 0.75 * progress)
		for action in scores: scores[action] = clampf(scores[action], 0.0, 1.0)
		return scores.duplicate()
	var threat := Profile.response(profile.threat_distance, context.distance / maxf(context.safe_distance, 1.0))
	var attack_readiness := 0.55 + 0.45 * aggression
	considerations[&"threat_proximity"] = threat
	considerations[&"attack_readiness"] = attack_readiness
	scores[&"idle"] = profile.idle_weight * (0.04 + 0.9 * need * (1.0 - threat))
	if context.distance > 8.0:
		scores[&"chase"] = profile.chase_weight * context.memory * (0.3 + 0.7 * aggression)
	if context.flee_enabled and not context.get(&"flee_exhausted", false) and context.distance < context.safe_distance:
		scores[&"flee"] = profile.flee_weight * need * (0.4 + 0.6 * threat) * (1.0 - 0.45 * support) * (1.0 - 0.4 * weakness)
	# Eligibility is a hard zero: scoring can never authorize an invisible/out-of-range attack.
	if context.visible and context.grounded and context.reachable:
		if context.opener and context.distance <= context.leap_range:
			var reach := Profile.response(profile.attack_distance, context.distance / maxf(context.leap_range, 1.0))
			considerations[&"leap_distance"] = reach
			scores[&"leap"] = profile.leap_weight * reach * attack_readiness
		if not context.opener and context.distance <= context.melee_range:
			var reach := Profile.response(profile.attack_distance, context.distance / maxf(context.melee_range, 1.0))
			considerations[&"melee_distance"] = reach
			scores[&"melee"] = profile.melee_weight * reach * attack_readiness
	considerations[&"retreat_exhausted"] = 1.0 if context.get(&"flee_exhausted", false) else 0.0
	considerations[&"counterattack"] = 1.0 if context.get(&"counterattack", false) else 0.0
	if context.get(&"counterattack", false):
		# Once cornered, commit to a legal attack. RNG/hysteresis cannot select flight again.
		var attack: StringName = &"leap" if float(scores[&"leap"]) > 0.0 else &"melee"
		var can_attack := float(scores[attack]) > 0.0
		for action in scores: scores[action] = 0.0
		if can_attack: scores[attack] = 1.0
		elif context.distance > 8.0 and context.memory > 0.0: scores[&"chase"] = 1.0
		else: scores[&"idle"] = profile.idle_weight
	for action in scores: scores[action] = clampf(scores[action], 0.0, 1.0)
	return scores.duplicate()

func choose(current: StringName, rng: RandomNumberGenerator, weighted: bool = false, top_ratio: float = 0.85, switch_margin: float = 0.08) -> StringName:
	var best: StringName = &"idle"
	var best_score := 0.0
	for action in ACTIONS:
		var score: float = scores.get(action, 0.0)
		if score > best_score:
			best = action
			best_score = score
	if best_score <= 0.0: return &"idle"
	var current_score: float = scores.get(current, 0.0)
	# Hysteresis keeps small score fluctuations from changing the action every tick.
	if current_score > 0.0 and current_score >= best_score - clampf(switch_margin, 0.0, 1.0): return current
	if not weighted: return best
	var candidates: Array[StringName] = []
	var total := 0.0
	for action in ACTIONS:
		var score: float = scores.get(action, 0.0)
		if score > 0.0 and score >= best_score * clampf(top_ratio, 0.0, 1.0):
			candidates.append(action)
			total += score
	var roll := rng.randf() * total
	for action in candidates:
		roll -= float(scores[action])
		if roll < 0.0: return action
	return best
