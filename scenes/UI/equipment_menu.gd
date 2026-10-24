extends Control

@onready var btn_weapon: Button = $MainSplit/Right_InventoryArea/TabButtons/weapon
@onready var btn_armor = $MainSplit/Right_InventoryArea/TabButtons/armor
@onready var btn_replica = $MainSplit/Right_InventoryArea/TabButtons/relica 


# Lấy đường dẫn các Lưới đồ (Grid)
@onready var grid_weapon = $MainSplit/Right_InventoryArea/GridArea/Grid_Weapons
@onready var grid_armor = $MainSplit/Right_InventoryArea/GridArea/Grid_Armor
@onready var grid_replica = $MainSplit/Right_InventoryArea/GridArea/Grid_Relica

func _ready() -> void:
	PlayerProgress.changed.connect(_refresh_weapon)
	visibility_changed.connect(_refresh_weapon)
	_on_btn_weapon_pressed()
	_refresh_weapon()

func _refresh_weapon() -> void:
	if not is_node_ready(): return
	var actor := get_tree().get_first_node_in_group("Player")
	if actor == null or actor.combat == null: return
	var item = actor.combat.equipped_weapon
	if item == null:
		$WeaponDetails.text = "No right-hand weapon. Left hand empty."
		return
	$WeaponDetails.text = "%s | Base %d > Attack %.2f\nProwess x%.2f | Strength x%.2f\n%s\nQ %s | Left hand empty" % [
		item.display_name, item.damage, item.damage * item.attack_multiplier(PlayerProgress.attributes, PlayerProgress.config),
		item.attribute_scaling.get(&"prowess", 0.0), item.attribute_scaling.get(&"strength", 0.0),
		item.requirement_text(PlayerProgress.attributes), "Ready" if item.meets_requirements(PlayerProgress.attributes) else "Locked: insufficient attributes"]
	$MainSplit/Left_DollArea/Slot_WeaponRight.tooltip_text = $WeaponDetails.text

# Hàm tiện ích để giấu tất cả các lưới đồ đi
# Nâng cấp hàm này để nó kiêm luôn việc reset màu của các nút
func hide_all_grids() -> void:
	# 1. Ẩn tất cả các lưới đồ
	grid_weapon.hide()
	grid_armor.hide()
	grid_replica.hide()
	
	# 2. Làm tối tất cả các nút (Màu xám)
	btn_weapon.modulate = Color(0.5, 0.5, 0.5) 
	btn_armor.modulate = Color(0.5, 0.5, 0.5)
	btn_replica.modulate = Color(0.5, 0.5, 0.5)

# --- CÁC HÀM BẤM NÚT ---

func _on_btn_weapon_pressed() -> void:
	hide_all_grids() # Giấu lưới và làm tối mọi nút
	grid_weapon.show() # Hiện lưới vũ khí
	btn_weapon.modulate = Color.WHITE # Thắp sáng nút Weapons

func _on_btn_armor_pressed() -> void:
	hide_all_grids()
	grid_armor.show()
	btn_armor.modulate = Color.WHITE # Thắp sáng nút Armor

func _on_btn_replica_pressed() -> void:
	hide_all_grids()
	grid_replica.show()
	btn_replica.modulate = Color.WHITE # Thắp sáng nút Replica
