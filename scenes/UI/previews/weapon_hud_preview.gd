extends Control
## Preview-only clock. No gameplay skills, resource costs, item use or key bindings.
@onready var hud = $hud
var _remaining := 0.0
var _duration := 6.0

func _ready() -> void:
	hud.set_process(false)
	hud.set_process_unhandled_input(false)
	for label in ["Thường", "Cooldown Q", "Sentinel"]:
		var button := Button.new()
		button.text = label
		button.pressed.connect(_choose.bind(label))
		$States.add_child(button)
	hud.hp = 78
	hud.stamina = 65.0
	hud.sync_hp_display()
	hud.sync_stamina_display()
	_choose("Thường")

func _choose(label: String) -> void:
	_remaining = 0.0
	hud.set_weapon_ability_presentation(&"Q", 0.0, 0.0)
	hud.set_sentinel_active(label == "Sentinel")
	if label == "Cooldown Q":
		_remaining = _duration
		hud.set_weapon_ability_presentation(&"Q", _remaining, _duration)
	if hud.fade_tween: hud.fade_tween.kill()
	hud.modulate = Color.WHITE
	hud.hud_art.modulate = Color.WHITE
	hud.weapon_loadout.modulate = Color.WHITE
	hud.sentinel_loadout.modulate = Color.WHITE

func _process(delta: float) -> void:
	if _remaining <= 0.0: return
	_remaining = maxf(_remaining - delta, 0.0)
	hud.set_weapon_ability_presentation(&"Q", _remaining, _duration)
