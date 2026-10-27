extends SceneTree

const WORK := "D:/Godot Project/soujourn--echoes-of-the-soul/output/integration/enemy_parts_2026-10-26_v1/"
const CASES := [
	["walk", 0.0],
	["walk", 0.5],
	["run", 0.25],
	["run", 0.75],
	["detect player", 0.2],
	["RESET", 0.0],
]

var canvas: SubViewport
var rigs: Array[Node2D] = []

func _initialize() -> void:
	root.hide()
	call_deferred("_capture")

func _capture() -> void:
	canvas = SubViewport.new()
	canvas.size = Vector2i(2200, 2520)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var backdrop := ColorRect.new()
	backdrop.size = Vector2(canvas.size)
	backdrop.z_index = -100
	backdrop.color = Color(0.18, 0.20, 0.24)
	canvas.add_child(backdrop)
	var packed: PackedScene = load("res://scenes/enemy/enemy_spine.tscn")
	if packed == null:
		push_error("Rig failed to load")
		quit(1)
		return
	var records: Array[Dictionary] = []
	for row in CASES.size():
		var case: Array = CASES[row]
		for col in 2:
			var rig: Node2D = packed.instantiate()
			canvas.add_child(rig)
			rigs.append(rig)
			if col == 1:
				_apply_candidate(rig)
			var player: AnimationPlayer = rig.get_node("AnimationPlayer")
			player.play("RESET")
			player.seek(0.0, true)
			player.play(StringName(case[0]))
			player.seek(float(case[1]), true)
			player.pause()
			rig.get_node("Skeleton2D").visible = true
			rig.get_node("AttackSprite").visible = false
			rig.get_node("Sprite2D2").visible = false
			rig.get_node("Sprite2D").visible = false
			rig.scale = Vector2(0.98, 0.98)
			rig.position = Vector2(col * 1100 + 495, row * 400 + 155) - Vector2(890, 696) * 0.98
			var label := Label.new()
			label.position = Vector2(col * 1100 + 30, row * 400 + 12)
			label.add_theme_font_size_override("font_size", 25)
			label.text = "%s | %s %.2fs" % ["ORIGINAL" if col == 0 else "APPROVED REPLACEMENT", case[0], case[1]]
			canvas.add_child(label)
			records.append({"column": col, "animation": case[0], "time": case[1], "sprite_count": rig.find_children("*", "Sprite2D", true, false).size()})
	await process_frame
	await process_frame
	RenderingServer.force_draw(false, 0.0)
	await RenderingServer.frame_post_draw
	var rendered: Image = canvas.get_texture().get_image()
	if rendered == null or rendered.is_empty():
		push_error("Empty capture")
		quit(2)
		return
	var err := rendered.save_png(WORK + "rig_comparison.png")
	if err != OK:
		push_error("Capture save failed: %s" % err)
		quit(3)
		return
	var record_file := FileAccess.open(WORK + "capture_results.json", FileAccess.WRITE)
	record_file.store_string(JSON.stringify({"status": "passed", "cases": records, "image_size": [rendered.get_width(), rendered.get_height()]}, "\t"))
	record_file.close()
	print("ENEMY_ART_CAPTURE_OK cases=%d" % records.size())
	quit(0)

func _apply_candidate(rig: Node2D) -> void:
	for node: Node in rig.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite.texture == null:
			continue
		var filename: String = sprite.texture.resource_path.get_file()
		var candidate_path := WORK + "candidate/" + filename
		if not FileAccess.file_exists(candidate_path):
			continue
		var image := Image.load_from_file(candidate_path)
		if image == null or image.is_empty():
			push_error("Failed candidate: " + candidate_path)
			continue
		sprite.texture = ImageTexture.create_from_image(image)

