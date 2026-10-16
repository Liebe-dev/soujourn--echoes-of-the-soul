extends Node
const S = AdelStateMachine.State
var checks := 0
var failures := 0
var p
var hud
var origin: Vector2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("SENTINEL ENTRY ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func reset() -> void:
	for action in ["move_right", "jump", "dodge", "attack", "weapon_skill", "guard and deflect"]: Input.action_release(action)
	p.end_sentinel()
	p.clear_combat_input()
	p.damage.reset()
	p.state_machine.resume_locomotion()
	p.stats.max_hp = 100
	p.stats.max_stamina = 100.0
	p.stats.heal_to_full()
	p.stats.stagger_thresholds_enabled = true
	p.sentinel_hp_drain_percent = 2.0
	p.position = origin
	p.velocity = Vector2.ZERO
	p.set_physics_process(false)

func active_mode(health: int) -> void:
	reset()
	p.begin_sentinel()
	p.sentinel_state.tick(1.5)
	p.stats.hp = health
	p.vitals.refresh()

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexSentinelEntry20261016"):
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
	p.stagger_zoom_enabled = false
	p.stagger_slow_motion_enabled = false
	p.hit_stop_enabled = false
	await frames(65)
	hud = p.get_node("Camera2D/hud")
	origin = p.position
	p.vitals.simulation_enabled = false
	reset()
	p.stats.hp = 10
	p.stats.stamina = 3.0
	p.stats.flask_charges = 1
	p.stats.stagger_tiers_ready.assign([false, false])
	p.stats.stagger_lock_hp = 66
	p.stats.stagger_lock_timer = 1.0
	p._playing_land_anim = true
	p.is_skidding = true
	check(p.begin_sentinel(), "activation accepted for living Player")
	check(not p._playing_land_anim and not p.is_skidding, "entry clears landing and skid animation flags so old clips cannot strand locomotion")
	check(p.is_sentinel_entering() and p.state_machine.current == S.SENTINEL_ENTRY and not p.can_move, "entry owns HFSM and movement lock")
	check(p.stats.hp == 10 and p.stats.stamina == 3, "entry does not instantly refill vitals")
	check(p.stats.stagger_tiers_ready == [true, true] and not p.stats.stagger_thresholds_enabled and p.stats.stagger_lock_timer == 0, "entry restores and suspends all thresholds, clearing old HP floor")
	p.take_damage(1000)
	var hit: Dictionary = hud.apply_damage(1000)
	check(p.stats.hp == 10 and not hit.get("died", false) and p.damage.is_invulnerable, "entry blocks actual damage and HUD damage facade")
	p.sentinel_state.tick(0.014)
	check(p.stats.hp == 10 and p.stats.stamina == 3, "recovery waits for first 0.015-second tick")
	p.sentinel_state.tick(0.001)
	check(p.stats.hp == 11 and p.stats.stamina == 4, "each tick restores one percent of both maximum vitals")
	p.sentinel_state.tick(0.735)
	check(p.stats.hp == 60 and p.stats.stamina == 53, "halfway entry has exactly fifty recovery ticks")
	for action in ["attack", "weapon_skill", "guard and deflect", "soul_heal"]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = true
		p._unhandled_input(event)
	p._handle_attack_input()
	p._perform_dash(1.0)
	p.request_weapon_skill()
	p._try_begin_guard()
	p.play_pickup_animation()
	check(not p.saber_skill.begin() and not p.dash.start_dash(1.0, true, 1), "direct skill and dash APIs reject entry")
	check(not p.vitals.begin_flask_use() and not p.vitals.flask_in_progress, "flask use is blocked during entry")
	check(not p.begin_campfire_ui(self), "entry cannot open campfire")
	check(p.state_machine.current == S.SENTINEL_ENTRY and not p._skill_requested and not p._guard_requested and not p.combat.attack_queued, "gameplay inputs do not interrupt entry or queue later actions")
	p.velocity = Vector2(900, -900)
	p.state_machine.physics_update(0.1)
	check(p.velocity == Vector2.ZERO and p.position == origin, "entry freezes horizontal and vertical movement")
	var extra: int = p.damage.grant_invulnerability(&"entry_test_other")
	p.sentinel_state.tick(0.749)
	check(p.is_sentinel_entering() and p.damage.is_invulnerable, "lock and immunity remain until the full 1.5 seconds")
	p.sentinel_state.tick(0.001)
	check(not p.is_sentinel_entering() and p.is_sentinel_active() and p.can_move, "entry ends at 1.5 seconds and returns movement")
	check(p.stats.hp == 100 and p.stats.stamina == 100 and p.stats.flask_charges == 1, "entry refills HP and stamina without refilling flasks")
	check(p.damage.is_invulnerable, "ending entry preserves another immunity source")
	p.damage.release_invulnerability(&"entry_test_other", extra)
	check(not p.damage.is_invulnerable, "entry releases its own immunity without leaving a stale source")
	check(not p.combat.attack_queued and not p._skill_requested and not p._guard_requested, "blocked inputs do not replay after entry")
	reset()
	p.saber_skill.allow_airborne = true
	check(p.saber_skill.begin(), "Q can be active before transformation")
	p.begin_sentinel()
	check(not p.saber_skill.is_active() and p.state_machine.current == S.SENTINEL_ENTRY, "transformation interrupts Q and takes exclusive action ownership")
	reset()
	p._perform_dash(1.0)
	check(p.dash.is_dodging, "dash can be active before transformation")
	p.begin_sentinel()
	check(not p.dash.is_dodging and p.damage.is_invulnerable and p.velocity == Vector2.ZERO, "transformation cleans dash motion and protection without losing entry immunity")
	reset()
	p.stats.max_hp = 137
	p.stats.max_stamina = 115.0
	p.stats.hp = 1
	p.stats.stamina = 0
	p.begin_sentinel()
	p.sentinel_state.tick(0.75)
	check(p.stats.hp == 69 and is_equal_approx(p.stats.stamina, 57.5), "fractional recovery is retained for non-100 maximum vitals")
	p.sentinel_state.tick(0.75)
	check(p.stats.hp == 137 and p.stats.stamina == 115, "recovery finishes exactly full without rounding loss")
	for fps in [30, 60, 120]:
		reset()
		p.stats.hp = 1
		p.stats.stamina = 0
		p.begin_sentinel()
		for i in int(fps * 1.5): p.sentinel_state.tick(1.0 / fps)
		check(not p.is_sentinel_entering() and p.stats.hp == 100 and p.stats.stamina == 100, "entry is stable at %d physics ticks per second" % fps)
	active_mode(67)
	p.sentinel_state.tick(1.0)
	check(p.stats.hp == 65 and p.stats.stagger_tiers_ready == [true, true] and not p.damage.is_stunned and not p.stats.has_any_debuff(), "drain crosses threshold without consuming markers, stagger or debuff")
	check(p.vitals.spend_sentinel_hp(40) and p.stats.hp == 25 and p.stats.stagger_tiers_ready == [true, true] and not p.stats.has_any_debuff(), "skill HP cost bypasses damage and threshold resolution")
	check(not p.vitals.spend_sentinel_hp(25) and p.stats.hp == 25, "unaffordable skill cost is rejected without spending HP")
	p.damage.apply_stagger(Vector2.LEFT)
	check(not p.damage.is_stunned, "active Sentinel also resists exhausted-guard stagger reactions")
	p.end_sentinel()
	check(p.stats.stagger_thresholds_enabled and p.stats.stagger_tiers_ready == [true, true] and p.stats.hp == 25 and not p.damage.is_stunned, "exit re-enables markers without immediately triggering or healing")
	hit = p.stats.apply_damage(99)
	check(hit.staggered and hit.stagger_tier == 0 and p.stats.hp == 25 and p.stats.stagger_tiers_ready == [false, true], "first new hit triggers only outermost 66-percent marker without healing")
	check(hit.debuff_id in ["bleeding", "fracture"], "deferred marker grants normal random debuff")
	p.stats.tick(1.1, true)
	hit = p.stats.apply_damage(99)
	check(hit.staggered and hit.stagger_tier == 1 and p.stats.hp == 25 and p.stats.stagger_tiers_ready == [false, false], "second new hit triggers only remaining 33-percent marker")
	p.stats.tick(1.1, true)
	hit = p.stats.apply_damage(99)
	check(hit.died and p.stats.hp == 0, "enemy damage is lethal after available threshold protections are spent")
	active_mode(20)
	p.end_sentinel()
	p.stats.bleeding_level = 1
	var bleed: Dictionary = p.stats.tick(1.1)
	check(bleed.damage_taken > 0 and p.stats.stagger_tiers_ready == [true, true], "bleeding ticks still bypass deferred thresholds")
	hit = p.stats.apply_damage(1)
	check(hit.staggered and hit.stagger_tier == 0, "direct hits can trigger deferred markers while bleeding")
	active_mode(50)
	p.end_sentinel()
	hit = p.stats.apply_damage(3)
	check(hit.staggered and hit.stagger_tier == 0 and p.stats.hp == 50, "exit between markers defers only the already-passed outer marker")
	p.stats.tick(1.1, true)
	hit = p.stats.apply_damage(50)
	check(hit.staggered and hit.stagger_tier == 1 and p.stats.hp == 33, "remaining lower marker still clamps ordinary threshold crossing")
	active_mode(20)
	p.end_sentinel()
	p.take_damage(5, p.global_position + Vector2(80, 0))
	check(p.damage.is_stunned and p.state_machine.current == S.KNOCKBACK and p.damage.is_invulnerable and p.stats.hp == 20, "actual Player hit after exit runs stagger animation, knockback and i-frame without healing")
	check(p.stats.stagger_tiers_ready == [false, true] and p.stats.has_any_debuff(), "actual Player hit consumes only one restored marker and grants debuff")
	active_mode(20)
	p.end_sentinel()
	hit = p.stats.apply_damage(1, Vector2.INF, true)
	check(not hit.staggered and p.stats.stagger_tiers_ready == [true, true], "explicit exhausted-guard threshold bypass remains intact")
	active_mode(21)
	check(p.vitals.spend_sentinel_hp(20) and p.stats.hp == 1 and not p.is_sentinel_active(), "affordable cost to one HP follows safe nonlethal exit")
	active_mode(21)
	p._handle_attack_input()
	check(p.state_machine.current == S.COMBO and p.vitals.spend_sentinel_hp(20) and p.is_sentinel_exit_pending() and not p.damage.is_stunned, "cost reaching one HP waits for an ongoing action without stagger")
	check(not p.vitals.spend_sentinel_hp(0), "pending exit rejects further skill costs")
	p.state_machine.resume_locomotion()
	p.sentinel_state.tick(0.0)
	check(not p.is_sentinel_active() and p.stats.hp == 1, "cost-driven pending exit finishes at the safe action boundary")
	active_mode(20)
	p.stats.stagger_tiers_ready.assign([false, false])
	hit = p.stats.apply_damage(999)
	check(hit.died, "enemy damage can kill active Sentinel outside entry")
	p.sentinel_state.tick(1.0)
	check(p.stats.hp == 0 and not p.is_sentinel_active(), "dead Sentinel never heals or resurrects on tick")
	reset()
	p.stats.hp = 10
	p.stats.stamina = 0
	p.stats.bleeding_level = 1
	p.stats._bleed_tick_timer = 0.99
	p.begin_sentinel()
	p.vitals.simulation_enabled = true
	p.set_physics_process(true)
	Input.action_press("move_right")
	Input.action_press("jump")
	await wait(0.15)
	check(p.position.distance_to(origin) < 0.01 and p.velocity == Vector2.ZERO and p.stats.hp > 10 and p.stats.hp < 30, "runtime entry heals gradually while movement and jump stay frozen")
	check(p.stats.hp == 10 + int(floor((p.sentinel_state._entry_elapsed + 0.000001) / 0.015)), "entry i-frame also blocks a due bleed tick while normal regeneration stays suspended")
	get_tree().paused = true
	var before: int = p.stats.hp
	await wait(0.2)
	check(p.stats.hp == before and p.is_sentinel_entering() and p.damage.is_invulnerable, "pause freezes recovery, lock duration and entry immunity")
	get_tree().paused = false
	Input.action_release("move_right")
	Input.action_release("jump")
	CombatTime.set_actor_exempt(p, true)
	CombatTime.request(self, &"entry_test_slow", 0.5, 2.0)
	before = p.stats.hp
	await wait(0.4)
	check(p.stats.hp - before >= 10 and p.stats.hp - before <= 16 and p.is_sentinel_entering(), "entry uses slowed world time even when Player is actor-exempt")
	CombatTime.remove(self)
	CombatTime.set_actor_exempt(p, false)
	await wait(1.3)
	check(not p.is_sentinel_entering() and not p.damage.is_invulnerable and p.can_move, "actual runtime releases lock and immunity after game-time entry")
	p.set_physics_process(false)
	p.vitals.simulation_enabled = false
	reset()
	p.damage.apply_stagger(Vector2.LEFT, 20.0, 0.05, 0.05, 0.2)
	p.begin_sentinel()
	await wait(0.3)
	check(p.state_machine.current == S.SENTINEL_ENTRY and not p.damage.is_stunned and p.damage.is_invulnerable, "old stagger callbacks cannot interrupt a new entry")
	p.restore_checkpoint_state(origin, false)
	check(not p.is_sentinel_active() and not p.is_sentinel_entering() and not p.damage.is_invulnerable and p.can_move and p.stats.stagger_thresholds_enabled, "checkpoint restoration clears entry lock and immunity and re-enables thresholds")
	reset()
	p.stats.hp = 1
	p.begin_sentinel()
	p.stats.hp = 0
	p.sentinel_state.tick(0.1)
	check(not p.is_sentinel_active() and p.stats.hp == 0 and not p.damage.is_invulnerable, "entry cancellation at zero HP releases protection without revival")
	print("SENTINEL ENTRY RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
