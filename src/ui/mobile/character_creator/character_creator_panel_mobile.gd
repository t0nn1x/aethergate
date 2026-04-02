class_name CharacterCreatorPanelMobile
extends CharacterCreatorPanel

const FONT_SIZE_MOBILE_BUTTON: int = 52
const FONT_SIZE_MOBILE_SECTION: int = 36
const FONT_SIZE_MOBILE_PRESET: int = 40
const FONT_SIZE_MOBILE_NAME: int = 42
const FONT_SIZE_MOBILE_DESCRIPTION: int = 32
const FONT_SIZE_MOBILE_TITLE: int = 46
const MOBILE_ACTION_BUTTON_MIN: Vector2 = Vector2(320, 96)
const MOBILE_PRESET_BUTTON_MIN: Vector2 = Vector2(0, 84)


func _ready() -> void:
	super._ready()
	_apply_mobile_layout()
	call_deferred("_refresh")


func _apply_style() -> void:
	super._apply_style()
	var font := load("res://Assets/Fonts/awesome/Awesome 9.ttf") as FontFile

	for btn: Button in [_confirm_button, _randomize_button, _cancel_button]:
		if btn == null:
			continue
		if font:
			btn.add_theme_font_size_override("font_size", FONT_SIZE_MOBILE_BUTTON)
		btn.custom_minimum_size = MOBILE_ACTION_BUTTON_MIN

	for label: Label in [_preset_section_label, _overworld_preview_title, _battle_preview_title, _details_section_label]:
		if label == null:
			continue
		if font:
			label.add_theme_font_size_override("font_size", FONT_SIZE_MOBILE_SECTION)

	if _preset_name_label != null and font:
		_preset_name_label.add_theme_font_size_override("font_size", FONT_SIZE_MOBILE_NAME)
	if _preset_description_label != null and font:
		_preset_description_label.add_theme_font_size_override("font_size", FONT_SIZE_MOBILE_DESCRIPTION)
	if _title_label != null and font:
		_title_label.add_theme_font_size_override("font_size", FONT_SIZE_MOBILE_TITLE)

	for button: Button in _preset_buttons:
		if button == null:
			continue
		if font:
			button.add_theme_font_size_override("font_size", FONT_SIZE_MOBILE_PRESET)
		button.custom_minimum_size = MOBILE_PRESET_BUTTON_MIN

	var title_banner := get_node_or_null(^"TitleBanner") as Control
	if title_banner != null:
		title_banner.offset_top = -118.0
		title_banner.offset_bottom = 20.0
	var banner_texture := get_node_or_null(^"TitleBanner/BannerTexture") as Control
	if banner_texture != null:
		banner_texture.custom_minimum_size = Vector2(560, 108)


func _apply_mobile_layout() -> void:
	if _content_layout != null:
		_content_layout.vertical = true
		_content_layout.add_theme_constant_override("separation", 16)
	if _actions_row != null:
		_actions_row.vertical = true
		_actions_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_actions_row.add_theme_constant_override("separation", 12)
	if _preview_stack != null:
		_preview_stack.add_theme_constant_override("separation", 14)
	if _preset_panel != null:
		_preset_panel.custom_minimum_size = Vector2(0, 320)
	if _preset_scroll != null:
		_preset_scroll.custom_minimum_size = Vector2(0, 260)
	if _overworld_preview_panel != null:
		_overworld_preview_panel.custom_minimum_size = Vector2(0, 220)
	if _battle_preview_panel != null:
		_battle_preview_panel.custom_minimum_size = Vector2(0, 244)


func _setup_button_group() -> void:
	super._setup_button_group()
	if _button_group != null:
		_button_group.font_size_normal = FONT_SIZE_MOBILE_BUTTON
		_button_group.font_size_hover = FONT_SIZE_MOBILE_BUTTON
