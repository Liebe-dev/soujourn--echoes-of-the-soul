extends Node
var checks := 0
var failures := 0
var p
var hud
var origin: Vector2
const S = AdelStateMachine.State

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PLAYER REFACTOR ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func reset() -> void:
	p.clear_combat_input()
	p.end_sentinel()
	p.state_machine.resume_locomotion()
	while not p.dash.able_to_dodge: await frames()
	p.stats.heal_to_full()
	p.damage.is_invulnerable = false
	p.position = origin
	p.velocity = Vector2.ZERO
	await frames(3)

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexPlayerRefactor20261016"):
		get_tree().quit(2)
		return
	Engine.max_fps = 144
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	p = scene.get_node("PlayableAdel")
	scene.get_node("Enemy").set_physics_process(false)
	scene.get_node("Enemy").position.x = 6000.0
	p.hit_stop_enabled = false
	p.stagger_zoom_enabled = false
	p.stagger_slow_motion_enabled = false
	await frames(65)
	hud = p.get_node("Camera2D/hud")
	origin = p.position
	check(p.stats == hud._stats and p.vitals.model == p.stats, "Player and HUD share one Player-owned stats model")
	p.vitals.simulation_enabled = false
	p.damage.start_invulnerability(0.1)
	p._perform_dash(1.0)
	await wait(0.14)
	check(p.state_machine.current == S.DASH_ACTIVE and p.damage.is_invulnerable, "old HIT timeout cannot clear active DASH immunity")
	p.take_damage(5, p.global_position + Vector2(-80, 0))
	check(p.stats.hp == 100, "actual damage stays blocked after old HIT timeout during dash")
	await wait(0.2)
	check(p.state_machine.current == S.DASH_SKID and not p.damage.is_invulnerable, "dash immunity ends before skid")
	await wait(0.3)
	await reset()
	p._perform_dash(1.0)
	p.damage.start_invulnerability(0.9)
	await wait(0.55)
	check(not p.dash.is_dodging and p.damage.is_invulnerable, "dash completion leaves an independent longer HIT window intact")
	await wait(0.42)
	check(not p.damage.is_invulnerable, "last remaining immunity source expires normally")
	p.damage.start_invulnerability(0.04)
	await wait(0.02)
	p.damage.start_invulnerability(0.25)
	await wait(0.07)
	check(p.damage.is_invulnerable, "stale callback cannot end a refreshed window of the same source")
	await wait(0.24)
	check(not p.damage.is_invulnerable, "refreshed source expires without leaking immunity")
	await reset()
	p._perform_dash(1.0)
	p.damage.apply_stagger(Vector2.LEFT, 10.0, 0.06, 0.08, 0.3)
	check(not p.dash.is_dodging and p.state_machine.is_in(S.STAGGER) and p.damage.is_invulnerable, "stagger interruption cancels dash movement but retains STAGGER immunity")
	await wait(0.35)
	check(not p.damage.is_stunned and not p.damage.is_invulnerable, "interrupted dash and stagger both clean up")
	p.damage.apply_stagger(Vector2.LEFT, 10.0, 0.04, 0.04, 0.15)
	await wait(0.02)
	p.damage.apply_stagger(Vector2.LEFT, 10.0, 0.15, 0.1, 0.3)
	await wait(0.06)
	check(p.damage.is_knocking_back and p.damage.is_stunned, "old stagger callbacks cannot advance or recover a newer stagger")
	await wait(0.12)
	check(not p.damage.is_knocking_back and p.damage.is_stunned, "new stagger reaches its own stun phase")
	await wait(0.22)
	await reset()
	var distances: Array[float] = []
	var old_ticks := Engine.physics_ticks_per_second
	for ticks in [30, 60, 120]:
		Engine.physics_ticks_per_second = ticks
		await reset()
		var start: float = p.position.x
		p._perform_dash(1.0)
		while p.dash.phase == DashComponent.Phase.ACTIVE: await frames()
		check(p.dash.phase == DashComponent.Phase.SKID and not p.damage.is_invulnerable, "first skid tick has no DASH immunity at %d ticks/sec" % ticks)
		while p.dash.is_dodging: await frames()
		distances.append(p.position.x - start)
		check(absf(distances.back() - 308.0) < 0.2, "integrated dash distance is 308px at %d physics ticks/sec" % ticks)
	Engine.physics_ticks_per_second = old_ticks
	check(distances.max() - distances.min() < 0.2, "dash distance stays stable across physics rates")
	await reset()
	var input_start: float = p.position.x
	Input.action_press("move_right")
	var dodge := InputEventAction.new()
	dodge.action = "dodge"
	dodge.pressed = true
	Input.parse_input_event(dodge)
	await frames()
	check(p.dash.is_dodging, "actual dodge input enters unified physics dash")
	Input.action_release("move_right")
	Input.action_release("dodge")
	while p.dash.is_dodging: await frames()
	check(absf(p.position.x - input_start - 308.0) < 0.2, "real input dash includes its first physics tick in the 308px budget")
	await reset()
	var wall := StaticBody2D.new()
	wall.position = origin + Vector2(140, -60)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20, 320)
	shape.shape = rectangle
	wall.add_child(shape)
	scene.add_child(wall)
	await frames(2)
	p._perform_dash(1.0)
	while p.dash.is_dodging: await frames()
	check(p.position.x < wall.position.x - 10 and not p.damage.is_invulnerable, "dash respects walls and still completes its phase/immunity cleanup")
	wall.queue_free()
	await reset()
	p._perform_dash(1.0)
	await frames(4)
	p.enter_rest(false)
	var rest_position: Vector2 = p.position
	await wait(0.6)
	check(p.position.is_equal_approx(rest_position) and p.velocity == Vector2.ZERO and p.dash.phase == DashComponent.Phase.IDLE, "interrupted dash has no leftover Tween or motion in rest")
	p.exit_rest()
	await reset()
	# A long fixture cooldown proves defense is independent of the next-dash lock.
	var scene_cooldown: float = p.dodge_cooldown.wait_time
	p.dodge_cooldown.wait_time = 0.5
	p._perform_dash(1.0)
	Input.action_press("guard and deflect")
	p._try_begin_guard()
	while p.dash.is_dodging: await frames()
	check(p.is_guarding and not p.dash.able_to_dodge and p.dodge_cooldown.time_left > 0.4, "held defense begins at skid end, long before cooldown finishes")
	check(p.spine_anim.assigned_animation == p.ANIM_DEFENSE and not p.defense.is_in_deflect_window(), "defense pose is immediate without granting a new deflect window")
	check(not p.dash.can_start(1.0, true), "cooldown still prevents another dash")
	Input.action_release("guard and deflect")
	p._release_guard_input()
	p.dodge_cooldown.wait_time = scene_cooldown
	await reset()
	# Removing the UI must not pause gameplay clocks or change stat ownership.
	var parent: Node = hud.get_parent()
	parent.remove_child(hud)
	p.vitals.simulation_enabled = true
	p.stats.stamina = 50.0
	p.stats._stamina_regen_time_left = 0.0
	p.stats.stamina_regen_per_second = 20.0
	await wait(0.22)
	check(p.stats.stamina > 53.0 and p.stats.stamina < 56.0, "stamina regenerates with no HUD in the scene")
	p.stats.hp = 100
	p.take_damage(5, p.global_position + Vector2(-80, 0))
	check(p.stats.hp == 95, "Player receives enemy-style damage with no HUD")
	p.stats.bleeding_level = 1
	p.stats._bleed_tick_timer = 0.99
	await wait(0.06)
	check(p.stats.hp == 92, "bleed still ticks with no HUD")
	p.stats.clear_all_debuffs()
	p.stats.hp = 40
	p.stats.restore_flask_charges()
	check(p.vitals.begin_flask_use(), "flask use can begin without a HUD")
	await wait(0.95)
	check(p.stats.hp == 74 and p.stats.flask_charges == 2 and not p.vitals.flask_in_progress, "flask completion is gameplay-owned and does not depend on a UI Tween")
	var saved: Dictionary = SaveManager._read_player_hp(get_tree())
	check(saved.hp == 74 and saved.max_hp == p.stats.max_hp, "save reads current Player HP without UI")
	SaveManager._apply_hp_to_hud(get_tree(), 55, 100)
	check(p.stats.hp == 55 and p.stats.stamina == p.stats.max_stamina, "save restoration updates Player stats without UI")
	SaveManager.heal_player_full(get_tree())
	check(p.stats.hp == p.stats.max_hp and p.stats.flask_charges == p.stats.max_flask_charges, "campfire healing uses Player stats without UI")
	var upgrades: int = PlayerProgress.hp_upgrades
	p.stats.hp = 50
	PlayerProgress.hp_upgrades += 1
	PlayerProgress._apply_hp_upgrade()
	check(p.stats.max_hp == 120 and p.stats.hp == 70, "HP upgrade still works without UI")
	PlayerProgress.hp_upgrades = upgrades
	PlayerProgress.apply_to_hud(get_tree())
	p.stats.hp = 100
	p.sentinel_hp_drain_percent = 20.0
	p.begin_sentinel()
	p.sentinel_state.tick(p.sentinel_entry_duration)
	await wait(0.22)
	check(p.sentinel_state.active and p.stats.hp < 100, "Sentinel drain works without HUD")
	p.end_sentinel()
	p.sentinel_hp_drain_percent = 2.0
	var health_before_attach: int = p.stats.hp
	parent.add_child(hud)
	p.vitals.refresh()
	check(hud._stats == p.stats and hud.hp == health_before_attach and hud.hp_bar.value == health_before_attach, "reattaching a HUD preserves stats and refreshes its presentation")
	parent.remove_child(hud)
	hud.free()
	hud = load("res://scenes/UI/hud.tscn").instantiate()
	parent.add_child(hud)
	check(hud._stats == p.stats and hud.hp == health_before_attach, "replacement HUD binds to existing Player model instead of resetting HP")
	hud.set_process(false)
	p.stats.stamina = 0.0
	p.stats._stamina_regen_time_left = 0.0
	await wait(0.22)
	check(p.stats.stamina > 3 and p.stats.stamina < 6, "disabling HUD processing does not stop or double-tick Player regeneration")
	get_tree().paused = true
	var paused_stamina: float = p.stats.stamina
	await wait(0.15)
	check(p.stats.stamina == paused_stamina, "pause still stops Player-owned vitals")
	get_tree().paused = false
	check(p.dodge_cooldown.wait_time == scene_cooldown, "authored cooldown remains unchanged after test fixtures")
	p.vitals.simulation_enabled = false
	SaveManager._data["scene_path"] = scene.scene_file_path
	SaveManager._data["spawn_position"] = {"x": origin.x, "y": origin.y}
	SaveManager._data["hp"] = 100
	SaveManager._data["max_hp"] = 100
	p.stats.hp = 5
	p.stats.stagger_tiers_ready[0] = false
	p.stats.stagger_tiers_ready[1] = false
	p.stats.stagger_lock_hp = -1
	p.stats.stagger_lock_timer = 0.0
	p.damage.reset()
	p.vitals.begin_flask_use()
	p.begin_sentinel()
	p.sentinel_state.tick(p.sentinel_entry_duration)
	p.stats.hp = 5
	p.stats.stagger_tiers_ready.assign([false, false])
	p.take_damage(20, p.global_position + Vector2(-80, 0))
	check(p.stats.hp == 100 and not p.sentinel_state.active and not p.vitals.flask_in_progress, "lethal damage respawns and clears Sentinel/flask state")
	await wait(1.0)
	check(p.stats.flask_charges == p.stats.max_flask_charges and not p.damage.is_invulnerable, "old life cannot consume a flask or leave immunity after respawn")
	p.damage.apply_stagger(Vector2.LEFT, 10.0, 0.15, 0.15, 0.5)
	SaveManager._restore_player(false)
	await wait(0.4)
	check(not p.damage.is_stunned and not p.damage.is_invulnerable and p.state_machine.is_in(S.LOCOMOTION), "checkpoint restoration invalidates previous-life stagger callbacks")
	var old_upgrades: int = PlayerProgress.hp_upgrades
	PlayerProgress.hp_upgrades = 1
	var bare = load("res://scenes/adel/playable_adel.tscn").instantiate()
	bare.get_node("Camera2D/hud").free()
	bare.position = origin + Vector2(3000, -100)
	scene.add_child(bare)
	check(bare.stats.max_hp == 120 and bare.stats.hp == 120, "Player authored without HUD initializes its own progression stats")
	bare.stats.hp = 90
	bare.take_damage(5, bare.global_position + Vector2(-80, 0))
	check(bare.stats.hp == 85, "Player authored without HUD accepts damage immediately")
	# Keep this extra actor until tree shutdown: the authored IK resource is shared.
	PlayerProgress.hp_upgrades = old_upgrades
	print("PLAYER REFACTOR RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
