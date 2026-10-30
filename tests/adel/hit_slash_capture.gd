extends SceneTree
## Native production Player/input capture. No preview effect, geometry, or clock.

var actor: CharacterBody2D
var enemy: CharacterBody2D
var vfx: SaberHitSlashVFX
var output := ""
var direction := 1
var events: Array[Dictionary] = []
var pictures: Dictionary = {}
var samples: Array[Dictionary] = []
var title: Label
var bad_order := 0

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		quit(2)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	if output.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i(960, 600)
	root.size = Vector2i(960, 600)
	var scene := load("res://scenes/enemy/spine_enemy_test.tscn").instantiate() as Node2D
	root.add_child(scene)
	current_scene = scene
	actor = scene.get_node("PlayableAdel") as CharacterBody2D
	enemy = scene.get_node("SpineEnemy") as CharacterBody2D
	for name in ["Enemy", "SpineEnemy"]:
		var target := scene.get_node(name) as Node2D
		target.set_physics_process(false)
		target.position.x = 10000.0
	scene.get_node("Instructions").visible = false
	actor.get_node("Camera2D/hud").visible = false
	for layer in scene.find_children("*", "CanvasLayer", true, false): layer.visible = false
	actor.vitals.simulation_enabled = false
	vfx = actor.hit_slash_vfx
	var camera := actor.get_node("Camera2D") as Camera2D
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.ground_framing_enabled = false
	camera.zoom = Vector2(1.65, 1.65)
	camera.offset = Vector2(60, -8)
	await wait_real(0.5)
	camera.global_position = actor.global_position
	camera.reset_smoothing()
	camera.force_update_scroll()
	var labels := CanvasLayer.new()
	root.add_child(labels)
	title = Label.new()
	title.position = Vector2(20, 16)
	title.add_theme_font_size_override("font_size", 21)
	labels.add_child(title)
	# Warm the existing sword material and the new hit material before live input.
	actor.set_physics_process(false)
	enemy.global_position = actor.global_position + Vector2(125, 34)
	enemy.current_health = 10000
	enemy.is_dead = false
	for attack in range(1, 5):
		actor.saber_hitbox.play_attack_window(StringName("saber_attack_%d" % attack), 20)
		actor.spine_anim.play("saber_attack_%d" % attack)
		actor.spine_anim.advance(0.16)
		vfx._on_target_hit(enemy)
		await RenderingServer.frame_post_draw
		actor.saber_hitbox.stop_attack_window()
		await process_frame
	vfx.clear_effects()
	actor.spine_rig.get_node("SaberSwingVFX").clear_effects()
	root.get_node("CombatTime").remove(actor)
	actor.spine_anim.play("idle")
	actor.set_physics_process(true)
	await wait_real(0.3)
	actor.saber_hitbox.target_hit.connect(_accepted_hit)
	for facing in [1, -1]:
		direction = facing
		actor._set_facing_direction(facing)
		actor.combat.combo_step = 0
		enemy.current_health = 10000
		enemy.is_dead = false
		enemy.global_position = actor.global_position + Vector2(facing * 125, 34)
		await physics_frame
		var queue_for := 0
		var release := true
		press(&"attack", true)
		var started := Time.get_ticks_usec()
		while Time.get_ticks_usec() - started < 3300000:
			await RenderingServer.frame_post_draw
			var step: int = actor.combat.combo_step
			title.text = "SABER %d · %s · 200 ms · kiếm > dấu trúng > địch" % [step, "PHẢI" if facing > 0 else "TRÁI"]
			var row := {"usec": Time.get_ticks_usec(), "facing": facing, "step": step, "marks": vfx._marks.size(), "time_scale": Engine.time_scale}
			for mark in vfx._marks:
				var sprite: Sprite2D = mark.sprite
				var alpha := float((sprite.material as ShaderMaterial).get_shader_parameter("opacity"))
				var attack := vfx.ATTACKS.find(mark.attack) + 1
				var key := "%s_attack_%d" % ["right" if facing > 0 else "left", attack]
				var weapon_depth: int = actor.spine_rig.get_node("SaberSwingVFX")._source_depth() - 1
				var enemy_depth := canvas_depth(enemy)
				if not (enemy_depth < sprite.z_index and sprite.z_index < weapon_depth): bad_order += 1
				row["opacity"] = alpha
				row["mark_z"] = sprite.z_index
				row["sword_z"] = weapon_depth
				row["enemy_z"] = enemy_depth
				if not pictures.has(key + "_peak"):
					pictures[key + "_peak"] = root.get_texture().get_image()
				if alpha > 0.35 and alpha < 0.65 and not pictures.has(key + "_fade"):
					pictures[key + "_fade"] = root.get_texture().get_image()
			samples.append(row)
			if release:
				press(&"attack", false)
				release = false
			elif step > 0 and step < 4 and step != queue_for and actor.spine_anim.current_animation_position >= 0.29:
				press(&"attack", true)
				release = true
				queue_for = step
		press(&"attack", false)
		await wait_real(0.3)
	for key: String in pictures:
		(pictures[key] as Image).save_png(output.path_join(key + ".png"))
	var file := FileAccess.open(output.path_join("capture_summary.json"), FileAccess.WRITE)
	var summary := {"events": events, "hits": events.size(), "bad_layer_samples": bad_order, "pictures": pictures.keys(), "fade_duration": vfx.fade_duration, "length_scale": vfx.length_scale, "remaining_marks": vfx._marks.size(), "scope": "Production Player and enemy, real input/physics, production VFX and real-time clock; no preview renderer."}
	file.store_string(JSON.stringify(summary, "\t"))
	var timeline := FileAccess.open(output.path_join("timeline.json"), FileAccess.WRITE)
	timeline.store_string(JSON.stringify(samples))
	print("HIT_SLASH_NATIVE_CAPTURE ", JSON.stringify(summary))
	quit(0 if events.size() == 8 and bad_order == 0 and pictures.size() >= 16 and vfx._marks.is_empty() else 1)

func _accepted_hit(target: Node2D) -> void:
	if target != enemy: return
	var attack: StringName = actor.saber_hitbox.get_active_attack_name()
	if vfx.ATTACKS.find(attack) < 0: return
	events.append({"attack": String(attack), "facing": direction, "usec": Time.get_ticks_usec(), "mark_already_present": not vfx._marks.is_empty(), "process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames()})

func canvas_depth(item: CanvasItem) -> int:
	var depth := 0
	var cursor: Node = item
	while cursor != null:
		if cursor is CanvasItem:
			depth += cursor.z_index
			if not cursor.z_as_relative: break
		cursor = cursor.get_parent()
	return depth

func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline: await process_frame

func press(action: StringName, down: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	Input.parse_input_event(event)
