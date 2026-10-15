# Mouse camera validation

Run `mouse_camera_validation.tscn` only in a copied project with `application/config/use_custom_user_dir=true` and `application/config/custom_user_dir_name` beginning with `CodexMouseCamera`.

The harness refuses other user directories. It clears test checkpoint slots inside that isolated directory, then exercises real Player/menu/campfire/title scenes.

Headless:
```
godot --headless --path <copied-project> res://tests/camera/mouse_camera_validation.tscn
```

Native cursor verification (Windows):
```
godot --path <copied-project> --rendering-method gl_compatibility res://tests/camera/mouse_camera_validation.tscn
```

The rendered harness focuses a 1280x720 game window and moves its pointer through test positions. External physical mouse movement during the short run can invalidate pointer-position assertions. Headless skips native cursor/focus assertions; it does not prove cursor centering. Game viewport captures do not contain the OS hardware cursor; native centering is recorded in the test log.

## Target lock and pause camera preferences

Run `lock_camera_validation.tscn` only in a copied project with custom user directory enabled and its name starting with `CodexLockCamera`. It refuses other directories. This suite removes/recreates the **test** `camera_controls.cfg` inside that isolated user directory.

```
godot --headless --path <copied-project> res://tests/camera/lock_camera_validation.tscn
godot --path <copied-project> --rendering-method gl_compatibility res://tests/camera/lock_camera_validation.tscn
```

Headless covers 39 checks with real Player/SpineEnemy scripts, targeting geometry, target destruction during selection, pan limits, idle timing, persistent preferences, and pause controls. Native Windows adds 17 checks for actual input dispatch, projected reticle, locked mouse suppression, idle return, menu cursor centering and menu transitions (56 total).

The native suite focuses and positions its own 1280x720 window and changes its pointer position. Physical mouse motion during the run can invalidate idle/pointer assertions. Captures do not include the OS hardware cursor; native pointer coordinates are asserted and logged.

## Hit-stop camera zoom

Run `hitstop_zoom_validation.tscn` only in a copied project with custom user directory enabled and its name starting with `CodexHitStopZoom`. The harness refuses production user directories.

```
godot --headless --path <copied-project> res://tests/camera/hitstop_zoom_validation.tscn
godot --path <copied-project> --rendering-method gl_compatibility res://tests/camera/hitstop_zoom_validation.tscn
```

56 assertions in each mode cover the accepted-hit path for all four Saber swings, actual Guard/Deflect input, all three real Q skill tiers, pulse amplitude/return, rejected/zero/whiff hits, retriggers, pause, stagger arbitration, enable/disable controls, existing jump no-hit-stop behavior, camera changes, and Player deletion. This version verifies the current user scene tuning: stagger distance220, frame0 duration0.4 and zoom return lead0.25; it does not replace those scene values with script defaults.

Native mode focuses a 1280x720 window and saves `hitstop-zoom-peak.png`. Timings are measured in unpaused real time; frame scheduling gives slight sampling differences at the short peak. Only the pulse duration is unscaled, not gameplay timers or animations.
