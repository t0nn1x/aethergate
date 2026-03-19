@tool
class_name MainScreen
extends CanvasLayer

signal play_pressed()
signal quit_requested()

const MENU_BUTTON_TEXTURE_SIZE: Vector2 = Vector2(84.0, 23.0)

@export var play_button_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/MenuPadding/MenuVBox/PlayButton"
@export var language_button_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/MenuPadding/MenuVBox/LanguageButton"
@export var quit_button_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/MenuPadding/MenuVBox/QuitButton"
@export var menu_margin_path: NodePath = ^"Root/MenuMargin"
@export var menu_card_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard"
@export var menu_vbox_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/MenuPadding/MenuVBox"
@export var background_dimmer_path: NodePath = ^"Root/BackgroundDimmer"
@export var menu_panel_path: NodePath = ^"Root/MenuPanel"
@export var menu_strip_path: NodePath = ^"Root/MenuStrip"
@export var title_logo_path: NodePath = ^"Root/TitleLogo"
@export var title_label_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/MenuPadding/MenuVBox/TitleLabel"
@export var localization_service_path: NodePath = ^"/root/LocalizationService"
@export var title_text_key: StringName = &"ui.main.title"
@export var play_button_text_key: StringName = &"ui.main.play"
@export var language_button_text_key: StringName = &"ui.main.language"
@export var quit_button_text_key: StringName = &"ui.main.quit"
@export var auto_focus_play_button: bool = false
@export var audio_service_path: NodePath = ^"/root/MusicPlayer"
@export_file("*.mp3", "*.wav", "*.ogg") var hover_sound_path: String = "res://src/Ui/Assets/Sounds/UI_Button_Click_2.mp3"
@export_file("*.mp3", "*.wav", "*.ogg") var click_sound_path: String = "res://src/Ui/Assets/Sounds/UI_Button_Click_8.mp3"
@export_dir var menu_music_folder_path: String = ""
@export_range(-40.0, 12.0, 0.1) var hover_volume_db: float = -10.0
@export_range(-40.0, 12.0, 0.1) var click_volume_db: float = -3.0
@export_range(-40.0, 12.0, 0.1) var menu_music_volume_db: float = -14.0
@export var sfx_bus_name: String = "SFX"
@export var music_bus_name: String = "Music"
@export var editor_preview_viewport: Vector2 = Vector2(1920.0, 1080.0)

var _play_button: Button
var _language_button: Button
var _quit_button: Button
var _menu_margin: MarginContainer
var _menu_card: Control
var _menu_vbox: VBoxContainer
var _background_dimmer: ColorRect
var _menu_panel: NinePatchRect
var _menu_strip: Panel
var _title_logo: TextureRect
var _title_logo_base_y: float = 0.0
var _title_logo_float_tween: Tween
var _logo_intro_done: bool = false
var _title_label: Label
var _viewport: Viewport
var _is_mobile_layout_active: bool = false
var _music_player_service: Node
var _localization_service: Node
var _creator_overlay_mode: bool = false


func _ready() -> void:
	_viewport = get_viewport()
	_cache_nodes()
	_wire_viewport_resize()
	_apply_responsive_layout()
	_style_strip_and_buttons()
	if Engine.is_editor_hint():
		return
	if not is_in_group("ui_panels_block_movement"):
		add_to_group("ui_panels_block_movement")
	_setup_audio()
	_configure_touch_interactions()
	_configure_platform_specific_ui()
	_setup_localization()
	_connect_signals()
	_setup_focus_chain()
	_apply_menu_content_visibility()
	_log_background_dimmer_bounds()
	if auto_focus_play_button:
		call_deferred("_focus_play_button")
	else:
		call_deferred("_clear_button_focus")
	_log_button_sizes()
	_start_menu_music_if_needed()
	print("[MainScreen] menu_open")
	call_deferred("_play_logo_intro")


func show_menu() -> void:
	visible = true
	set_creator_overlay_mode(false)
	_apply_responsive_layout()
	_start_menu_music_if_needed()
	if auto_focus_play_button:
		call_deferred("_focus_play_button")
	else:
		call_deferred("_clear_button_focus")
	call_deferred("_play_logo_intro")
	print("[MainScreen] menu_shown")


