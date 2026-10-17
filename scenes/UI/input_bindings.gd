extends Node
## Keyboard/mouse bindings, independent of checkpoint saves.
signal bindings_changed
const CONFIG_PATH := "user://controls.cfg"
const MAX_BINDINGS := 2
const ACTIONS := [
	{"action": &"move_left", "label": "Move left"},
	{"action": &"move_right", "label": "Move right"},
	{"action": &"move_down", "label": "Down"},
	{"action": &"jump", "label": "Jump"},
	{"action": &"run", "label": "Toggle run"},
	{"action": &"dodge", "label": "Dodge / dash"},
	{"action": &"attack", "label": "Attack (right hand)"},
	{"action": &"guard and deflect", "label": "Guard / deflect (left hand)"},
	{"action": &"weapon_skill", "label": "Weapon skill"},
	{"action": &"soul_heal", "label": "Heal"},
	{"action": &"interact", "label": "Interact / campfire"},
	{"action": &"toggle_master_menu", "label": "Character menu"},
	{"action": &"target_lock", "label": "Lock / switch target"},
]
var _defaults: Dictionary = {}
var _bindings: Dictionary = {}

func _ready() -> void:
	for definition in ACTIONS:
		var action: StringName = definition.action
		var entries: Array[InputEvent] = []
		var configured: Dictionary = ProjectSettings.get_setting("input/" + action, {})
		for event in configured.get("events", []):
			if _supported(event): entries.append(_normalize(event))
		_defaults[action] = entries
	reload_saved()

func _supported(event: Variant) -> bool:
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode else event.keycode
		return code != 0 and code != KEY_ESCAPE
	if event is InputEventMouseButton:
		return event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]
	return false

func _normalize(event: InputEvent) -> InputEvent:
	if event is InputEventKey:
		var key := InputEventKey.new()
		key.physical_keycode = event.physical_keycode if event.physical_keycode else event.keycode
		key.ctrl_pressed = event.ctrl_pressed and key.physical_keycode != KEY_CTRL
		key.alt_pressed = event.alt_pressed and key.physical_keycode != KEY_ALT
		key.shift_pressed = event.shift_pressed and key.physical_keycode != KEY_SHIFT
		key.meta_pressed = event.meta_pressed and key.physical_keycode != KEY_META
		key.device = -1
		return key
	var mouse := InputEventMouseButton.new()
	mouse.button_index = event.button_index
	mouse.device = -1
	return mouse

func label_for(event: InputEvent) -> String:
	if event == null: return "Unassigned"
	if event is InputEventMouseButton:
		return {1: "Mouse left", 2: "Mouse right", 3: "Mouse middle", 8: "Mouse 4", 9: "Mouse 5"}.get(event.button_index, event.as_text())
	return event.as_text().replace(" (Physical)", "").replace(" - Physical", "")

func get_bindings(action: StringName) -> Array:
	return _bindings.get(action, []).duplicate(true)

func _same_control(a: InputEvent, b: InputEvent) -> bool:
	# Extra modifiers also trigger unmodified gameplay actions: reject overlaps.
	if a is InputEventKey and b is InputEventKey: return a.physical_keycode == b.physical_keycode
	if a is InputEventMouseButton and b is InputEventMouseButton: return a.button_index == b.button_index
	return false

func _validate(candidate: Dictionary) -> String:
	var used: Array[Dictionary] = []
	for definition in ACTIONS:
		var events: Array = candidate.get(definition.action, [])
		if events.is_empty() or events.size() > MAX_BINDINGS: return "Keep at least one binding for " + definition.label + "."
		for event in events:
			if not _supported(event): return "Choose a keyboard key or mouse button. Esc is reserved for Back."
			for previous in used:
				if _same_control(event, previous.event): return "%s is already assigned to %s." % [label_for(event), previous.label]
			used.append({"event": event, "label": definition.label})
	return ""

