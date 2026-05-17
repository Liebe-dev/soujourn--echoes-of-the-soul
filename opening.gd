extends Node

const LEVEL_SCENE := "res://main.tscn"

@onready var click_indicator = $Vignette/ClickIndicator
@onready var cutscene_image3 = $Vignette/cutscene3
@onready var subtitle = $Vignette/Subtitle
@onready var vignette = $Vignette/Vignette
@onready var blink_screen = $Vignette/BlinkScreen
@onready var cutscene_image1 = $Vignette/cutscene1
@onready var cutscene_image2 = $Vignette/cutscene2
@onready var blur_overlay = $Vignette/BlurOverlay

var is_cutscene_playing := true
var is_waiting_to_end_cutscene := false
var is_waiting_for_input := false
var is_waiting_for_image3_input := false
var indicator_tween: Tween
var blur_tween: Tween
var tween: Tween
var vignette_tween: Tween

func _ready() -> void:
	click_indicator.hide()
	blink_screen.color = Color.BLACK
	cutscene_image1.visible = true
	cutscene_image2.visible = false
	cutscene_image3.visible = false
	blink_screen.modulate.a = 1.0
	vignette.modulate.a = 0
	vignette.visible = true
	blink_screen.visible = true
	blur_overlay.modulate.a = 1.0
	blur_overlay.visible = true
	subtitle.hide()

	blur_tween = create_tween()
	blur_tween.tween_property(blur_overlay, "modulate:a", 0.0, 11.0)

	tween = create_tween()
	tween.tween_property(blink_screen, "modulate:a", 0.2, 4)
	tween.tween_callback(hien_thoai1)
	tween.tween_property(blink_screen, "modulate:a", 1.0, 2)

	tween.tween_property(blink_screen, "modulate:a", 0.1, 3)
	tween.tween_callback(hien_thoai2)
	tween.tween_property(blink_screen, "modulate:a", 1.0, 2)

	tween.tween_callback(bloodblink)
	tween.tween_property(blink_screen, "modulate:a", 0.0, 2)

	await tween.finished
	if not is_cutscene_playing:
		return

	blink_screen.hide()
	blur_overlay.hide()

	await get_tree().create_timer(2.0).timeout
	if not is_cutscene_playing:
		return

	is_waiting_for_image3_input = true

	click_indicator.show()
	indicator_tween = create_tween()
	indicator_tween.set_loops()
	indicator_tween.tween_property(click_indicator, "modulate:a", 0.0, 1)
	indicator_tween.tween_property(click_indicator, "modulate:a", 1.0, 1)

	vignette_tween = create_tween()
	vignette_tween.set_loops()
	vignette_tween.tween_property(vignette, "modulate:a", 0.4, 1.2)
	vignette_tween.tween_property(vignette, "modulate:a", 1.0, 1.2)

func bloodblink() -> void:
	blink_screen.color = Color.RED
	cutscene_image1.visible = false
	cutscene_image2.visible = true
	cutscene_image2.modulate.a = 1.0

	cutscene_image3.visible = false
	cutscene_image3.modulate.a = 0.0

func chuyen_canh() -> void:
	cutscene_image3.visible = true

	var crossfade_tween = create_tween()
	crossfade_tween.tween_property(cutscene_image3, "modulate:a", 1.0, 0.7)

	await crossfade_tween.finished
	if not is_cutscene_playing:
		return

	cutscene_image2.visible = false

	is_waiting_to_end_cutscene = true
	click_indicator.show()
	indicator_tween = create_tween()
	indicator_tween.set_loops()
	indicator_tween.tween_property(click_indicator, "modulate:a", 0.0, 1)
	indicator_tween.tween_property(click_indicator, "modulate:a", 1.0, 1)

func hien_thoai2() -> void:
	tween.pause()
	blur_tween.pause()
	subtitle.text = "Nóng nữa"
	subtitle.modulate.a = 0.0
	subtitle.show()
	var text_tween = create_tween()
	text_tween.tween_property(subtitle, "modulate:a", 1.0, 1)
	is_waiting_for_input = true

func hien_thoai1() -> void:
	tween.pause()
	blur_tween.pause()
	subtitle.text = "Lạnh quá"
	subtitle.modulate.a = 0.0
	subtitle.show()
	var text_tween = create_tween()
	text_tween.tween_property(subtitle, "modulate:a", 1.0, 1)
	is_waiting_for_input = true

func _input(event: InputEvent) -> void:
	if is_waiting_for_input:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			if subtitle.modulate.a < 1.0:
				subtitle.modulate.a = 1.0
			else:
				is_waiting_for_input = false
				var fade_out_tween = create_tween()
				fade_out_tween.tween_property(subtitle, "modulate:a", 0.0, 0.5)
				tween.play()
				blur_tween.play()

	if is_waiting_for_image3_input:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			is_waiting_for_image3_input = false
			click_indicator.hide()
			if indicator_tween:
				indicator_tween.kill()
			chuyen_canh()

	if is_waiting_to_end_cutscene:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			is_waiting_to_end_cutscene = false
			click_indicator.hide()
			if indicator_tween:
				indicator_tween.kill()
			_finish_opening()

func _finish_opening() -> void:
	is_cutscene_playing = false

	var end_tween = create_tween()
	end_tween.tween_property(cutscene_image3, "modulate:a", 0.0, 0.5)

	await end_tween.finished
	cutscene_image3.hide()

	blink_screen.color = Color.BLACK
	blink_screen.modulate.a = 0.0
	blink_screen.show()

	var fade_tween = create_tween()
	fade_tween.tween_property(blink_screen, "modulate:a", 1.0, 0.8)
	await fade_tween.finished

	get_tree().change_scene_to_file(LEVEL_SCENE)

func skip_cutscene() -> void:
	is_cutscene_playing = false

	if tween:
		tween.kill()
	if blur_tween:
		blur_tween.kill()
	if indicator_tween:
		indicator_tween.kill()

	is_waiting_for_input = false
	is_waiting_for_image3_input = false
	is_waiting_to_end_cutscene = false

	blink_screen.hide()
	blur_overlay.hide()
	cutscene_image1.hide()
	cutscene_image2.hide()
	cutscene_image3.hide()
	subtitle.hide()
	click_indicator.hide()

	get_tree().change_scene_to_file(LEVEL_SCENE)
