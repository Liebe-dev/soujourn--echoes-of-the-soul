# Spine enemy: separate leap damage area

The root CollisionShape2D remains the world collider and the receiver detected by
Adel's SaberHitbox. It has not moved or changed. LeapHitbox is a separate Area2D
at the root of spine_enemy.tscn; its capsule is initially the same size and position
as the body collider, using an independent Shape2D resource:
radius=76, height=152, local center=(-5, -25).

Edit the leap area in Godot:
spine_enemy.tscn > SpineEnemy > LeapHitbox > CollisionShape2D
- Transform > Position controls the local center.
- Shape > Radius/Height controls the volume.
SpineEnemy > Opening Leap > Leap Damage controls damage (default 20).
WeaponPivot/Hitbox remains the attack2/attack3 VFX area, at (-114.5,-55),
size=(231,170); those user-authored settings and all rig alignment are preserved.
The Leap shape is independent; body and leap size changes do not synchronize.

Only the selected attack shape is enabled. Windup/attack1_1 has no damage area.
LEAP/attack1_2 selects LeapHitbox around the body, including the rear. LAND/
attack1_3 and recovery close both shapes. attack2/attack3 select the original
forward area during their existing timed windows. The root world collider stays
enabled, and player/enemy body passthrough stays in force.

All areas share a single hit registry and call Player.take_damage with the enemy
origin. Each player gets at most one contact per swing, including rejected damage
from Guard, Deflect, dash or invulnerability. New swings clear the registry.
Guard/Deflect rules, stats, stagger, animations and audio are unchanged.

Active overlap checks run after movement, before landing closes the window.
Physics shape queries supplement Area2D's cached overlaps only at opening and
actual landing (normally two queries per leap). This catches a target already
inside and contact on the last flight frame without ray/pixel/bone checks on
every frame. Target loss closes the area; enemy death clears active damage.

Godot 4.7 verification in a project copy with isolated user data:
- Dedicated leap suite: 79 passed, including real rendering and frame-boundary
  contacts, front/rear, two facing directions, multiple player probes, reentry,
  repeat-contact prevention, freed target, Guard/Deflect and death cleanup.
- Existing AI/animation sequence 23, melee VFX 37, defense 59, body passthrough
  17, Adel HFSM 31: all passed. Total: 246 distinct checks.
- Capture enemy_leap_hitbox.png: green = body leap volume; yellow = melee volume.
  Both outlines are verification-only; normal gameplay does not draw them.

Standalone test scene: res://tests/enemy/leap_hitbox_validation.tscn.
Run tests in an isolated project copy with application/config/use_custom_user_dir
enabled and its own custom directory so production saves are not touched.
Legacy defense testing.tscn still reports its existing missing walk animation and
WeaponPivot node errors. The new leap suite has no script errors. Existing rig
Bone2D warnings remain outside this change.
