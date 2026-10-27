extends SceneTree

const WORK := "D:/Godot Project/soujourn--echoes-of-the-soul/output/integration/enemy_parts_2026-10-26_v1/"
const PARTS := ["body.png", "head.png", "lef leg.png", "left hand.png", "left palm.png", "right bicep.png", "right hand.png", "right leg.png", "right palm.png", "tail.png"]
const CASES := [["walk", 0.0], ["walk", 0.5], ["run", 0.25], ["run", 0.75], ["detect player", 0.2], ["RESET", 0.0]]

func _initialize() -> void:
	root.hide()
	call_deferred("_capture")

func _capture() -> void:
	var canvas := SubViewport.new()
	canvas.size = Vector2i(1100, 2640)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var backdrop := ColorRect.new()
	backdrop.size = Vector2(canvas.size)
	backdrop.color = Color(0.18, 0.20, 0.24)
	backdrop.z_index = -100
	canvas.add_child(backdrop)
	var packed: PackedScene = load("res://scenes/enemy/enemy_spine.tscn")
	assert(packed != null)
	var records: Array[Dictionary] = []
	for row in CASES.size():
		var case: Array = CASES[row]
		var rig: Node2D = packed.instantiate()
		canvas.add_child(rig)
		var loaded_parts: Array[Dictionary] = []
		for node: Node in rig.find_children("*", "Sprite2D", true, false):
			var sprite := node as Sprite2D
			if sprite.texture == null:
				continue
			var filename := sprite.texture.resource_path.get_file()
			if not filename in PARTS:
				continue
			var expected := Image.load_from_file(WORK + "candidate/" + filename)
			assert(expected != null and not expected.is_empty())
			assert(sprite.texture.get_size() == Vector2(expected.get_size()), "Imported size mismatch: " + filename)
			loaded_parts.append({"file": filename, "width": sprite.texture.get_width(), "height": sprite.texture.get_height()})
		assert(loaded_parts.size() == 10, "Expected ten imported parts")
		var player: AnimationPlayer = rig.get_node("AnimationPlayer")
		player.play("RESET")
		player.seek(0.0, true)
		player.play(StringName(case[0]))
		player.seek(float(case[1]), true)
		player.pause()
		rig.get_node("Skeleton2D").visible = true
		for node_name: String in ["AttackSprite", "Sprite2D2", "Sprite2D"]:
			rig.get_node(node_name).visible = false
		rig.scale = Vector2(0.98, 0.98)
		rig.position = Vector2(495, row * 440 + 160) - Vector2(890, 696) * 0.98
		var label := Label.new()
		label.position = Vector2(30, row * 440 + 12)
		label.add_theme_font_size_override("font_size", 25)
		label.text = "%s | %.2fs" % [case[0], case[1]]
		canvas.add_child(label)
		records.append({"animation": case[0], "time": case[1], "loaded_parts": loaded_parts})
	await process_frame
	await process_frame
	RenderingServer.force_draw(false, 0.0)
	await RenderingServer.frame_post_draw
	var rendered: Image = canvas.get_texture().get_image()
	assert(rendered != null and not rendered.is_empty())
	assert(rendered.save_png(WORK + "installed_rig_check.png") == OK)
	assert(rendered.get_region(Rect2i(0, 0, 1100, 1320)).save_png(WORK + "final_preview.png") == OK)
	var result_file := FileAccess.open(WORK + "installed_validation.json", FileAccess.WRITE)
	result_file.store_string(JSON.stringify({"status": "passed", "source": "imported replacement PNG resources; no runtime texture overrides", "cases": records}, "\t"))
	result_file.close()
	print("INSTALLED_ENEMY_ART_OK cases=%d parts_per_case=10" % records.size())
	quit(0)
