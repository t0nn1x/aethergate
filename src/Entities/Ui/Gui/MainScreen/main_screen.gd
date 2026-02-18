class_name MainScreen
extends CanvasLayer

signal play_pressed()
signal quit_requested()

const MENU_BUTTON_TEXTURE_SIZE: Vector2 = Vector2(84.0, 23.0)

@export var play_button_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/MenuPadding/MenuVBox/PlayButton"
@export var quit_button_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/MenuPadding/MenuVBox/QuitButton"
@export var menu_margin_path: NodePath = ^"Root/MenuMargin"
@export var menu_vbox_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/MenuPadding/MenuVBox"
@export var title_label_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/MenuPadding/MenuVBox/TitleLabel"
@export var auto_focus_play_button: bool = false
@export var audio_service_path: NodePath = ^"/root/MusicPlayer"
@export_file("*.mp3", "*.wav", "*.ogg") var hover_sound_path: String = "res://src/Entities/Ui/Assets/Sounds/UI_Button_Click_2.mp3"
@export_file("*.mp3", "*.wav", "*.ogg") var click_sound_path: String = "res://src/Entities/Ui/Assets/Sounds/UI_Button_Click_8.mp3"
@export_dir var menu_music_folder_path: String = ""
@export_range(-40.0, 12.0, 0.1) var hover_volume_db: float = -10.0
@export_range(-40.0, 12.0, 0.1) var click_volume_db: float = -3.0
@export_range(-40.0, 12.0, 0.1) var menu_music_volume_db: float = -14.0
@export var sfx_bus_name: String = "SFX"
@export var music_bus_name: String = "Music"

var _play_button: Button
var _quit_button: Button
var _menu_margin: MarginContainer
var _menu_vbox: VBoxContainer
var _title_label: Label
var _viewport: Viewport
var _is_mobile_layout_active: bool = false
var _music_player_service: Node


func _ready() -> void:
	_viewport = get_viewport()
	_cache_nodes()
	_setup_audio()
	_configure_touch_interactions()
	_configure_platform_specific_ui()
	_connect_signals()
	_setup_focus_chain()
	_wire_viewport_resize()
	_apply_responsive_layout()
	if auto_focus_play_button:
		call_deferred("_focus_play_button")
	else:
		call_deferred("_clear_button_focus")
	_log_button_sizes()
	_start_menu_music_if_needed()
	print("[MainScreen] menu_open")


func show_menu() -> void:
	visible = true
	_apply_responsive_layout()
	_start_menu_music_if_needed()
	if auto_focus_play_button:
		call_deferred("_focus_play_button")
	else:
		call_deferred("_clear_button_focus")
	print("[MainScreen] menu_shown")


func hide_menu() -> void:
	visible = false
	_stop_menu_music()
	print("[MainScreen] menu_closed")


func _cache_nodes() -> void:
	_play_button = get_node_or_null(play_button_path) as Button
	_quit_button = get_node_or_null(quit_button_path) as Button
	_menu_margin = get_node_or_null(menu_margin_path) as MarginContainer
	_menu_vbox = get_node_or_null(menu_vbox_path) as VBoxContainer
	_title_label = get_node_or_null(title_label_path) as Label

	if _play_button == null:
		push_warning("MainScreen: Play button is missing.")
	if _quit_button == null:
		push_warning("MainScreen: Quit button is missing.")
	if _menu_margin == null:
		push_warning("MainScreen: Menu margin container is missing.")
	if _menu_vbox == null:
		push_warning("MainScreen: Menu VBox is missing.")
	if _title_label == null:
		push_warning("MainScreen: Title label is missing.")


func _setup_audio() -> void:
	_music_player_service = get_node_or_null(audio_service_path)
	if _music_player_service == null:
		push_warning("MainScreen: MusicPlayer service not found at '%s'." % audio_service_path)
		return

	_music_player_service.configure_ui_sounds(
		hover_sound_path,
		hover_volume_db,
		click_sound_path,
		click_volume_db,
		sfx_bus_name
	)
	_music_player_service.configure_menu_music_from_folder(
		menu_music_folder_path,
		menu_music_volume_db,
		music_bus_name,
		true
	)
	_music_player_service.play_menu_music(true)


func _start_menu_music_if_needed() -> void:
	if _music_player_service == null or not visible:
		return
	_music_player_service.play_menu_music(false)


func _stop_menu_music() -> void:
	if _music_player_service:
		_music_player_service.stop_music()


func _connect_signals() -> void:
	if _play_button and not _play_button.pressed.is_connected(_on_play_pressed):
		_play_button.pressed.connect(_on_play_pressed)
	if _quit_button and not _quit_button.pressed.is_connected(_on_quit_pressed):
		_quit_button.pressed.connect(_on_quit_pressed)
	_wire_button_audio_signals()


func _wire_button_audio_signals() -> void:
	var buttons: Array = [_play_button, _quit_button]
	for node: Variant in buttons:
		var button: Button = node as Button
		if button == null:
			continue
		if not button.mouse_entered.is_connected(_on_button_hovered):
			button.mouse_entered.connect(_on_button_hovered)
		if not button.focus_entered.is_connected(_on_button_hovered):
			button.focus_entered.connect(_on_button_hovered)


