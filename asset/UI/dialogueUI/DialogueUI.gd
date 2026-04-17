extends CanvasLayer

@onready var name_label = $box/name
@onready var text_label = $box/text
@onready var choice_box = $box/choices
@onready var auto_button = $box/lon/auto
@onready var skip_button = $box/lon/skip

@onready var char_left = $char/left
@onready var char_center = $char/mid
@onready var char_right = $char/right

@onready var log_panel = $box/logPanel
@onready var log_list = $box/logPanel/ScrollContainer/LogList
@onready var log_button = $box/lon/log
@onready var log_scroll = $box/logPanel/ScrollContainer

var dialogue = []
var index = 0

var auto_mode = false
var skip_mode = false

var typing = false
var full_text = ""
var typing_speed = 0.03

func _ready():

	log_panel.visible = false
	log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	log_button.pressed.connect(toggle_log)

func toggle_log():

	log_panel.visible = !log_panel.visible

	if log_panel.visible:

		# dừng auto / skip
		auto_mode = false
		skip_mode = false

		auto_button.modulate = Color(1,1,1)
		skip_button.modulate = Color(1,1,1)

		# log sáng
		log_button.modulate = Color(0.6,0.8,1)

		# khóa các nút khác
		auto_button.disabled = true
		skip_button.disabled = true

	else:

		log_button.modulate = Color(1,1,1)

		# mở lại các nút
		auto_button.disabled = false
		skip_button.disabled = false
func start_dialogue(data):
	dialogue = data
	index = 0
	show_line()
func start_typing():

	typing = true
	text_label.text = ""

	for c in full_text:

		text_label.text += c
		await get_tree().create_timer(typing_speed).timeout

		if not typing:
			text_label.text = full_text
			return

	typing = false

func show_line():

	for c in choice_box.get_children():
		c.queue_free()

	if index >= dialogue.size():
		hide()
		return

	var line = dialogue[index]

	# Nếu có choice → dừng skip
	if line.has("choices"):
		skip_mode = false
		skip_button.modulate = Color(1,1,1)
	if line.has("sprite"):
		var s = line["sprite"]
		show_character(s.character, s.expression, s.position)

	name_label.text = line.get("name","")
	full_text = line.get("text","")
	start_typing()

	if line.has("choices"):
		for choice in line["choices"]:
			var b = Button.new()
			b.text = choice["text"]
			b.pressed.connect(func():
				index = choice["next"]
				show_line()
			)
			choice_box.add_child(b)

	if auto_mode:

	# đợi typing xong
		while typing:
			await get_tree().process_frame

	await get_tree().create_timer(2).timeout

	if auto_mode and index < dialogue.size():
		next_line()
	add_log(line)
func next_line():

	if not skip_mode and index >= dialogue.size():
		return

	index += 1
	show_line()

	if skip_mode and index < dialogue.size():

		var line = dialogue[index]

		if line.has("choices"):
			skip_mode = false
			skip_button.modulate = Color(1,1,1)
			return

		await get_tree().create_timer(0.05).timeout

		# nếu đã tắt skip thì dừng luôn
		if not skip_mode:
			return

		next_line()
func show_character(character, expression, position):

	var path = "res://characters/%s_%s.png" % [character, expression]
	var tex = load(path)

	if position == "left":
		char_left.texture = tex

	if position == "center":
		char_center.texture = tex

	if position == "right":
		char_right.texture = tex


func _input(event):

	if log_panel.visible:
		return

	if index >= dialogue.size():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

		var hovered = get_viewport().gui_get_hovered_control()

		if hovered and log_panel.is_ancestor_of(hovered):
			return

		var line = dialogue[index]

		if typing:
			typing = false
			return

		if not line.has("choices"):
			index += 1
			show_line()
func add_log(line):

	var label = Label.new()

	label.text = line.get("name","") + ": " + line.get("text","")

	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	log_list.add_child(label)

	await get_tree().process_frame
	log_scroll.scroll_vertical = log_scroll.get_v_scroll_bar().max_value


func _on_auto_pressed():

	auto_mode = !auto_mode

	if auto_mode:
		auto_button.modulate = Color(0.5,1,0.5)
	else:
		auto_button.modulate = Color(1,1,1)

func _on_skip_pressed():

	if index >= dialogue.size():
		return

	var line = dialogue[index]

	if line.has("choices"):
		return

	skip_mode = !skip_mode

	if skip_mode:
		skip_button.modulate = Color(0.5,1,0.5)
		next_line()
	else:
		skip_button.modulate = Color(1,1,1)

func _on_menu_pressed():

	get_tree().paused = true
	$PauseMenu.visible = true


func _on_resume_pressed():

	get_tree().paused = false
	$PauseMenu.visible = false
