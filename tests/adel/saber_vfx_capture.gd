extends SceneTree
## Automated capture of the real playable scene, controlled through game input.
## Run in an isolated CodexSaberVFX user directory with -- --output=<folder>.

var scene: Node2D
var actor: CharacterBody2D
var vfx: SaberSwingVFX
var output := ""
var capture_frame := 0
var current_pass := 0
var queue_for_step := 0
var release_attack := false
var captured_poses: Dictionary = {}
var frame_times: Array[int] = []
var captured_frames: Array[Image] = []
var pose_images: Dictionary = {}

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		quit(2)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
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
	vfx = actor.get_node("SpinePivot/SpineRig/SaberSwingVFX") as SaberSwingVFX
	# Keep the actual player, physics, hitboxes, animations, and input handling.
	# Hide unrelated UI and hold enemies away from the focused demonstration.
	scene.get_node("Instructions").visible = false
	for enemy_name in ["Enemy", "SpineEnemy"]:
		var enemy := scene.get_node(enemy_name) as Node2D
		enemy.set_physics_process(false)
		enemy.position.x = 3000.0
	actor.get_node("Camera2D/hud").visible = false
	for canvas_layer in scene.find_children("*", "CanvasLayer", true, false):
		canvas_layer.visible = false
	actor.vitals.simulation_enabled = false
	var camera := actor.get_node("Camera2D") as Camera2D
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.ground_framing_enabled = false
	camera.offset = Vector2(45, -15)
	camera.zoom = Vector2(2.1, 2.1)
	await wait_real(0.6)
	camera.global_position = actor.global_position
	camera.offset = Vector2(45, -15)
	camera.reset_smoothing()
	camera.force_update_scroll()
	# Compile/upload the four VFX materials before recording gameplay input.
	actor.set_physics_process(false)
	for attack in range(1, 5):
		actor.spine_anim.play("saber_attack_%d" % attack)
		actor.spine_anim.advance(0.16)
		vfx._sample_animation()
		await RenderingServer.frame_post_draw
	vfx.clear_effects()
	actor.spine_anim.play(&"idle")
	actor.set_physics_process(true)
	var pass_started := Time.get_ticks_usec()
	press(&"attack", true)
	release_attack = true
	var started := Time.get_ticks_usec()
	while Time.get_ticks_usec() - started < 6500000:
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		frame_times.append(Time.get_ticks_usec() - started)
		capture_frame += 1
		camera.global_position = actor.global_position
		camera.force_update_scroll()
		var step: int = actor.combat.combo_step
		if vfx._attached.visible and step > 0 and not captured_poses.has(step):
			pose_images[step] = image.duplicate()
			captured_poses[step] = true
		# Encode only after the live run; PNG compression must not stall combat.
		image.resize(960, 540, Image.INTERPOLATE_BILINEAR)
		image.convert(Image.FORMAT_RGB8)
		captured_frames.append(image)
		if release_attack:
			press(&"attack", false)
			release_attack = false
		elif step > 0 and step < 4 and step != queue_for_step and actor.spine_anim.current_animation_position >= 0.29:
			press(&"attack", true)
			release_attack = true
			queue_for_step = step
		if current_pass == 0 and Time.get_ticks_usec() - pass_started > 2800000:
			current_pass = 1
			queue_for_step = 0
			press(&"move_left", true)
			press(&"attack", true)
			release_attack = true
		elif current_pass == 1 and actor.facing_direction < 0:
			press(&"move_left", false)
	press(&"attack", false)
	press(&"move_left", false)
	for frame in captured_frames.size():
		captured_frames[frame].save_png(output + "/frames/frame_%04d.png" % frame)
	for step: int in pose_images:
		(pose_images[step] as Image).save_png(output + "/saber_attack_%d_ingame.png" % step)
	var timing_file := FileAccess.open(output + "/frame_times.json", FileAccess.WRITE)
	timing_file.store_string(JSON.stringify(frame_times))
	print("SABER_VFX_CAPTURE_OK frames=", capture_frame, " attacks=", captured_poses.size())
	quit(0 if captured_poses.size() == 4 else 1)

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await process_frame

func press(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
