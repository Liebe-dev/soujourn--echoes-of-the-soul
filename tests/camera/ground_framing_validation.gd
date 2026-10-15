extends Node

var checks := 0
var failures := 0
var player
var camera
var hud
var rendered := false
const GROUND_FRACTION := 43.0 / 270.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rendered = DisplayServer.get_name() != "headless"
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("GROUND FRAMING ", "PASS " if ok else "FAIL ", label)

func frame(count: int = 2) -> void:
	for i in count: await get_tree().process_frame

func ground_screen_point() -> Vector2:
	return get_viewport().get_canvas_transform() * Vector2(player.global_position.x, player.global_position.y + camera.target_feet_offset_y())

func capture(label: String) -> void:
	if not rendered: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://camera-ground-" + label + ".png")

func button(down: bool) -> void:
	var event := InputEventAction.new()
	event.action = &"guard and deflect"
	event.pressed = down
	Input.parse_input_event(event)
	await frame()

func ready_combat() -> void:
	await button(false)
	var deadline := Time.get_ticks_msec() + 4000
	while player.damage.is_invulnerable and Time.get_ticks_msec() < deadline: await frame()
	player.stagger_impact.cancel()
	player.deflect_slow_motion.cancel()
	CombatTime.remove(player)
	hud.hp = 70
	hud.clear_all_debuffs()
	hud.restore_stagger_thresholds()
	hud.restore_stamina_full()
	player._set_facing_direction(1)
	await frame()

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexGroundFraming20261015"):
		get_tree().quit(2)
		return
	Engine.max_fps = 120
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	player = scene.get_node("PlayableAdel")
	scene.get_node("Enemy").set_physics_process(false)
	hud = player.get_node("Camera2D/hud")
	hud.set_process(false)
	player.vitals.simulation_enabled = false
	camera = player.get_node("Camera2D")
	camera.mouse_pan_enabled = false
	camera.lock_on_enabled = false
	camera._mouse_pan = Vector2.ZERO
	await get_tree().create_timer(0.8).timeout
	player.set_physics_process(false)
	camera.set_physics_process(false)
	camera._target_y = player.global_position.y - 30.0
	camera.global_position = Vector2(player.global_position.x, camera._target_y)
	var initial_zoom: Vector2 = camera.zoom
	check(is_equal_approx(camera.ground_screen_fraction, GROUND_FRACTION), "ground fraction defaults to 43/270")
	check(player.stamina_exhaustion_slow_motion_duration_multiplier == 0.5, "exhaustion uses half of configured stagger slow-motion duration")
	var window := get_window()
	var initial_size := window.size
	var initial_content := window.content_scale_size
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(1920, 1200)]:
		window.content_scale_size = dimensions
		if not rendered: window.size = dimensions
		await frame(3)
		for amount in [1.0, 1.5, 2.0]:
			camera.zoom = Vector2.ONE * amount
			camera._apply_camera_offset()
			camera.force_update_scroll()
			await frame()
			var height: float = camera.get_viewport_rect().size.y
			var margin := height - ground_screen_point().y
			check(absf(margin - height * GROUND_FRACTION) < 0.25, "projected foot plane keeps ground fraction at viewport %s zoom %.1f" % [dimensions, amount])
			if dimensions == Vector2i(1920, 1080):
				check(absf(margin / amount - 172.0 / amount) < 0.25, "visible ground world units equal 172 / zoom at %.1fx" % amount)
				await capture("zoom-" + str(amount))
	window.content_scale_size = initial_content
	window.size = initial_size
	await frame(3)
	camera.zoom = initial_zoom
	camera._apply_camera_offset()
	var origin_x: float = player.global_position.x
	var authored_delay: float = camera.horizontal_follow_delay
	var authored_speed: float = camera.follow_speed_x
	for direction in [-1.0, 1.0]:
		player.global_position.x = origin_x
		camera.global_position.x = origin_x
		camera._last_target_x = origin_x
		camera._horizontal_direction = 0
		camera._horizontal_delay_left = 0.0
		var steps := int(floor(authored_delay * 60.0))
		for i in steps:
			player.global_position.x += direction * 5.0
			camera._physics_process(1.0 / 60.0)
		check(absf(camera.global_position.x - origin_x) < 0.01, "configured X start delay remains intact moving " + str(direction))
		var delay_x: float = camera.global_position.x
		camera.set_combat_zoom(&"stagger", 1.5)
		camera.force_update_scroll()
		await frame()
		check(is_equal_approx(camera.global_position.x, delay_x) and (ground_screen_point().x - camera.get_viewport_rect().size.x * 0.5) * direction > 0.0, "stagger zoom preserves horizontal lag instead of recentering " + str(direction))
		camera.clear_combat_zoom(&"stagger")
		for i in 300: camera._physics_process(1.0 / 60.0)
		check(absf(camera.global_position.x - player.global_position.x) < 0.01, "stationary X settles to center after zoom " + str(direction))
	check(camera.horizontal_follow_delay == authored_delay and camera.follow_speed_x == authored_speed, "camera delay and speed tuning unchanged")
	player.global_position.x = origin_x
	camera.global_position = Vector2(origin_x, player.global_position.y - 30.0)
	camera._target_y = camera.global_position.y
	camera._mouse_pan = Vector2(30, -20)
	camera._apply_camera_offset()
	check(camera.offset.is_equal_approx(camera._base_offset + camera._mouse_pan), "mouse/lock pan remains additive to default framing")
	camera._mouse_pan = Vector2.ZERO
	camera.zoom = initial_zoom
	camera._apply_camera_offset()
	var base_offset: Vector2 = camera.offset
	for i in 10:
		camera.set_combat_zoom(&"stagger", 1.5)
		camera.clear_combat_zoom(&"stagger")
	check(camera.zoom.is_equal_approx(initial_zoom) and camera.offset.is_equal_approx(base_offset), "repeated zoom cycles produce no vertical drift")
	camera._apply_camera_offset()
	camera.force_update_scroll()
	await frame()
	await capture("restored")
	player.set_physics_process(true)
	camera.set_physics_process(true)
	for late in [false, true]:
		await ready_combat()
		hud.stamina = 10.0
		await button(true)
		await get_tree().create_timer(0.36 if late else 0.15).timeout
		player.take_damage(20, player.global_position + Vector2(80, 0))
		var key := str(player.stagger_impact.get_instance_id()) + ":stagger_impact"
		var expected: float = player.stagger_slow_motion_duration * 0.5
		check(CombatTime._effects.has(key) and is_equal_approx(CombatTime._effects[key].left, expected), "exhausted %s starts exactly half-duration slow motion" % ("guard" if late else "deflect"))
		check(player.stagger_impact._multiplier == player.stamina_exhaustion_zoom_multiplier, "exhaustion keeps designer's zoom setting")
		var worst_error := 0.0
		var deadline := Time.get_ticks_msec() + int((expected + 0.09) * 1000.0)
		while Time.get_ticks_msec() < deadline:
			await frame(1)
			worst_error = maxf(worst_error, absf(ground_screen_point().y - camera.get_viewport_rect().size.y * (1.0 - GROUND_FRACTION)))
		check(Engine.time_scale == 1.0, "exhaustion slowdown expires at shortened duration")
		check(worst_error < 2.0, "ground framing stays stable throughout real exhaustion zoom")
	await ready_combat()
	player.take_damage(10, player.global_position + Vector2(80, 0))
	var key := str(player.stagger_impact.get_instance_id()) + ":stagger_impact"
	check(CombatTime._effects.has(key) and is_equal_approx(CombatTime._effects[key].left, player.stagger_slow_motion_duration), "normal HP threshold keeps full configured slowdown duration")
	var worst_error := 0.0
	var peak_zoom := 1.0
	var captured := false
	var deadline := Time.get_ticks_msec() + 3000
	while player.damage.is_stunned and Time.get_ticks_msec() < deadline:
		await frame(1)
		peak_zoom = maxf(peak_zoom, camera.zoom.x / initial_zoom.x)
		worst_error = maxf(worst_error, absf(ground_screen_point().y - camera.get_viewport_rect().size.y * (1.0 - GROUND_FRACTION)))
		if rendered and not captured and camera.zoom.x / initial_zoom.x > 1.49:
			captured = true
			await capture("stagger-peak")
	check(peak_zoom > 1.46 and peak_zoom <= 1.501, "normal stagger keeps authored 50 percent zoom")
	check(worst_error < 2.0, "ground plane remains at requested screen fraction through zoom in and out")
	check(camera.zoom.is_equal_approx(initial_zoom), "real stagger returns to base zoom")
	print("GROUND FRAMING RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
