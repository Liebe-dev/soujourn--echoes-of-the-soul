extends PanelContainer
## Placeholder status slot — swap %Icon texture when art is ready.

@onready var _icon: ColorRect = %Icon
@onready var _level: Label = %LevelBadge

var effect_id: String = ""

func configure(p_effect_id: String, level: int, is_buff: bool) -> void:
	effect_id = p_effect_id
	visible = true
	_level.visible = level > 1
	_level.text = str(level) if level > 1 else ""
	_icon.color = _color_for(p_effect_id, is_buff)
	tooltip_text = _tooltip_for(p_effect_id, level)

func _color_for(id: String, is_buff: bool) -> Color:
	if is_buff:
		return Color(0.35, 0.75, 1.0, 0.95)
	match id:
		"bleeding":
			return Color(0.85, 0.12, 0.15, 0.95)
		"fracture":
			return Color(0.55, 0.5, 0.58, 0.95)
		_:
			return Color(0.5, 0.5, 0.55, 0.9)

func _tooltip_for(id: String, level: int) -> String:
	match id:
		"bleeding":
			if level >= 2:
				return "Bleeding II — heavy health drain. Flask removes bleeding and heals."
			return "Bleeding — health drain over time. Flask removes bleeding and heals."
		"fracture":
			return "Fracture Lv.%d — weaker offense, take more damage.%s Flask −1 level and heals." % [
				level,
				" Slow + slower attacks." if level >= 2 else "",
			]
		_:
			return id if level <= 1 else "%s (%d)" % [id, level]
