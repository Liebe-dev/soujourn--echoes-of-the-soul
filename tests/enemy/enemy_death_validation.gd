extends Node
class Probe extends CharacterBody2D:
	var hits := 0
	func take_damage(_amount: int, _source: Vector2 = Vector2.INF) -> void: hits += 1

var checks := 0
var failures := 0
var scene
var player
var enemy
var rendered := false
var exp_events := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not ProjectSettings.get_setting("application/config/use_custom_user_dir", false) or not String(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("CodexEnemyDeath"):
		get_tree().quit(2)
		return
	Engine.max_fps = 120
	rendered = DisplayServer.get_name() != "headless"
	run.call_deferred()

func frame(count: int = 2) -> void:
	for i in count: await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("ENEMY DEATH ", "PASS " if ok else "FAIL ", label)

func button(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	await frame(1)

func spawn(pos: Vector2):
	var instance = load("res://scenes/enemy/spine_enemy.tscn").instantiate()
	instance.position = pos
	scene.add_child(instance)
	instance.set_physics_process(false)
	return instance

func capture(label: String) -> void:
	if not rendered: return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://enemy-death-" + label + ".png")

func run() -> void:
	if rendered:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1280, 720)
		get_window().position = Vector2i(40, 40)
		get_window().grab_focus()
		await wait(0.15)
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	player = scene.get_node("PlayableAdel")
	enemy = scene.get_node("Enemy")
	enemy.set_physics_process(false)
	player.hit_stop_enabled = false
	var deadline := Time.get_ticks_msec() + 5000
	while not player.is_on_floor() and Time.get_ticks_msec() < deadline: await frame(1)
	enemy.position = player.position + Vector2(400, 25)
	var death_clip: Animation = enemy.animation_player.get_animation(&"death")
	check(death_clip.length == 10.0 and death_clip.loop_mode == Animation.LOOP_NONE, "authored death clip lasts ten seconds without looping")
	var has_fade := false
	for track in death_clip.get_track_count():
		if String(death_clip.track_get_path(track)) == "Skeleton2D:modulate": has_fade = true
	check(has_fade, "existing skeleton fading track is used")
	var probe := Probe.new()
	probe.add_to_group("Player")
	scene.add_child(probe)
	enemy.target = probe
	enemy.attack_animation = &"attack2"
	enemy._enter_state(enemy.State.MELEE)
	enemy._swing_damage = 12
	enemy._set_damage_window(true)
	var camera = player.get_node("Camera2D")
	camera.target_lock.locked = enemy
	camera.target_lock._had_lock = true
	PlayerProgress.level = 1
	PlayerProgress.exp = 0
	PlayerProgress.exp_changed.connect(func(_exp, _needed, _level): exp_events += 1)
	enemy.current_health = 20
	player.saber_hitbox.play_attack_window(&"saber_attack_1", 20)
	player.saber_hitbox._on_hitbox_body_entered(enemy)
	player.saber_hitbox.stop_attack_window()
	var started := Time.get_ticks_msec()
	check(enemy.is_dead and enemy.current_health == 0 and enemy.state == enemy.State.DEAD, "lethal Saber hit immediately enters terminal death state")
	check(enemy.animation_player.assigned_animation == &"death" and enemy.animation_player.is_playing(), "death animation starts immediately from active melee")
	check(not enemy.is_queued_for_deletion() and enemy.velocity == Vector2.ZERO, "corpse remains for animation and lethal hit stops active lunge velocity")
	check(not enemy._window_open and enemy._active_hitbox == null and enemy.target == null, "death immediately closes damage logic and clears target")
	check(PlayerProgress.exp == enemy.exp_reward and exp_events == 1, "EXP granted once at the lethal hit")
	check(not enemy.take_damage(100), "corpse rejects further damage immediately")
	enemy.die()
	check(exp_events == 1 and PlayerProgress.exp == enemy.exp_reward, "repeated death cannot grant more EXP")
	check(enemy.get_lock_on_point() == Vector2.INF and not enemy.is_in_group(&"camera_lock_targets"), "corpse immediately ceases to be a lock-on target")
	check(not player.saber_skill._valid_enemy(enemy), "Q excludes the corpse before physics caches update")
	await frame(3)
	check(camera.target_lock.locked == null, "existing camera lock releases the killed enemy")
	check(enemy.get_node("CollisionShape2D").disabled and enemy.hitbox_shape.disabled and enemy.leap_hitbox_shape.disabled, "hurtbox and both offensive shapes are disabled")
	check(enemy.collision_layer == 0 and enemy.collision_mask == enemy.corpse_terrain_mask and not enemy.hitbox.monitoring and not enemy.leap_hitbox.monitoring, "combat layers are disabled while corpse only collides with terrain")
	check(enemy.hitbox.collision_layer == 0 and enemy.hitbox.collision_mask == 0 and enemy.leap_hitbox.collision_layer == 0 and enemy.leap_hitbox.collision_mask == 0, "all offensive collision layers and masks are cleared")
	enemy._try_hit_body(probe)
	enemy._apply_swing_damage()
	enemy._apply_leap_contact_damage()
	check(probe.hits == 0, "corpse cannot deal damage through cached contacts")
	enemy._enter_state(enemy.State.RUN)
	enemy._set_animation(&"attack3")
	enemy._set_damage_window(true)
	enemy._on_animation_finished(&"detect player")
	check(enemy.state == enemy.State.DEAD and enemy.animation_player.assigned_animation == &"death" and not enemy._window_open, "stale state/animation callbacks cannot reopen combat")
	await capture("start")
	# Existing Q stun must not resume or move the enemy after lethal damage.
	var stunned = spawn(Vector2(2600, 400))
	stunned.set_physics_process(true)
	var stun = load("res://scenes/adel/components/enemy_skill_stun.gd").new()
	stun.name = "WeaponSkillStun"
	stun.remaining = 0.4
	stunned.add_child(stun)
	stunned.take_damage(1000)
	var corpse_position: Vector2 = stunned.position
	check(stunned.animation_player.assigned_animation == &"death" and stun.is_queued_for_deletion(), "dying while Q-stunned cancels stun and starts death")
	await wait(0.5)
	check(not is_instance_valid(stun) and stunned.is_physics_processing() and stunned.state == stunned.State.DEAD and stunned.position.y > corpse_position.y and is_equal_approx(stunned.position.x, corpse_position.x), "stun expiry cannot restore AI or interrupt corpse fall")
	check(stunned.animation_player.is_playing() and stunned.animation_player.assigned_animation == &"death" and not stunned.hitbox.monitoring, "stun cleanup does not interrupt death or re-enable hitbox")
	var living = spawn(Vector2(2200, 500))
	living.set_physics_process(true)
	var short_stun = load("res://scenes/adel/components/enemy_skill_stun.gd").new()
	short_stun.name = "WeaponSkillStun"
	short_stun.remaining = 0.08
	living.add_child(short_stun)
	await wait(0.15)
	check(not is_instance_valid(short_stun) and living.is_physics_processing() and living.animation_player.is_playing() and living.hitbox.monitoring, "nonlethal skill stun still restores a living enemy normally")
	living.queue_free()
	var leaping = spawn(Vector2(2400, 350))
	leaping.target = probe
	leaping._enter_state(leaping.State.LEAP)
	leaping.velocity = Vector2(200, -300)
	leaping.take_damage(1000)
	await frame(3)
	check(is_zero_approx(leaping.velocity.x) and leaping.velocity.y > 0.0 and not leaping._window_open and leaping.leap_hitbox_shape.disabled and leaping.animation_player.assigned_animation == &"death", "death during leap stops horizontal motion, falls and closes the body damage area")
	leaping.animation_player.advance(10.0)
	# A real charged Q lethal hit must not attach a fresh stun to the corpse.
	var victim = spawn(player.position + Vector2(120, 0))
	victim.current_health = 20
	player._set_facing_direction(1)
	await button(&"weapon_skill", true)
	deadline = Time.get_ticks_msec() + 3000
	while player.saber_skill.charge_time < player.saber_skill.charge_level_1_time + 0.03 and Time.get_ticks_msec() < deadline: await frame(1)
	await button(&"weapon_skill", false)
	deadline = Time.get_ticks_msec() + 3000
	while not player.saber_skill._confirmed and Time.get_ticks_msec() < deadline: await frame(1)
	check(player.saber_skill._confirmed and victim.is_dead and victim.animation_player.assigned_animation == &"death", "actual charged Q lethal hit plays death")
	await frame(3)
	check(victim.get_node_or_null("WeaponSkillStun") == null and victim.is_physics_processing() and victim.state == victim.State.DEAD, "charged lethal Q never freezes death or corpse fall with a newly attached stun")
	# Pause and global slow motion control playback, not a separate wall-time deletion.
	var paused = spawn(Vector2(2900, 500))
	paused.take_damage(1000)
	get_tree().paused = true
	var paused_at: float = paused.animation_player.current_animation_position
	await wait(0.18)
	check(paused.animation_player.current_animation_position == paused_at and is_instance_valid(paused), "pause freezes death clip and preserves corpse")
	get_tree().paused = false
	await wait(0.1)
	check(paused.animation_player.current_animation_position > paused_at, "resuming continues death playback")
	paused.animation_player.advance(10.0)
	await frame(3)
	check(not is_instance_valid(paused), "death completion signal removes the corpse")
	deadline = Time.get_ticks_msec() + 3000
	while player.saber_skill.is_active() and Time.get_ticks_msec() < deadline: await frame(1)
	CombatTime.request(self, &"death_test", 0.5, 0.4)
	var slow = spawn(Vector2(3100, 500))
	slow.take_damage(1000)
	await wait(0.2)
	check(slow.animation_player.current_animation_position > 0.03 and slow.animation_player.current_animation_position < 0.17, "global slow motion also slows the authored death animation")
	CombatTime.remove(self, &"death_test")
	slow.animation_player.advance(10.0)
	await frame(3)
	# Keep the primary corpse on real playback through the authored fade and ten-second end.
	deadline = Time.get_ticks_msec() + 14000
	while is_instance_valid(enemy) and enemy.animation_player.current_animation_position < 6.0 and Time.get_ticks_msec() < deadline: await frame(1)
	check(is_instance_valid(enemy), "corpse is retained until its ten-second animation ends")
	if is_instance_valid(enemy):
		var skeleton: Node2D = enemy.rig.get_node("Skeleton2D")
		check(skeleton.modulate.a > 0.1 and skeleton.modulate.a < 0.9, "original animation applies partial fade without extra tween")
		await capture("fading")
		while is_instance_valid(enemy) and enemy.animation_player.current_animation_position < 9.7 and Time.get_ticks_msec() < deadline: await frame(1)
		check(is_instance_valid(enemy), "corpse still exists immediately before ten game seconds")
		while is_instance_valid(enemy) and Time.get_ticks_msec() < deadline: await frame(1)
	check(not is_instance_valid(enemy) and Time.get_ticks_msec() - started >= 9900, "natural ten-second playback removes enemy from map")
	# Base/prototype contract remains immediate, unlike animated SpineEnemy.
	var legacy = load("res://scenes/enemy/enemy_base.gd").new()
	var body_shape := CollisionShape2D.new()
	body_shape.name = "CollisionShape2D"
	body_shape.shape = CapsuleShape2D.new()
	legacy.add_child(body_shape)
	scene.add_child(legacy)
	legacy.take_damage(1000)
	check(legacy.is_queued_for_deletion(), "EnemyBase default still removes legacy enemies immediately")
	await frame(3)
	check(not is_instance_valid(legacy), "legacy removal is not delayed by SpineEnemy presentation")
	# Real restart reloads the scene; death state is never persisted.
	var old_scene = scene
	check(SaveManager.restart_current_area(), "actual Restart Area accepts scene reload after death")
	await frame(8)
	scene = get_tree().current_scene
	var restored = scene.get_node_or_null("Enemy")
	check(not is_instance_valid(old_scene) and is_instance_valid(restored) and not restored.is_dead and restored.current_health == restored.max_health, "reset recreates enemy alive at full HP")
	check(not restored.get_node("CollisionShape2D").disabled and restored.collision_layer == 4 and restored.rig.get_node("Skeleton2D").modulate.a == 1.0, "reset restores hurtbox, collision and full opacity")
	restored.take_damage(1000)
	var old_corpse = restored
	check(is_instance_valid(old_corpse) and old_corpse.animation_player.assigned_animation == &"death", "second death also waits for animation")
	check(SaveManager.restart_current_area(), "reset during fading corpse succeeds")
	await frame(8)
	restored = get_tree().current_scene.get_node_or_null("Enemy")
	check(not is_instance_valid(old_corpse) and is_instance_valid(restored) and not restored.is_dead, "reset during death discards old corpse and respawns enemy")
	print("ENEMY DEATH RESULT checks=", checks, " failures=", failures, " display=", DisplayServer.get_name())
	get_tree().quit(1 if failures else 0)
