extends Control


@onready var lv_value: Label = $MainPanel/MarginContainer/HBoxContainer/LeftColumn/Stats/VBoxContainer/LV_EXP/lv_value
@onready var hp_value: Label = $"MainPanel/MarginContainer/HBoxContainer/LeftColumn/Stats/VBoxContainer/MainStatsGrid/hp value"
@onready var sp_value: Label = $MainPanel/MarginContainer/HBoxContainer/LeftColumn/Stats/VBoxContainer/MainStatsGrid/sp_value

# @onready var exp_label: Label = $"Đường/Dẫn/Tới/Label_EXP"
func _ready() -> void:
	# Cập nhật chỉ số ngay khi game vừa load xong
	update_character_stats()

func update_character_stats() -> void:
	# Đảm bảo Autoload PlayerProgress có tồn tại
	if PlayerProgress != null:
		
		# 1. Gắn Level vào lv_value
		if lv_value:
			lv_value.text = str(PlayerProgress.level)
			
		# 2. Gắn Máu vào hp_value (Định dạng: Máu hiện tại / Máu tối đa)
		if hp_value:
			hp_value.text = str(PlayerProgress.get_max_hp())
			
		# 3. Gắn Thể lực (Stamina/SP) vào sp_value
		if sp_value:
			sp_value.text = str(int(PlayerProgress.get_max_stamina()))
