@tool
class_name OverworldChunk
extends Node2D

const PREVIEW_ROOT_NAME := "_PreviewNeighbors"
const PREVIEW_Z_INDEX := 100
const MIN_ENFORCE_INTERVAL := 0.1
const DEFAULT_PREVIEW_RADIUS := 2

@export var chunk_coord: Vector2i = Vector2i.ZERO: set = _set_chunk_coord
@export var chunk_size_tiles: int = 48: set = _set_chunk_size_tiles
@export var tile_size: Vector2i = Vector2i(48, 48): set = _set_tile_size
@export_dir var chunk_scene_dir: String = "res://Map/Overworld/Chunks/Midra": set = _set_chunk_scene_dir
@export var show_bounds: bool = true: set = _set_show_bounds
@export var bounds_color: Color = Color(0.2, 0.7, 1.0, 0.6): set = _set_bounds_color
@export var bounds_fill_color: Color = Color(0.2, 0.7, 1.0, 0.08): set = _set_bounds_fill_color
@export var bounds_line_width: float = 2.0: set = _set_bounds_line_width
@export var enforce_interval_seconds: float = 0.5

@export var preview_neighbors: bool = false: set = _set_preview_neighbors
@export var preview_radius: int = DEFAULT_PREVIEW_RADIUS: set = _set_preview_radius
@export var enforce_bounds_in_editor: bool = false: set = _set_enforce_bounds_in_editor
@export var cleanup_out_of_bounds: bool = false: set = _set_cleanup_out_of_bounds

var _preview_root: Node2D = null
var _enforce_timer: float = 0.0
var _is_preview_instance: bool = false
var _preview_origin_coord: Vector2i = Vector2i.ZERO

func _ready() -> void:
	if Engine.is_editor_hint() and not _is_preview_instance:
		preview_neighbors = false
	_on_geometry_changed()
	if Engine.is_editor_hint():
		_refresh_preview()

func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE and preview_neighbors:
		preview_neighbors = false

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if not enforce_bounds_in_editor:
		return
	_enforce_timer -= delta
	if _enforce_timer <= 0.0:
		_enforce_timer = max(enforce_interval_seconds, MIN_ENFORCE_INTERVAL)
		_enforce_bounds()

func _set_chunk_coord(value: Vector2i) -> void:
	if chunk_coord == value:
		return
	chunk_coord = value
	_on_geometry_changed()

func _set_chunk_scene_dir(value: String) -> void:
	chunk_scene_dir = _normalize_dir(value)
	if Engine.is_editor_hint():
		_refresh_preview()

func _set_preview_neighbors(value: bool) -> void:
	if preview_neighbors == value:
		return
	preview_neighbors = value
	if Engine.is_editor_hint():
		_refresh_preview()

func _set_preview_radius(value: int) -> void:
	var sanitized = max(value, 1)
	if preview_radius == sanitized:
		return
	preview_radius = sanitized
	if Engine.is_editor_hint():
		_refresh_preview()

func _set_chunk_size_tiles(value: int) -> void:
	var sanitized = _coerce_chunk_size(value)
	if chunk_size_tiles == sanitized:
		return
	chunk_size_tiles = sanitized
	_on_geometry_changed()

func _set_tile_size(value: Vector2i) -> void:
	var sanitized = _coerce_tile_size(value)
	if tile_size == sanitized:
		return
	tile_size = sanitized
	_on_geometry_changed()

func _set_show_bounds(value: bool) -> void:
	show_bounds = value
	_update_bounds()

func _set_bounds_color(value: Color) -> void:
	bounds_color = value
	_update_bounds()

func _set_bounds_fill_color(value: Color) -> void:
	bounds_fill_color = value
	_update_bounds()

func _set_bounds_line_width(value: float) -> void:
	bounds_line_width = max(value, 0.0)
	_update_bounds()

func _set_enforce_bounds_in_editor(value: bool) -> void:
	enforce_bounds_in_editor = value
	if enforce_bounds_in_editor:
		_enforce_timer = 0.0
		_enforce_bounds()

