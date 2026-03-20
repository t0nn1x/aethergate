@tool
class_name MainScreen
extends CanvasLayer

signal play_pressed()
signal quit_requested()

const MENU_BUTTON_TEXTURE_SIZE: Vector2 = Vector2(84.0, 23.0)
const FONT_SIZE_NORMAL: int = 36
const ScreenLocalization = preload("res://src/Ui/Common/ScreenLocalization/screen_localization.gd")
const UiSoundPlayer = preload("res://src/Ui/Common/UiSoundPlayer/ui_sound_player.gd")

@export var play_button_path: NodePath = ^"Root/MenuStrip/Center/ButtonRow/PlayButton"
@export var settings_button_path: NodePath = ^"Root/MenuStrip/Center/ButtonRow/SettingsButton"
@export var quit_button_path: NodePath = ^"Root/MenuStrip/Center/ButtonRow/QuitButton"
@export var main_buttons_path: NodePath = ^"Root/MenuStrip/Center/ButtonRow"
@export var settings_panel_path: NodePath = ^"Root/MenuStrip/Center/SettingsPanel"
@export var menu_strip_path: NodePath = ^"Root/MenuStrip"
@export var title_logo_path: NodePath = ^"Root/TitleLogo"
@export var play_button_text_key: StringName = &"ui.main.play"
@export var settings_button_text_key: StringName = &"ui.main.settings"
@export var quit_button_text_key: StringName = &"ui.main.quit"
@export var auto_focus_play_button: bool = true
@export_dir var menu_music_folder_path: String = ""
@export_range(-40.0, 12.0, 0.1) var menu_music_volume_db: float = -14.0
@export var music_bus_name: String = "Music"

var _play_button: Button
var _settings_button: Button
var _quit_button: Button
var _main_buttons_container: Control
var _settings_panel: Control
var _settings_language_button: Button
var _settings_sound_button: Button
var _settings_graphics_button: Button
var _settings_controls_button: Button
var _settings_back_button: Button
var _menu_strip: Panel
var _title_logo: TextureRect
var _logo_float_offset: float = 0.0
var _title_logo_intro_tween: Tween
var _title_logo_float_tween: Tween
var _strip_intro_tween: Tween
var _view_tween: Tween
var _logo_intro_done: bool = false
var _splash_intro_pending: bool = false
var _viewport: Viewport
var _is_mobile_layout_active: bool = false
var _music_service: Node
var _creator_overlay_mode: bool = false
var _button_group: MenuButtonGroup
var _settings_button_group: MenuButtonGroup
var _loc: ScreenLocalization
var _sfx: UiSoundPlayer


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
	_setup_localization()
	_setup_sfx()
	_setup_audio()
	_configure_touch_interactions()
	_configure_platform_specific_ui()
	_connect_signals()
	if auto_focus_play_button:
		call_deferred("_focus_play_button")
	else:
		call_deferred("_clear_button_focus")
	# Pre-hide elements now; animation fires once the splash screen signals completion.
	_pre_hide_intro_elements()
	_splash_intro_pending = true
	UIEvents.splash_completed.connect(_on_splash_completed, CONNECT_ONE_SHOT)


func show_menu() -> void:
	visible = true
	set_creator_overlay_mode(false)
	_apply_responsive_layout()
	_start_menu_music_if_needed()
	if auto_focus_play_button:
		call_deferred("_focus_play_button")
	else:
		call_deferred("_clear_button_focus")
	if not _splash_intro_pending:
		call_deferred("_play_logo_intro")


func hide_menu() -> void:
	set_creator_overlay_mode(false)
	visible = false
	_stop_menu_music()


func set_creator_overlay_mode(enabled: bool) -> void:
	_creator_overlay_mode = enabled


func _cache_nodes() -> void:
	_play_button = get_node_or_null(play_button_path) as Button
	_settings_button = get_node_or_null(settings_button_path) as Button
	_quit_button = get_node_or_null(quit_button_path) as Button
	_main_buttons_container = get_node_or_null(main_buttons_path) as Control
	_settings_panel = get_node_or_null(settings_panel_path) as Control
	_menu_strip = get_node_or_null(menu_strip_path) as Panel
	_title_logo = get_node_or_null(title_logo_path) as TextureRect
	if _settings_panel != null:
		_settings_language_button = _settings_panel.get_node_or_null(^"SettingsGrid/LanguageButton") as Button
		_settings_sound_button = _settings_panel.get_node_or_null(^"SettingsGrid/SoundButton") as Button
		_settings_graphics_button = _settings_panel.get_node_or_null(^"SettingsGrid/GraphicsButton") as Button
		_settings_controls_button = _settings_panel.get_node_or_null(^"SettingsGrid/ControlsButton") as Button
		_settings_back_button = _settings_panel.get_node_or_null(^"BackButton") as Button
	if Engine.is_editor_hint():
		return
	if _play_button == null:
		push_warning("MainScreen: Play button is missing.")
	if _settings_button == null:
		push_warning("MainScreen: Settings button is missing.")
	if _quit_button == null:
		push_warning("MainScreen: Quit button is missing.")
	if _title_logo == null:
		push_warning("MainScreen: Title logo is missing.")


