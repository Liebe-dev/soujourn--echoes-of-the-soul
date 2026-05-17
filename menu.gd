extends Node2D

@onready var press_start_label = $PressStartLabel
@onready var menu_buttons = $Control
@onready var fade_rect = $FadeRect
@onready var bgm_player = $BGMPlayer
@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound
@onready var start_sound = $StartSound
@onready var settings_menu = $SettingsMenu

var is_waiting_for_start = false
var blink_tween : Tween

var is_intro_playing = true
var bg_fade_tween : Tween
var text_fade_in_tween : Tween

func _ready():
	menu_buttons.hide()
	press_start_label.hide()
	for btn in menu_buttons.get_children():
		# Nếu node đó đúng là một nút bấm (Button)
		if btn is Button:
			# Bắt tín hiệu "chuột lia vào" và nối nó với hàm phát âm thanh
			btn.mouse_entered.connect(_on_button_hovered)
	for btn in menu_buttons.get_children():
		# Nếu node đó đúng là một nút bấm (Button)
		if btn is Button:
			# Bắt tín hiệu "chuột lia vào" và nối nó với hàm phát âm thanh
			btn.pressed.connect(_on_button_click)
	if fade_rect:
		fade_rect.modulate.a = 1.0
		fade_rect.show()
		bg_fade_tween = create_tween()
		bg_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, 1.8)
		await bg_fade_tween.finished
		
	if not is_intro_playing: return
	
	fade_rect.hide()
	
	press_start_label.modulate.a = 0.0 
	press_start_label.show()
	
	text_fade_in_tween = create_tween()
	text_fade_in_tween.tween_property(press_start_label, "modulate:a", 1.0, 1.0)
	await text_fade_in_tween.finished
	
	if not is_intro_playing: return
	
	start_blinking()
	is_waiting_for_start = true
	is_intro_playing = false 

func start_blinking():
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(press_start_label, "modulate:a", 0.0, 1.5)
	blink_tween.tween_property(press_start_label, "modulate:a", 1.0, 1.5)
func _input(event):
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		if is_intro_playing:
			is_intro_playing = false
			
			if bg_fade_tween: bg_fade_tween.kill()
			if text_fade_in_tween: text_fade_in_tween.kill()
			
			fade_rect.hide()
			press_start_label.show()
			press_start_label.modulate.a = 1.0
			
			start_blinking()
			
			set_deferred("is_waiting_for_start", true)
			return
			
		if is_waiting_for_start:
			is_waiting_for_start = false
			start_sound.play()
			if blink_tween:
				blink_tween.kill()
				
			var text_fade_out = create_tween()
			text_fade_out.tween_property(press_start_label, "modulate:a", 0.0, 0.5) 
			await text_fade_out.finished 
			
			press_start_label.hide()
			
			menu_buttons.modulate.a = 0.0 
			menu_buttons.show()
			
			var menu_fade_in = create_tween()
			menu_fade_in.tween_property(menu_buttons, "modulate:a", 1.0, 0.8)
func _on_start_pressed() -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	fade_rect.show() 
	
	var tween = create_tween()
	tween.set_parallel(true) 
	
	tween.tween_property($Control/Continue, "modulate:a", 0.0, 0.8)
	tween.tween_property($Control/Option, "modulate:a", 0.0, 0.8)
	tween.tween_property($Control/Quit, "modulate:a", 0.0, 0.8)
	
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.8)
	
	tween.tween_property(bgm_player, "volume_db", -50.0, 2)
	await tween.finished

	get_tree().change_scene_to_file("res://opening.tscn")
	
func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://continue")


func _on_option_pressed() -> void:
	settings_menu.visible = true

func _on_quit_pressed() -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	fade_rect.show() 
	
	var tween = create_tween()
	tween.set_parallel(true) 
	
	tween.tween_property($Control/Continue, "modulate:a", 0.0, 0.8)
	tween.tween_property($Control/Option, "modulate:a", 0.0, 0.8)
	tween.tween_property($Control/Start, "modulate:a", 0.0, 0.8)
	tween.tween_property(bgm_player, "volume_db", -50.0, 2)
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.2)
	
	await tween.finished
	get_tree().quit()
func _on_button_hovered():
	hover_sound.play()
	
func _on_button_click():
	click_sound.play()
