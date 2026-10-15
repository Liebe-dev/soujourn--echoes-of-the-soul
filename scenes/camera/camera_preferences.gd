extends RefCounted
## Separate from checkpoint/save-slot data.
const PATH := "user://camera_controls.cfg"

static func read_defaults(deadzone: float, reset_enabled: bool, reset_delay: float) -> Dictionary:
	var values := {"deadzone": deadzone, "reset_enabled": reset_enabled, "reset_delay": reset_delay}
	var config := ConfigFile.new()
	if config.load(PATH) != OK: return values
	var saved: Variant = config.get_value("camera", "deadzone", deadzone)
	if (saved is float or saved is int) and is_finite(float(saved)):
		values.deadzone = clampf(float(saved), 0.0, 0.9)
	saved = config.get_value("camera", "reset_enabled", reset_enabled)
	if saved is bool: values.reset_enabled = saved
	saved = config.get_value("camera", "reset_delay", reset_delay)
	if (saved is float or saved is int) and is_finite(float(saved)):
		values.reset_delay = clampf(float(saved), 0.5, 30.0)
	return values

static func store(deadzone: float, reset_enabled: bool, reset_delay: float) -> Error:
	var config := ConfigFile.new()
	config.set_value("camera", "deadzone", clampf(deadzone, 0.0, 0.9))
	config.set_value("camera", "reset_enabled", reset_enabled)
	config.set_value("camera", "reset_delay", clampf(reset_delay, 0.5, 30.0))
	return config.save(PATH)
