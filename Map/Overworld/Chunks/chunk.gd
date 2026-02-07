@tool
class_name OverworldChunk
extends Node2D

const PREVIEW_ROOT_NAME := "_PreviewNeighbors"
const PREVIEW_Z_INDEX := 100
const MIN_ENFORCE_INTERVAL := 0.1
const DEFAULT_PREVIEW_RADIUS := 2
const COLLISION_CACHE_PREFIX := "_CollisionCache_"
const NAVIGATION_OBSTACLE_ROOT_NAME := "_NavigationObstacles"

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
var _extracted_sprites: Array[Sprite2D] = []
var _navigation_obstacles: Array[NavigationObstacle2D] = []
var _navigation_obstacle_root: Node2D = null
var world_y_sort: Node2D = null  ## Set by ChunkManager before adding to tree

static var _water_material: ShaderMaterial = null

func _ready() -> void:
	if Engine.is_editor_hint() and not _is_preview_instance:
		preview_neighbors = false
	_on_geometry_changed()
	if Engine.is_editor_hint():
		_refresh_preview()
		return
	_apply_water_shader()
	_extract_y_sorted_objects()

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	_cleanup_extracted_sprites()

func _apply_water_shader() -> void:
	## Apply the shared water ShaderMaterial to the Base TileMapLayer.
	if _water_material == null:
		var shader := load("res://Map/Overworld/Shaders/water.gdshader") as Shader
		if shader:
			_water_material = ShaderMaterial.new()
			_water_material.shader = shader
		else:
			push_warning("OverworldChunk: water.gdshader not found")
			return

	var base_layer := get_node_or_null("Base") as TileMapLayer
	if base_layer:
		base_layer.material = _water_material

func _extract_y_sorted_objects() -> void:
	## Extract qualifying tiles from TileMapLayers into sprites for proper y-sorting.
	##
	## Layer behavior:
	##   "Objects" layer → extract ALL tiles, UNLESS tile has disable_y_sort = true
	##   Any other layer  → extract NOTHING, UNLESS tile has enable_y_sort = true
	##
	## This allows Objects tiles to opt-out (stay flat on ground) and terrain tiles
	## to opt-in (e.g. forest trees that should y-sort with the player).
	if not world_y_sort:
		push_warning("OverworldChunk: WorldYSort not found, y-sorting won't work")
		return
	
	for child in get_children():
		if child is TileMapLayer:
			var layer := child as TileMapLayer
			if layer.name.begins_with(COLLISION_CACHE_PREFIX):
				continue
			_extract_layer_tiles(layer)

func _extract_layer_tiles(layer: TileMapLayer) -> void:
	## Extract tiles from a single TileMapLayer based on its name and custom data flags.
	var tile_set := layer.tile_set
	if not tile_set:
		return
	
	var is_objects_layer := layer.name == "Objects"
	# Cache whether this tileset has the relevant custom data layer (avoids per-tile errors)
	var has_disable_flag := tile_set.get_custom_data_layer_by_name("disable_y_sort") != -1
	var has_enable_flag := tile_set.get_custom_data_layer_by_name("enable_y_sort") != -1
	
	var cells_to_remove: Array[Vector2i] = []
	var tileset_tile_size := Vector2(tile_set.tile_size)
	var collision_cache_layer := _get_or_create_collision_cache_layer(layer)
	
	for cell in layer.get_used_cells():
		var tile_info := _get_tile_info(layer, tile_set, cell)
		if not tile_info:
			continue

		var should_extract := _should_extract(tile_info.tile_data, is_objects_layer, has_disable_flag, has_enable_flag)
		var has_collision := _tile_has_collision(tile_set, tile_info.tile_data)
		if has_collision and (is_objects_layer or should_extract):
			_create_navigation_obstacle_for_cell(layer, cell, tileset_tile_size)

		if not should_extract:
			continue
		
		var sprite := _create_y_sorted_sprite(layer, cell, tile_info, tileset_tile_size)
		world_y_sort.add_child(sprite)
		_extracted_sprites.append(sprite)
		_copy_cell_to_collision_layer(layer, collision_cache_layer, cell)
		cells_to_remove.append(cell)
	
	# Remove extracted tiles from the layer so they don't render twice
	for cell in cells_to_remove:
		layer.erase_cell(cell)

func _get_or_create_collision_cache_layer(source_layer: TileMapLayer) -> TileMapLayer:
	var layer_name := "%s%s" % [COLLISION_CACHE_PREFIX, source_layer.name]
	var existing := get_node_or_null(layer_name) as TileMapLayer
	if existing:
		return existing

	var collision_layer := TileMapLayer.new()
	collision_layer.name = layer_name
	collision_layer.tile_set = source_layer.tile_set
	collision_layer.y_sort_enabled = false
	collision_layer.visible = false
	collision_layer.enabled = true
	add_child(collision_layer)
	collision_layer.owner = null
	return collision_layer

func _copy_cell_to_collision_layer(source_layer: TileMapLayer, collision_layer: TileMapLayer, cell: Vector2i) -> void:
	if not source_layer or not collision_layer:
		return

	var source_id := source_layer.get_cell_source_id(cell)
	if source_id < 0:
		return

	collision_layer.tile_set = source_layer.tile_set
	collision_layer.set_cell(
		cell,
		source_id,
		source_layer.get_cell_atlas_coords(cell),
		source_layer.get_cell_alternative_tile(cell)
	)

