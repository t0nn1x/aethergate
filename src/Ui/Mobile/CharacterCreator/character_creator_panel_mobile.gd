class_name CharacterCreatorPanelMobile
extends CharacterCreatorPanel

const FONT_SIZE_MOBILE_BUTTON: int = 52
const FONT_SIZE_MOBILE_LABEL: int = 46
const FONT_SIZE_MOBILE_TITLE: int = 46
const MOBILE_NAV_BUTTON_SIZE: float = 88.0
const MOBILE_ACTION_BUTTON_MIN: Vector2 = Vector2(260, 96)
const MOBILE_LABEL_MIN: Vector2 = Vector2(200, 72)


func _apply_style() -> void:
	super._apply_style()
	var font := load("res://Assets/Fonts/awesome/Awesome 9.ttf") as FontFile
	for btn: Button in [_confirm_button, _randomize_button, _cancel_button]:
		if btn == null:
			continue
		if font:
			btn.add_theme_font_size_override("font_size", FONT_SIZE_MOBILE_BUTTON)
		btn.custom_minimum_size = MOBILE_ACTION_BUTTON_MIN
	for btn: Button in [_head_prev, _head_next, _body_prev, _body_next, _legs_prev, _legs_next]:
		if btn == null:
			continue
		btn.custom_minimum_size = Vector2(MOBILE_NAV_BUTTON_SIZE, MOBILE_NAV_BUTTON_SIZE)
	for lbl: Label in [_head_label, _body_label, _legs_label]:
		if lbl == null:
			continue
		if font:
			lbl.add_theme_font_size_override("font_size", FONT_SIZE_MOBILE_LABEL)
		lbl.custom_minimum_size = MOBILE_LABEL_MIN
	if _title_label != null and font:
		_title_label.add_theme_font_size_override("font_size", FONT_SIZE_MOBILE_TITLE)
	var title_banner := get_node_or_null(^"TitleBanner") as Control
	if title_banner != null:
		title_banner.offset_top = -118.0
		title_banner.offset_bottom = 20.0
	var banner_texture := get_node_or_null(^"TitleBanner/BannerTexture") as Control
	if banner_texture != null:
		banner_texture.custom_minimum_size = Vector2(560, 108)


func _setup_button_group() -> void:
	super._setup_button_group()
	if _button_group != null:
		_button_group.font_size_normal = FONT_SIZE_MOBILE_BUTTON
		_button_group.font_size_hover = FONT_SIZE_MOBILE_BUTTON
