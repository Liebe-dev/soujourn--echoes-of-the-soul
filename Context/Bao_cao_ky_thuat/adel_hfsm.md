# Adel HFSM and recovery presentation

## Behavior

After saber_defense, saber_guard, saber_deflect or saber_stagger ends, Adel plays
saber_ready with only sprite frame 2 for 1 game second. Movement, jump, attack,
guard, dash, pickup and rest can interrupt this recovery; it adds no action lock.
Normal combo recovery retains the source saber_ready frame sequence.

AdelAnimationComponent duplicates the player's AnimationLibrary and constructs
a private Animation variant. The source rig, textures, transforms and animation
tracks on disk remain unchanged. The frame track is applied after texture/hframes
so a previous 1-frame defense pose can safely become frame 2 of the ready sheet.
Frame and duration are set in adel_animation_component.gd (_ready_final.length
and track_insert_key for TestAttackSprite:frame).

## Responsibilities

- AdelStateMachine: action hierarchy, transitions through the common parent,
  shared input/physics dispatch and movement/action permissions.
- playable_adel.gd: character body, wiring, public damage/rest/weapon interfaces,
  state enter/exit effects and physical application of component decisions.
- AdelAnimationComponent: facing, ground/air/jump presentation, held poses and
  the two ready variants.
- AdelGhostTrail: dash trail creation, pooling, cancellation and owner cleanup.
- Existing Locomotion/Combat/Damage/Dash/Defense modules retain their mechanics.
- DeflectSlowMotion remains an independent global time pulse. Physical stagger
  can progress while its Deflect visual is held.

State hierarchy:

ROOT
  LOCOMOTION: GROUNDED, AIRBORNE, READY
  ATTACK: COMBO, JUMP_ATTACK(HANG/FALL), JUMP_LAND
  DEFENSE: HOLD, GUARD_REACTION, DEFLECT_REACTION
  DASH: ACTIVE, SKID
  STAGGER: KNOCKBACK, STUN
  CONTACT_REACTION, REST, PICKUP

Transitions exit children up to the common parent, then enter the new branch.
Leaving Attack invalidates interruption callbacks and clears the queued attack
and both combat hitboxes. Leaving Defense ends protection. Leaving Dash kills
its tween, cancels new trails and starts cooldown. No delayed dash coroutine can
overwrite a subsequent state. Combo reset uses a scaled physics countdown.

can_move/is_locked retain setters for existing map and SaveManager callers;
the setters control external locks. is_doing_action/is_resting are derived from
the HFSM. A map unlock cannot accidentally clear an active action's ownership.
Animation completion is accepted only by the matching active state. Sibling
defense reactions do not restart the guard-start Deflect window.

## Tuning and scope

Player Inspector remains unchanged. Existing scene overrides (125 px stagger,
0.5x slowdown for 0.4 real seconds) are preserved. No audio/FMOD, stamina cost,
enemy rig, source animation, legacy prototype, HUD or stats changes are included
in this refactor. Previous uncommitted Guard/Deflect work is retained.

## Validation

Run standalone suites in an isolated copy of the project with
application/config/use_custom_user_dir=true and a dedicated custom user directory
to avoid reading or writing production saves:

godot --headless --path <isolated-project> res://tests/adel/ready_recovery_validation.tscn
godot --headless --path <isolated-project> res://tests/adel/adel_hfsm_validation.tscn

Godot 4.7 validation: ready 21, hierarchy/lifecycle 31, defense animation 16,
slow-motion 25, broader defense 59, stagger/attack matrix 40, passthrough 17,
death/respawn 20, stagger/HUD 17: 246 distinct checks passed. The hierarchy suite
also ran with real rendering; adel_ready_frame2.png is an actual game capture.
Legacy defense tests explicitly use 0.6x/0.2s fixture settings; they do not change
the production scene overrides. Knockback distance allows one physics tick of
timer-boundary tolerance (the pre-existing timer/physics clocks complete on
frames); knockback mechanics were not changed.

The legacy testing scene still reports its existing missing walk animation and
WeaponPivot node errors. New validation scenes have no script errors. Existing
Bone2D and FMOD bank/import warnings are outside this change.

API reference: https://docs.godotengine.org/en/stable/classes/class_animationlibrary.html
