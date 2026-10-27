extends SceneTree
## Actual player + input/physics capture. Never run against the player's real save.

var scene: Node2D
var actor: CharacterBody2D
var vfx: JumpAttackVFX
var camera: Camera2D
var output := ""
var frames: Array[Image] = []
var timestamps: Array[int] = []
var poses: Dictionary = {}
var maximum_floor_error := 0.0
var hit_stop_requested := false

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	if output.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output + "/frames")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate() as Node2D
	root.add_child(scene)
	current_scene = scene
	actor = scene.get_node("PlayableAdel") as CharacterBody2D
	vfx = actor.get_node("SpinePivot/SpineRig/JumpAttackVFX") as JumpAttackVFX
	scene.get_node("Instructions").visible = false
	for enemy_name in ["Enemy", "SpineEnemy"]:
		var enemy := scene.get_node(enemy_name) as Node2D
		enemy.set_physics_process(false)
		enemy.position.x = 3000.0
	actor.get_node("Camera2D/hud").visible = false
	for layer in scene.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	actor.vitals.simulation_enabled = false
	camera = actor.get_node("Camera2D") as Camera2D
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.ground_framing_enabled = false
	camera.zoom = Vector2(2.1, 2.1)
	await wait_real(0.5)
	# Upload materials before recording; this does not drive the recorded combat.
	actor.set_physics_process(false)
	for pose in [{"clip":vfx.AIR_CLIP,"time":0.19},{"clip":vfx.LAND_CLIP,"time":0.0}]:
		actor.spine_anim.play(pose.clip)
		actor.spine_anim.advance(pose.time)
		vfx._sample_animation()
		vfx._tick_effects(Time.get_ticks_usec())
		await RenderingServer.frame_post_draw
	vfx.clear_effects()
	actor.spine_anim.play(&"idle")
	actor.spine_anim.advance(0.0)
	actor.set_physics_process(true)
	await physics_frame
	var started := Time.get_ticks_usec()
	var pass_index := 0
	var state := 0
	var pass_one_started := false
	var jump_started := 0
	while Time.get_ticks_usec() - started < 4500000:
		camera.global_position = actor.global_position
		camera.offset = Vector2(45.0 * actor.facing_direction, -15)
		camera.reset_smoothing()
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var elapsed := float(now - started) / 1000000.0
		var image := root.get_texture().get_image()
		for record: Dictionary in vfx._effects:
			var key := ("right_" if pass_index == 0 else "left_hit_stop_") + ("air" if record.kind == vfx.AIR_CLIP else "land")
			if not poses.has(key):
				poses[key] = image.duplicate()
			if record.kind == vfx.LAND_CLIP:
				var air: MeshInstance2D = record.nodes[1]
				var ground_point := air.global_transform * Vector2(0, 123)
				for index in actor.get_slide_collision_count():
					var collision := actor.get_slide_collision(index)
					if collision.get_normal().dot(Vector2.UP) > 0.7:
						maximum_floor_error = maxf(maximum_floor_error, absf(ground_point.y - collision.get_position().y))
				if pass_index == 1 and not hit_stop_requested:
					root.get_node("CombatTime").request(actor, &"hit_stop", 0.01, 0.12)
					hit_stop_requested = true
		image.resize(960, 540, Image.INTERPOLATE_BILINEAR)
		image.convert(Image.FORMAT_RGB8)
		frames.append(image)
		timestamps.append(now - started)
		if elapsed > 1.85 and not pass_one_started:
			pass_one_started = true
			pass_index = 1
			state = -1
			press(&"move_left", true)
		if state == -1 and actor.facing_direction < 0:
			press(&"move_left", false)
			state = 0
		if state == 0 and actor.is_on_floor():
			press(&"jump", true)
			jump_started = now
			state = 1
		elif state == 1:
			press(&"jump", false)
			if not actor.is_on_floor() and now - jump_started > 80000:
				press(&"move_down", true)
				press(&"attack", true)
				state = 2
		elif state == 2:
			press(&"attack", false)
			press(&"move_down", false)
			state = 3
	press(&"jump", false)
	press(&"attack", false)
	press(&"move_left", false)
	press(&"move_down", false)
	for index in frames.size():
		frames[index].save_png(output + "/frames/frame_%04d.png" % index)
	for key: String in poses:
		(poses[key] as Image).save_png(output + "/" + key + ".png")
	var timing := FileAccess.open(output + "/frame_times.json", FileAccess.WRITE)
	timing.store_string(JSON.stringify(timestamps))
	var result := {"captured_poses":poses.keys(),"frames":frames.size(),"max_ground_contact_error_world_pixels":maximum_floor_error,"left_hit_stop_requested":hit_stop_requested,"pending_vfx_at_end":vfx._effects.size()}
	var summary := FileAccess.open(output + "/capture_summary.json", FileAccess.WRITE)
	summary.store_string(JSON.stringify(result, "\t"))
	print("JUMP_VFX_CAPTURE ", JSON.stringify(result))
	quit(0 if poses.size() == 4 and maximum_floor_error < 1.0 and hit_stop_requested and vfx._effects.is_empty() else 1)

func press(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await process_frame
