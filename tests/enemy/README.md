# Enemy validation

## Limited retreat and pursuit counterattack (2026-10-30)

Both FSM and Utility enemies have a three-second retreat budget per encounter.
Only time actually spent in FLEE consumes it; idle/stun or brief Utility switches
cannot refill it. When exhausted, FLEE is unavailable even if pressure is weak.
FSM waits; Utility can choose its other available actions.

If visible threat stays strictly above 0.5 for three consecutive game seconds
during the retreat episode (including waiting after the cap), the enemy turns,
rearms one opening leap and commits to chase/leap/melee for the encounter.
The leap still has its telegraph, landing and recovery, then melee follows when
the target is in range. Low health, weighted selection and hysteresis cannot
immediately send it back into FLEE. Stun still interrupts combat.

Default threat is 1 - horizontal distance / flee_safe_distance, clamped to [0, 1],
and zero without visible sight. Thus with safe distance 600, threat > 0.5 means
a visible player closer than 300 units. Utility uses the profile's threat-distance
Curve instead, so custom profiles can adjust this mapping. Threat <= 0.5,
occlusion, stun or a committed attack breaks the consecutive pressure timer.
After counterattack is armed, it follows normal target memory and sight rules;
it never permits an attack through terrain.

Encounter loss/new target, death, or sufficient healing clears the retreat policy.
Healing means the FSM recovery threshold, or zero Utility flee-need response.
The following fields are editable under Survival:

- flee_max_duration: 3 seconds of retreat.
- counterattack_threat_threshold: 0.5, strict greater-than comparison.
- counterattack_pressure_duration: 3 consecutive seconds.

The comparison overlay shows retreat time, current visible threat, pressure time
and whether counterattack is armed. Run flee_counterattack_validation.tscn in the
isolated copy below to verify both decision modes, strict/consecutive pressure,
walls, follow-up melee, cap persistence, healing/stun/death, configurable durations,
weighted selection, and timing at 30/60/120 Hz.
Headless validation: retreat/counterattack 64/64; all six suites 296/296.

```
godot --headless --path <copied-project> res://tests/enemy/flee_counterattack_validation.tscn
```

## Utility AI / section 4.3 (2026-10-30)

Use `scenes/enemy/utility_enemy.tscn` for a Utility enemy, or select **AI Decisions
> Decision Mode > Utility** on any `spine_enemy.gd` instance. The original
`spine_enemy.tscn` keeps **FSM** as its default for baseline comparison.
Run `scenes/enemy/utility_ai_test.tscn` with F6 for a playable comparison: Utility
on the left, FSM on the right, with current scores and considerations displayed.
Normal controls remain A/D, Space, left mouse and the existing weapon skill.

`enemy_utility_profile.gd` is an editable Resource containing six response Curves
and six action weights. Curve inputs and outputs are normalized to [0, 1].
The scorer in `enemy_utility_ai.gd` combines the responses, then the existing FSM
executes the selected action. It does not require a Behavior Tree.

| Action | Main considerations / availability |
| --- | --- |
| Idle | Time resting, time patrolling; low health when threat is distant |
| Patrol | Patrol/rest progress; available without a remembered target |
| Chase | Target memory confidence, own health, player weakness, ally support |
| Leap | Attack distance and aggression; visible/reachable, grounded, opener available |
| Melee | Attack distance and aggression; visible/reachable, grounded, opener consumed |
| Flee | Low own health, threat proximity, player weakness, ally support |

Aggression = `0.55 * health_confidence + 0.25 * player_weakness + 0.20 * ally_support`.
For example, melee utility = `melee_weight * attack_distance * (0.55 + 0.45 * aggression)`.
Impossible actions receive zero before selection. Flee need has its own curve
(default: strongest at <=20% HP, zero at >=60%); it is not the baseline FSM's hard
threshold. Setting the enemy's `flee_health_ratio = 0` disables fleeing in either mode.
`flee_safe_distance` normalizes threat proximity and caps flee availability.

Decisions run every 0.2 game seconds by default. Hysteresis (switch margin 0.08)
reduces oscillation. Optional **Utility Weighted Selection** samples positive
scores within 85% of the best score; otherwise selection takes the highest score,
retaining the current action when its score is within the switch margin.
Weights, Curves, cadence, margin, top ratio and ally radius are editable per enemy.

Initial detection, windup, flight, landing, melee and recovery retain their existing
animation/physics lifecycle; stun and death override decisions. Occlusion cancels
windup/melee as before. Utility does not reselect midway through committed attacks.
Damage and visibility changes invalidate the decision timer. Scores and responses
are exposed as `utility_action`, `utility_scores`, `utility_considerations` and
the `utility_decided` signal, without logging every frame.

