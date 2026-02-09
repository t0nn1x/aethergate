class_name PixelPerfectViewportRoot
extends Node

## Renders the game world in a fixed-size SubViewport and scales the final
## output for smooth zoom transitions without camera fractional shimmer.

@onready var world_viewport_container: SubViewportContainer = $WorldViewportContainer
@onready var world_viewport: SubViewport = $WorldViewportContainer/WorldViewport

var _zoom_min: float = 1.0
var _zoom_max: float = 6.0
var _zoom: float = 1.0


func _ready() -> void:
	add_to_group("pixel_viewport_root")
	_configure_container()
	var window: Window = get_window()
	if window:
		window.size_changed.connect(_on_window_size_changed)
	_update_layout()


func set_world_zoom(value: float, zoom_min: float, zoom_max: float) -> float:
	_zoom_min = maxf(zoom_min, 0.01)
	_zoom_max = maxf(zoom_max, _zoom_min)
	_zoom = clampf(value, _zoom_min, _zoom_max)
	_update_layout()
	return _zoom


func get_world_zoom() -> float:
	return _zoom


func _configure_container() -> void:
	world_viewport_container.stretch = true
	world_viewport_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _on_window_size_changed() -> void:
	_update_layout()


func _update_layout() -> void:
	var window: Window = get_window()
	if not window:
		return

	var window_size: Vector2i = window.size
	if window_size.x <= 0 or window_size.y <= 0:
		return

	world_viewport_container.position = Vector2.ZERO
	world_viewport_container.size = Vector2(window_size)
	world_viewport_container.pivot_offset = world_viewport_container.size * 0.5

	# Zoom is driven by viewport resolution: larger zoom -> smaller render target.
	# The SubViewportContainer stretches this to screen.
	world_viewport.size = Vector2i(
		maxi(1, int(roundf(float(window_size.x) / maxf(_zoom, 0.01)))),
		maxi(1, int(roundf(float(window_size.y) / maxf(_zoom, 0.01))))
	)

	_apply_output_zoom()


func _apply_output_zoom() -> void:
	world_viewport_container.scale = Vector2.ONE

	# Filter by zoom granularity: crisp on integer zoom, smooth on fractional.
	var integer_scale: bool = absf(_zoom - roundf(_zoom)) < 0.001
	world_viewport_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if integer_scale else CanvasItem.TEXTURE_FILTER_LINEAR
