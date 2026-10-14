# Guard recoil and stamina

## Designer controls

Open scenes/adel/playable_adel.tscn and select the PlayableAdel root in Inspector.

Guard Knockback:
- Guard Knockback Distance: current saved scene = 20 px; script default = 50 px.
- Guard Knockback Duration: current saved scene = 0.1 game seconds; script default = 0.2.

Stamina:
- Dash Stamina Cost = 20.
- Guard Stamina Cost = 20 per accepted guarded hit.
- Deflect Stamina Cost = 20 per accepted deflected hit.
- Stamina Regen Delay = 1.5 game seconds.
- Stamina Regen Per Second = 28 (retained existing rate, editable).

Stagger Threshold (shared by HP-threshold and insufficient-stamina reactions):
- Stagger Knockback Distance: current saved scene = 200 px.
- Stagger Knockback Duration = 0.3 game seconds.
- Stagger Stun Duration = 0.45 game seconds.
- Iframe: scenes/adel/components/damage_component.gd > STAGGER_INVULN_SEC = 1.0.
  This is total game time from the start of the push, including push and stun;
  invulnerability always lasts at least through stun when configured phases are longer.
- saber_stagger frame 0 during the push, frame 1 during stun; frame-2 saber_ready
  on recovery. Both reactions call the same DamageComponent.apply_stagger path.
- Separate Stamina Exhaustion exports were removed to prevent tuning drift.

These exports are declared near the top of scenes/adel/playable_adel.gd. Stamina
cost/recovery settings are injected into the HUD's StatsComponent at Player ready;
save the scene and restart gameplay to apply edited stamina configuration.

Default maximum stamina is 100. The authoritative progression base is
scenes/Mechanic/player_progress.gd > BASE_MAX_STAMINA (line 8). StatsComponent's
max_stamina/stamina defaults are also 100. Existing stamina upgrades remain intact.

## Rules

A funded late frontal Guard starts a horizontal recoil without adding vertical
velocity. Protection remains active while stamina stays positive. Its saber_guard pose is held while the recoil is
active, then returns to saber_defense if the button stays held and stamina is positive. Another valid hit
can be guarded during recoil and restarts the configured recoil budget. Solid
walls clip travel; releasing defense cancels its pending recoil. Airborne guard
retains normal vertical physics without a new upward impulse.

Stamina is charged once when dash begins or a hit is actually classified as
Guard/Deflect. Holding saber_defense without a hit costs nothing. Attack costs
are not added in this scope. The green HUD bar updates immediately when charged.
Regeneration is independent of the HUD's combat/visibility timer. Spending resets
the recovery delay; Attack, Defense (including neutral hold and guard reactions)
and an active Deflect pulse keep resetting the wait. Once those end, 1.5 seconds
of eligible game time must pass before gradual recovery at 28/s. Recovery clamps
at maximum and keeps the HUD visible while its bar changes.

Insufficiency is evaluated BEFORE the cost: exactly 20 can pay a 20-cost action
normally, even though it leaves stamina at 0. That accepted Guard still finishes
its normal recoil/pose; an accepted Deflect keeps its pose throughout its slow
motion pulse. Protection ends immediately at zero, so subsequent accepted hits
cannot Guard/Deflect, including hits before the next physics update. Existing
hit/stagger/dash invulnerability still rejects hits normally.

With positive stamina below the configured cost:
- Dash spends all remaining stamina and has no additional punishment.
- Deflect spends the remainder, blocks all HP loss and immediately starts the
  complete horizontal stagger reaction (push, stun, two frames and shared iframe).
  It cancels any Deflect slow-motion pulse so the stagger pose is immediate.
- Guard spends the remainder and receives the normal guarded damage (default
  50%, followed by existing damage modifiers), then the same complete reaction.

At zero stamina:
- Dash cannot begin and consumes no cooldown, aerial dash allowance, iframe or
  recovery-delay reset. Movement, jump and attack remain available.
- Defense cannot begin or remain protective, so neither Guard nor Deflect can
  succeed. Already-held Defense releases; pressing a rejected Defense input does
  not block stamina regeneration or automatically re-enter Defense on recovery.
  Release and press again after stamina recovers to enter Defense.

Exhausted reactions consume no HP-threshold marker and apply no random debuff.
Exhausted Guard HP loss may cross 66%/33% without activating those thresholds.
An already active HP floor lock is still respected. Reactions remain horizontal
and do not add an upward impulse. Solid walls clip travel. Defense ends during
the reaction; control returns only after both shared push and stun phases finish.

Funded Guard damage can still trigger the existing HP-threshold stagger, which
takes priority over its ordinary guard pose. Such a Guard-triggered threshold
reaction is also horizontal, so a guarded hit never adds an upward kick.

## Structure and validation

DefenseComponent owns guard timing/direction classification and the recoil travel
budget. Player applies its returned horizontal speed through move_and_slide.
DamageComponent snapshots the same stagger configuration for both threshold
and exhaustion reactions. The Player checks positive stamina at action entry,
hit classification and held-Defense updates. DefenseComponent can end protection
without cancelling the recoil of a just-paid hit. StatsComponent owns costs, delay and recovery. ui.gd synchronizes
the green bar and reads the owning Player's action block state. No new global
singleton or audio modification was added.

The maintained guard/stamina suite covers costs, partial spending, complete
stagger phases, zero-stamina input and held-stance cutoff, same-frame hits, paid
hit reactions at zero, recovery timing, attack interruption/recovery and lethal
guard respawn. Run logs and final verified counts accompany each change in the
workspace output bundle; no normal player save data is used.

Standalone test: res://tests/adel/guard_stamina_validation.tscn. Run in an isolated
copy using application/config/use_custom_user_dir=true and a dedicated user data
directory named CodexGuardStaminaValidation; the suite refuses to run against
normal production user data because it intentionally writes a test checkpoint.
The death regression also exercises save/respawn paths.
