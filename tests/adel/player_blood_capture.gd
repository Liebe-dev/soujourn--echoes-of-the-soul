extends SceneTree
## Native render QA: one real stagger first, then persistent two-bar coverage fixture.

var actor: CharacterBody2D
var blood: PlayerBlood
var output := ""
var camera: Camera2D
var title: Label
var reports: Array[Dictionary] = []
var identity := ""
var motion: Array[Dictionary] = []
var invalid_motion_frames := 0

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if output.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var watchdog := Timer.new()
	watchdog.wait_time = 90
	watchdog.ignore_time_scale = true
	watchdog.one_shot = true
	watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(watchdog)
	watchdog.timeout.connect(func() -> void: quit(2))
	watchdog.start()
	root.size = Vector2i(960,600)
	root.content_scale_size = root.size
	var stage := load("res://scenes/enemy/spine_enemy_test.tscn").instantiate() as Node2D
	root.add_child(stage)
	current_scene = stage
	actor = stage.get_node("PlayableAdel")
	for name in ["Enemy", "SpineEnemy"]:
		var enemy := stage.get_node(name) as Node2D
		enemy.set_physics_process(false)
		enemy.global_position.x = 10000
	stage.get_node("Instructions").visible = false
	actor.set_physics_process(false)
	actor.vitals.simulation_enabled = false
	for layer in stage.find_children("*", "CanvasLayer", true, false): layer.visible = false
	var game_camera := actor.get_node("Camera2D") as Camera2D
	game_camera.set_process(false)
	game_camera.set_physics_process(false)
	game_camera.enabled = false
	camera = Camera2D.new()
	root.add_child(camera)
	camera.make_current()
	actor.spine_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var labels := CanvasLayer.new()
	root.add_child(labels)
	title = Label.new()
	title.position = Vector2(16,12)
	title.add_theme_font_size_override("font_size", 18)
	labels.add_child(title)
	blood = actor.player_blood
	actor.stats.max_hp = 100
	actor.stats.heal_to_full()
	actor.take_damage(40, actor.global_position + Vector2(80,0))
	await capture("00_actual_hp_stagger", "HIT STAGGER THẬT · 2 VẾT + DƯỚI MẮT")
	actor.stagger_impact.cancel()
	actor.damage.reset()
	# Two existing stagger groups, fixed slots solely to inspect all mappings.
	# This fixture is labeled separately from the actual gameplay trigger above.
	blood.add_stagger(1)
	blood.groups[0].sites = [0,1]
	blood.groups[0].samples = [4,1]
	blood.groups[1].sites = [2,3]
	blood.groups[1].samples = [2,7]
	identity = JSON.stringify(blood.groups)
	var rig := actor.spine_rig as Node2D
	var fbf := rig.get_node("TestAttackSprite") as Sprite2D
	for name in ["SaberSwingVFX", "JumpAttackVFX", "SaberReadyVFX", "SaberSkillVFX"]:
		rig.get_node(name).enabled = false
	for direction in [1,-1]:
		actor._set_facing_direction(direction)
		for filename in blood.mapping.fbf:
			var sheet: Dictionary = blood.mapping.fbf[filename]
			rig.get_node("Skeleton2D").visible = false
			fbf.visible = true
			fbf.texture = load("res://asset/Character/Adel/Saber attack/" + filename)
			fbf.hframes = int(sheet.hframes)
			for frame_key in sheet.frames:
				fbf.frame = int(frame_key)
				await capture("fbf_%s_%s_%s" % [filename.get_basename(),frame_key,direction], "MAPPING QA · %s · FRAME %s · HƯỚNG %s" % [filename,frame_key,direction])
		for clip in actor.spine_anim.get_animation_list():
			if clip == &"RESET": continue
			for sample_time in [0.0,0.15,0.3]:
				actor.spine_anim.play("RESET")
				actor.spine_anim.advance(0.0)
				rig.get_node("Skeleton2D").visible = true
				actor.spine_anim.play(clip)
				actor.spine_anim.advance(sample_time)
				if fbf.visible: continue # FBF frames already covered above.
				await capture("rig_%s_%s_%s" % [String(clip).validate_filename(),sample_time,direction], "MAPPING QA · %s · %.2fs · HƯỚNG %s" % [clip,sample_time,direction])
	actor._set_facing_direction(1)
	actor.spine_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	rig.get_node("Skeleton2D").visible = true
	for clip in [&"saber_stagger", &"idle", &"run", &"saber_attack_1", &"saber_attack_4", &"saber_skill_4", &"saber_skill_6", &"jump_air (fall)", &"dash", &"idle"]:
		actor.spine_anim.play(clip)
		var deadline := Time.get_ticks_usec() + 450000
		while Time.get_ticks_usec() < deadline:
			await RenderingServer.frame_post_draw
			var valid := true
			if fbf.is_visible_in_tree():
				valid = fbf.material == blood._bindings.back().material and int(fbf.material.get_shader_parameter("mark_count")) >= 2
			else:
				for binding in blood._bindings:
					if int(binding.site) == 4 and binding.sprite.is_visible_in_tree():
						valid = valid and binding.sprite.material == binding.material and int(binding.material.get_shader_parameter("mark_count")) == 1
			if not valid: invalid_motion_frames += 1
			motion.append({"clip":String(clip),"fbf":fbf.is_visible_in_tree(),"frame":fbf.frame,"valid":valid,"usec":Time.get_ticks_usec()})
	var same_identity := JSON.stringify(blood.groups) == identity
	actor.spine_anim.pause()
	actor.stats.restore_stagger_thresholds()
	await capture("recovery_0_peak", "HỒI VẠCH · BẮT ĐẦU TAN")
	await wait_real(1.5)
	await capture("recovery_1_mid", "HỒI VẠCH · TAN GIỮA CHỪNG")
	await wait_real(1.6)
	await capture("recovery_2_clean", "HỒI VẠCH · ĐÃ TAN HẾT")
	var summary := {"poses":reports,"motion_frames":motion.size(),"invalid_motion_frames":invalid_motion_frames,"identity_preserved":same_identity,"groups_after_fade":blood.groups.size(),"scope":"Native production materials. First frame: actual take_damage HP stagger. Coverage frames: fixed all-four-sites fixture, camera fitted, no AI/HUD/audio QA."}
	FileAccess.open(output.path_join("capture_summary.json"),FileAccess.WRITE).store_string(JSON.stringify(summary,"\t"))
	FileAccess.open(output.path_join("motion_timeline.json"),FileAccess.WRITE).store_string(JSON.stringify(motion,"\t"))
	print("BLOOD CAPTURE: %d poses; %d motion frames; invalid=%d; identity preserved=%s; groups after fade=%d" % [reports.size(),motion.size(),invalid_motion_frames,same_identity,blood.groups.size()])
	var success := same_identity and invalid_motion_frames == 0 and blood.groups.is_empty()
	watchdog.queue_free()
	stage.queue_free()
	await process_frame
	quit(0 if success else 1)

func capture(filename: String, label: String) -> void:
	title.text = label + " · #850505 · 80%"
	blood.sync_visuals()
	var bounds := visible_bounds(actor.spine_rig)
	camera.zoom = Vector2.ONE * minf(850.0 / maxf(bounds.size.x,1), 475.0 / maxf(bounds.size.y,1))
	camera.global_position = bounds.get_center() - Vector2(0,20)/camera.zoom
	camera.reset_smoothing()
	camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output.path_join(filename + ".png"))
	reports.append({"file":filename + ".png","png_error":error,"groups":blood.groups.duplicate(true)})

func visible_bounds(rig: Node2D) -> Rect2:
	var result := Rect2()
	var first := true
	for node in rig.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if not sprite.is_visible_in_tree() or sprite.texture == null or sprite.name == "Sprite2D": continue
		var region := sprite.global_transform * sprite.get_rect()
		result = region if first else result.merge(region)
		first = false
	return result

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000)
	while Time.get_ticks_usec() < deadline: await process_frame
