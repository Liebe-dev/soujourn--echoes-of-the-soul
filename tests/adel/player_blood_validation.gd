extends SceneTree

var checks := 0
var failures := 0
var actor: CharacterBody2D
var blood: PlayerBlood
var stage: Node2D

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		quit(2)
		return
	var watchdog := Timer.new()
	watchdog.wait_time = 35.0
	watchdog.ignore_time_scale = true
	watchdog.one_shot = true
	watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(watchdog)
	watchdog.timeout.connect(func() -> void:
		paused = false
		Engine.time_scale = 1.0
		push_error("Blood validation timeout")
		quit(2))
	watchdog.start()
	stage = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	actor = stage.get_node("PlayableAdel")
	for name in ["Enemy", "SpineEnemy"]:
		var enemy := stage.get_node(name) as Node2D
		enemy.set_physics_process(false)
		enemy.global_position.x = 10000
	actor.set_physics_process(false)
	actor.vitals.simulation_enabled = false
	actor.spine_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	blood = actor.player_blood
	for test: StringName in [&"test_damage_and_random", &"test_recovery_events", &"test_mapping_and_transition", &"test_lifetime_and_cleanup"]:
		if await call(test) != true: check(false, "%s returned normally" % test)
	paused = false
	Engine.time_scale = 1.0
	watchdog.queue_free()
	stage.queue_free()
	await process_frame
	print("PLAYER BLOOD RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + label)

func reset_actor() -> void:
	actor.end_sentinel()
	actor.damage.reset()
	actor.defense.end_guard()
	actor.stats.max_hp = 100
	actor.stats.hp = 100
	actor.stats.stagger_thresholds_enabled = true
	actor.stats.heal_to_full()
	actor.state_machine.resume_locomotion()
	blood.clear_blood()

func test_damage_and_random() -> bool:
	reset_actor()
	actor.take_damage(10, actor.global_position + Vector2(80,0))
	check(blood.groups.is_empty(), "ordinary accepted HP damage creates no wound")
	actor.damage.reset()
	actor.take_damage(30, actor.global_position + Vector2(80,0))
	check(blood.groups.size() == 1, "accepted HP stagger creates one group")
	check(blood.groups[0].tier == 0 and blood.groups[0].sites.size() == 2, "group bound to broken bar and two body sites")
	check(blood.groups[0].sites[0] != blood.groups[0].sites[1], "body sites distinct")
	check(actor.damage.is_stunned, "existing gameplay stagger still applied")
	var group_before := JSON.stringify(blood.groups)
	actor._on_damage_stagger_recovered()
	check(JSON.stringify(blood.groups) == group_before, "stand-up does not clear/fade wound")
	reset_actor()
	actor.damage.start_invulnerability(1.0)
	actor.take_damage(80)
	check(blood.groups.is_empty() and actor.stats.hp == 100, "iframe damage rejected with no blood")
	actor.damage.reset()
	actor._apply_stamina_exhaustion(Vector2.INF)
	check(blood.groups.is_empty(), "stamina exhaustion creates no HP wound")
	reset_actor()
	actor.defense.begin_guard(actor.defense.deflect_delay + actor.defense.deflect_window * 0.5)
	actor.take_damage(80, actor.global_position + Vector2(80 * actor.facing_direction,0))
	check(blood.groups.is_empty() and actor.stats.hp == 100, "successful deflect creates no blood")
	reset_actor()
	actor.vitals.drain_hp_nonlethal(50)
	check(blood.groups.is_empty(), "self drain does not stain")
	actor.stats.bleeding_level = 2
	actor.vitals.tick(1.1, 1.1)
	check(blood.groups.is_empty(), "bleed tick does not stain")
	reset_actor()
	var duplicate_sample_seen := false
	var sites_seen := {}
	var samples_seen := {}
	for draw in range(512):
		blood.add_stagger(0)
		var group: Dictionary = blood.groups.back()
		if group.sites[0] == group.sites[1]: check(false, "random site uniqueness")
		duplicate_sample_seen = duplicate_sample_seen or group.samples[0] == group.samples[1]
		for site in group.sites: sites_seen[site] = true
		for sample in group.samples: samples_seen[sample] = true
	check(duplicate_sample_seen and sites_seen.size() == 4 and samples_seen.size() == 8, "sampler covers 4 sites/8 samples and allows repeated sample")
	check(blood.groups.size() == 4, "group capacity enforced")
	return true

func test_recovery_events() -> bool:
	reset_actor()
	actor.take_damage(40)
	actor.damage.reset()
	actor.stats.stagger_lock_timer = 0
	actor.take_damage(50)
	check(blood.groups.size() == 2 and blood.groups[1].tier == 1, "two distinct broken bars keep separate groups")
	actor.stats.flask_charges = 3
	var flask: Dictionary = actor.stats.use_soul_flask()
	check(flask.used and blood.groups[1].fade_start >= 0 and blood.groups[0].fade_start < 0, "flask restores only matching bar group")
	actor.stats.restore_stagger_thresholds()
	check(blood.groups[0].fade_start >= 0, "safe-zone/all-bars restore starts remaining fade")
	reset_actor()
	actor.take_damage(40)
	actor.damage.reset()
	actor.stats.suspend_stagger_thresholds()
	check(blood.groups[0].fade_start < 0, "Sentinel suspension is not a recovery event")
	actor.stats.resume_stagger_thresholds()
	check(blood.groups[0].fade_start < 0, "Sentinel exit does not start wound fade")
	actor.vitals.heal_to_full()
	# A full heal is a recovery even after Sentinel silently reset its marker flags.
	check(blood.groups[0].fade_start >= 0, "full heal explicitly recovers existing wound group")
	return true

func test_mapping_and_transition() -> bool:
	reset_actor()
	blood.add_stagger(0)
	var identity := JSON.stringify(blood.groups)
	var source := actor.spine_rig.get_node("TestAttackSprite") as Sprite2D
	var frame_count := 0
	for filename in blood.mapping.fbf:
		var sheet: Dictionary = blood.mapping.fbf[filename]
		source.texture = load("res://asset/Character/Adel/Saber attack/" + filename)
		source.hframes = int(sheet.hframes)
		for frame_key in sheet.frames:
			source.frame = int(frame_key)
			blood.sync_visuals()
			var specs: Array = blood._specs(blood._bindings.back())
			check(specs.size() == 5 and source.material is ShaderMaterial, "%s/%s has all five site mappings" % [filename,frame_key])
			check((source.material as ShaderMaterial).get_shader_parameter("mark_count") >= 2, "%s/%s renders selected body sites" % [filename,frame_key])
			frame_count += 1
	check(frame_count == 31, "all 31 authored FBF frames covered")
	for clip in actor.spine_anim.get_animation_list():
		if clip == &"RESET": continue
		actor.spine_anim.play("RESET")
		actor.spine_anim.advance(0.0)
		actor.spine_anim.play(clip)
		actor.spine_anim.advance(0.0)
		blood.sync_visuals()
		check(JSON.stringify(blood.groups) == identity, "%s retains group identity/age" % clip)
	check(blood._bindings.size() == 10, "both rig head/body variants plus FBF bound")
	check(blood.tint == Color("#850505") and is_equal_approx(blood.opacity, 0.8), "approved tint/opacity defaults")
	for binding in blood._bindings:
		if int(binding.site) == 4:
			check(binding.sprite.material.get_shader_parameter("mark_count") == 1, "rig under-eye always added outside body pool")
	return true

func test_lifetime_and_cleanup() -> bool:
	reset_actor()
	blood.add_stagger(0)
	var born := int(blood.groups[0].born)
	blood._update_groups(born + 149999999)
	check(blood.groups[0].fade_start < 0, "timeout does not begin before 150 seconds")
	blood._update_groups(born + 150000000)
	check(blood.groups[0].fade_start == born + 150000000, "timeout begins at 150 seconds")
	blood._update_groups(born + 151500000)
	check(is_equal_approx(float(blood.groups[0].alpha), 0.5), "3-second fade has intermediate alpha")
	blood._update_groups(born + 153000000)
	check(blood.groups.is_empty(), "timeout fade completes")
	blood.add_stagger(0)
	var before := blood._clock_usec
	paused = true
	await wait_real(0.12)
	check(blood._clock_usec == before, "menu pause freezes blood age")
	paused = false
	Engine.time_scale = 0.02
	before = blood._clock_usec
	await wait_real(0.12)
	blood._advance_clock(Time.get_ticks_usec())
	check(blood._clock_usec - before > 80000, "age follows wall time through slow motion")
	Engine.time_scale = 1.0
	actor.restore_checkpoint_state(actor.global_position, false)
	check(blood.groups.is_empty(), "checkpoint/respawn clears wounds")
	blood.add_stagger(0)
	actor.stats.hp = 0
	blood.sync_visuals()
	check(blood.groups.is_empty(), "death including non-contact HP loss clears wounds")
	actor.stats.hp = 100
	blood.add_stagger(0)
	blood.enabled = false
	await process_frame
	check(blood.groups.is_empty(), "disabling component clears effects")
	for binding in blood._bindings: check(binding.sprite.material == binding.original, "original material restored when clear")
	blood.enabled = true
	return true

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000)
	while Time.get_ticks_usec() < deadline: await process_frame
