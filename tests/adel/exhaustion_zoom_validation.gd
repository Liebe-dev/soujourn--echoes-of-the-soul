extends Node

var checks := 0
var failures := 0
var player
var hud
var camera
var base_zoom: Vector2

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("EXHAUSTION ZOOM ", "PASS " if ok else "FAIL ", label)

func frame(count: int = 2) -> void:
	for i in count: await get_tree().process_frame

func button(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = &"guard and deflect"
	event.pressed = pressed
	Input.parse_input_event(event)
	await frame()

func reset() -> void:
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
	player.position.x = 600.0
	player._set_facing_direction(1)
	await frame()

func verify_impact(expected: float, label: String) -> void:
	check(is_equal_approx(player.stagger_impact._multiplier, expected), label + " selects exact configured zoom multiplier")
	check(player.damage.is_stunned and player.damage.is_invulnerable and player.spine_anim.assigned_animation == player.ANIM_STAGGER, label + " retains stagger animation, stun and i-frame")
	check(player.damage.active_knockback_distance == player.stagger_knockback_distance and is_equal_approx(player.damage.stagger_duration(), player.stagger_knockback_duration + player.stagger_stun_duration), label + " keeps authored knockback distance and duration")
	var maximum_ratio := 1.0
	var deadline := Time.get_ticks_msec() + 220
	while Time.get_ticks_msec() < deadline:
		await frame(1)
		maximum_ratio = maxf(maximum_ratio, camera.zoom.x / base_zoom.x)
	check(maximum_ratio <= expected + 0.001 and maximum_ratio >= expected - 0.04, label + " real camera reaches intended peak without multiplying other zoom")
	var restore_deadline := Time.get_ticks_msec() + 4000
	while player.damage.is_stunned and Time.get_ticks_msec() < restore_deadline: await frame()
	check(camera.zoom.is_equal_approx(base_zoom), label + " restores original camera zoom")

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexExhaustionZoom20261015"):
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
	await get_tree().create_timer(0.7).timeout
	base_zoom = camera.zoom
	check(player.stagger_zoom_multiplier == 1.5 and player.stamina_exhaustion_zoom_multiplier == 1.3, "normal 1.5x and exhaustion 1.3x are separate Inspector settings")
	for late in [false, true]:
		await reset()
		hud.stamina = 10.0
		await button(true)
		await get_tree().create_timer(0.36 if late else 0.15).timeout
		player.take_damage(20, player.global_position + Vector2(80, 0))
		var label := "exhausted guard" if late else "exhausted deflect"
		check(hud.stamina == 0.0 and hud.hp == (60 if late else 70), label + " keeps existing damage and partial-spending rules")
		check(hud.stagger_tiers_ready == [true, true], label + " does not consume HP stagger thresholds")
		await verify_impact(1.3, label)
	await reset()
	player.take_damage(10, player.global_position + Vector2(80, 0))
	check(hud.hp == 66 and not hud.stagger_tiers_ready[0], "subsequent ordinary hit still triggers real HP threshold")
	await verify_impact(1.5, "normal threshold after exhaustion")
	await reset()
	player.stamina_exhaustion_zoom_multiplier = 1.2
	hud.stamina = 10.0
	await button(true)
	await get_tree().create_timer(0.36).timeout
	player.take_damage(20, player.global_position + Vector2(80, 0))
	await verify_impact(1.2, "custom exhaustion setting")
	check(player.stagger_zoom_multiplier == 1.5, "changing exhaustion setting never changes normal stagger zoom")
	print("EXHAUSTION ZOOM RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
