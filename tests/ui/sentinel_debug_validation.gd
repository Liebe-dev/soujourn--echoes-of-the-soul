extends Node

var checks := 0
var failures := 0
var hud

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func frame(count: int = 3) -> void:
	for i in count: await get_tree().process_frame

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("SENTINEL DEBUG ", "PASS " if ok else "FAIL ", label)

func key(code: Key, echo: bool = false, pressed: bool = true, control: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	event.ctrl_pressed = control
	Input.parse_input_event(event)
	await frame(1)
	if pressed:
		event = InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = false
		Input.parse_input_event(event)
		await frame(1)

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexSentinelHUD20261015-DebugKeys"):
		get_tree().quit(2)
		return
	Engine.max_fps = 120
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	var player = scene.get_node("PlayableAdel")
	player.sentinel_hp_drain_percent = 0.0
	scene.get_node("Enemy").set_physics_process(false)
	await frame(50)
	hud = player.get_node("Camera2D/hud")
	hud.set_process(false)
	player.vitals.simulation_enabled = false
	var debug = hud.get_node("SentinelDebugControls")
	hud.hp = 70
	hud.bleeding_level = 1
	var stats_before := [hud.hp, hud.stamina, hud.flask_charges, hud.bleeding_level, hud.stagger_tiers_ready.duplicate()]
	await key(KEY_R)
	check(not hud.sentinel_active, "R cannot preview Sentinel without full charge")
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 30.0, "T adds exactly 30 points through real input dispatch")
	await key(KEY_T, true)
	check(hud.ultimate_meter.charge == 30.0, "held-key echo does not repeatedly fill charge")
	await key(KEY_T, false, false)
	check(hud.ultimate_meter.charge == 30.0, "key release does not add charge")
	await key(KEY_T, false, true, true)
	check(hud.ultimate_meter.charge == 30.0, "Ctrl+T is not a debug action")
	await key(KEY_R)
	check(not hud.sentinel_active and hud.ultimate_meter.charge == 30.0, "failed R leaves partial charge unchanged")
	await key(KEY_T)
	await key(KEY_T)
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 100.0 and hud.ultimate_meter.is_ultimate_ready(), "four T presses cap at 100 and reveal ready HUD")
	await key(KEY_R)
	check(hud.sentinel_active and hud.ultimate_meter.charge == 0.0 and hud.sentinel_loadout.visible, "R consumes full charge and enables Sentinel; drain disabled in this input fixture")
	await key(KEY_R)
	check(hud.sentinel_active, "R does not toggle an active form off")
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 0.0, "no charge gained while Sentinel presentation is active")
	await key(KEY_Y)
	check(player.is_sentinel_entering() and hud.sentinel_active, "debug Y cannot bypass the entry action lock")
	player.sentinel_state.tick(player.sentinel_entry_duration)
	hud.set_sentinel_exit_pending(true)
	await key(KEY_Y)
	check(not hud.sentinel_active and not hud.sentinel_loadout.visible and not hud.sentinel_loadout.exit_pending, "Y immediately clears active and pending-exit presentation")
	check(hud.hp_bar.texture_progress == hud._normal_hp_fill and hud.get_node("ScreenSpace/bar/hp_bar_panel/hp_bar_wrap/stagger_markers").visible, "Y restores regular HP and threshold visuals")
	await key(KEY_Y)
	check(not hud.sentinel_active and hud.ultimate_meter.charge == 0.0, "Y outside Sentinel has no side effects")
	check(hud.hp == hud.max_hp and hud.stamina == hud.max_stamina and hud.flask_charges == stats_before[2] and hud.bleeding_level == stats_before[3] and hud.stagger_tiers_ready == [true, true], "entry restores HP, stamina and markers without refilling flasks")
	debug.debug_keys_enabled = false
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 0.0, "Inspector toggle disables debug shortcuts")
	debug.debug_keys_enabled = true
	debug.ultimate_gain = 15.0
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 15.0, "Inspector gain setting controls debug fill")
	debug.ultimate_gain = 30.0
	get_tree().paused = true
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 15.0, "paused game cannot receive debug fill")
	get_tree().paused = false
	var menu = player.get_node("Camera2D/UI_Layer/master_menu")
	menu.show()
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 15.0, "visible menu including close fade blocks debug keys")
	menu.hide()
	hud.set_campfire_hidden(true)
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 15.0, "hidden campfire HUD blocks debug keys")
	hud.set_campfire_hidden(false)
	var camp_owner := Node.new()
	scene.add_child(camp_owner)
	player._campfire_ui_owner = camp_owner
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 15.0, "campfire ownership blocks input before/after visual transitions")
	player._campfire_ui_owner = null
	player.state_machine.transition(AdelStateMachine.State.REST)
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 15.0, "rest exit period blocks debug keys")
	player.state_machine.resume_locomotion()
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 45.0, "debug input resumes after menu/campfire exit")
	hud.set_ultimate_charge(0.0)
	var second = load("res://scenes/UI/hud.tscn").instantiate()
	scene.add_child(second)
	second.set_process(false)
	hud.get_node("SentinelDebugControls").debug_keys_enabled = false
	await key(KEY_T)
	check(second.ultimate_meter.charge == 30.0 and hud.ultimate_meter.charge == 0.0, "standalone preview HUD supports shortcuts without double-dispatch")
	print("SENTINEL DEBUG RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
