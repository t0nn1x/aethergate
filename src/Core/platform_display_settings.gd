extends Node

## Applies platform-specific window defaults at startup.
## Keep iOS/mobile project display settings as-is, but allow desktop overrides.

const DESKTOP_FEATURES: PackedStringArray = ["windows", "macos", "linuxbsd"]

func _enter_tree() -> void:
	_apply_platform_window_defaults()
	call_deferred("_apply_platform_window_defaults")

func _apply_platform_window_defaults() -> void:
	var root_window := get_tree().root
	if not root_window:
		return

	if _is_desktop_platform():
		_apply_desktop_window_defaults(root_window)
		return


func _apply_desktop_window_defaults(root_window: Window) -> void:
	if OS.has_feature("windows"):
		_apply_windows_fullscreen_defaults(root_window)
		return

	# Other desktop platforms default to fullscreen.
	root_window.mode = Window.MODE_FULLSCREEN
	print(
		"[FIX][Display] desktop_fullscreen_applied platform=%s mode=%s screen=%d size=%s"
		% [OS.get_name(), root_window.mode, root_window.current_screen, DisplayServer.screen_get_size(root_window.current_screen)]
	)

func _apply_windows_fullscreen_defaults(window: Window) -> void:
	var screen: int = window.current_screen
	if screen < 0:
		screen = DisplayServer.window_get_current_screen()

	# Match the target monitor bounds first, then switch to fullscreen.
	window.position = DisplayServer.screen_get_position(screen)
	window.size = DisplayServer.screen_get_size(screen)
	window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN

	print(
		"[FIX][Display] windows_fullscreen_applied mode=%s screen=%d size=%s"
		% [window.mode, screen, DisplayServer.screen_get_size(screen)]
	)

func _is_desktop_platform() -> bool:
	for feature in DESKTOP_FEATURES:
		if OS.has_feature(feature):
			return true
	return false
