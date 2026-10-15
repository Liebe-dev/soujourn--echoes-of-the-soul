extends Node

var checks := 0
var failures := 0
var player
var hud
var origin: Vector2
var S = AdelStateMachine.State

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("DASH DEFENSE ", "PASS " if ok else "FAIL ", label)

func frame(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func button(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	await frame()

func ready_player() -> void:
	for action in [&"guard and deflect", &"dodge", &"move_right"]: await button(action, false)
	player.clear_combat_input()
	var deadline := Time.get_ticks_msec() + 3000
	while (not player.dash.able_to_dodge or player.state_machine.is_in(S.DASH)) and Time.get_ticks_msec() < deadline: await frame()
	hud.restore_stamina_full()
	player.position = origin
	player.velocity = Vector2.ZERO
	await frame(4)

func begin_dash() -> void:
	await button(&"move_right", true)
	await button(&"dodge", true)
	await button(&"dodge", false)
	await button(&"move_right", false)
	check(player.state_machine.is_in(S.DASH), "real dodge input starts dash")

func dash_finished() -> void:
	var deadline := Time.get_ticks_msec() + 2000
	while player.state_machine.is_in(S.DASH) and Time.get_ticks_msec() < deadline: await frame()

func cooldown_finished() -> void:
	var deadline := Time.get_ticks_msec() + 2000
	while not player.dash.able_to_dodge and Time.get_ticks_msec() < deadline: await frame()
	await frame(2)

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexDashDefense20261016"):
		get_tree().quit(2)
		return
	Engine.max_fps = 120
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	player = scene.get_node("PlayableAdel")
	scene.get_node("Enemy").set_physics_process(false)
	scene.get_node("Enemy").position.x = 6000.0
	await frame(65)
	origin = player.position
	hud = player.get_node("Camera2D/hud")
	hud.set_process(false)
	player.vitals.simulation_enabled = false
	var original_cooldown: float = player.dodge_cooldown.wait_time
	await begin_dash()
	await button(&"guard and deflect", true)
	check(player._guard_requested and player.state_machine.is_in(S.DASH) and not player.is_guarding, "held defense queues without cancelling active dash")
	await dash_finished()
	check(not player.dash.able_to_dodge and player.is_guarding, "held defense starts at skid end while dash cooldown still runs")
	check(player.spine_anim.assigned_animation == player.ANIM_DEFENSE, "skid completion immediately plays defense pose")
	check(not player.defense.is_in_deflect_window(), "waiting through dash does not restart the deflect window")
	check(hud.stamina == 100.0 - player.dash_stamina_cost, "buffered defense adds no stamina cost until an accepted hit")
	await button(&"guard and deflect", false)
	check(not player.is_guarding and not player._guard_requested, "release exits buffered defense normally")
	await ready_player()
	await begin_dash()
	await button(&"guard and deflect", true)
	await button(&"guard and deflect", false)
	await dash_finished()
	await cooldown_finished()
	check(not player.is_guarding and not player._guard_requested, "releasing during dash cancels pending defense permanently")
	await ready_player()
	await begin_dash()
	await dash_finished()
	await button(&"guard and deflect", true)
	check(player.is_guarding and not player.dash.able_to_dodge, "fresh press during dash cooldown enters defense immediately")
	await button(&"guard and deflect", false)
	await cooldown_finished()
	check(not player.is_guarding, "release during cooldown does not produce delayed defense")
	await ready_player()
	await begin_dash()
	await button(&"guard and deflect", true)
	player.clear_combat_input()
	await dash_finished()
	await cooldown_finished()
	check(not player.is_guarding and not player._guard_requested and Input.is_action_pressed("guard and deflect"), "menu/focus cleanup cancels queued input even if physical button remains held")
	await ready_player()
	hud.stamina = 10.0
	await begin_dash()
	await button(&"guard and deflect", true)
	await dash_finished()
	await cooldown_finished()
	check(hud.stamina == 0.0 and not player.is_guarding, "zero stamina still prevents defense after a partial-cost dash")
	await ready_player()
	hud.stamina = 10.0
	await begin_dash()
	await button(&"guard and deflect", true)
	check(player._guard_requested and not player.is_guarding, "depleted dash can retain held intent without granting zero-stamina defense")
	hud.stamina = 1.0
	await dash_finished()
	await cooldown_finished()
	check(player.is_guarding, "stamina recovered during dash allows the still-held request to enter defense")
	await ready_player()
	player.position.y -= 120.0
	await frame(2)
	await begin_dash()
	check(player.dash.is_air, "airborne fixture uses actual air dash")
	await button(&"guard and deflect", true)
	await dash_finished()
	check(player.is_guarding and not player.dash.able_to_dodge, "air dash enters held defense immediately after active phase")
	await cooldown_finished()
	check(player.is_guarding, "air defense remains held while cooldown completes")
	await button(&"guard and deflect", false)
	check(player.dodge_cooldown.wait_time == original_cooldown, "dash cooldown duration remains unchanged")
	print("DASH DEFENSE RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
