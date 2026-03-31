@tool
extends MainScreen

const FONT_SIZE_MOBILE: int = 64
const FONT_SIZE_MOBILE_HOVER: int = 64
const FONT_SIZE_MOBILE_LABEL: int = 60
const MOBILE_BUTTON_HEIGHT_SCALE: float = 1.6
const MOBILE_BUTTON_WIDTH_SCALE: float = 1.14
const MOBILE_MENU_STRIP_TOP: float = 0.44
const MOBILE_MENU_STRIP_BOTTOM: float = 0.735
const MOBILE_LOGO_LEFT: float = -0.04
const MOBILE_LOGO_RIGHT: float = 1.04
const MOBILE_LOGO_TOP: float = 0.207
const MOBILE_LOGO_BOTTOM: float = 0.433


func _configure_platform_specific_ui() -> void:
	super._configure_platform_specific_ui()
	if _settings_vsync_button != null:
		_settings_vsync_button.visible = false


func _connect_signals() -> void:
	super._connect_signals()
	_apply_mobile_button_group_font_sizes()


func _style_strip_and_buttons() -> void:
	super._style_strip_and_buttons()
	_apply_mobile_sizes()


func _apply_responsive_layout() -> void:
	super._apply_responsive_layout()
	_apply_mobile_chrome_layout()
	_apply_mobile_sizes()


func _apply_mobile_sizes() -> void:
	var viewport_size: Vector2 = _resolve_viewport_size()
	var h: float = clampf(viewport_size.y * 0.06 * MOBILE_BUTTON_HEIGHT_SCALE, 140.0, 198.0)
	var w: float = clampf(viewport_size.x * 0.72 * MOBILE_BUTTON_WIDTH_SCALE, 340.0, viewport_size.x * 0.88)
	var btn_size := Vector2(w, h).round()

	for btn: Variant in [
		_play_button, _settings_button, _quit_button,
		_settings_language_button, _settings_vsync_button, _settings_back_button,
	]:
		if not btn is Button:
			continue
		var b := btn as Button
		b.custom_minimum_size = btn_size
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", FONT_SIZE_MOBILE)
		b.add_theme_color_override("font_hover_color", b.get_theme_color("font_color"))
		b.add_theme_color_override("font_focus_color", b.get_theme_color("font_color"))

	for lbl: Variant in [_volume_label, _volume_value_label]:
		if lbl is Label:
			(lbl as Label).add_theme_font_size_override("font_size", FONT_SIZE_MOBILE_LABEL)
	if _volume_slider != null:
		var slider_width: float = clampf(viewport_size.x * 0.44, 220.0, viewport_size.x * 0.56)
		var slider_height: float = clampf(viewport_size.y * 0.03, 52.0, 72.0)
		_volume_slider.custom_minimum_size = Vector2(slider_width, slider_height).round()


func _apply_mobile_chrome_layout() -> void:
	if _menu_strip != null:
		_menu_strip.anchor_left = 0.0
		_menu_strip.anchor_right = 1.0
		_menu_strip.anchor_top = MOBILE_MENU_STRIP_TOP
		_menu_strip.anchor_bottom = MOBILE_MENU_STRIP_BOTTOM
	if _title_logo != null:
		_title_logo.anchor_left = MOBILE_LOGO_LEFT
		_title_logo.anchor_right = MOBILE_LOGO_RIGHT
		_title_logo.anchor_top = MOBILE_LOGO_TOP
		_title_logo.anchor_bottom = MOBILE_LOGO_BOTTOM


func _apply_mobile_button_group_font_sizes() -> void:
	for group_node: Variant in [_button_group, _settings_button_group]:
		var group := group_node as MenuButtonGroup
		if group == null:
			continue
		group.font_size_normal = FONT_SIZE_MOBILE
		group.font_size_hover = FONT_SIZE_MOBILE_HOVER
		group.hover_duration = 0.0
		group.exit_duration = 0.0
