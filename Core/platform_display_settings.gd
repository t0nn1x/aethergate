extends Node

## Applies platform-specific window defaults at startup.
## Keep iOS/mobile project display settings as-is, but allow desktop overrides.

const DESKTOP_FEATURES: PackedStringArray = ["windows", "macos", "linuxbsd"]
const WINDOWS_DEFAULT_SIZE := Vector2i(1920, 1080)

func _enter_tree() -> void:
	_apply_platform_window_defaults()
	call_deferred("_apply_platform_window_defaults")

func _apply_platform_window_defaults() -> void:
	if not _is_desktop_platform():
		return

	var root_window := get_tree().root
	if not root_window:
		return

	if OS.has_feature("windows"):
		# Windows default: start windowed at Full HD.
		root_window.mode = Window.MODE_WINDOWED
		_apply_centered_window_size(root_window, WINDOWS_DEFAULT_SIZE)
		return

	# Other desktop platforms default to fullscreen.
	root_window.mode = Window.MODE_FULLSCREEN

func _apply_centered_window_size(window: Window, target_size: Vector2i) -> void:
	var screen := window.current_screen
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var clamped_size := Vector2i(
		min(target_size.x, usable_rect.size.x),
		min(target_size.y, usable_rect.size.y)
	)
	window.size = clamped_size
	window.position = usable_rect.position + Vector2i((usable_rect.size - clamped_size) / 2.0)

func _is_desktop_platform() -> bool:
	for feature in DESKTOP_FEATURES:
		if OS.has_feature(feature):
			return true
	return false
