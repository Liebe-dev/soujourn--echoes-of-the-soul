# Enemy death validation

Run `enemy_death_validation.tscn` only in a copied project with custom user directory enabled and its name starting with `CodexEnemyDeath`. It refuses production user directories. EXP and scene-reload tests run only in this isolated copy.

```
godot --headless --path <copied-project> res://tests/enemy/enemy_death_validation.tscn
godot --path <copied-project> --rendering-method gl_compatibility res://tests/enemy/enemy_death_validation.tscn
```

40 assertions cover the real ten-second source clip and fade, lethal Saber/Q, corpse immunity, terminal AI state, disabled combat colliders plus terrain-only corpse physics, camera lock removal, EXP idempotence, stale callbacks, existing/living Q stun, death during leap, pause/slow motion, natural animation completion, unchanged EnemyBase default removal, and real Restart Area before/after death completion.

Native mode focuses a 1280x720 window and captures `enemy-death-start.png` and `enemy-death-fading.png`. The primary corpse uses normal playback through the full ten seconds; auxiliary death/reset cases use AnimationPlayer.advance to complete their clip quickly. Clip time is scaled game time, not a separate wall-time deletion timer.


## Airborne corpse fall (2026-10-16)

Run `corpse_fall_validation.tscn` in a copied project with custom user directory containing `CodexCorpseFall20261016`. Its 19 assertions compare actual enemy corpse falling against the Player locomotion module, including landing, terminal speed, death playback, pause/slow motion, combat exclusion and character pass-through. Run headless and with rendering. Original hurtbox/attack shapes stay disabled; the new runtime-only CorpseTerrainCollider handles world geometry. The existing 40-check death suite now expects corpse gravity instead of frozen movement, retaining natural 10-second fade/removal and reset checks.
