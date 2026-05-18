extends CanvasLayer

@onready var shake_overlay: ColorRect = $ShakeOverlay

var _shake_time := 0.0
var _shake_amount := 0.0
var _shake_active := false

func _ready() -> void:
	if shake_overlay:
		shake_overlay.visible = false

func _process(delta: float) -> void:
	if not _shake_active or shake_overlay == null:
		return
	_shake_time += delta
	_set_shader_shake(_shake_time, _shake_amount)
	_shake_amount = move_toward(_shake_amount, 0.0, delta * 2.8)
	if _shake_amount <= 0.02:
		_stop_shake()

func trigger_impact_shake(strength: float = 0.55) -> void:
	if shake_overlay == null:
		return
	_shake_time = 0.0
	_shake_amount = clampf(strength, 0.0, 1.0)
	_shake_active = true
	shake_overlay.visible = true
	_set_shader_shake(_shake_time, _shake_amount)

func _set_shader_shake(time: float, amount: float) -> void:
	var mat := shake_overlay.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("shake_time", time)
		mat.set_shader_parameter("shake_amount", amount)

func _stop_shake() -> void:
	_shake_active = false
	_shake_amount = 0.0
	if shake_overlay:
		shake_overlay.visible = false
		_set_shader_shake(0.0, 0.0)