func _set_cleanup_out_of_bounds(value: bool) -> void:
	cleanup_out_of_bounds = value
	if cleanup_out_of_bounds:
		_enforce_bounds()
		cleanup_out_of_bounds = false
		notify_property_list_changed()

func _on_geometry_changed() -> void:
	_update_position()
	_update_bounds()
	if Engine.is_editor_hint():
		_refresh_preview()

func _update_position() -> void:
	if _is_preview_instance:
		position = _preview_offset()
		return
	position = Vector2(
		chunk_coord.x * chunk_size_tiles * tile_size.x,
		-chunk_coord.y * chunk_size_tiles * tile_size.y
	)

func _update_bounds() -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if not show_bounds or not Engine.is_editor_hint():
		return
	var size = _chunk_pixel_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if bounds_fill_color.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), bounds_fill_color, true)
	var line_width = bounds_line_width if bounds_line_width > 0.0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), bounds_color, false, line_width)

func _chunk_pixel_size() -> Vector2:
	return Vector2(
		chunk_size_tiles * tile_size.x,
		chunk_size_tiles * tile_size.y
	)

func _enforce_bounds() -> void:
	var max_x = max(chunk_size_tiles, 1)
	var max_y = max(chunk_size_tiles, 1)
	for child in get_children():
		if child is TileMapLayer:
			var layer: TileMapLayer = child
			var used_cells = layer.get_used_cells()
			for cell in used_cells:
				if cell.x < 0 or cell.y < 0 or cell.x >= max_x or cell.y >= max_y:
					layer.erase_cell(cell)

func _refresh_preview() -> void:
	if not Engine.is_editor_hint():
		return
	_clear_preview()
	if not preview_neighbors:
		return
	_preview_root = Node2D.new()
	_preview_root.name = PREVIEW_ROOT_NAME
	_preview_root.z_index = PREVIEW_Z_INDEX
	_preview_root.owner = null
	add_child(_preview_root)
	var loaded_count = 0
	for offset in _preview_offsets(preview_radius):
		var coord = chunk_coord + offset
		var path = chunk_scene_dir.path_join("chunk_%d_%d.tscn" % [coord.x, coord.y])
		var scene = load(path)
		if not scene:
			continue
		var instance = scene.instantiate()
		if instance is OverworldChunk:
			_configure_preview_chunk(instance, coord)
		instance.name = "_Preview_%d_%d" % [coord.x, coord.y]
		instance.owner = null
		_preview_root.add_child(instance)
		loaded_count += 1
	if loaded_count == 0:
		push_warning("Preview neighbors: no scenes found for %s in %s" % [chunk_coord, chunk_scene_dir])

func _clear_preview() -> void:
	if _preview_root and is_instance_valid(_preview_root):
		_preview_root.queue_free()
		_preview_root = null

func _configure_preview_chunk(instance: OverworldChunk, coord: Vector2i) -> void:
	instance._is_preview_instance = true
	instance._preview_origin_coord = chunk_coord
	instance.preview_neighbors = false
	instance.preview_radius = preview_radius
	instance.enforce_bounds_in_editor = false
	instance.cleanup_out_of_bounds = false
	instance.show_bounds = true
	instance.bounds_line_width = max(instance.bounds_line_width, 1.0)
	instance.z_index = PREVIEW_Z_INDEX
	instance.chunk_size_tiles = chunk_size_tiles
	instance.tile_size = tile_size
	instance.chunk_coord = coord

func _preview_offsets(radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x == 0 and y == 0:
				continue
			result.append(Vector2i(x, y))
	return result

func _coerce_chunk_size(value: int) -> int:
	return max(value, 1)

func _coerce_tile_size(value: Vector2i) -> Vector2i:
	return Vector2i(max(value.x, 1), max(value.y, 1))

func _normalize_dir(value: String) -> String:
	var normalized = value
	while normalized.ends_with("/") or normalized.ends_with("\\"):
		normalized = normalized.substr(0, normalized.length() - 1)
	return normalized

func _preview_offset() -> Vector2:
	var delta = chunk_coord - _preview_origin_coord
	return Vector2(delta.x, -delta.y) * _chunk_pixel_size()