func _on_button_hovered() -> void:
	_play_hover_sound()


func _setup_focus_chain() -> void:
	var menu_buttons: Array[Button] = _get_focusable_menu_buttons()
	if menu_buttons.is_empty():
		push_warning("MainScreen: focus chain setup skipped (no focusable menu buttons).")
		return

	var button_count: int = menu_buttons.size()
	for index in range(button_count):
		var current: Button = menu_buttons[index]
		var previous: Button = menu_buttons[(index - 1 + button_count) % button_count]
		var next: Button = menu_buttons[(index + 1) % button_count]
		current.focus_neighbor_top = previous.get_path()
		current.focus_neighbor_bottom = next.get_path()


func _wire_viewport_resize() -> void:
	if _viewport == null:
		return
	if not _viewport.size_changed.is_connected(_on_viewport_size_changed):
		_viewport.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = _resolve_viewport_size()
	var safe_rect: Rect2 = _resolve_safe_area(viewport_size)
	var safe_left: float = safe_rect.position.x
	var safe_top: float = safe_rect.position.y
	var safe_right: float = maxf(0.0, viewport_size.x - (safe_rect.position.x + safe_rect.size.x))
	var safe_bottom: float = maxf(0.0, viewport_size.y - (safe_rect.position.y + safe_rect.size.y))

	var aspect_ratio: float = viewport_size.x / maxf(viewport_size.y, 1.0)
	var is_portrait: bool = aspect_ratio <= 1.0
	_is_mobile_layout_active = _is_mobile_platform()

	var edge_margin: float = clampf(minf(viewport_size.x, viewport_size.y) * 0.04, 24.0, 96.0)
	_apply_menu_margin(edge_margin, safe_left, safe_top, safe_right, safe_bottom)
	_apply_title_style(viewport_size, is_portrait)
	_apply_menu_spacing(viewport_size, is_portrait)
	_apply_button_sizes(viewport_size, is_portrait)

	print(
		"[MainScreen] responsive_layout mobile=%s viewport=%.0fx%.0f safe=%.0f,%.0f,%.0f,%.0f"
		% [_is_mobile_layout_active, viewport_size.x, viewport_size.y, safe_left, safe_top, safe_right, safe_bottom]
	)


func _apply_menu_margin(edge: float, safe_left: float, safe_top: float, safe_right: float, safe_bottom: float) -> void:
	if _menu_margin == null:
		return
	_menu_margin.add_theme_constant_override("margin_left", int(edge + safe_left))
	_menu_margin.add_theme_constant_override("margin_top", int(edge + safe_top))
	_menu_margin.add_theme_constant_override("margin_right", int(edge + safe_right))
	_menu_margin.add_theme_constant_override("margin_bottom", int(edge + safe_bottom))


func _apply_title_style(viewport_size: Vector2, is_portrait: bool) -> void:
	if _title_label == null:
		return
	var title_size: int = 48
	if _is_mobile_layout_active:
		title_size = 44 if is_portrait else 40
	_title_label.add_theme_font_size_override("font_size", title_size)
	_title_label.add_theme_constant_override("outline_size", 1 if _is_mobile_layout_active else 2)


func _apply_menu_spacing(viewport_size: Vector2, is_portrait: bool) -> void:
	if _menu_vbox == null:
		return
	var separation: int
	if _is_mobile_layout_active and not is_portrait:
		separation = int(clampf(viewport_size.y * 0.02, 12.0, 22.0))
	else:
		separation = int(clampf(viewport_size.y * 0.015, 14.0, 30.0))
	_menu_vbox.add_theme_constant_override("separation", separation)


func _apply_button_sizes(viewport_size: Vector2, is_portrait: bool) -> void:
	var button_size: Vector2
	var button_aspect_ratio: float = _get_menu_button_aspect_ratio()

	if _is_mobile_layout_active:
		if is_portrait:
			var portrait_height: float = clampf(viewport_size.y * 0.06, 88.0, 124.0)
			button_size = _build_proportional_button_size(
				portrait_height,
				button_aspect_ratio,
				280.0,
				viewport_size.x * 0.72
			)

		else:
			var landscape_height: float = clampf(viewport_size.y * 0.085, 88.0, 112.0)
			button_size = _build_proportional_button_size(
				landscape_height,
				button_aspect_ratio,
				300.0,
				viewport_size.x * 0.42
			)

	else:
		var desktop_height: float = clampf(viewport_size.y * 0.068, 68.0, 96.0)
		button_size = _build_proportional_button_size(
			desktop_height,
			button_aspect_ratio,
			260.0,
			viewport_size.x * 0.26
		)

	_apply_button_target_size(_play_button, button_size)
	_apply_button_target_size(_quit_button, button_size)