func hide_menu() -> void:
	set_creator_overlay_mode(false)
	visible = false
	_stop_menu_music()
	print("[MainScreen] menu_closed")


func set_creator_overlay_mode(enabled: bool) -> void:
	if _creator_overlay_mode == enabled:
		return
	_creator_overlay_mode = enabled
	_apply_menu_content_visibility()
	print("[FIX][MainScreen] creator_overlay_mode=%s" % str(_creator_overlay_mode))


func _cache_nodes() -> void:
	_play_button = get_node_or_null(play_button_path) as Button
	_language_button = get_node_or_null(language_button_path) as Button
	_quit_button = get_node_or_null(quit_button_path) as Button
	_menu_margin = get_node_or_null(menu_margin_path) as MarginContainer
	_menu_card = get_node_or_null(menu_card_path) as Control
	_menu_vbox = get_node_or_null(menu_vbox_path) as VBoxContainer
	_background_dimmer = get_node_or_null(background_dimmer_path) as ColorRect
	_title_label = get_node_or_null(title_label_path) as Label
	_menu_panel = get_node_or_null(menu_panel_path) as NinePatchRect
	_menu_strip = get_node_or_null(menu_strip_path) as Panel
	_title_logo = get_node_or_null(title_logo_path) as TextureRect

	if Engine.is_editor_hint():
		return
	if _play_button == null:
		push_warning("MainScreen: Play button is missing.")
	if _language_button == null:
		push_warning("MainScreen: Language button is missing.")
	if _quit_button == null:
		push_warning("MainScreen: Quit button is missing.")
	if _menu_margin == null:
		push_warning("MainScreen: Menu margin container is missing.")
	if _menu_card == null:
		push_warning("MainScreen: Menu card is missing.")
	if _menu_vbox == null:
		push_warning("MainScreen: Menu VBox is missing.")
	if _background_dimmer == null:
		push_warning("MainScreen: Background dimmer is missing.")
	if _title_label == null:
		push_warning("MainScreen: Title label is missing.")
	if _title_logo == null:
		push_warning("MainScreen: Title logo is missing.")


func _apply_menu_content_visibility() -> void:
	if _menu_card == null:
		return
	_menu_card.visible = not _creator_overlay_mode


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
	if _language_button and not _language_button.pressed.is_connected(_on_language_pressed):
		_language_button.pressed.connect(_on_language_pressed)
	if _quit_button and not _quit_button.pressed.is_connected(_on_quit_pressed):
		_quit_button.pressed.connect(_on_quit_pressed)
	_wire_button_audio_signals()


func _wire_button_audio_signals() -> void:
	var buttons: Array = [_play_button, _language_button, _quit_button]
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
	_log_background_dimmer_bounds()


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
	_position_logo()
	_position_panel()
	_position_strip()