func bind(action: StringName, index: int, event: InputEvent) -> String:
	if not _bindings.has(action) or index < 0 or index >= MAX_BINDINGS: return "Invalid binding."
	if not _supported(event): return "Choose a keyboard key or mouse button. Esc cancels; the wheel is not a held button."
	var next := _bindings.duplicate(true)
	var entries: Array = next[action]
	if index > entries.size(): return "Assign the first binding before the second."
	var normalized := _normalize(event)
	if index < entries.size(): entries[index] = normalized
	else: entries.append(normalized)
	return _commit(next)

func clear_secondary(action: StringName) -> String:
	var next := _bindings.duplicate(true)
	if not next.has(action): return "Invalid action."
	if next[action].size() > 1: next[action].resize(1)
	return _commit(next)

func reset_action(action: StringName) -> String:
	var next := _bindings.duplicate(true)
	if not _defaults.has(action): return "Invalid action."
	next[action] = _defaults[action].duplicate(true)
	return _commit(next)

func reset_defaults() -> String:
	return _commit(_defaults.duplicate(true))

func _encode(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"kind": "key", "code": int(event.physical_keycode), "ctrl": event.ctrl_pressed, "alt": event.alt_pressed, "shift": event.shift_pressed, "meta": event.meta_pressed}
	return {"kind": "mouse", "button": int(event.button_index)}

func _decode(data: Variant) -> InputEvent:
	if not data is Dictionary: return null
	if data.get("kind") == "key":
		if not data.get("code") is int or data.code <= 0 or data.code > 0x1ffffff: return null
		var key := InputEventKey.new()
		key.physical_keycode = data.code
		for flag in ["ctrl", "alt", "shift", "meta"]:
			if not data.get(flag, false) is bool: return null
		key.ctrl_pressed = data.get("ctrl", false)
		key.alt_pressed = data.get("alt", false)
		key.shift_pressed = data.get("shift", false)
		key.meta_pressed = data.get("meta", false)
		return _normalize(key) if _supported(key) else null
	if data.get("kind") == "mouse":
		if not data.get("button") is int: return null
		var mouse := InputEventMouseButton.new()
		mouse.button_index = data.button
		return _normalize(mouse) if _supported(mouse) else null
	return null

func _commit(candidate: Dictionary) -> String:
	var problem := _validate(candidate)
	if not problem.is_empty(): return problem
	var config := ConfigFile.new()
	config.set_value("controls", "version", 1)
	for definition in ACTIONS:
		var serialized: Array[Dictionary] = []
		for event in candidate[definition.action]: serialized.append(_encode(event))
		config.set_value("bindings", definition.action, serialized)
	if config.save(CONFIG_PATH) != OK: return "Could not save controls. Your previous bindings are still active."
	_apply(candidate)
	return ""

func reload_saved() -> void:
	var candidate := _defaults.duplicate(true)
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK and config.get_value("controls", "version", 0) == 1:
		for definition in ACTIONS:
			if not config.has_section_key("bindings", definition.action): continue
			var raw: Variant = config.get_value("bindings", definition.action)
			if not raw is Array or raw.is_empty() or raw.size() > MAX_BINDINGS: continue
			var decoded: Array[InputEvent] = []
			for entry in raw:
				var event := _decode(entry)
				if event == null:
					decoded.clear()
					break
				decoded.append(event)
			if not decoded.is_empty(): candidate[definition.action] = decoded
		if not _validate(candidate).is_empty(): candidate = _defaults.duplicate(true)
	_apply(candidate)

func _apply(candidate: Dictionary) -> void:
	_bindings = candidate
	for definition in ACTIONS:
		var action: StringName = definition.action
		Input.action_release(action)
		for event in InputMap.action_get_events(action):
			if event is InputEventKey or event is InputEventMouseButton: InputMap.action_erase_event(action, event)
		for event in _bindings[action]: InputMap.action_add_event(action, event.duplicate())
	bindings_changed.emit()
