extends Control

@onready var tabs = [
	$topbar/TopBar/Character,
	$topbar/TopBar/Equipment,
	$topbar/TopBar/Arts,
	$topbar/TopBar/Inventory,
	$topbar/TopBar/Record,
	$topbar/TopBar/Map
]

# Các Scene nội dung con nằm dưới cùng (nhớ đổi tên cho chuẩn)
@onready var contents = [
	$CharacterMenu,
	$Equipment_menu,
	# Thêm các tab khác tương ứng
]

var current_tab_index: int = 0

func _ready() -> void:
	hide()
	for i in range(tabs.size()):
		var glow = tabs[i].get_node("GlowEffect")
		glow.modulate.a = 0.0 # Tàng hình quầng đỏ
		if i < contents.size() and contents[i] != null:
			contents[i].hide() # Riêng nội dung bự ở dưới thì vẫn dùng hide() được
			
	switch_tab(0)

func switch_tab(index: int) -> void:
	current_tab_index = index
	
	for i in range(tabs.size()):
		var tab_node = tabs[i]
		var glow = tab_node.get_node("GlowEffect")
		var label = tab_node.get_node("Label")
		
		if i == index:
			glow.modulate.a = 1.0
			label.add_theme_color_override("font_color", Color.WHITE)
			if i < contents.size() and contents[i] != null:
				var current_content = contents[i]
				current_content.show() # Hiện lên trước
				current_content.modulate.a = 0.0 # Ép nó tàng hình
				var tween = create_tween()
				tween.tween_property(current_content, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
				
		else:
			glow.modulate.a = 0.0
			if i < contents.size() and contents[i] != null:
				contents[i].hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_master_menu"):
		visible = !visible
		get_tree().paused = visible
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if event.is_action_pressed("ui_page_down"): # Nút E
		var next_tab = (current_tab_index + 1) % tabs.size()
		switch_tab(next_tab)
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("ui_page_up"): # Nút Q
		var prev_tab = (current_tab_index - 1 + tabs.size()) % tabs.size()
		switch_tab(prev_tab)
		get_viewport().set_input_as_handled()
