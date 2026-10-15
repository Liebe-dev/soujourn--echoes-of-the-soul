extends Node

var checks := 0
var failures := 0
var rendered := false
var preview
var hud

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rendered = DisplayServer.get_name() != "headless"
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("SENTINEL HUD ", "PASS " if ok else "FAIL ", label)

func frame(count: int = 3) -> void:
	for i in count: await get_tree().process_frame

func snapshot(label: String) -> Image:
	if not rendered: return null
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://sentinel-hud-" + label + ".png")
	return img

func point(item: CanvasItem, local: Vector2) -> Vector2i:
	return Vector2i(item.get_global_transform_with_canvas() * local)

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexSentinelHUD20261015"):
		get_tree().quit(2)
		return
	Engine.max_fps = 120
	preview = load("res://scenes/UI/previews/dark_sentinel_hud_preview.tscn").instantiate()
	preview.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().root.add_child(preview)
	get_tree().current_scene = preview
	await frame()
	hud = preview.get_node("hud")
	var loadout = hud.sentinel_loadout
	var meter = hud.ultimate_meter
	var markers = hud.get_node("ScreenSpace/bar/hp_bar_panel/hp_bar_wrap/stagger_markers")
	check(loadout.visible and hud.sentinel_active, "F6 preview opens with Sentinel layout")
	check(hud.hp_bar.texture_progress == hud.SENTINEL_HP_FILL and hud.hp_bar.texture_over == hud.SENTINEL_HP_RIM, "active form uses black HP with red rim")
	check(not markers.visible, "Sentinel presentation hides threshold markers")
	for name in loadout.SLOT_NAMES:
		check(loadout.get_node(name).get_node("Key").text == name.trim_prefix("Skill"), "correct key legend for " + name)
	check(loadout.get_node("Q").position.x < loadout.get_node("E").position.x and loadout.get_node("E").position.x < loadout.get_node("Skill1").position.x, "Q and E flank weapon; numbered skills follow to the right")
	check(loadout.position.is_equal_approx(Vector2(24, 842)), "loadout anchors 24px from bottom-left at 1920x1080")
	var active_image: Image = await snapshot("active")
	if rendered:
		var outside := active_image.get_pixelv(point(loadout, Vector2(10, 10)))
		var background := active_image.get_pixelv(point(loadout, Vector2(250, 10)))
		check(outside.is_equal_approx(background), "rendered atlas gray backdrop is transparent")
		check(not active_image.get_pixelv(point(loadout, Vector2(100, 50))).is_equal_approx(background), "weapon artwork remains visible after background keying")
		var hp_dark := active_image.get_pixelv(point(hud.hp_bar, Vector2(80, 15)))
		var hp_rim := active_image.get_pixelv(point(hud.hp_bar, Vector2(80, 4)))
		check(hp_dark.r < 0.12 and hp_dark.g < 0.12 and hp_dark.b < 0.12, "rendered Sentinel health fill is black")
		check(hp_rim.r > hp_rim.g * 2.0, "rendered Sentinel health rim is red")

	var stats_before := [hud.hp, hud.stamina, hud.flask_charges, hud.stagger_tiers_ready.duplicate()]
	hud.set_sentinel_exit_pending(true)
	check(loadout.exit_pending and loadout.get_node("Q").get_node("Icon").modulate.r < 0.5 and loadout.get_node("Skill4").get_node("Icon").modulate.r < 0.5, "pending exit visually disables all six skill slots")
	hud.set_sentinel_exit_pending(false)
	hud.set_sentinel_ability_presentation(&"Q", 2.0, 4.0)
	var q = loadout.get_node("Q")
	check(q.get_node("Remaining").text == "2" and is_equal_approx(q.get_node("Cooldown").size.y, 35.0), "cooldown display uses supplied values without creating a gameplay timer")
	hud.set_sentinel_ability_presentation(&"1", 0.0, 0.0, false)
	check(loadout.get_node("Skill1").get_node("Icon").modulate.r < 0.5, "unaffordable skill has a distinct dimmed presentation")
	await snapshot("cooldowns")
	hud.set_sentinel_active(false)
	check(not loadout.visible and markers.visible, "leaving Sentinel hides loadout and restores threshold visuals")
	check(hud.hp_bar.texture_progress == hud._normal_hp_fill and hud.hp_bar.texture_over == hud._normal_hp_rim, "normal HP textures restore exactly")
	check([hud.hp, hud.stamina, hud.flask_charges, hud.stagger_tiers_ready] == stats_before, "presentation changes never mutate HP, stamina, flasks or threshold state")
	hud.set_sentinel_exit_pending(true)
	check(not loadout.exit_pending, "inactive form ignores pending-exit presentation")
	hud.set_sentinel_active(true)
	check(not q.get_node("Cooldown").visible and loadout.get_node("Skill1").get_node("Icon").modulate == Color.WHITE, "new presentation session has no stale cooldowns or resource warnings")
	hud.set_campfire_hidden(true)
	check(not loadout.is_visible_in_tree() and not meter.is_visible_in_tree(), "campfire hides both new widgets through existing ScreenSpace canvas")
	hud.set_campfire_hidden(false)
	check(loadout.is_visible_in_tree(), "leaving campfire restores current Sentinel presentation")
	hud.set_sentinel_active(false)
	hud.set_ultimate_charge(-10)
	check(meter.charge == 0.0 and not meter.get_node("ClawsLeft").visible, "empty charge clamps and hides ready claws")
	hud.set_ultimate_charge(25, 50)
	check(is_equal_approx(meter.get_node("Fill").material.get_shader_parameter("progress"), 0.5), "charge fills horizontally using configurable maximum")
	await snapshot("partial")
	hud.set_ultimate_charge(999)
	check(meter.charge == 100 and meter.is_ultimate_ready(), "charge clamps to maximum and reports ready")
	check(meter.get_node("ClawsLeft").visible and meter.get_node("ClawsRight").visible and meter.get_node("Prompt").visible, "full charge reveals both claw sets and R prompt")
	var full_image: Image = await snapshot("ready")
	await get_tree().create_timer(0.65).timeout
	var fire_image: Image = await snapshot("ready-fire")
	if rendered:
		var changes := 0
		for x in range(8, 120, 8):
			for y in range(4, 18, 3):
				var p := point(meter, Vector2(x, y))
				if not full_image.get_pixelv(p).is_equal_approx(fire_image.get_pixelv(p)): changes += 1
		check(changes > 10, "full black fill visibly animates with slow fire")
	var fire_time: float = meter._visual_time
	Engine.time_scale = 0.5
	await get_tree().create_timer(0.14, true, false, true).timeout
	check(meter._visual_time - fire_time > 0.035 and meter._visual_time - fire_time < 0.12, "fire animation follows game slow motion")
	Engine.time_scale = 1.0
	get_tree().paused = true
	var paused_time: float = meter._visual_time
	await get_tree().create_timer(0.12, true, false, true).timeout
	check(is_equal_approx(meter._visual_time, paused_time), "fire animation stops while paused")
	get_tree().paused = false
	await frame()
	hud.set_process(true)
	await get_tree().create_timer(0.02).timeout
	hud.hide_timer = hud.hide_delay + 1.0
	hud.in_combat = true
	hud._process(0.0)
	check(not hud.is_hidden, "full ultimate keeps HUD available instead of combat fading")
	hud.set_process(false)
	hud.set_sentinel_active(true)
	hud.modulate = Color(0.8, 0.7, 0.6, 0.2)
	hud._process(0.0)
	check(loadout.modulate == hud.modulate, "bottom loadout participates in existing HUD fade and flash")
	hud.modulate = Color.WHITE
	hud._process(0.0)

	var other = load("res://scenes/UI/hud.tscn").instantiate()
	add_child(other)
	other.set_process(false)
	other.set_ultimate_charge(50)
	check(other.ultimate_meter.get_node("Fill").material != meter.get_node("Fill").material and meter.get_node("Fill").material.get_shader_parameter("progress") == 0.0, "HUD instances keep independent fill materials")
	other.queue_free()
	await frame()
	var window := get_window()
	var old_size := window.size
	var old_content := window.content_scale_size
	window.content_scale_size = Vector2i(640, 360)
	window.size = Vector2i(640, 360)
	await frame(4)
	hud._layout_hud()
	check(loadout.position.y >= loadout.reserved_top - 0.1, "small viewport keeps loadout below top HUD")
	check(loadout.position.x + 515.0 * loadout.scale.x <= hud.get_viewport_rect().size.x - 24.0 + 0.1 and loadout.position.y + 214.0 * loadout.scale.y <= hud.get_viewport_rect().size.y - 24.0 + 0.1, "small viewport keeps full loadout inside safe margins")
	await snapshot("small")
	window.content_scale_size = old_content
	window.size = old_size
	await frame()
	preview.queue_free()
	await frame()
	var arena = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	var player = arena.get_node("PlayableAdel")
	arena.get_node("Enemy").set_physics_process(false)
	await frame(70)
	player.set_physics_process(false)
	hud = player.get_node("Camera2D/hud")
	hud.set_sentinel_active(true)
	hud.set_ultimate_charge(0.0)
	var original_position: Vector2 = hud.sentinel_loadout.get_global_transform_with_canvas().origin
	player.position.x += 80.0
	player.get_node("Camera2D").zoom = Vector2(1.5, 1.5)
	await frame()
	check(hud.sentinel_loadout.get_global_transform_with_canvas().origin.is_equal_approx(original_position), "real player camera movement and zoom do not move the new loadout")
	check(hud.sentinel_loadout.visible and hud.hp_bar.texture_over == hud.SENTINEL_HP_RIM, "real player scene loads Sentinel presentation through existing HUD instance")
	player.get_node("Camera2D").zoom = Vector2(1.05, 1.05)
	if hud.fade_tween: hud.fade_tween.kill()
	hud.modulate = Color.WHITE
	hud._process(0.0)
	await snapshot("gameplay")
	print("SENTINEL HUD RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
