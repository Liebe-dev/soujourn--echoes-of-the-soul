extends RefCounted
## Session-only skill switches; release builds always keep normal cooldowns.
static var cooldowns_enabled := true

static func are_cooldowns_enabled() -> bool:
	return not OS.is_debug_build() or cooldowns_enabled
