@tool
class_name MainScreen
extends CanvasLayer

signal play_pressed()
signal quit_requested()

const MENU_BUTTON_TEXTURE_SIZE: Vector2 = Vector2(84.0, 23.0)

@export var play_button_path: NodePath = ^"Root/MenuStrip/Center/ButtonRow/PlayButton"
@export var language_button_path: NodePath = ^"Root/MenuStrip/Center/ButtonRow/LanguageButton"
@export var quit_button_path: NodePath = ^"Root/MenuStrip/Center/ButtonRow/QuitButton"
@export var menu_strip_path: NodePath = ^"Root/MenuStrip"
@export var title_logo_path: NodePath = ^"Root/TitleLogo"
@export var localization_service_path: NodePath = ^"/root/LocalizationService"
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

var _play_button: Button
var _language_button: Button
var _quit_button: Button
var _menu_strip: Panel
var _title_logo: TextureRect
var _logo_float_offset: float = 0.0
var _title_logo_intro_tween: Tween
var _title_logo_float_tween: Tween
var _logo_intro_done: bool = false
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
	# Deferred pass ensures anchor-based sizes are fully settled after the first frame.
	call_deferred("_apply_responsive_layout")
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
	if auto_focus_play_button:
		call_deferred("_focus_play_button")
	else:
		call_deferred("_clear_button_focus")
	_start_menu_music_if_needed()
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


func hide_menu() -> void:
	set_creator_overlay_mode(false)
	visible = false
	_stop_menu_music()


func set_creator_overlay_mode(enabled: bool) -> void:
	_creator_overlay_mode = enabled


func _cache_nodes() -> void:
	_play_button = get_node_or_null(play_button_path) as Button
	_language_button = get_node_or_null(language_button_path) as Button
	_quit_button = get_node_or_null(quit_button_path) as Button
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
	if _title_logo == null:
		push_warning("MainScreen: Title logo is missing.")


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
	var root: Control = get_node_or_null(^"Root") as Control
	if root != null:
		if not root.resized.is_connected(_on_viewport_size_changed):
			root.resized.connect(_on_viewport_size_changed)
		return
	if _viewport == null:
		return
	if not _viewport.size_changed.is_connected(_on_viewport_size_changed):
		_viewport.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = _resolve_viewport_size()
	var aspect_ratio: float = viewport_size.x / maxf(viewport_size.y, 1.0)
	var is_portrait: bool = aspect_ratio <= 1.0
	_is_mobile_layout_active = _is_mobile_platform()
	_apply_button_sizes(viewport_size, is_portrait)


func _apply_button_sizes(viewport_size: Vector2, is_portrait: bool) -> void:
	var button_aspect_ratio: float = _get_menu_button_aspect_ratio()
	var button_size: Vector2
	if _is_mobile_layout_active:
		if is_portrait:
			var h: float = clampf(viewport_size.y * 0.06, 88.0, 124.0)
			button_size = _build_proportional_button_size(h, button_aspect_ratio, 280.0, viewport_size.x * 0.72)
		else:
			var h: float = clampf(viewport_size.y * 0.085, 88.0, 112.0)
			button_size = _build_proportional_button_size(h, button_aspect_ratio, 300.0, viewport_size.x * 0.42)
	else:
		var h: float = clampf(viewport_size.y * 0.068, 68.0, 96.0)
		button_size = _build_proportional_button_size(h, button_aspect_ratio, 260.0, viewport_size.x * 0.26)
	_apply_button_target_size(_play_button, button_size)
	_apply_button_target_size(_language_button, button_size)
	_apply_button_target_size(_quit_button, button_size)


func _apply_button_target_size(button: Button, size: Vector2) -> void:
	if button == null:
		return
	var min_touch: float = 88.0 if _is_mobile_layout_active else 56.0
	button.custom_minimum_size = Vector2(maxf(size.x, min_touch), maxf(size.y, min_touch)).round()
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _get_menu_button_aspect_ratio() -> float:
	if MENU_BUTTON_TEXTURE_SIZE.y <= 0.0:
		return 3.0
	return MENU_BUTTON_TEXTURE_SIZE.x / MENU_BUTTON_TEXTURE_SIZE.y


func _build_proportional_button_size(height: float, aspect_ratio: float, min_width: float, max_width: float) -> Vector2:
	var h: float = maxf(height, 1.0)
	var w: float = clampf(h * maxf(aspect_ratio, 1.0), min_width, maxf(min_width, max_width))
	return Vector2(w, h)


func _resolve_viewport_size() -> Vector2:
	var root: Control = get_node_or_null(^"Root") as Control
	if root != null:
		var s: Vector2 = root.size
		if s.x > 0.0 and s.y > 0.0:
			return s
	if _viewport:
		var s: Vector2 = _viewport.get_visible_rect().size
		if s.x > 0.0 and s.y > 0.0:
			return s
	return Vector2(1920.0, 1080.0)


func _is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


func _configure_touch_interactions() -> void:
	var buttons: Array = [_play_button, _language_button, _quit_button]
	for node: Variant in buttons:
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


