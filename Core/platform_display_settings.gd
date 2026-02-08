extends Node

## Applies platform-specific window defaults at startup.
## Keep iOS/mobile project display settings as-is, but allow desktop overrides.

const DESKTOP_FEATURES: PackedStringArray = ["windows", "macos", "linuxbsd"]

func _ready() -> void:
	_apply_platform_window_defaults()

func _apply_platform_window_defaults() -> void:
	if not _is_desktop_platform():
		return

	var root_window := get_tree().root
	if not root_window:
		return

	# Desktop default: start in fullscreen.
	root_window.mode = Window.MODE_FULLSCREEN

func _is_desktop_platform() -> bool:
	for feature in DESKTOP_FEATURES:
		if OS.has_feature(feature):
			return true
	return false
