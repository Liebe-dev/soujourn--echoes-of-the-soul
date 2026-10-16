extends Node
## Temporary debug shortcuts; real players route activation through the drain module.
## Standalone HUD previews keep presentation-only behavior.

@export var debug_keys_enabled := true
@export_range(1.0, 100.0, 1.0) var ultimate_gain: float = 30.0

var _hud: Control
var _actor: Node

func _ready() -> void:
	_hud = get_parent() as Control
	var ancestor := _hud.get_parent()
	while ancestor != null:
		if ancestor.has_method("is_campfire_ui_active"):
			_actor = ancestor
			break
		ancestor = ancestor.get_parent()

func _unhandled_key_input(event: InputEvent) -> void:
	if not debug_keys_enabled or not OS.is_debug_build(): return
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed: return
	if not _can_debug(): return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	match key:
		KEY_T:
			if not _hud.sentinel_active:
				_hud.set_ultimate_charge(_hud.ultimate_meter.charge + ultimate_gain, _hud.ultimate_meter.maximum)
				_hud.enter_combat()
		KEY_R:
			if _hud.ultimate_meter.is_ultimate_ready() and not _hud.sentinel_active:
				if is_instance_valid(_actor) and _actor.has_method("begin_sentinel"):
					if not _actor.begin_sentinel(): return
				else: _hud.set_sentinel_active(true)
				_hud.set_ultimate_charge(0.0, _hud.ultimate_meter.maximum)
		KEY_Y:
			if _hud.sentinel_active:
				if is_instance_valid(_actor) and _actor.has_method("end_sentinel"): _actor.end_sentinel()
				else: _hud.set_sentinel_active(false)
				_hud.enter_combat()
		_: return
	get_viewport().set_input_as_handled()

func _can_debug() -> bool:
	if get_tree().paused or not _hud.get_node("ScreenSpace").visible: return false
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit: return false
	if is_instance_valid(_actor):
		if _actor.is_sentinel_entering(): return false
		if _actor.is_campfire_ui_active() or _actor.is_in_rest_state(): return false
		for path in ["Camera2D/UI_Layer/master_menu", "Camera2D/UI_Layer/PauseMenu"]:
			var menu := _actor.get_node_or_null(path) as Control
			if menu != null and menu.visible: return false
	return true
