extends Control

signal closed

@onready var panel: PanelContainer = $Panel

var _campfire: Node = null

func _ready() -> void:
	hide()
	panel.hide()
	var hp_btn: Button = get_node_or_null("Panel/MarginContainer/VBox/Stats/HPRow/UpgradeButton")
	var stamina_btn: Button = get_node_or_null("Panel/MarginContainer/VBox/Stats/StaminaRow/UpgradeButton")
	var back_btn: Button = get_node_or_null("Panel/MarginContainer/VBox/BackButton")
	if hp_btn:
		hp_btn.pressed.connect(_on_hp_upgrade_pressed)
	if stamina_btn:
		stamina_btn.pressed.connect(_on_stamina_upgrade_pressed)
	if back_btn:
		back_btn.pressed.connect(close)

func open(campfire: Node = null) -> void:
	_campfire = campfire
	show()
	panel.show()
	_refresh()

func close() -> void:
	hide()
	panel.hide()
	closed.emit()

func _refresh() -> void:
	PlayerProgress.refresh_upgrade_menu_ui(self)

func _on_hp_upgrade_pressed() -> void:
	if PlayerProgress.try_upgrade_hp():
		_refresh()
		SaveManager.sync_progress_to_active_slot()

func _on_stamina_upgrade_pressed() -> void:
	if PlayerProgress.try_upgrade_stamina():
		_refresh()
		SaveManager.sync_progress_to_active_slot()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
