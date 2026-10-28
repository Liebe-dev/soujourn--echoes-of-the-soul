extends SceneTree
## Production Q component only: no injected preview geometry or effect controller.

var output := ""
var actor: CharacterBody2D
var enemy: CharacterBody2D
var vfx: Node2D
var camera: Camera2D
var frames: Array[Image] = []
var timeline: Array[Dictionary] = []
var pictures: Dictionary = {}
var events: Array[Dictionary] = []
var hits := 0
var misses := 0
var missing_dash := 0
var hit_stop_samples := 0
var title: Label

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
	root.content_scale_size = Vector2i(960,540)
	root.size = Vector2i(960,540)
	var scene := load("res://scenes/enemy/spine_enemy_test.tscn").instantiate() as Node2D
	root.add_child(scene)
	current_scene = scene
	actor = scene.get_node("PlayableAdel") as CharacterBody2D
	enemy = scene.get_node("Enemy") as CharacterBody2D
	vfx = actor.get_node("SpinePivot/SpineRig/SaberSkillVFX") as Node2D
	scene.get_node("Instructions").visible = false
	for name in ["Enemy", "SpineEnemy"]:
		var target := scene.get_node(name) as Node2D
		target.set_physics_process(false)
		target.position.x = 3000.0
	actor.vitals.simulation_enabled = false
	actor.get_node("Camera2D/hud").visible = false
	for layer in scene.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	camera = actor.get_node("Camera2D") as Camera2D
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.ground_framing_enabled = false
	camera.zoom = Vector2(1.575,1.575)
	actor.saber_skill.lunge_started.connect(func() -> void:
		events.append({"kind":"dash", "usec":Time.get_ticks_usec()})
	)
	actor.saber_skill.impact_confirmed.connect(func(duration: float) -> void:
		hits += 1
		events.append({"kind":"confirmed_hit", "usec":Time.get_ticks_usec(), "duration":duration})
	)
	actor.saber_skill.recovery_started.connect(func(confirmed: bool) -> void:
		if not confirmed:
			misses += 1
		events.append({"kind":"slash" if confirmed else "whiff_slash", "usec":Time.get_ticks_usec()})
	)
	var labels := CanvasLayer.new()
	root.add_child(labels)
	title = Label.new()
	title.position = Vector2(19,14)
	title.add_theme_font_size_override("font_size",18)
	labels.add_child(title)
	var caption := Label.new()
	caption.position = Vector2(19,499)
	caption.add_theme_font_size_override("font_size",16)
	caption.text = "Q brush · 2 răng cưa · #ef241e / #f55d58 · đuôi → kiếm"
	labels.add_child(caption)
	await wait_real(0.5)
	actor.set_physics_process(false)
	vfx.set_process(false)
	for clip: StringName in [&"saber_skill_4", &"saber_skill_6"]:
		actor.spine_anim.play(clip)
		actor.spine_anim.advance(0.0)
		vfx._dash.global_transform = vfx._source.global_transform * vfx._frame_basis()
		vfx._slash.global_transform = vfx._source.global_transform * vfx._frame_basis()
		vfx._dash.visible = true
		vfx._slash.visible = true
		await RenderingServer.frame_post_draw
	vfx.clear_effects()
	vfx.set_process(true)
	actor.spine_anim.play(&"idle")
	actor.spine_anim.advance(0.0)
	actor.set_physics_process(true)
	await physics_frame
	await capture_pass(0, true)
	await capture_pass(1, false)
	for action: StringName in [&"weapon_skill", &"move_left", &"move_right"]:
		press(action, false)
	for index in frames.size():
		frames[index].save_png(output + "/frames/frame_%04d.png" % index)
	for key: String in pictures:
		(pictures[key] as Image).save_png(output + "/" + key + ".png")
	var file := FileAccess.open(output + "/timeline.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(timeline))
	var summary := {"frames":frames.size(), "hits":hits, "whiffs":misses, "bad_dash_samples":missing_dash, "actual_hit_stop_samples":hit_stop_samples, "events":events, "pictures":pictures.keys(), "remaining_dash":vfx._dash.visible, "remaining_slash":vfx._slash.visible, "lunge_speed_scene":actor.saber_skill.lunge_speed, "dash_depth":vfx._dash.z_index, "source_depth":vfx._source_depth(), "color":vfx.tint.to_html(false), "scope":"Production SaberSkillVFX from rig, no preview overlay"}
	var metadata := FileAccess.open(output + "/capture_summary.json", FileAccess.WRITE)
	metadata.store_string(JSON.stringify(summary,"\t"))
	print("Q_VFX_NATIVE_CAPTURE ", JSON.stringify(summary))
	quit(0 if hits == 1 and misses == 1 and missing_dash == 0 and hit_stop_samples > 0 and not vfx._dash.visible and not vfx._slash.visible else 1)

func capture_pass(pass_id: int, hit: bool) -> void:
	actor.saber_skill.reset_cooldown()
	if hit:
		enemy.current_health = 1000
		enemy.is_dead = false
		enemy.position = actor.position + Vector2(175,0)
		await physics_frame
	else:
		enemy.position.x = 3000.0
		press(&"move_left", true)
		await physics_frame
		await physics_frame
		press(&"move_left", false)
		await physics_frame
	title.text = "Q · " + ("TRÚNG — ĐUÔI NHỌN → ĐẦU TÙ" if hit else "HỤT — TẮT CUNG LAO NGAY")
	var started := Time.get_ticks_usec()
	var pressed := false
	var released := false
	while Time.get_ticks_usec() - started < 1650000:
		var elapsed := float(Time.get_ticks_usec() - started) / 1000000.0
		if elapsed >= 0.12 and not pressed:
			press(&"weapon_skill", true)
			pressed = true
		if elapsed >= 0.36 and not released:
			press(&"weapon_skill", false)
			released = true
		camera.global_position = actor.global_position
		camera.set("_authored_offset", Vector2(50.0 * actor.facing_direction,-35))
		camera.set("_mouse_pan", Vector2.ZERO)
		camera.offset = Vector2(50.0 * actor.facing_direction,-35)
		camera.reset_smoothing()
		camera.force_update_scroll()
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var dashing: bool = actor.saber_skill.is_dashing()
		var hit_stop: bool = root.get_node("CombatTime").is_hit_stopping()
		if dashing and not vfx._dash.visible:
			missing_dash += 1
		var progress := -1.0
		if vfx._impact_born >= 0:
			progress = float(Time.get_ticks_usec() - vfx._impact_born) / 1000000.0 / vfx._impact_duration
			if hit_stop and vfx._dash.visible:
				hit_stop_samples += 1
		if dashing and not pictures.has("dash_" + str(pass_id)):
			pictures["dash_" + str(pass_id)] = image.duplicate()
		if vfx._impact_born >= 0 and vfx._dash.visible:
			pictures["impact_%02d" % hit_stop_samples] = image.duplicate()
		if vfx._slash.visible and not pictures.has("slash_" + str(pass_id)):
			pictures["slash_" + str(pass_id)] = image.duplicate()
		image.convert(Image.FORMAT_RGB8)
		frames.append(image)
		timeline.append({"pass":pass_id, "usec":Time.get_ticks_usec()-started, "dashing":dashing, "dash_visible":vfx._dash.visible, "erase_progress":progress, "hit_stop":hit_stop, "slash_visible":vfx._slash.visible})
	await wait_real(0.15)

func press(action: StringName, down: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	Input.parse_input_event(event)

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await process_frame