func _get_focusable_menu_buttons() -> Array[Button]:
	var result: Array[Button] = []
	var candidates: Array = [_play_button, _language_button, _quit_button]
	for node: Variant in candidates:
		var button: Button = node as Button
		if button == null or not button.visible or button.disabled:
			continue
		result.append(button)
	return result


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
	if _localization_service and _localization_service.has_signal("locale_changed"):
		if not _localization_service.locale_changed.is_connected(_on_locale_changed):
			_localization_service.locale_changed.connect(_on_locale_changed)
	_apply_localized_texts()


func _on_locale_changed(_locale: StringName) -> void:
	_apply_localized_texts()


func _translate_key(key: StringName) -> String:
	if _localization_service:
		return _localization_service.translate_key(key)
	return tr(String(key))


func _apply_localized_texts() -> void:
	if _play_button:
		_play_button.text = _translate_key(play_button_text_key)
	if _quit_button:
		_quit_button.text = _translate_key(quit_button_text_key)
	_update_language_button_label()


func _update_language_button_label() -> void:
	if _language_button == null:
		return
	var locale_code: String = _resolve_current_locale_code()
	var localized_name: String = _resolve_localized_language_name(locale_code)
	_language_button.text = _translate_key(language_button_text_key) % [localized_name]


func _resolve_localized_language_name(locale_code: String) -> String:
	var code: String = locale_code.strip_edges().to_lower()
	if code.is_empty():
		code = "en"
	var key: String = "ui.common.language_name_%s" % code
	var translated: String = _translate_key(StringName(key))
	return translated if translated != key else code.to_upper()


func _resolve_current_locale_code() -> String:
	if _localization_service:
		return String(_localization_service.get_current_locale()).strip_edges().to_lower()
	return String(TranslationServer.get_locale()).get_slice("_", 0).get_slice("-", 0).to_lower()


func _resolve_supported_locales() -> PackedStringArray:
	if _localization_service:
		var locales: Variant = _localization_service.get_supported_locales()
		if locales is PackedStringArray:
			return locales
	return PackedStringArray(["en", "uk"])


func _on_language_pressed() -> void:
	_play_click_sound()
	var supported: PackedStringArray = _resolve_supported_locales()
	if supported.is_empty():
		return
	var current: String = _resolve_current_locale_code()
	var idx: int = supported.find(current)
	if idx < 0:
		idx = 0
	var next_locale: String = supported[(idx + 1) % supported.size()]
	if _localization_service:
		_localization_service.set_locale(StringName(next_locale), true)
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
	play_pressed.emit()


func _on_quit_pressed() -> void:
	if not _can_programmatically_quit():
		return
	_play_click_sound()
	quit_requested.emit()
	call_deferred("_quit_application")


func _quit_application() -> void:
	get_tree().root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


func _set_logo_float_offset(v: float) -> void:
	_logo_float_offset = v
	if _title_logo == null:
		return
	_title_logo.offset_top = v
	_title_logo.offset_bottom = v


func _style_strip_and_buttons() -> void:
	if _menu_strip != null:
		var strip_style := StyleBoxFlat.new()
		strip_style.bg_color = Color(0.02, 0.05, 0.10, 0.72)
		_menu_strip.add_theme_stylebox_override("panel", strip_style)
	var awesome_font: FontFile = load("res://Assets/Fonts/awesome/Awesome 9.ttf") as FontFile
	var empty_style := StyleBoxEmpty.new()
	var buttons: Array = [_play_button, _language_button, _quit_button]
	for btn_node: Variant in buttons:
		var btn := btn_node as Button
		if btn == null:
			continue
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_stylebox_override("hover", empty_style)
		btn.add_theme_stylebox_override("pressed", empty_style)
		btn.add_theme_stylebox_override("focus", empty_style)
		btn.add_theme_stylebox_override("disabled", empty_style)
		if awesome_font != null:
			btn.add_theme_font_override("font", awesome_font)
		btn.add_theme_font_size_override("font_size", 36)
		btn.add_theme_color_override("font_color", Color(0.92, 0.85, 0.62, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.78, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.65, 0.60, 0.38, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(0.92, 0.85, 0.62, 1.0))


func _play_logo_intro() -> void:
	if _title_logo == null:
		return
	_logo_intro_done = false
	if _title_logo_intro_tween != null:
		_title_logo_intro_tween.kill()
	if _title_logo_float_tween != null:
		_title_logo_float_tween.kill()
		_title_logo_float_tween = null
	_title_logo.modulate.a = 0.0
	_set_logo_float_offset(-30.0)
	_title_logo_intro_tween = create_tween()
	_title_logo_intro_tween.set_parallel(true)
	_title_logo_intro_tween.tween_property(_title_logo, "modulate:a", 1.0, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_title_logo_intro_tween.tween_method(_set_logo_float_offset, -30.0, 0.0, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_title_logo_intro_tween.chain().tween_callback(func() -> void:
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
	_title_logo_float_tween.tween_method(_set_logo_float_offset, 0.0, -4.0, 1.25) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_title_logo_float_tween.tween_method(_set_logo_float_offset, -4.0, 0.0, 1.25) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
