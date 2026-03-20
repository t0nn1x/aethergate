extends MainScreen

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
@export var patreon_url: String = ""
@export var discord_url: String = ""
@export var youtube_url: String = ""
@export var telegram_url: String = ""
@export var twitter_url: String = ""

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
	call_deferred("_apply_social_icons_transform")
	_connect_social_icon_links()


func _apply_button_sizes(viewport_size: Vector2, is_portrait: bool) -> void:
	super._apply_button_sizes(viewport_size, is_portrait)

	if _is_mobile_layout_active:
		return

	_scale_desktop_button(_play_button, viewport_size)
	_scale_desktop_button(_settings_button, viewport_size)
	_scale_desktop_button(_quit_button, viewport_size)


func _scale_desktop_button(button: Button, viewport_size: Vector2) -> void:
	if button == null:
		return

	var target_size: Vector2 = button.custom_minimum_size * _resolve_desktop_button_scale()
	target_size.x = maxf(target_size.x, DESKTOP_MIN_BUTTON_SIZE.x)
	target_size.y = maxf(target_size.y, DESKTOP_MIN_BUTTON_SIZE.y)
	target_size.x = minf(target_size.x, viewport_size.x * DESKTOP_MAX_BUTTON_WIDTH_FACTOR)
	target_size.y = minf(target_size.y, DESKTOP_MAX_BUTTON_HEIGHT)
	_apply_button_target_size(button, target_size)


func _resolve_desktop_button_scale() -> float:
	var visible_button_count: int = 0
	var candidates: Array = [_play_button, _settings_button, _quit_button]
	for node: Variant in candidates:
		var button: Button = node as Button
		if button == null:
			continue
		if not button.visible:
			continue
		visible_button_count += 1

	if visible_button_count >= 3:
		# Keep panel height close to previous 2-button layout while preserving equal button sizes.
		return DESKTOP_BUTTON_SCALE * (2.0 / 3.0)
	return DESKTOP_BUTTON_SCALE


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
	var fallback_size: Vector2 = _social_icons_row.custom_minimum_size.round()
	if row_size.x <= 0.0 or row_size.y <= 0.0:
		row_size = fallback_size
	else:
		row_size.x = maxf(row_size.x, fallback_size.x)
		row_size.y = maxf(row_size.y, fallback_size.y)
	_social_icons_row.size = row_size
	var row_x: float = (_social_icons_container.size.x - row_size.x) * 0.5 + social_icons_horizontal_offset
	var row_y: float = _social_icons_container.size.y - row_size.y - social_icons_bottom_inset
	_social_icons_row.position = Vector2(round(row_x), round(row_y))


func _connect_social_icon_links() -> void:
	if _social_icons_row == null:
		return

	_wire_social_icon("PatreonIcon", patreon_url)
	_wire_social_icon("DiscordIcon", discord_url)
	_wire_social_icon("YoutubeIcon", youtube_url)
	_wire_social_icon("TelegramIcon", telegram_url)
	_wire_social_icon("TwitterIcon", twitter_url)


func _wire_social_icon(icon_node_name: String, url: String) -> void:
	var icon: Control = _social_icons_row.get_node_or_null(NodePath(icon_node_name)) as Control
	if icon == null:
		return

	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var handler: Callable = Callable(self, "_on_social_icon_input").bind(url)
	if not icon.gui_input.is_connected(handler):
		icon.gui_input.connect(handler)


func _on_social_icon_input(event: InputEvent, url: String) -> void:
	if url.strip_edges().is_empty():
		return

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		_open_social_link(url)
		return

	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event != null and touch_event.pressed:
		_open_social_link(url)


func _open_social_link(url: String) -> void:
	var normalized_url: String = url.strip_edges()
	if normalized_url.is_empty():
		return
	var result: Error = OS.shell_open(normalized_url)
	if result != OK:
		push_warning("MainScreenMacOS: Failed to open social link '%s' (error %d)." % [normalized_url, int(result)])
