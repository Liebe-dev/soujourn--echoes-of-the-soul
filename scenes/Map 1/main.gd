extends Node2D
#12
@onready var wobtear = $doggo
@onready var WorldEnvi = $WorldEnvironment
@onready var point_light = $CanvasLayer/PointLight2D
@onready var fade_in_overlay = $CanvasLayer/ColorOverLay
@onready var Godray = $GodRay/GodRay
@onready var Godray2 = $GodRay/GodRay2
@onready var Godray3 = $GodRay/GodRay3
@onready var Godray4 = $GodRay/GodRay4
@onready var ishmael = $Ishmael
@onready var slide_sound = $"Slide Sound"
@onready var vignette = $ScreenEffects/Vignette
@onready var blink_screen = $ScreenEffects/BlinkScreen
@onready var player = $CharacterBody2D
@onready var camera = $CharacterBody2D/Camera2D
@onready var ishmael_label = $Ishmael/SpeechBubble/Label
@onready var ishmael_bubble = $Ishmael/SpeechBubble

signal ishmael_dialogue_finished
var dialogue_lines: Array[String] = [
	"Bất ngờ thật",
	"Cậu thích nghi với cơ thể ấy tốt hơn ta tưởng",
	"Sao không thử vận động một chút nhỉ ?"
	]
var current_line_index: int = 0
var is_typing: bool = false
var is_dialogue_active: bool = false
var type_tween: Tween
var delay_tween: Tween
var is_locked: bool = false
var wobtear_start_x: float

func _on_area_2d_body_entered(body: Node2D) -> void:
	fade_in_overlay.modulate.a = 1.0
	Godray.modulate.a = 0
	Godray2.modulate.a = 0
	Godray3.modulate.a = 0
	Godray4.modulate.a = 0
	if body.name == "CharacterBody2D":
		Godray.modulate.a = 0.0
		var light_tween = create_tween()

		light_tween.set_parallel(true)

		light_tween.tween_property(point_light, "energy", 1.0, 1.5)
		light_tween.tween_property(fade_in_overlay, "modulate:a", 0.0, 3.0)
		light_tween.tween_property(Godray, "modulate:a", 1.0, 5.0)
		light_tween.tween_property(Godray2, "modulate:a", 1.0, 5.0)
		light_tween.tween_property(Godray3, "modulate:a", 1.0, 5.0)
		light_tween.tween_property(Godray4, "modulate:a", 1.0, 5.0)
		light_tween.tween_property(WorldEnvi.environment, "glow_intensity", 1, 2.0)
		light_tween.tween_property(slide_sound, "volume_db", -5, 6)

func _on_slide_sound_trigger_body_entered(body: Node2D) -> void:
	if body.name == "CharacterBody2D":
		if slide_sound.playing == false:
			slide_sound.play()

func _ready() -> void:
	player.can_move = false
	vignette.modulate.a = 0.0
	vignette.visible = true
	await _fade_in_from_opening()
	if SaveManager.pending_continue:
		await get_tree().process_frame
		SaveManager.apply_continue_state()
		return
	_begin_level_intro()

func _fade_in_from_opening() -> void:
	blink_screen.color = Color.BLACK
	blink_screen.modulate.a = 1.0
	blink_screen.show()
	var fade = create_tween()
	fade.tween_property(blink_screen, "modulate:a", 0.0, 1.0)
	await fade.finished
	blink_screen.hide()