func _apply_button_target_size(button: Button, size: Vector2) -> void:
	if button == null:
		return
	var min_touch_size: float = 88.0 if _is_mobile_layout_active else 56.0
	size.x = maxf(size.x, min_touch_size)
	size.y = maxf(size.y, min_touch_size)
	size = size.round()

	var nine_slice_button: NineSliceMenuButton = button as NineSliceMenuButton
	if nine_slice_button:
		nine_slice_button.button_size = size
	else:
		button.custom_minimum_size = size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _get_menu_button_aspect_ratio() -> float:
	if MENU_BUTTON_TEXTURE_SIZE.y <= 0.0:
		return 3.0
	return MENU_BUTTON_TEXTURE_SIZE.x / MENU_BUTTON_TEXTURE_SIZE.y


func _build_proportional_button_size(
	height: float,
	aspect_ratio: float,
	min_width: float,
	max_width: float
) -> Vector2:
	var target_height: float = maxf(height, 1.0)
	var unclamped_width: float = target_height * maxf(aspect_ratio, 1.0)
	var safe_max_width: float = maxf(min_width, max_width)
	var target_width: float = clampf(unclamped_width, min_width, safe_max_width)
	return Vector2(target_width, target_height)


func _resolve_viewport_size() -> Vector2:
	if _viewport:
		var rect_size: Vector2 = _viewport.get_visible_rect().size
		if rect_size.x > 0.0 and rect_size.y > 0.0:
			return rect_size
	return Vector2(1920.0, 1080.0)


func _resolve_safe_area(viewport_size: Vector2) -> Rect2:
	if not _is_mobile_platform():
		return Rect2(Vector2.ZERO, viewport_size)

	var safe_rect_i: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect_i.size.x <= 0 or safe_rect_i.size.y <= 0:
		return Rect2(Vector2.ZERO, viewport_size)

	var window_size: Vector2 = DisplayServer.window_get_size()
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Rect2(safe_rect_i.position, safe_rect_i.size)

	var scale: Vector2 = Vector2(
		viewport_size.x / window_size.x,
		viewport_size.y / window_size.y
	)
	var scaled_position: Vector2 = Vector2(
		safe_rect_i.position.x * scale.x,
		safe_rect_i.position.y * scale.y
	)
	var scaled_size: Vector2 = Vector2(
		safe_rect_i.size.x * scale.x,
		safe_rect_i.size.y * scale.y
	)
	scaled_position.x = clampf(scaled_position.x, 0.0, viewport_size.x)
	scaled_position.y = clampf(scaled_position.y, 0.0, viewport_size.y)
	scaled_size.x = clampf(scaled_size.x, 0.0, viewport_size.x - scaled_position.x)
	scaled_size.y = clampf(scaled_size.y, 0.0, viewport_size.y - scaled_position.y)
	return Rect2(scaled_position, scaled_size)


func _is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


func _configure_touch_interactions() -> void:
	var interactive_buttons: Array = [_play_button, _quit_button]
	for node: Variant in interactive_buttons:
		var button: Button = node as Button
		if button == null:
			continue
		button.focus_mode = Control.FOCUS_ALL
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		if not button.is_in_group("touch_interactive"):
			button.add_to_group("touch_interactive")


func _configure_platform_specific_ui() -> void:
	if _quit_button == null:
		return
	if not _can_programmatically_quit():
		_quit_button.visible = false
		_quit_button.disabled = true
		_quit_button.focus_mode = Control.FOCUS_NONE
		print("[FIX][Quit] hiding Quit button on iOS (programmatic quit unsupported).")


func _get_focusable_menu_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	var candidates: Array = [_play_button, _quit_button]
	for node: Variant in candidates:
		var button: Button = node as Button
		if button == null:
			continue
		if not button.visible or button.disabled:
			continue
		buttons.append(button)
	return buttons


func _can_programmatically_quit() -> bool:
	return OS.get_name() != "iOS"


func _focus_play_button() -> void:
	if _play_button and _play_button.visible:
		_play_button.grab_focus()


func _clear_button_focus() -> void:
	var buttons: Array = [_play_button, _quit_button]
	for node: Variant in buttons:
		var button: Button = node as Button
		if button and button.has_focus():
			button.release_focus()


func _play_hover_sound() -> void:
	if _music_player_service:
		_music_player_service.play_ui_hover()


func _play_click_sound() -> void:
	if _music_player_service:
		_music_player_service.play_ui_click()


func _on_play_pressed() -> void:
	_play_click_sound()
	print("[MainScreen] play_pressed")
	hide_menu()
	play_pressed.emit()


func _on_quit_pressed() -> void:
	if not _can_programmatically_quit():
		print("[FIX][Quit] ignoring quit request on iOS.")
		return
	_play_click_sound()
	print("[MainScreen] quit_requested")
	quit_requested.emit()
	call_deferred("_quit_application")


func _quit_application() -> void:
	get_tree().root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


func _log_button_sizes() -> void:
	if _play_button:
		print("[MainScreen] Play button size: %s" % _play_button.custom_minimum_size)
	if _quit_button:
		print("[MainScreen] Quit button size: %s" % _quit_button.custom_minimum_size)
