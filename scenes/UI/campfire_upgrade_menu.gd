extends Control
signal closed
const Config = preload("res://scenes/Mechanic/progression_config.gd")
@onready var panel: PanelContainer = $Panel
@onready var body: VBoxContainer = $Panel/MarginContainer/VBox
var _campfire: Node
var _draft: Dictionary = {}
var _rows: Dictionary = {}
var _confirming := false

func _ready() -> void:
	hide()
	for i in Config.ATTRIBUTES.size():
		var id: StringName = Config.ATTRIBUTES[i]
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = Config.LABELS[i]
		label.add_theme_font_size_override("font_size", 22)
		label.tooltip_text = Config.DESCRIPTIONS[i]
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var minus := Button.new()
		minus.text = "-"
		minus.add_theme_font_size_override("font_size", 22)
		minus.custom_minimum_size = Vector2(44, 44)
		minus.pressed.connect(_adjust.bind(id, -1))
		row.add_child(minus)
		var value := Label.new()
		value.add_theme_font_size_override("font_size", 22)
		value.custom_minimum_size.x = 140
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(value)
		var plus := Button.new()
		plus.text = "+"
		plus.add_theme_font_size_override("font_size", 22)
		plus.custom_minimum_size = Vector2(44, 44)
		plus.pressed.connect(_adjust.bind(id, 1))
		row.add_child(plus)
		body.get_node("Scroll/Attributes").add_child(row)
		_rows[id] = {"value": value, "minus": minus, "plus": plus}
	body.get_node("Actions/Confirm").pressed.connect(_confirm)
	body.get_node("Actions/Reset").pressed.connect(_reset_draft)
	body.get_node("BackButton").pressed.connect(close)
	PlayerProgress.changed.connect(_refresh)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	panel.size = Vector2(920, 880)
	var available := get_viewport_rect().size - Vector2(32, 32)
	panel.scale = Vector2.ONE * minf(1.0, minf(available.x / 920.0, available.y / 880.0))
	panel.position = (get_viewport_rect().size - panel.size * panel.scale) * 0.5

func open(campfire: Node = null) -> void:
	_campfire = campfire
	_draft.clear()
	body.get_node("Status").text = PlayerProgress.migration_message
	show()
	panel.show()
	_refresh()
	body.get_node("BackButton").grab_focus()

func close() -> void:
	_draft.clear()
	hide()
	panel.hide()
	closed.emit()

func _reset_draft() -> void:
	_draft.clear()
	body.get_node("Status").text = ""
	_refresh()

func _spent() -> int:
	var total := 0
	for value in _draft.values(): total += int(value)
	return total

func _adjust(id: StringName, delta: int) -> void:
	if _confirming or (delta > 0 and _spent() >= PlayerProgress.upgrade_points): return
	_draft[id] = maxi(0, int(_draft.get(id, 0)) + delta)
	_refresh()

func _refresh() -> void:
	if not is_node_ready(): return
	body.get_node("Header/LevelValue").text = str(PlayerProgress.level)
	body.get_node("Header/ExpValue").text = "%d / %d" % [PlayerProgress.exp, PlayerProgress.get_exp_to_next_level()]
	body.get_node("Header/PointsValue").text = "%d remaining (%d planned)" % [PlayerProgress.upgrade_points - _spent(), _spent()]
	var next := PlayerProgress.attributes.duplicate()
	for id in Config.ATTRIBUTES:
		var count := int(_draft.get(id, 0))
		next[id] += count
		_rows[id].value.text = "%d > %d" % [PlayerProgress.attributes[id], next[id]]
		_rows[id].minus.disabled = count <= 0
		_rows[id].plus.disabled = _spent() >= PlayerProgress.upgrade_points
	var actor := get_tree().get_first_node_in_group("Player")
	var base_regen: float = actor.stamina_regen_per_second if actor != null else 28.0
	var config: Resource = PlayerProgress.config
	var preview := "HP %d > %d    Stamina %.0f > %.0f    Regen %.2f > %.2f /s" % [
		PlayerProgress.get_max_hp(), config.max_hp(next), PlayerProgress.get_max_stamina(), config.max_stamina(next),
		config.stamina_regen(PlayerProgress.attributes, base_regen), config.stamina_regen(next, base_regen)]
	if actor != null and actor.combat != null:
		var weapon = actor.combat.equipped_weapon
		if weapon != null:
			preview += "\n%s attack %.2f > %.2f | Skill %s > %s" % [weapon.display_name,
				weapon.damage * weapon.attack_multiplier(PlayerProgress.attributes, config), weapon.damage * weapon.attack_multiplier(next, config),
				"Ready" if weapon.meets_requirements(PlayerProgress.attributes) else "Locked",
				"Ready" if weapon.meets_requirements(next) else "Locked"]
	body.get_node("Preview").text = preview
	body.get_node("Actions/Confirm").disabled = _spent() <= 0 or _spent() > PlayerProgress.upgrade_points or _confirming

func _confirm() -> void:
	if _confirming: return
	_confirming = true
	if SaveManager.commit_attribute_allocation(_draft):
		_draft.clear()
		body.get_node("Status").text = "Attributes saved. Current HP/stamina retained."
	else:
		body.get_node("Status").text = SaveManager.last_error
	_confirming = false
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_campfire) and _campfire.has_method("is_ui_active") and _campfire.is_ui_active(): return
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