func _begin_level_intro() -> void:
	var anim = player.get_node("AnimatedSprite2D")
	player.can_move = false
	var npc_anim = wobtear.get_node("AnimatedSprite2D")

	npc_anim.play("release")
	camera.zoom = Vector2(2.5, 2.5)
	anim.play("lay_up")
	anim.pause()
	anim.frame = 0
	await get_tree().create_timer(2.0).timeout

	vignette.modulate.a = 0.0
	var vig_tween = create_tween()
	vig_tween.tween_property(vignette, "modulate:a", 1, 2)

	npc_anim.play("walking")
	wobtear_start_x = wobtear.global_position.x

	var khoang_cach_lui = -320.0
	var vi_tri_dich = wobtear.global_position.x + khoang_cach_lui
	var move_tween = create_tween()
	move_tween.tween_property(wobtear, "global_position:x", vi_tri_dich, 7.0)
	move_tween.tween_callback(func(): npc_anim.play("idle"))

	anim.play("lay_up")
	await anim.animation_finished

	await get_tree().create_timer(3.0).timeout

	var camera_tween = create_tween()
	camera_tween.tween_property(camera, "zoom", Vector2(1.5, 1.5), 3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	anim.play("sit_up")
	await anim.animation_finished

	anim.play("idle")
	player.can_move = true

	await get_tree().create_timer(2.0).timeout
	ishmael.visible = true
	var ishmael_anim = ishmael.get_node("AnimatedSprite2D")

	ishmael_anim.play("Appear")
	await ishmael_anim.animation_finished

	ishmael_anim.play("Idle")

	bat_dau_thoai_ishmael()
	await self.ishmael_dialogue_finished

var fill_speed: float = 20.0
var decay_speed: float = 15.0
var qte_value: float = 0.0
var is_qte_running: bool = false
var qte_finished_permanently: bool = false

func _process(delta):
	if is_qte_running:
		qte_value -= decay_speed * delta

		if Input.is_action_just_pressed("ui_accept"):
			qte_value += fill_speed

		qte_value = clamp(qte_value, 0, 100)

		$QTEUI/qte/ProgressBar.value = qte_value

		if qte_value >= 100:
			finish_qte()

func _input(event: InputEvent) -> void:
	if is_dialogue_active:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			if is_typing:
				if type_tween:
					type_tween.kill()
				chay_xong_chu()
			else:
				chuyen_thoai_tiep_theo()

func start_qte() -> void:
	$CharacterBody2D.is_locked = true
	player.can_move = false
	var npc_anim = wobtear.get_node("AnimatedSprite2D")
	npc_anim.play("attack")

	await npc_anim.animation_finished

	wobtear.hide()

	is_qte_running = true
	qte_value = 20.0
	$QTEUI.show()

	var cam = $CharacterBody2D/Camera2D
	cam.make_current()

	$CharacterBody2D/AnimatedSprite2D.play("struggle")

	var tween2 = create_tween()
	tween2.tween_property(cam, "zoom", Vector2(2.5, 2.5), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func finish_qte():
	is_qte_running = false
	qte_finished_permanently = true

	$QTEUI.hide()
	$CharacterBody2D.is_locked = false

	var player_anim = $CharacterBody2D/AnimatedSprite2D

	player_anim.play("qte2")
	await player_anim.animation_finished

	if has_node("doggo/qte"):
		$doggo/qte.queue_free()

	if not player_anim.frame_changed.is_connected(_on_player_qte3_frame_changed):
		player_anim.frame_changed.connect(_on_player_qte3_frame_changed)

	player_anim.play("qte3")

func _on_qte_body_entered(body: Node2D) -> void:
	if body.name == "CharacterBody2D" and not is_qte_running and not qte_finished_permanently and not $CharacterBody2D.is_locked:
		start_qte()

func bat_dau_thoai_ishmael() -> void:
	is_dialogue_active = true
	current_line_index = 0
	ishmael_bubble.show()
	hien_thi_dong_thoai()

func hien_thi_dong_thoai() -> void:
	if current_line_index >= dialogue_lines.size():
		ket_thuc_thoai_ishmael()
		return
	if current_line_index == 2:
		doggo_quay_lai_tan_cong()
	is_typing = true
	ishmael_label.text = dialogue_lines[current_line_index]
	ishmael_label.visible_characters = 0

	var text_length = dialogue_lines[current_line_index].length()
	var typing_speed = 0.05

	if type_tween:
		type_tween.kill()
	type_tween = create_tween()
	type_tween.tween_property(ishmael_label, "visible_characters", text_length, text_length * typing_speed)
	type_tween.finished.connect(chay_xong_chu)

func chay_xong_chu() -> void:
	is_typing = false
	ishmael_label.visible_characters = -1

	if delay_tween:
		delay_tween.kill()
	delay_tween = create_tween()
	delay_tween.tween_interval(2.0)
	delay_tween.finished.connect(chuyen_thoai_tiep_theo)

func chuyen_thoai_tiep_theo() -> void:
	if delay_tween:
		delay_tween.kill()
	current_line_index += 1
	hien_thi_dong_thoai()

func ket_thuc_thoai_ishmael() -> void:
	is_dialogue_active = false
	ishmael_bubble.hide()
	ishmael_dialogue_finished.emit()

func doggo_quay_lai_tan_cong() -> void:
	var npc_anim = wobtear.get_node("AnimatedSprite2D")
	npc_anim.play("walking")

	var khoang_cach_tien_them = 200.0

	var vi_tri_tan_cong = wobtear_start_x

	if wobtear_start_x < wobtear.global_position.x:
		npc_anim.flip_h = true
		vi_tri_tan_cong = wobtear_start_x - khoang_cach_tien_them
	else:
		npc_anim.flip_h = false
		vi_tri_tan_cong = wobtear_start_x + khoang_cach_tien_them

	var return_tween = create_tween()
	return_tween.tween_property(wobtear, "global_position:x", vi_tri_tan_cong, 3.5)

	await return_tween.finished

	npc_anim.play("attack")

func _on_player_qte3_frame_changed() -> void:
	var player_anim = $CharacterBody2D/AnimatedSprite2D

	if player_anim.animation == "qte3" and player_anim.frame == 8:
		player_anim.frame_changed.disconnect(_on_player_qte3_frame_changed)

		hieu_ung_toi_man_hinh_va_doi_anim()

func hieu_ung_toi_man_hinh_va_doi_anim() -> void:
	blink_screen.color = Color.BLACK
	blink_screen.modulate.a = 0.0
	blink_screen.show()

	var fade_tween = create_tween()
	fade_tween.tween_property(blink_screen, "modulate:a", 1.0, 1.0)

	await fade_tween.finished
	wobtear.show()
	wobtear.get_node("AnimatedSprite2D").play("death")

	var player_anim = $CharacterBody2D/AnimatedSprite2D
	player_anim.flip_h = true
	player_anim.play("lay_up")
	player_anim.pause()
	player_anim.frame = 1
	var camera_tween = create_tween()
	camera_tween.tween_property(camera, "zoom", Vector2(1.5, 1.5), 0.5)
	await get_tree().create_timer(2.0).timeout
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(blink_screen, "modulate:a", 0.0, 1.0)

	await fade_in_tween.finished
	blink_screen.hide()
	dialogue_lines = [
		"Có hơi tàn bạo quá không ?",
	]
	ishmael.visible = true
	var ishmael_anim = ishmael.get_node("AnimatedSprite2D")
	ishmael_anim.play("Idle")

	bat_dau_thoai_ishmael()
	await self.ishmael_dialogue_finished

	player_anim.play("lay_up")
	await player_anim.animation_finished
	dialogue_lines = [
		"Cố xuống núi trước khi mặt trời lặn nhé, cơ thể cậu sắp không chịu nổi đâu."
	]

	bat_dau_thoai_ishmael()
	await self.ishmael_dialogue_finished
	player_anim.play("sit_up")
	await player_anim.animation_finished
	await get_tree().create_timer(1.0).timeout
	ishmael_anim.play_backwards("Appear")
	await ishmael_anim.animation_finished
	ishmael.hide()

	player_anim.play("idle")
	player.can_move = true
