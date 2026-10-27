extends SceneTree
## Actual combat input -> full Ready, then guard release -> held Ready without a slash.

var scene: Node2D
var actor: CharacterBody2D
var vfx: SaberReadyVFX
var camera: Camera2D
var output := ""
var images: Array[Image] = []
var timestamps: Array[int] = []
var poses: Dictionary = {}
var hit_stop_requested := false
var held_samples := 0
var ghost_samples := 0

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
	vfx = actor.get_node("SpinePivot/SpineRig/SaberReadyVFX") as SaberReadyVFX
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
	actor.set_physics_process(false)
	actor.presentation.ready_pose(false)
	actor.spine_anim.advance(0.346)
	vfx._sample_animation()
	await RenderingServer.frame_post_draw
	actor.spine_anim.advance(0.01)
	vfx._sample_animation()
	await RenderingServer.frame_post_draw
	vfx.clear_effects()
	actor.spine_anim.play(&"idle")
	actor.spine_anim.advance(0.0)
	actor.set_physics_process(true)
	await physics_frame
	var started := Time.get_ticks_usec()
	var pass_index := 0
	var state := 0
	var left_started := false
	var guard_started := false
	var guard_released := false
	while Time.get_ticks_usec() - started < 5100000:
		camera.global_position = actor.global_position
		camera.offset = Vector2(45.0 * actor.facing_direction, -15)
		camera.reset_smoothing()
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var elapsed := float(now - started) / 1000000.0
		var image := root.get_texture().get_image()
		if not vfx._residuals.is_empty():
			var key := "right_ready" if pass_index == 0 else "left_hit_stop_ready"
			if not poses.has(key):
				poses[key] = image.duplicate()
			if pass_index == 1 and not hit_stop_requested:
				root.get_node("CombatTime").request(actor, &"hit_stop", 0.01, 0.16)
				hit_stop_requested = true
		if guard_released and actor._ready_final_frame and vfx._markers.x < 0.0 and actor.spine_anim.current_animation == &"saber_ready" and actor.spine_anim.current_animation_position > 0.35:
			held_samples += 1
			if not vfx._residuals.is_empty() or vfx._overhead.visible or vfx._front.visible:
				ghost_samples += 1
			if not poses.has("held_ready_no_slash"):
				poses["held_ready_no_slash"] = image.duplicate()
		image.resize(960, 540, Image.INTERPOLATE_BILINEAR)
		image.convert(Image.FORMAT_RGB8)
		images.append(image)
		timestamps.append(now - started)
		if elapsed > 1.90 and not left_started:
			left_started = true
			pass_index = 1
			state = -1
			press(&"move_left", true)
		if state == -1 and actor.facing_direction < 0:
			press(&"move_left", false)
			state = 0
		if state == 0:
			press(&"attack", true)
			state = 1
		elif state == 1:
			press(&"attack", false)
			state = 2
		if elapsed > 3.65 and not guard_started:
			guard_started = true
			press(&"guard and deflect", true)
		elif elapsed > 3.78 and guard_started and not guard_released:
			guard_released = true
			press(&"guard and deflect", false)
	press(&"attack", false)
	press(&"move_left", false)
	press(&"guard and deflect", false)
	for index in images.size():
		images[index].save_png(output + "/frames/frame_%04d.png" % index)
	for key: String in poses:
		(poses[key] as Image).save_png(output + "/" + key + ".png")
	var timing := FileAccess.open(output + "/frame_times.json", FileAccess.WRITE)
	timing.store_string(JSON.stringify(timestamps))
	var result := {"poses":poses.keys(),"frames":images.size(),"hit_stop_requested":hit_stop_requested,"held_ready_samples_after_flick_marker":held_samples,"held_samples_require_final_only_resource":true,"ghost_slash_samples":ghost_samples,"pending_ready_vfx":vfx._residuals.size()}
	var summary := FileAccess.open(output + "/capture_summary.json", FileAccess.WRITE)
	summary.store_string(JSON.stringify(result, "\t"))
	print("READY_VFX_CAPTURE ", JSON.stringify(result))
	quit(0 if poses.size() == 3 and hit_stop_requested and held_samples > 0 and ghost_samples == 0 and vfx._residuals.is_empty() else 1)

func press(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await process_frame
