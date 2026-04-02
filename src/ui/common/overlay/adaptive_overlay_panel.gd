class_name AdaptiveOverlayPanel
extends CanvasLayer

## Reusable base for full-screen overlays that need:
## - mobile safe-area handling
## - optional movement blocking registration
## - viewport resize lifecycle hook

@export var content_margin_path: NodePath
@export var block_world_movement: bool = true
@export var movement_block_group_name: StringName = &"ui_panels_block_movement"
@export var auto_wire_viewport_resize: bool = true

var _overlay_viewport: Viewport

signal overlay_viewport_resized(viewport_size: Vector2)


func _ready() -> void:
	_overlay_viewport = get_viewport()
	if block_world_movement and not is_in_group(movement_block_group_name):
		add_to_group(movement_block_group_name)
	_wire_viewport_resize()
	_on_overlay_viewport_resized()


func get_overlay_viewport() -> Viewport:
	if _overlay_viewport:
		return _overlay_viewport
	_overlay_viewport = get_viewport()
	return _overlay_viewport


func _wire_viewport_resize() -> void:
	if not auto_wire_viewport_resize:
		return
	var viewport: Viewport = get_overlay_viewport()
	if viewport == null:
		return
	if not viewport.size_changed.is_connected(_on_overlay_viewport_size_changed):
		viewport.size_changed.connect(_on_overlay_viewport_size_changed)


func _on_overlay_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_overlay_viewport_size()
	overlay_viewport_resized.emit(viewport_size)
	_on_overlay_viewport_resized()


func _on_overlay_viewport_resized() -> void:
	pass


func get_overlay_viewport_size() -> Vector2:
	var viewport: Viewport = get_overlay_viewport()
	if viewport:
		var visible_size: Vector2 = viewport.get_visible_rect().size
		if visible_size.x > 0.0 and visible_size.y > 0.0:
			return visible_size
	return Vector2(1920.0, 1080.0)


func is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


func resolve_overlay_safe_insets(viewport_size: Vector2) -> Dictionary:
	var safe_area: Rect2 = resolve_overlay_safe_area(viewport_size)
	var safe_left: float = safe_area.position.x
	var safe_top: float = safe_area.position.y
	var safe_right: float = maxf(0.0, viewport_size.x - (safe_area.position.x + safe_area.size.x))
	var safe_bottom: float = maxf(0.0, viewport_size.y - (safe_area.position.y + safe_area.size.y))
	return {
		"left": safe_left,
		"top": safe_top,
		"right": safe_right,
		"bottom": safe_bottom
	}


func resolve_overlay_safe_area(viewport_size: Vector2) -> Rect2:
	if not is_mobile_platform():
		return Rect2(Vector2.ZERO, viewport_size)

	var safe_rect_i: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect_i.size.x <= 0 or safe_rect_i.size.y <= 0:
		return Rect2(Vector2.ZERO, viewport_size)

	var window_size: Vector2 = DisplayServer.window_get_size()
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Rect2(safe_rect_i.position, safe_rect_i.size)

	var scale: Vector2 = Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	var scaled_position: Vector2 = Vector2(safe_rect_i.position.x * scale.x, safe_rect_i.position.y * scale.y)
	var scaled_size: Vector2 = Vector2(safe_rect_i.size.x * scale.x, safe_rect_i.size.y * scale.y)
	scaled_position.x = clampf(scaled_position.x, 0.0, viewport_size.x)
	scaled_position.y = clampf(scaled_position.y, 0.0, viewport_size.y)
	scaled_size.x = clampf(scaled_size.x, 0.0, viewport_size.x - scaled_position.x)
	scaled_size.y = clampf(scaled_size.y, 0.0, viewport_size.y - scaled_position.y)
	return Rect2(scaled_position, scaled_size)


func apply_overlay_margins(
	base_edge_margin: float,
	extra_left: float = 0.0,
	extra_top: float = 0.0,
	extra_right: float = 0.0,
	extra_bottom: float = 0.0
) -> void:
	var margin_container: MarginContainer = get_node_or_null(content_margin_path) as MarginContainer
	if margin_container == null:
		return

	var viewport_size: Vector2 = get_overlay_viewport_size()
	var safe_area: Rect2 = resolve_overlay_safe_area(viewport_size)
	var safe_left: float = safe_area.position.x
	var safe_top: float = safe_area.position.y
	var safe_right: float = maxf(0.0, viewport_size.x - (safe_area.position.x + safe_area.size.x))
	var safe_bottom: float = maxf(0.0, viewport_size.y - (safe_area.position.y + safe_area.size.y))

	margin_container.add_theme_constant_override("margin_left", int(round(base_edge_margin + safe_left + extra_left)))
	margin_container.add_theme_constant_override("margin_top", int(round(base_edge_margin + safe_top + extra_top)))
	margin_container.add_theme_constant_override("margin_right", int(round(base_edge_margin + safe_right + extra_right)))
	margin_container.add_theme_constant_override("margin_bottom", int(round(base_edge_margin + safe_bottom + extra_bottom)))