func _log_background_dimmer_bounds() -> void:
	if _background_dimmer == null:
		return
	var viewport_size: Vector2 = _resolve_viewport_size()
	var dimmer_rect: Rect2 = _background_dimmer.get_rect()
	print(
		"[FIX][MainScreenDimmer] viewport=%.0fx%.0f rect=%.1f,%.1f %.1fx%.1f offsets=%.1f,%.1f,%.1f,%.1f"
		% [
			viewport_size.x,
			viewport_size.y,
			dimmer_rect.position.x,
			dimmer_rect.position.y,
			dimmer_rect.size.x,
			dimmer_rect.size.y,
			_background_dimmer.offset_left,
			_background_dimmer.offset_top,
			_background_dimmer.offset_right,
			_background_dimmer.offset_bottom
		]
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
	_apply_button_target_size(_language_button, button_size)
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
	if Engine.is_editor_hint():
		if editor_preview_viewport.x > 0.0 and editor_preview_viewport.y > 0.0:
			return editor_preview_viewport
		return Vector2(1920.0, 1080.0)
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
	var interactive_buttons: Array = [_play_button, _language_button, _quit_button]
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
	var candidates: Array = [_play_button, _language_button, _quit_button]
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
	var buttons: Array = [_play_button, _language_button, _quit_button]
	for node: Variant in buttons:
		var button: Button = node as Button
		if button and button.has_focus():
			button.release_focus()


func _setup_localization() -> void:
	_localization_service = get_node_or_null(localization_service_path)
	if (
		_localization_service
		and _localization_service.has_signal("locale_changed")
		and not _localization_service.is_connected("locale_changed", Callable(self, "_on_locale_changed"))
	):
		_localization_service.connect("locale_changed", Callable(self, "_on_locale_changed"))
	_apply_localized_texts()


func _on_locale_changed(_locale: StringName) -> void:
	_apply_localized_texts()


func _translate_key(key: StringName) -> String:
	if _localization_service and _localization_service.has_method("translate_key"):
		return String(_localization_service.call("translate_key", key))
	return tr(String(key))


func _apply_localized_texts() -> void:
	if _title_label:
		_title_label.text = _translate_key(title_text_key)
	if _play_button:
		_play_button.text = _translate_key(play_button_text_key)
	if _quit_button:
		_quit_button.text = _translate_key(quit_button_text_key)
	_update_language_button_label()


func _update_language_button_label() -> void:
	if _language_button == null:
		return
	var locale_code: String = _resolve_current_locale_code()
	var localized_language_name: String = _resolve_localized_language_name(locale_code)
	_language_button.text = _translate_key(language_button_text_key) % [localized_language_name]


func _resolve_localized_language_name(locale_code: String) -> String:
	var normalized_code: String = locale_code.strip_edges().to_lower()
	if normalized_code.is_empty():
		normalized_code = "en"
	var key: String = "ui.common.language_name_%s" % normalized_code
	var translated: String = _translate_key(StringName(key))
	if translated == key:
		return normalized_code.to_upper()
	return translated


func _resolve_current_locale_code() -> String:
	if _localization_service and _localization_service.has_method("get_current_locale"):
		return String(_localization_service.call("get_current_locale")).strip_edges().to_lower()
	return String(TranslationServer.get_locale()).get_slice("_", 0).get_slice("-", 0).to_lower()


func _resolve_supported_locales() -> PackedStringArray:
	if _localization_service and _localization_service.has_method("get_supported_locales"):
		var locales_variant: Variant = _localization_service.call("get_supported_locales")
		if locales_variant is PackedStringArray:
			return locales_variant as PackedStringArray
	return PackedStringArray(["en", "uk"])


func _on_language_pressed() -> void:
	_play_click_sound()
	var supported_locales: PackedStringArray = _resolve_supported_locales()
	if supported_locales.is_empty():
		return
	var current_locale: String = _resolve_current_locale_code()
	var current_index: int = supported_locales.find(current_locale)
	if current_index < 0:
		current_index = 0
	var next_locale: String = supported_locales[(current_index + 1) % supported_locales.size()]
	print(
		"[FIX][Localization] language_button_pressed current=%s next=%s supported=%s"
		% [current_locale, next_locale, str(supported_locales)]
	)
	if _localization_service and _localization_service.has_method("set_locale"):
		_localization_service.call("set_locale", StringName(next_locale), true)
		return
	TranslationServer.set_locale(next_locale)
	_apply_localized_texts()


func _play_hover_sound() -> void:
	if _music_player_service:
		_music_player_service.play_ui_hover()


func _play_click_sound() -> void:
	if _music_player_service:
		_music_player_service.play_ui_click()


func _on_play_pressed() -> void:
	_play_click_sound()
	print("[MainScreen] play_pressed")
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


func _position_logo() -> void:
	if _title_logo == null or _title_logo.texture == null:
		return
	var vp_size: Vector2 = _resolve_viewport_size()
	var tex_size: Vector2 = _title_logo.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var max_logo_width: float = vp_size.x * 0.6
	var max_logo_height: float = vp_size.y * 0.42
	var logo_scale: float = minf(1.0, minf(max_logo_width / tex_size.x, max_logo_height / tex_size.y))
	var logo_w: float = tex_size.x * logo_scale
	var logo_h: float = tex_size.y * logo_scale
	_title_logo.size = Vector2(logo_w, logo_h)
	var logo_x: float = roundf((vp_size.x - logo_w) * 0.5)
	_title_logo_base_y = roundf(vp_size.y * 0.07)
	_title_logo.position = Vector2(logo_x, _title_logo_base_y)
	if _logo_intro_done and _title_logo_float_tween != null:
		_start_logo_float()


func _position_panel() -> void:
	if _menu_panel == null:
		return
	var vp_size: Vector2 = _resolve_viewport_size()
	var logo_bottom: float = _title_logo_base_y + (_title_logo.size.y if _title_logo != null else 0.0)
	var gap: float = 4.0
	var panel_top: float = logo_bottom + gap
	var panel_w: float = _title_logo.size.x if _title_logo != null else vp_size.x * 0.4
	var panel_x: float = roundf((vp_size.x - panel_w) * 0.5)
	var panel_bottom: float = roundf(vp_size.y * 0.88)
	_menu_panel.position = Vector2(panel_x, roundf(panel_top))
	_menu_panel.size = Vector2(panel_w, panel_bottom - panel_top)


func _position_strip() -> void:
	if _menu_strip == null:
		return
	var vp_size: Vector2 = _resolve_viewport_size()
	var logo_bottom: float = _title_logo_base_y + (_title_logo.size.y if _title_logo != null else 0.0)
	var strip_h: float = roundf(vp_size.y * 0.15)
	_menu_strip.offset_top = roundf(logo_bottom)
	_menu_strip.offset_bottom = roundf(logo_bottom + strip_h)


func _style_strip_and_buttons() -> void:
	if _menu_strip != null:
		var strip_style := StyleBoxFlat.new()
		strip_style.bg_color = Color(0.02, 0.05, 0.10, 0.72)
		strip_style.border_width_top = 1
		strip_style.border_width_bottom = 1
		strip_style.border_color = Color(0.25, 0.45, 0.75, 0.3)
		_menu_strip.add_theme_stylebox_override("panel", strip_style)
	var buttons: Array = [_play_button, _language_button, _quit_button]
	for btn_node: Variant in buttons:
		var btn := btn_node as Button
		if btn == null:
			continue
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.12, 0.18, 0.32, 0.0)
		normal.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("focus", normal)
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.14, 0.22, 0.42, 0.85)
		hover.set_corner_radius_all(6)
		hover.border_width_left = 1
		hover.border_width_right = 1
		hover.border_width_top = 1
		hover.border_width_bottom = 1
		hover.border_color = Color(0.85, 0.72, 0.28, 0.9)
		btn.add_theme_stylebox_override("hover", hover)
		var pressed := StyleBoxFlat.new()
		pressed.bg_color = Color(0.06, 0.10, 0.20, 0.92)
		pressed.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.65, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.70, 0.65, 0.40, 1.0))


func _play_logo_intro() -> void:
	if _title_logo == null:
		return
	_logo_intro_done = false
	if _title_logo_float_tween != null:
		_title_logo_float_tween.kill()
		_title_logo_float_tween = null
	_title_logo.modulate.a = 0.0
	_title_logo.position.y = _title_logo_base_y - 30.0
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_title_logo, "modulate:a", 1.0, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_title_logo, "position:y", _title_logo_base_y, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(func() -> void:
		_logo_intro_done = true
		_start_logo_float()
	)


func _start_logo_float() -> void:
	if _title_logo == null:
		return
	if _title_logo_float_tween != null:
		_title_logo_float_tween.kill()
	_title_logo_float_tween = create_tween()
	_title_logo_float_tween.set_loops()
	# Each leg is 1.25s so the full up-down cycle = 2.5s
	_title_logo_float_tween.tween_property(_title_logo, "position:y", _title_logo_base_y - 4.0, 1.25) \
		.from(_title_logo_base_y).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_title_logo_float_tween.tween_property(_title_logo, "position:y", _title_logo_base_y, 1.25) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
