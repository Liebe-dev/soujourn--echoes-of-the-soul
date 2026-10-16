extends Control
## F6 visual preview only. No player, combat controller or form mechanics are spawned.

@onready var hud = $hud

func _ready() -> void:
	hud.set_process(false)
	hud.set_process_unhandled_input(false)
	var titles := ["Thường", "Ulti 50%", "Ulti đầy", "Sentinel", "Chờ thoát", "Hồi chiêu / thiếu tài nguyên"]
	for i in titles.size():
		var button := Button.new()
		button.text = titles[i]
		button.pressed.connect(_show_state.bind(i))
		$States.add_child(button)
	get_viewport().size_changed.connect(_layout_guides)
	_layout_guides()
	_show_state(3)

func _layout_guides() -> void:
	var large := get_viewport_rect().size.x >= 1000.0 and get_viewport_rect().size.y >= 600.0
	$States.visible = large
	$State.visible = large

func _show_state(index: int) -> void:
	hud.set_sentinel_active(false)
	hud.set_ultimate_charge(0.0)
	hud.hp = 1 if index == 4 else 78
	hud.stamina = 65.0
	hud.sync_hp_display()
	hud.sync_stamina_display()
	if index == 1: hud.set_ultimate_charge(50.0)
	if index == 2: hud.set_ultimate_charge(100.0)
	if index >= 3: hud.set_sentinel_active(true)
	if index == 4: hud.set_sentinel_exit_pending(true)
	if index == 5:
		hud.set_sentinel_ability_presentation(&"Q", 2.0, 4.0)
		hud.set_sentinel_ability_presentation(&"1", 0.0, 0.0, false)
		hud.set_sentinel_ability_presentation(&"3", 5.0, 8.0)
	if hud.fade_tween: hud.fade_tween.kill()
	hud.modulate = Color.WHITE
	hud.hud_art.modulate = Color.WHITE
	hud.sentinel_loadout.modulate = Color.WHITE
	hud.weapon_loadout.modulate = Color.WHITE
	$State.text = "T: +30 ulti | R: bật HUD Sentinel khi đầy | Y: thoát. Chỉ xem thử giao diện."
