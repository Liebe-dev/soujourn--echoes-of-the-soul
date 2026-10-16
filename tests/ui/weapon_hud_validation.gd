extends Node
var checks := 0
var failures := 0
var rendered := false
var hud

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.get_user_data_dir().contains("CodexWeaponHUD"):
		get_tree().quit(2)
		return
	rendered = DisplayServer.get_name() != "headless"
	run.call_deferred()

func frames(n: int = 3) -> void:
	for i in n: await get_tree().process_frame

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("WEAPON HUD ", "PASS " if ok else "FAIL ", label)

func snapshot(label: String) -> Image:
	if not rendered: return null
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://weapon-hud-" + label + ".png")
	var active_loadout = hud.sentinel_loadout if hud.sentinel_active else hud.weapon_loadout
	var transform: Transform2D = active_loadout.get_global_transform_with_canvas()
	var extent: Vector2 = active_loadout.REFERENCE_SIZE * transform.get_scale()
	var rect := Rect2(transform.origin - Vector2(16, 16), extent + Vector2(32, 32))
	var bounds := Rect2i(rect.intersection(Rect2(Vector2.ZERO, Vector2(img.get_size()))))
	img.get_region(bounds).save_png("res://weapon-hud-" + label + "-detail.png")
	return img

func run() -> void:
	Engine.max_fps = 120
	var preview = load("res://scenes/UI/previews/weapon_hud_preview.tscn").instantiate()
	var authored_normal_scale: float = preview.get_node("hud/ScreenSpace/WeaponLoadout").hud_scale
	var authored_sentinel_scale: float = preview.get_node("hud/ScreenSpace/SentinelLoadout").hud_scale
	get_tree().root.add_child(preview)
	get_tree().current_scene = preview
	await frames()
	hud = preview.get_node("hud")
	var loadout = hud.weapon_loadout
	var q = loadout.get_node("Q")
	check(is_equal_approx(loadout.hud_scale, authored_normal_scale), "normal scale saved in Inspector survives HUD initialization")
	check(is_equal_approx(hud.sentinel_loadout.hud_scale, authored_sentinel_scale), "Sentinel scale saved in Inspector survives HUD initialization")
	check(loadout.visible and not hud.sentinel_loadout.visible, "normal form displays only normal weapon loadout")
	check(loadout.get_node("RightWeaponArtwork").texture.resource_path.ends_with("saber1.png"), "right-hand slot uses the supplied diagonal Saber artwork")
	check(loadout.get_node("RightWeaponArtwork").position.x < loadout.get_node("LeftWeaponArtwork").position.x, "weapon hands preserve the reference composition")
	check(loadout.left_weapon == null and loadout.get_node("LeftWeaponArtwork").texture == null, "left-hand weapon slot is empty")
	check(not loadout.has_node("E") and not q.has_node("Key"), "no left-hand skill or Q/E key captions are drawn")
	check(q.icon.resource_path.ends_with("skill.png"), "Q uses the supplied skill icon")
	var sword = loadout.get_node("RightWeaponArtwork")
	check(sword.size.is_equal_approx(Vector2(sword.texture.get_size())) and is_zero_approx(sword.rotation), "sword keeps its full authored size and diagonal orientation")
	check(loadout.get_node("ItemSlots").get_child_count() == 3, "three empty item placeholders are reserved")
	check(not loadout.has_node("Mana") and not loadout.has_node("Skill1"), "mana and Arts are absent")
	check(is_equal_approx(loadout.inset_opacity, 0.32), "inset alpha is configured as 32 percent")
	check(is_equal_approx(loadout.get_node("Inset").material.get_shader_parameter("inset_opacity"), 0.32), "source alpha is normalized before applying inset opacity")
	check(loadout.get_node("BorderRepair/Left").flip_v and loadout.get_node("BorderRepair/Right").flip_v, "corner repairs reuse intact original frame pieces")
	var bottom: float = loadout.position.y + loadout.REFERENCE_SIZE.y * loadout.scale.y
	check(is_equal_approx(loadout.position.x, 24.0) and is_equal_approx(bottom, 1056.0), "normal loadout uses the shared 24-pixel bottom-left margin")
	var normal_image: Image = await snapshot("normal")
	if rendered:
		var sample := Vector2i(loadout.get_global_transform_with_canvas() * Vector2(65, 20))
		var fill := normal_image.get_pixelv(sample)
		check(absf(fill.r - 68.0 / 255.0) < 0.02 and absf(fill.g - 71.0 / 255.0) < 0.02, "rendered inset blends gray at 32 percent opacity")
		var empty_slot := Vector2i(loadout.get_global_transform_with_canvas() * Vector2(147, 12))
		check(normal_image.get_pixelv(empty_slot).is_equal_approx(fill), "empty left-hand slot keeps the translucent inset")
		var repaired_corner := Vector2i(loadout.get_global_transform_with_canvas() * Vector2(200, 65))
		check(normal_image.get_pixelv(repaired_corner).is_equal_approx(fill), "removing E leaves no cutout in the lower empty weapon inset")
	var stats_before := [hud.hp, hud.stamina, hud.flask_charges]
	for ratio in [1.0, 0.5, 0.1, 0.0]:
		hud.set_weapon_ability_presentation(&"Q", ratio * 6.0, 6.0)
		check(is_equal_approx(q.get_node("Cooldown").material.get_shader_parameter("remaining_ratio"), ratio), "cooldown vertical coverage ratio %.1f" % ratio)
		check(q.get_node("Cooldown").visible == (ratio > 0.0) and q.get_node("Remaining").visible == (ratio > 0.0), "cooldown overlay and digits visibility %.1f" % ratio)
		var color: Color = q.get_node("Frame").get_theme_stylebox("panel").border_color
		check(color.is_equal_approx(q.cooldown_border_color if ratio > 0.0 else Color.WHITE), "border color returns to white at ready %.1f" % ratio)
	check(is_equal_approx(q.cooldown_opacity, 0.6), "cooldown overlay uses 60 percent black")
	hud.set_weapon_ability_presentation(&"Q", 5.2, 6.0)
	check(q.get_node("Remaining").text == "5.2s", "remaining time is shown with a decimal second")
	var before: float = q.remaining
	await frames(10)
	check(is_equal_approx(q.remaining, before), "gameplay presentation owns no countdown clock")
	hud.set_weapon_ability_presentation(&"Q", 3.0, 6.0)
	await snapshot("cooldown")
	if rendered:
		var img: Image = get_viewport().get_texture().get_image()
		# Read the same source pixel with and without the lower-half overlay.
		var point := Vector2i(q.get_global_transform_with_canvas() * Vector2(12, 31))
		var dark := img.get_pixelv(point)
		hud.set_weapon_ability_presentation(&"Q", 0.0, 0.0)
		await frames()
		await RenderingServer.frame_post_draw
		var lit := get_viewport().get_texture().get_image().get_pixelv(point)
		check(dark.r + dark.g + dark.b < (lit.r + lit.g + lit.b) * 0.6, "rendered cooldown darkens the remaining lower half")
	hud.set_weapon_ability_presentation(&"Q", 0.0, 0.0)
	hud.set_weapon_ability_presentation(&"E", 2.0, 4.0)
	check(not q.get_node("Cooldown").visible and not loadout.has_node("E"), "updates for absent E do not recreate a skill or alter Q")
	hud.set_sentinel_active(true)
	check(not loadout.visible and hud.sentinel_loadout.visible, "Sentinel replaces the normal loadout")
	await snapshot("sentinel")
	hud.set_sentinel_active(false)
	check(loadout.visible and not hud.sentinel_loadout.visible, "normal loadout returns on Sentinel exit")
	check([hud.hp, hud.stamina, hud.flask_charges] == stats_before, "HUD switching and cooldown presentation do not spend resources")
	hud.set_campfire_hidden(true)
	check(not loadout.is_visible_in_tree(), "campfire hides normal loadout through ScreenSpace")
	hud.set_campfire_hidden(false)
	check(loadout.is_visible_in_tree(), "campfire exit restores normal loadout")
	hud.modulate = Color(1, 1, 1, 0.2)
	hud._process(0.0)
	check(loadout.modulate == hud.modulate, "normal loadout inherits HUD fade")
	hud.modulate = Color.WHITE
	hud._process(0.0)
	var old_size := get_window().size
	var old_content := get_window().content_scale_size
	get_window().content_scale_size = Vector2i(640, 360)
	get_window().size = Vector2i(640, 360)
	await frames(5)
	hud._layout_hud()
	check(is_equal_approx(loadout.hud_scale, authored_normal_scale) and is_equal_approx(hud.sentinel_loadout.hud_scale, authored_sentinel_scale), "viewport resize preserves both configured loadout scales")
	check(loadout.position.y >= loadout.reserved_top - 0.1, "small viewport keeps weapon HUD below top HUD")
	check(loadout.position.x + loadout.REFERENCE_SIZE.x * loadout.scale.x <= 616.1, "small viewport keeps weapon HUD inside right margin")
	await snapshot("small")
	get_window().content_scale_size = old_content
	get_window().size = old_size
	await frames()
	preview.queue_free()
	await frames()
	var arena = load("res://scenes/enemy/spine_enemy_test.tscn").instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	var player = arena.get_node("PlayableAdel")
	arena.get_node("Enemy").set_physics_process(false)
	await frames(70)
	player.set_physics_process(false)
	hud = player.get_node("Camera2D/hud")
	check(hud.weapon_loadout.right_weapon.resource_path.ends_with("saber1.png") and hud.weapon_loadout.left_weapon == null, "spine_enemy_test inherits current weapon assets instead of stale HUD overrides")
	check(hud.weapon_loadout.get_node("Q").icon.resource_path.ends_with("skill.png"), "spine_enemy_test inherits the current Q skill icon")
	check(is_equal_approx(hud.weapon_loadout.scale.x, authored_normal_scale), "spine_enemy_test applies the scale saved on its loadout instance")
	if hud.fade_tween: hud.fade_tween.kill()
	hud.modulate = Color.WHITE
	hud._process(0.0)
	var origin: Vector2 = hud.weapon_loadout.get_global_transform_with_canvas().origin
	player.position.x += 100.0
	player.get_node("Camera2D").zoom = Vector2(1.5, 1.5)
	await frames()
	check(hud.weapon_loadout.get_global_transform_with_canvas().origin.is_equal_approx(origin), "camera movement and zoom leave normal HUD fixed on screen")
	await snapshot("gameplay")
	print("WEAPON HUD RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
