extends MainScreen

const DESKTOP_TITLE_FONT_SIZE: int = 62
const DESKTOP_BUTTON_SCALE: float = 1.45
const DESKTOP_MIN_BUTTON_SIZE: Vector2 = Vector2(360.0, 102.0)
const DESKTOP_MAX_BUTTON_HEIGHT: float = 124.0
const DESKTOP_MAX_BUTTON_WIDTH_FACTOR: float = 0.38

@export var title_banner_texture_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/MenuPadding/MenuVBox/TitleBanner/BannerTexture"
@export var title_banner_offset: Vector2 = Vector2(0.0, -64.0)
@export var social_icons_row_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard/SocialIconsLayer/SocialIconsRow"
@export var social_icons_container_path: NodePath = ^"Root/MenuMargin/CenterContainer/MenuCard"
# social buttons x and y values
@export var social_icons_bottom_inset: float = -100.0
@export var social_icons_horizontal_offset: float = -25.0

var _title_banner_texture: TextureRect
var _social_icons_row: HBoxContainer
var _social_icons_container: Control


func _ready() -> void:
	super._ready()
	_title_banner_texture = get_node_or_null(title_banner_texture_path) as TextureRect
	_social_icons_row = get_node_or_null(social_icons_row_path) as HBoxContainer
	_social_icons_container = get_node_or_null(social_icons_container_path) as Control
	_apply_title_banner_transform()
	_apply_social_icons_transform()


func _apply_title_style(_viewport_size: Vector2, is_portrait: bool) -> void:
	if _title_label == null:
		return

	var title_size: int = DESKTOP_TITLE_FONT_SIZE
	if _is_mobile_layout_active:
		title_size = 52 if is_portrait else 48
	_title_label.add_theme_font_size_override("font_size", title_size)
	_title_label.add_theme_constant_override("outline_size", 2)


func _apply_button_sizes(viewport_size: Vector2, is_portrait: bool) -> void:
	super._apply_button_sizes(viewport_size, is_portrait)

	if _is_mobile_layout_active:
		return

	_scale_desktop_button(_play_button, viewport_size)
	_scale_desktop_button(_quit_button, viewport_size)


func _scale_desktop_button(button: Button, viewport_size: Vector2) -> void:
	if button == null:
		return

	var target_size: Vector2 = button.custom_minimum_size * DESKTOP_BUTTON_SCALE
	target_size.x = maxf(target_size.x, DESKTOP_MIN_BUTTON_SIZE.x)
	target_size.y = maxf(target_size.y, DESKTOP_MIN_BUTTON_SIZE.y)
	target_size.x = minf(target_size.x, viewport_size.x * DESKTOP_MAX_BUTTON_WIDTH_FACTOR)
	target_size.y = minf(target_size.y, DESKTOP_MAX_BUTTON_HEIGHT)
	_apply_button_target_size(button, target_size)


func _apply_responsive_layout() -> void:
	super._apply_responsive_layout()
	_apply_title_banner_transform()
	_apply_social_icons_transform()


func _apply_title_banner_transform() -> void:
	if _title_banner_texture == null:
		return
	var parent_control: Control = _title_banner_texture.get_parent_control()
	if parent_control == null:
		return

	var texture_size: Vector2 = _title_banner_texture.size
	var centered_x: float = (parent_control.size.x - texture_size.x) * 0.5
	_title_banner_texture.position = Vector2(
		round(centered_x + title_banner_offset.x),
		round(title_banner_offset.y)
	)


func _apply_social_icons_transform() -> void:
	if _social_icons_row == null or _social_icons_container == null:
		return

	var row_size: Vector2 = _social_icons_row.get_combined_minimum_size().round()
	_social_icons_row.size = row_size
	var row_x: float = (_social_icons_container.size.x - row_size.x) * 0.5 + social_icons_horizontal_offset
	var row_y: float = _social_icons_container.size.y - row_size.y - social_icons_bottom_inset
	_social_icons_row.position = Vector2(round(row_x), round(row_y))