func _tile_has_collision(tile_set: TileSet, tile_data: TileData) -> bool:
	if not tile_set or not tile_data:
		return false

	var physics_layer_count := tile_set.get_physics_layers_count()
	for layer_id in range(physics_layer_count):
		if tile_data.get_collision_polygons_count(layer_id) > 0:
			return true

	return false

func _get_or_create_navigation_obstacle_root() -> Node2D:
	if _navigation_obstacle_root and is_instance_valid(_navigation_obstacle_root):
		return _navigation_obstacle_root

	var existing_root := get_node_or_null(NAVIGATION_OBSTACLE_ROOT_NAME) as Node2D
	if existing_root:
		_navigation_obstacle_root = existing_root
		return _navigation_obstacle_root

	var root := Node2D.new()
	root.name = NAVIGATION_OBSTACLE_ROOT_NAME
	add_child(root)
	root.owner = null
	_navigation_obstacle_root = root
	return _navigation_obstacle_root

func _create_navigation_obstacle_for_cell(layer: TileMapLayer, cell: Vector2i, tileset_tile_size: Vector2) -> void:
	var obstacle_root := _get_or_create_navigation_obstacle_root()
	if not obstacle_root:
		return

	var obstacle := NavigationObstacle2D.new()
	obstacle.name = "NavObstacle_%s_%d_%d" % [layer.name, cell.x, cell.y]
	obstacle.avoidance_enabled = true

	var half_size := tileset_tile_size * 0.5 - Vector2(2.0, 2.0)
	half_size.x = max(half_size.x, 2.0)
	half_size.y = max(half_size.y, 2.0)

	obstacle.vertices = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
	obstacle.position = layer.to_global(layer.map_to_local(cell))

	obstacle_root.add_child(obstacle)
	obstacle.owner = null
	_navigation_obstacles.append(obstacle)

func _should_extract(tile_data: TileData, is_objects_layer: bool, has_disable_flag: bool, has_enable_flag: bool) -> bool:
	## Decide if a tile should be extracted into WorldYSort.
	if is_objects_layer:
		# Objects layer: extract everything UNLESS disable_y_sort is true
		if has_disable_flag:
			var val = tile_data.get_custom_data("disable_y_sort")
			if val is bool and val == true:
				return false
		return true
	else:
		# Terrain / other layers: skip everything UNLESS enable_y_sort is true
		if has_enable_flag:
			var val = tile_data.get_custom_data("enable_y_sort")
			if val is bool and val == true:
				return true
		return false

func _get_tile_info(layer: TileMapLayer, tile_set: TileSet, cell: Vector2i) -> Dictionary:
	## Get all relevant information about a tile at a cell position
	var tile_data := layer.get_cell_tile_data(cell)
	if not tile_data:
		return {}
	
	var source_id := layer.get_cell_source_id(cell)
	if source_id < 0:
		return {}
	
	var source := tile_set.get_source(source_id)
	if not source is TileSetAtlasSource:
		return {}
	
	var atlas_source: TileSetAtlasSource = source
	var atlas_coords := layer.get_cell_atlas_coords(cell)
	var alternative := layer.get_cell_alternative_tile(cell)
	var region: Rect2i = atlas_source.get_tile_texture_region(atlas_coords, alternative)
	
	if region.size == Vector2i.ZERO:
		return {}
	
	return {
		"tile_data": tile_data,
		"atlas_source": atlas_source,
		"region": region,
		"region_size": Vector2(region.size)
	}

func _create_y_sorted_sprite(layer: TileMapLayer, cell: Vector2i, tile_info: Dictionary, tileset_tile_size: Vector2) -> Sprite2D:
	## Create a sprite from tile information, positioned for y-sorting
	var tile_data: TileData = tile_info.tile_data
	var atlas_source: TileSetAtlasSource = tile_info.atlas_source
	var region: Rect2i = tile_info.region
	
	var sprite := Sprite2D.new()
	sprite.name = "YSort_%s_%d_%d" % [layer.name, cell.x, cell.y]
	sprite.texture = atlas_source.texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(region.position, region.size)
	sprite.centered = true
	sprite.flip_h = tile_data.flip_h
	sprite.flip_v = tile_data.flip_v
	
	# z_index = 0 so sprites sort purely by Y position within WorldYSort
	sprite.z_index = 0
	
	if tile_data.transpose:
		sprite.rotation = PI * 0.5
	
	# Calculate positions
	var cell_center_local := layer.map_to_local(cell)
	var cell_center_global := layer.to_global(cell_center_local)
	var texture_origin := Vector2(tile_data.texture_origin)
	var texture_center := cell_center_global + texture_origin
	var sort_y := cell_center_global.y + tileset_tile_size.y * 0.5
	
	# Position sprite at sort point with visual offset
	sprite.position = Vector2(texture_center.x, sort_y)
	sprite.offset.y = texture_center.y - sort_y
	
	return sprite

func _cleanup_extracted_sprites() -> void:
	for sprite in _extracted_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_extracted_sprites.clear()

	for obstacle in _navigation_obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	_navigation_obstacles.clear()

	if is_instance_valid(_navigation_obstacle_root):
		_navigation_obstacle_root.queue_free()
	_navigation_obstacle_root = null

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