func _setup_localization() -> void:
	_loc = ScreenLocalization.new()
	add_child(_loc)
	_loc.locale_updated.connect(func(_l: StringName) -> void: _apply_localized_texts())
	_apply_localized_texts()


func _setup_sfx() -> void:
	_sfx = UiSoundPlayer.new()
	add_child(_sfx)


func _setup_audio() -> void:
	_music_service = get_node_or_null(^"/root/MusicPlayer")
	if _music_service == null:
		push_warning("MainScreen: MusicPlayer service not found.")
		return
	_music_service.configure_menu_music_from_folder(
		menu_music_folder_path, menu_music_volume_db, music_bus_name, true
	)
	_music_service.play_menu_music(true)


func _start_menu_music_if_needed() -> void:
	if _music_service == null or not visible:
		return
	_music_service.play_menu_music(false)


func _stop_menu_music() -> void:
	if _music_service:
		_music_service.stop_music()


func _connect_signals() -> void:
	if _play_button and not _play_button.pressed.is_connected(_on_play_pressed):
		_play_button.pressed.connect(_on_play_pressed)
	if _settings_button and not _settings_button.pressed.is_connected(_on_settings_pressed):
		_settings_button.pressed.connect(_on_settings_pressed)
	if _quit_button and not _quit_button.pressed.is_connected(_on_quit_pressed):
		_quit_button.pressed.connect(_on_quit_pressed)
	if _settings_language_button and not _settings_language_button.pressed.is_connected(_on_settings_language_pressed):
		_settings_language_button.pressed.connect(_on_settings_language_pressed)
	if _settings_back_button and not _settings_back_button.pressed.is_connected(_on_settings_back_pressed):
		_settings_back_button.pressed.connect(_on_settings_back_pressed)

	_button_group = MenuButtonGroup.new()
	add_child(_button_group)
	_button_group.button_focused.connect(func(_b: Button) -> void: _sfx.play_hover())
	_button_group.setup([_play_button, _settings_button, _quit_button])

	_settings_button_group = MenuButtonGroup.new()
	add_child(_settings_button_group)
	_settings_button_group.button_focused.connect(func(_b: Button) -> void: _sfx.play_hover())
	_settings_button_group.setup_grid([
		[_settings_language_button, _settings_sound_button],
		[_settings_graphics_button, _settings_controls_button],
		[_settings_back_button],
	])


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
	_apply_button_target_size(_settings_button, button_size)
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
	var buttons: Array = [
		_play_button, _settings_button, _quit_button,
		_settings_language_button, _settings_sound_button,
		_settings_graphics_button, _settings_controls_button, _settings_back_button,
	]
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


func _can_programmatically_quit() -> bool:
	return OS.get_name() != "iOS"


func _focus_play_button() -> void:
	if _play_button and _play_button.visible:
		_play_button.grab_focus()


func _clear_button_focus() -> void:
	var buttons: Array = [_play_button, _settings_button, _quit_button]
	for node: Variant in buttons:
		var button: Button = node as Button
		if button and button.has_focus():
			button.release_focus()


func _apply_localized_texts() -> void:
	if _play_button:
		_play_button.text = _loc.translate(play_button_text_key)
	if _settings_button:
		_settings_button.text = _loc.translate(settings_button_text_key)
	if _quit_button:
		_quit_button.text = _loc.translate(quit_button_text_key)
	_update_settings_language_label()
	if _settings_sound_button:
		_settings_sound_button.text = _loc.translate(&"ui.settings.sound")
	if _settings_graphics_button:
		_settings_graphics_button.text = _loc.translate(&"ui.settings.graphics")
	if _settings_controls_button:
		_settings_controls_button.text = _loc.translate(&"ui.settings.controls")
	if _settings_back_button:
		_settings_back_button.text = _loc.translate(&"ui.settings.back")


func _update_settings_language_label() -> void:
	if _settings_language_button == null:
		return
	var locale_code: String = _loc.get_current_locale()
	var localized_name: String = _resolve_localized_language_name(locale_code)
	_settings_language_button.text = _loc.translate(&"ui.settings.language") % [localized_name]


func _resolve_localized_language_name(locale_code: String) -> String:
	var code: String = locale_code.strip_edges().to_lower()
	if code.is_empty():
		code = "en"
	var key: String = "ui.common.language_name_%s" % code
	var translated: String = _loc.translate(StringName(key))
	return translated if translated != key else code.to_upper()


func _on_settings_pressed() -> void:
	_sfx.play_click()
	_open_settings_view()


