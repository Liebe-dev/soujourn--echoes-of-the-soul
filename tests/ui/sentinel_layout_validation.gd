extends Node

var checks := 0
var failures := 0

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("SENTINEL LAYOUT ", "PASS " if ok else "FAIL ", label)

func frame(count: int = 2) -> void:
	for i in count: await get_tree().process_frame

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexSentinelHUD20261015-LayoutFix"):
		get_tree().quit(2)
		return
	var loadout = load("res://scenes/UI/sentinel/sentinel_loadout.tscn").instantiate()
	get_tree().root.add_child(loadout)
	await frame()
	var loadout_position: Vector2 = loadout.position
	var loadout_scale: Vector2 = loadout.scale
	get_tree().root.remove_child(loadout)
	# Reproduces editor scene-switch retention before the old nodes are freed.
	get_viewport().size_changed.emit()
	loadout.hud_scale = 1.1
	loadout._layout()
	check(loadout.position.is_equal_approx(loadout_position) and loadout.scale.is_equal_approx(loadout_scale), "detached loadout keeps its last valid layout through stale callbacks and Inspector setters")
	loadout.free()
	var hud = load("res://scenes/UI/hud.tscn").instantiate()
	var meter = hud.get_node("ScreenSpace/bar/hp_bar_panel/UltimateMeter")
	var authored: Vector2 = meter.position
	get_tree().root.add_child(hud)
	await frame()
	hud.set_process(false)
	check(meter.position.is_equal_approx(authored), "runtime preserves the UltimateMeter position saved in hud.tscn")
	meter.position = Vector2(63, -45)
	get_viewport().size_changed.emit()
	check(meter.position.is_equal_approx(Vector2(63, -45)), "viewport resize does not snap the meter back to a hardcoded offset")
	for i in 8:
		get_tree().root.remove_child(hud)
		get_viewport().size_changed.emit()
		hud._layout_hud()
		hud.sentinel_loadout.hud_scale = 0.9 + float(i) * 0.01
		meter.meter_size = Vector2(132 + i, 22)
		meter.fire_speed = 0.35
		get_tree().root.add_child(hud)
		await frame()
		check(meter.position.is_equal_approx(Vector2(63, -45)), "scene detach/reattach cycle %d keeps the dragged position" % i)
	hud.set_ultimate_charge(100)
	check(hud.ultimate_meter.is_ultimate_ready(), "full ultimate presentation survives scene detach/reattach")
	get_tree().root.remove_child(hud)
	get_viewport().size_changed.emit()
	hud.free()
	print("SENTINEL LAYOUT RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
