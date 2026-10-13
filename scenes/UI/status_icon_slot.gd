extends PanelContainer
## Status icon with an image for known debuffs and color fallback for other effects.
const BLEED_ICON: Texture2D = preload("res://asset/UI/Menu screen/Bleed.png")
const FRACTURE_ICON: Texture2D = preload("res://asset/UI/Menu screen/fracture.png")

const EFFECT_ICONS: Dictionary = {
	"fracture": FRACTURE_ICON,
	"absorbent": preload("res://asset/UI/Menu screen/absorbent.png"),
	"blessing": preload("res://asset/UI/Menu screen/blessing.png"),
	"camouflage": preload("res://asset/UI/Menu screen/camouflage.png"),
	"concussion": preload("res://asset/UI/Menu screen/concussion.png"),
	"drain": preload("res://asset/UI/Menu screen/drain.png"),
	"excitement": preload("res://asset/UI/Menu screen/excitement.png"),
	"overload": preload("res://asset/UI/Menu screen/overload.png"),
	"poison": preload("res://asset/UI/Menu screen/poison.png"),
	"regenerate": preload("res://asset/UI/Menu screen/regenerate.png"),
	"sharpness": preload("res://asset/UI/Menu screen/sharpness.png"),
	"sightless": preload("res://asset/UI/Menu screen/sightless.png"),
	"toughness": preload("res://asset/UI/Menu screen/toughness.png"),
	"feeling death": preload("res://asset/UI/Menu screen/feeling death.png"),
}

var _bleed_atlas: AtlasTexture

@onready var _icon: ColorRect = %Icon
@onready var _effect_image: TextureRect = %EffectImage
@onready var _level: Label = %LevelBadge

var effect_id: String = ""

func configure(p_effect_id: String, level: int, is_buff: bool) -> void:
	effect_id = p_effect_id
	visible = true
	_level.visible = level > 1
	_level.text = str(level) if level > 1 else ""
	var image: Texture2D = EFFECT_ICONS.get(p_effect_id)
	if p_effect_id == "bleeding":
		if _bleed_atlas == null:
			_bleed_atlas = AtlasTexture.new()
			_bleed_atlas.atlas = BLEED_ICON
			_bleed_atlas.region = Rect2(10, 9, 20, 20)
		image = _bleed_atlas
	_effect_image.texture = image
	_effect_image.visible = image != null
	_icon.color = Color.TRANSPARENT if image != null else _color_for(p_effect_id, is_buff)
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
