extends SceneTree
## Native still capture of production input/physics. No overlay or animation retiming.

var output := ""
var actor: CharacterBody2D
var vfx: JumpAttackVFX
var camera: Camera2D
var samples := [0, 0]
var wrong_visibility := 0
var wrong_pose := 0
var landings := [false, false]
var pictures: Dictionary = {}
var hit_stop_requested := false
var hit_stop_samples := 0

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
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var scene := load("res://scenes/enemy/spine_enemy_test.tscn").instantiate() as Node2D
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
	actor.set_physics_process(false)
	vfx.set_process(false)
	for pose in [{"clip":vfx.AIR_CLIP,"time":0.19}, {"clip":vfx.LAND_CLIP,"time":0.0}]:
		actor.spine_anim.play(pose.clip)
		actor.spine_anim.advance(pose.time)
		vfx._sample_animation()
		vfx._descent.global_transform = vfx._source_frame_transform()
		vfx._descent.z_index = vfx._source_depth() + 1
		vfx._descent.visible = true
		await RenderingServer.frame_post_draw
	vfx.clear_effects()
	vfx.set_process(true)
	actor.spine_anim.play(&"idle")
	actor.spine_anim.advance(0.0)
	actor.set_physics_process(true)
	await physics_frame
	var started := Time.get_ticks_usec()
	var pass_index := 0
	var state := 0
	var jump_started := 0
	var second_started := false
	while Time.get_ticks_usec() - started < 6500000:
		camera.global_position = actor.global_position
		camera.offset = Vector2(45.0 * actor.facing_direction, -15)
		camera.reset_smoothing()
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var expected: bool = actor.combat.is_jump_attacking and not actor.combat.is_jump_attack_hanging and not actor.is_on_floor() and vfx._source.frame == 1 and vfx._source.is_visible_in_tree()
		if vfx._descent.visible != expected:
			wrong_visibility += 1
		if vfx._descent.visible:
			samples[pass_index] += 1
			if vfx._source.frame != 1:
				wrong_pose += 1
			var key := "right_descent" if pass_index == 0 else "left_long_descent"
			if not pictures.has(key):
				pictures[key] = root.get_texture().get_image()
			if pass_index == 1 and not hit_stop_requested:
				root.get_node("CombatTime").request(actor, &"hit_stop", 0.01, 0.12)
				hit_stop_requested = true
			if root.get_node("CombatTime").is_hit_stopping():
				hit_stop_samples += 1
		if actor.combat.is_jump_attack_landing and not landings[pass_index]:
			landings[pass_index] = true
			pictures["right_landing" if pass_index == 0 else "left_landing"] = root.get_texture().get_image()
		if now - started > 2800000 and actor.is_on_floor() and not second_started:
			second_started = true
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
			if not actor.is_on_floor() and now - jump_started > 180000:
				if pass_index == 1:
					actor.position.y -= 360.0
				press(&"move_down", true)
				press(&"attack", true)
				state = 2
		elif state == 2:
			press(&"attack", false)
			press(&"move_down", false)
			state = 3
	for action: StringName in [&"jump", &"attack", &"move_down", &"move_left"]:
		press(action, false)
	for key: String in pictures:
		(pictures[key] as Image).save_png(output + "/" + key + ".png")
	var summary := {"descent_samples":samples,"wrong_visibility_samples":wrong_visibility,"wrong_pose_samples":wrong_pose,"landings":landings,"pictures":pictures.keys(),"left_long_drop_extra_height_world_pixels":360,"hit_stop_requested":hit_stop_requested,"hit_stop_descent_samples":hit_stop_samples,"pending_residuals_at_end":vfx._effects.size(),"descent_visible_at_end":vfx._descent.visible}
	var file := FileAccess.open(output + "/capture_summary.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(summary, "\t"))
	print("DESCENT_NATIVE_CAPTURE ", JSON.stringify(summary))
	quit(0 if samples[0] > 0 and samples[1] > 6 and wrong_visibility == 0 and wrong_pose == 0 and landings[0] and landings[1] and hit_stop_samples > 0 and pictures.size() == 4 and vfx._effects.is_empty() and not vfx._descent.visible else 1)

func press(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await process_frame
