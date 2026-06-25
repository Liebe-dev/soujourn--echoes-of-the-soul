extends CanvasLayer

@onready var transition_rect: ColorRect = $TransitionRect 
@onready var menu_bg: TextureRect = $TextureRect
@onready var main_panel: Control = $MainPanel

var is_menu_open: bool = false
var is_transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	menu_bg.hide()
	main_panel.hide()
	transition_rect.show()
	transition_rect.modulate.a = 0.0
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character_menu") or (is_menu_open and event.is_action_pressed("ui_cancel")):
		
		if is_transitioning:
			return
			
		get_viewport().set_input_as_handled()
		_toggle_menu()

func _toggle_menu() -> void:
	is_transitioning = true
	is_menu_open = !is_menu_open
	
	if is_menu_open:
		menu_bg.hide()
		main_panel.hide()
		transition_rect.modulate.a = 0.0
		
		get_tree().paused = true
		show()
		var tween_in = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_in.tween_property(transition_rect, "modulate:a", 1.0, 0.6)
		await tween_in.finished
		
		menu_bg.show()
		main_panel.show()
		var tween_out = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_out.tween_property(transition_rect, "modulate:a", 0.0, 0.3)
		await tween_out.finished
		
	else:
		var tween_in = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_in.tween_property(transition_rect, "modulate:a", 1.0, 0.3)
		await tween_in.finished
		
		menu_bg.hide()
		main_panel.hide()
		
		var tween_out = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_out.tween_property(transition_rect, "modulate:a", 0.0, 0.6)
		await tween_out.finished
		
		hide()
		get_tree().paused = false
		
	is_transitioning = false
