extends Node

## Applies platform-specific window defaults at startup.
## Keep iOS/mobile project display settings as-is, but allow desktop overrides.

const DESKTOP_FEATURES: PackedStringArray = ["windows", "macos", "linuxbsd"]
const DEFAULT_DESKTOP_CURSOR_PATH: String = "res://Assets/Cursors/28x28px/Cursor Default.png"
const DEFAULT_DESKTOP_CURSOR_HOTSPOT: Vector2 = Vector2(0.0, 0.0)
const DEFAULT_DESKTOP_CURSOR_CLICK_OFFSET: Vector2 = Vector2(1.0, 1.0)

var _desktop_cursor_texture: Texture2D
var _desktop_cursor_enabled: bool = false
var _desktop_cursor_pressed: bool = false
var _desktop_cursor_current_hotspot: Vector2 = Vector2(-1.0, -1.0)

func _enter_tree() -> void:
	_apply_platform_window_defaults()
	call_deferred("_apply_platform_window_defaults")

func _apply_platform_window_defaults() -> void:
	var root_window := get_tree().root
	if not root_window:
		return

	if _is_desktop_platform():
		_apply_desktop_window_defaults(root_window)
		_apply_desktop_cursor()
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


func _apply_desktop_cursor() -> void:
	if not ResourceLoader.exists(DEFAULT_DESKTOP_CURSOR_PATH, "Texture2D"):
		_desktop_cursor_enabled = false
		set_process_input(false)
		return

	_desktop_cursor_texture = load(DEFAULT_DESKTOP_CURSOR_PATH) as Texture2D
	if _desktop_cursor_texture == null:
		_desktop_cursor_enabled = false
		set_process_input(false)
		return

	_desktop_cursor_enabled = true
	_desktop_cursor_current_hotspot = Vector2(-1.0, -1.0)
	_set_cursor_pressed(false, true)
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not _desktop_cursor_enabled:
		return

	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event == null:
		return

	_set_cursor_pressed(_is_any_mouse_button_pressed())


func _is_any_mouse_button_pressed() -> bool:
	return (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_XBUTTON1)
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_XBUTTON2)
	)


func _set_cursor_pressed(is_pressed: bool, force: bool = false) -> void:
	if not _desktop_cursor_enabled:
		return
	if _desktop_cursor_pressed == is_pressed and not force:
		return

	_desktop_cursor_pressed = is_pressed
	_refresh_desktop_cursor(force)


func _refresh_desktop_cursor(force: bool = false) -> void:
	if _desktop_cursor_texture == null:
		return

	var hotspot: Vector2 = DEFAULT_DESKTOP_CURSOR_HOTSPOT
	if _desktop_cursor_pressed:
		hotspot += DEFAULT_DESKTOP_CURSOR_CLICK_OFFSET

	if not force and _desktop_cursor_current_hotspot == hotspot:
		return

	Input.set_custom_mouse_cursor(_desktop_cursor_texture, Input.CURSOR_ARROW, hotspot)
	_desktop_cursor_current_hotspot = hotspot
