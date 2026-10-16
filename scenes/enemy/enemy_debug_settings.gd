extends RefCounted
## Session-only switches. Never saved to progression or enabled in release builds.
static var ai_disabled := false
static var immortal := false

static func is_ai_disabled() -> bool:
	return OS.is_debug_build() and ai_disabled

static func is_immortal() -> bool:
	return OS.is_debug_build() and immortal
