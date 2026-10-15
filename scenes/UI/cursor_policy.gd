class_name CursorPolicy
extends RefCounted
## Single path for gameplay/UI cursor transitions; no checkpoint data is involved.
static func set_visible(viewport: Viewport, visible: bool, center_on_show: bool = false) -> void:
	if not is_instance_valid(viewport): return
	var desired_mode := Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN
	var changed := Input.mouse_mode != desired_mode
	# Center before showing, and neutralize mouse look before returning to play.
	if changed or (visible and center_on_show): center(viewport)
	Input.set_mouse_mode(desired_mode)

static func center(viewport: Viewport) -> void:
	if not is_instance_valid(viewport): return
	var window := viewport.get_window()
	# Do not warp the OS pointer into an unfocused game over another application.
	if window != null and not window.has_focus(): return
	viewport.warp_mouse(viewport.get_visible_rect().get_center())
