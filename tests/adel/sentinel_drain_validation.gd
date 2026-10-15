extends Node

var checks := 0
var failures := 0
var player
var hud
var world_time := 0.0
const S = AdelStateMachine.State

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func _physics_process(delta: float) -> void:
	world_time += delta

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("SENTINEL DRAIN ", "PASS " if ok else "FAIL ", label)

func frame(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frame()
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	Input.parse_input_event(event)
	await frame()

func reset_mode(health: int = 100) -> void:
	player.end_sentinel()
	player.clear_combat_input()
	player.state_machine.resume_locomotion()
	player.combat.combo_step = 0
	player.damage.is_invulnerable = false
	hud.max_hp = 100
	hud.hp = health
	hud.stamina = 100.0
	player.sentinel_hp_drain_percent = 2.0
	player.begin_sentinel()

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexSentinelDrain20261016"):
		get_tree().quit(2)
		return
	Engine.max_fps = 120
	var scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	player = scene.get_node("PlayableAdel")
	scene.get_node("Enemy").set_physics_process(false)
	scene.get_node("Enemy").position.x = 6000.0
	await frame(65)
	hud = player.get_node("Camera2D/hud")
	hud.set_process(false)
	player.vitals.simulation_enabled = false
	player.set_physics_process(false)
	for fps in [30, 60, 120]:
		reset_mode()
		for i in fps: player.sentinel_state.tick(1.0 / fps)
		check(hud.hp == 98, "2 percent max HP per second at %d ticks/sec" % fps)
	reset_mode()
	hud.max_hp = 250
	hud.hp = 200
	player.sentinel_state.tick(1.0)
	check(hud.hp == 195, "rate uses maximum HP, not current HP")
	reset_mode()
	player.sentinel_state.tick(0.25)
	check(hud.hp == 100, "sub-point drain is retained rather than rounded up every frame")
	player.sentinel_state.tick(0.25)
	check(hud.hp == 99 and hud.hp_bar.value == 99, "fractional accumulation spends one HP and synchronizes HUD")
	reset_mode(67)
	var tiers = hud.stagger_tiers_ready.duplicate()
	var debuffs = [hud.bleeding_level, hud.fracture_level]
	hud.stagger_lock_hp = 66
	hud.stagger_lock_timer = 1.0
	player.sentinel_state.tick(2.0)
	check(hud.hp == 63 and hud.stagger_tiers_ready == tiers and not player.damage.is_stunned, "drain bypasses threshold and its temporary HP floor without stagger")
	check([hud.bleeding_level, hud.fracture_level] == debuffs and not player.damage.is_invulnerable, "drain does not apply debuffs or damage i-frames")
	hud.stagger_lock_hp = -1
	hud.stagger_lock_timer = 0.0
	reset_mode(2)
	player.sentinel_state.tick(10.0)
	check(hud.hp == 1 and not player.sentinel_state.active and not hud.sentinel_active, "large delta stops at one HP and exits immediately from locomotion")
	check(not hud.sentinel_loadout.exit_pending and hud.hp_bar.texture_progress == hud._normal_hp_fill, "automatic exit restores HUD and clears pending visuals")
	reset_mode(2)
	player._handle_attack_input()
	check(player.state_machine.current == S.COMBO, "real attack starts before depletion")
	player.combat.handle_attack_input(true)
	player.sentinel_state.tick(1.0)
	check(hud.hp == 1 and player.is_sentinel_exit_pending() and hud.sentinel_loadout.exit_pending, "depletion during attack enters pending exit")
	check(not player.combat.attack_queued and player.state_machine.current == S.COMBO, "pending exit clears buffered next combo without cancelling current swing")
	var step: int = player.combat.combo_step
	player._handle_attack_input()
	player._advance_queued_combo()
	check(player.combat.combo_step == step and not player.combat.attack_queued, "new attack and early combo advancement are rejected while pending")
	check(not player.saber_skill.begin(), "pending exit rejects new Q skill")
	var stamina: float = hud.stamina
	player._perform_dash(1.0)
	check(player.state_machine.current == S.COMBO and hud.stamina == stamina, "pending exit rejects new dash without spending stamina")
	player.sentinel_state.tick(30.0)
	check(hud.hp == 1 and player.sentinel_state.active, "HP stays at one while original action is in progress")
	player.set_physics_process(true)
	await frame(55)
	check(not player.sentinel_state.active and player.combat.combo_step <= 1, "actual attack animation finishes before form exits, without chained combo")
	player.set_physics_process(false)
	reset_mode(1)
	player._guard_press_age = 1.0
	player.state_machine.transition(S.DEFENSE_HOLD)
	player.sentinel_state.tick(0.0)
	check(not player.sentinel_state.active and player.is_guarding, "defense never delays exit and stance remains functional")
	player.clear_combat_input()
	reset_mode(2)
	player._perform_dash(1.0)
	player.sentinel_state.tick(1.0)
	check(player.is_sentinel_exit_pending() and player.state_machine.current == S.DASH_ACTIVE and hud.hp == 1, "dash does not block self-drain and remains active while exit waits")
	player.set_physics_process(true)
	await frame(20)
	check(player.sentinel_state.active and player.state_machine.current == S.DASH_SKID, "deferred exit includes ground skid")
	await frame(20)
	check(not player.sentinel_state.active and not player.state_machine.is_in(S.DASH), "exit happens after actual dash/skid completion without waiting for cooldown")
	player.set_physics_process(false)
	reset_mode(3)
	hud.hp = 0
	player.sentinel_state.tick(5.0)
	check(hud.hp == 0 and not player.sentinel_state.active, "dead HP is never clamped back to one or resurrected")
	check(hud.drain_hp_nonlethal(100) == 0 and hud.hp == 0, "nonlethal spending preserves already-dead stats")
	reset_mode(2)
	var result: Dictionary = hud._stats.apply_damage(5, Vector2.INF, true)
	player.sentinel_state.tick(0.0)
	check(result.died and hud.hp == 0 and not player.sentinel_state.active, "normal damage model can kill an active Sentinel, unlike drain")
	reset_mode(100)
	player.end_sentinel()
	hud.set_ultimate_charge(100.0)
	await key(KEY_R)
	check(player.sentinel_state.active and hud.sentinel_active and hud.ultimate_meter.charge == 0.0, "real R routes full meter into gameplay drain state")
	player.set_physics_process(true)
	await get_tree().create_timer(0.6, true, false, true).timeout
	check(hud.hp <= 99 and hud.hp >= 98, "actual runtime physics drains HP over game time")
	get_tree().paused = true
	var paused_hp: int = hud.hp
	await get_tree().create_timer(0.3, true, false, true).timeout
	check(hud.hp == paused_hp, "tree pause stops drain")
	get_tree().paused = false
	await key(KEY_T)
	check(hud.ultimate_meter.charge == 0.0, "debug T cannot refill meter during active form")
	await key(KEY_Y)
	var exited_hp: int = hud.hp
	await frame(35)
	check(not player.sentinel_state.active and hud.hp == exited_hp, "Y stops drain immediately and preserves current HP")
	reset_mode()
	player.sentinel_hp_drain_percent = 20.0
	var start_world := world_time
	CombatTime.set_actor_exempt(player, true)
	CombatTime.request(self, &"sentinel_time_test", 0.5, 2.0)
	await get_tree().create_timer(0.65, true, false, true).timeout
	var elapsed := world_time - start_world
	var spent: int = 100 - hud.hp
	check(Engine.time_scale == 0.5 and elapsed > 0.2 and elapsed < 0.5, "runtime slow motion scales game time")
	check(absf(float(spent) - elapsed * 20.0) <= 1.1 and spent < 10, "drain uses slowed world time even when Player has actor exemption")
	CombatTime.set_actor_exempt(player, false)
	CombatTime.remove(self)
	player.end_sentinel()
	player.set_physics_process(false)
	reset_mode(2)
	player.saber_skill.allow_airborne = true
	Input.action_press("weapon_skill")
	check(player.saber_skill.begin(), "real Q can already be charging at time of depletion")
	player.sentinel_state.tick(1.0)
	check(player.is_sentinel_exit_pending() and player.saber_skill.is_active(), "depletion does not abort an ongoing charge")
	player.set_physics_process(true)
	await frame(140)
	check(not player.sentinel_state.active and not player.saber_skill.is_active(), "held Q auto-releases and finishes before pending exit")
	Input.action_release("weapon_skill")
	await frame(5)
	# Review-only reproduction: an earlier normal-hit timer expires inside a new dash.
	player.damage.start_invulnerability(0.1)
	player._perform_dash(1.0)
	await frame(8)
	var overlap_bug: bool = player.state_machine.current == S.DASH_ACTIVE and not player.damage.is_invulnerable and player.damage.can_take_damage()
	check(not overlap_bug and player.damage.is_invulnerable, "earlier hit timer cannot remove active dash protection")
	await frame(35)
	print("SENTINEL DRAIN RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