func _on_settings_back_pressed() -> void:
	_sfx.play_click()
	_close_settings_view()


func _on_settings_language_pressed() -> void:
	_sfx.play_click()
	_loc.set_next_locale()


func _open_settings_view() -> void:
	if _settings_panel == null or _main_buttons_container == null:
		return
	if _view_tween != null:
		_view_tween.kill()
	_settings_panel.visible = true
	_settings_panel.modulate.a = 0.0
	_view_tween = create_tween().set_parallel(true)
	_view_tween.tween_property(_main_buttons_container, "modulate:a", 0.0, 0.18) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_view_tween.tween_property(_settings_panel, "modulate:a", 1.0, 0.28) \
		.set_delay(0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_view_tween.chain().tween_callback(func() -> void:
		_main_buttons_container.visible = false
		if _settings_language_button:
			_settings_language_button.grab_focus()
	)


func _close_settings_view() -> void:
	if _settings_panel == null or _main_buttons_container == null:
		return
	if _view_tween != null:
		_view_tween.kill()
	_main_buttons_container.visible = true
	_main_buttons_container.modulate.a = 0.0
	_view_tween = create_tween().set_parallel(true)
	_view_tween.tween_property(_settings_panel, "modulate:a", 0.0, 0.18) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_view_tween.tween_property(_main_buttons_container, "modulate:a", 1.0, 0.28) \
		.set_delay(0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_view_tween.chain().tween_callback(func() -> void:
		_settings_panel.visible = false
		if _play_button:
			_play_button.grab_focus()
	)


func _on_play_pressed() -> void:
	_sfx.play_click()
	play_pressed.emit()


func _on_quit_pressed() -> void:
	if not _can_programmatically_quit():
		return
	_sfx.play_click()
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
	var buttons: Array = [
		_play_button, _settings_button, _quit_button,
		_settings_language_button, _settings_sound_button,
		_settings_graphics_button, _settings_controls_button, _settings_back_button,
	]
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
		btn.add_theme_font_size_override("font_size", FONT_SIZE_NORMAL)
		btn.add_theme_color_override("font_color", Color(0.92, 0.85, 0.62, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.78, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.65, 0.60, 0.38, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(1.0, 0.98, 0.78, 1.0))
	# Grid buttons expand to fill their column so both columns stay equal width.
	for btn: Button in [
		_settings_language_button, _settings_sound_button,
		_settings_graphics_button, _settings_controls_button,
	]:
		if btn != null:
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _on_splash_completed() -> void:
	_splash_intro_pending = false
	_play_logo_intro()


func _pre_hide_intro_elements() -> void:
	if _title_logo != null:
		_title_logo.modulate.a = 0.0
		_set_logo_float_offset(-40.0)
	if _menu_strip != null:
		_menu_strip.modulate.a = 0.0
		_set_strip_intro_offset(50.0)
	var buttons: Array = [_play_button, _settings_button, _quit_button]
	for node: Variant in buttons:
		var btn := node as Button
		if btn != null:
			btn.modulate.a = 0.0


func _play_logo_intro() -> void:
	if _title_logo == null:
		return
	_logo_intro_done = false
	if _title_logo_intro_tween != null:
		_title_logo_intro_tween.kill()
	if _title_logo_float_tween != null:
		_title_logo_float_tween.kill()
		_title_logo_float_tween = null
	if _strip_intro_tween != null:
		_strip_intro_tween.kill()

	_pre_hide_intro_elements()

	# Logo: fade in + rise up. Callback starts the looping float once done.
	_title_logo_intro_tween = create_tween().set_parallel(true)
	_title_logo_intro_tween.tween_property(_title_logo, "modulate:a", 1.0, 0.9) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_title_logo_intro_tween.tween_method(_set_logo_float_offset, -40.0, 0.0, 0.85) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_title_logo_intro_tween.chain().tween_callback(func() -> void:
		_logo_intro_done = true
		_start_logo_float()
	)

	# Strip + buttons on a separate tween so the logo float callback fires on time.
	var buttons: Array = [_play_button, _settings_button, _quit_button]
	_strip_intro_tween = create_tween().set_parallel(true)
	if _menu_strip != null:
		_strip_intro_tween.tween_property(_menu_strip, "modulate:a", 1.0, 0.7) \
			.set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		_strip_intro_tween.tween_method(_set_strip_intro_offset, 50.0, 0.0, 0.6) \
			.set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	for i: int in buttons.size():
		var btn := buttons[i] as Button
		if btn == null:
			continue
		_strip_intro_tween.tween_property(btn, "modulate:a", 1.0, 0.35) \
			.set_delay(0.5 + i * 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _set_strip_intro_offset(v: float) -> void:
	if _menu_strip == null:
		return
	_menu_strip.offset_top = v
	_menu_strip.offset_bottom = v


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