Player HP comes from `get_ai_health_ratio()` on the gameplay stats model. Both
player position and HP are remembered only while visible; hidden changes do not
update the context. Allied support counts other living `enemy_ai_agents` within
500 units and clear terrain sight. Both FSM and Utility spine enemies join that
group; corpses leave it. This remains local decision AI with the existing movement,
not terrain pathfinding.

Run `enemy_utility_validation.tscn` in the same isolated copy described below.
Its 45 checks cover scoring, response curves, all four context factors, hard
eligibility, highest/weighted choice, hysteresis, actual prefab/animation/physics
integration, hidden HP/position memory, ally occlusion/death, cadence/damage
invalidation, mode switching, stun and terminal death.

```
godot --headless --path <copied-project> res://tests/enemy/enemy_utility_validation.tscn
```

## Enemy FSM and wall detection (2026-10-30)

`spine_enemy.gd` implements the baseline FSM with `_enter_state`, `_update_state`,
`_exit_state` and separate `_evaluate_transition` rules. WALK is Patrol; RUN is
Chase; WINDUP/LEAP/LAND/MELEE/RECOVERY are the attack phases. IDLE, FLEE,
STUNNED and terminal DEAD complete the baseline. Existing detection animation
still completes via its AnimationPlayer signal.

Sight uses a physics ray between body collider centers, excludes observer and
target, and checks `sight_obstacle_mask` (default terrain layer 1). Walls must
have enabled physics collision on a selected layer; purely visual walls do not
block sight. Detection is omnidirectional within range. While occluded, enemies
remember only the last seen position, then forget after `chase_memory`.
The older `s_1e_1.gd` prototype also uses this sight check and last seen position.

Flee starts at 20% health, ends at safe distance (600) or recovery to 35% health.
Set `flee_health_ratio = 0` to disable it. The current rig has no idle/stun clip,
so those states pause the available pose. Skill stun delegates to the FSM;
older enemies retain the existing component behavior.

Run in a copied project with a separate custom user directory (death rewards
must not touch the actual save), with APPDATA/LOCALAPPDATA also isolated:

```
godot --headless --path <copied-project> res://tests/enemy/enemy_fsm_validation.tscn
godot --headless --path <copied-project> res://tests/enemy/enemy_detect_validation.tscn
godot --headless --path <copied-project> res://tests/enemy/leap_hitbox_validation.tscn
godot --headless --path <copied-project> res://tests/enemy/enemy_death_validation.tscn
```

The FSM suite covers wall occlusion in both directions, configurable layers,
player/terrain shared collision layer, memory expiry/reacquisition, no hidden
position tracking, patrol/idle timers, flee/recovery/safe waiting, skill stun
extension/cleanup, death overriding stun and the legacy prototype detection path.
Headless validation: FSM 32/32, detection 34/34, leap hitboxes 81/81 and death 40/40.

## Death regression suite

Run `enemy_death_validation.tscn` only in a copied project with custom user directory enabled and its name starting with `CodexEnemyDeath`. It refuses production user directories. EXP and scene-reload tests run only in this isolated copy.

```
godot --headless --path <copied-project> res://tests/enemy/enemy_death_validation.tscn
godot --path <copied-project> --rendering-method gl_compatibility res://tests/enemy/enemy_death_validation.tscn
```

40 assertions cover the real ten-second source clip and fade, lethal Saber/Q, corpse immunity, terminal AI state, disabled combat colliders plus terrain-only corpse physics, camera lock removal, EXP idempotence, stale callbacks, existing/living Q stun, death during leap, pause/slow motion, natural animation completion, unchanged EnemyBase default removal, and real Restart Area before/after death completion.

Native mode focuses a 1280x720 window and captures `enemy-death-start.png` and `enemy-death-fading.png`. The primary corpse uses normal playback through the full ten seconds; auxiliary death/reset cases use AnimationPlayer.advance to complete their clip quickly. Clip time is scaled game time, not a separate wall-time deletion timer.


## Airborne corpse fall (2026-10-16)

Run `corpse_fall_validation.tscn` in a copied project with custom user directory containing `CodexCorpseFall20261016`. Its 19 assertions compare actual enemy corpse falling against the Player locomotion module, including landing, terminal speed, death playback, pause/slow motion, combat exclusion and character pass-through. Run headless and with rendering. Original hurtbox/attack shapes stay disabled; the new runtime-only CorpseTerrainCollider handles world geometry. The existing 40-check death suite now expects corpse gravity instead of frozen movement, retaining natural 10-second fade/removal and reset checks.
