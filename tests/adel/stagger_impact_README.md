# Stagger impact validation

Run only in a copied project with `application/config/use_custom_user_dir=true` and `application/config/custom_user_dir_name` starting with `CodexStaggerImpact`. The suite refuses other user directories. Do not run against production checkpoint data.

```
godot --headless --path <copied-project> res://tests/adel/stagger_impact_validation.tscn
godot --path <copied-project> --rendering-method gl_compatibility res://tests/adel/stagger_impact_validation.tscn
```

49 checks in each mode cover real Player/SpineEnemy test-scene integration, threshold/attack interruption, horizontal direction, 200px travel across 30/60/120 physics steps, motion during frame 1, complete stop at 0.5 game seconds, 50% zoom with player focus, real-time slowdown, return before recovery, pause, camera ownership, retriggers, exhausted Guard and owner deletion.

Native mode focuses its own 1280x720 game window and saves peak/restored viewport captures. Waits for grounded state account for initial shader compilation. Time-scale assertions allow a processing frame after the real-time deadline; Godot applies changes on frame boundaries. Existing rig Bone2D warnings are unrelated to these assertions.

`adel_hfsm_validation.gd` and `guard_stamina_validation.gd` disable only the new zoom/slow-motion presentation to keep their pre-existing combat-clock assertions isolated. The new suite runs with presentation enabled for the complete path, including exhausted Guard.
