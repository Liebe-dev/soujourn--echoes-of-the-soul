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

49 assertions cover hit-stop without camera zoom on all four Saber swings, the configured Guard/Deflect pulse, the dedicated impact zoom on each Q tier, rejected/zero/whiff hits, retriggers, pause, stagger arbitration, enable/disable controls, jump damage, camera changes, and Player deletion. The suite uses the scene's zoom settings. The dedicated Q impact suite checks the zoom timing and magnitude for each tier.

Native mode focuses a 1280x720 window and saves `hitstop-zoom-peak.png`. Timings are measured in unpaused real time; frame scheduling gives slight sampling differences at the short peak. Only the pulse duration is unscaled, not gameplay timers or animations.


## Ground framing and shorter stamina-exhaustion slow motion

Run `ground_framing_validation.tscn` only in a copied project with custom user directory containing `CodexGroundFraming20261015`. The suite checks the projected physical foot plane at 43/270 of viewport height above the bottom, across three viewport sizes and absolute zoom 1/1.5/2; horizontal delay; mouse pan; repeated zoom; and real exhausted guard/deflect versus normal threshold slow-motion duration. There are 35 checks in headless and native modes. Native mode captures the viewport at the three zoom levels and the real stagger peak. Tests never modify production camera or player scene tuning.
