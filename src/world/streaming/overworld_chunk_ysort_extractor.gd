class_name OverworldChunkYSortExtractor
extends RefCounted

## Runtime y-sort extraction utilities for OverworldChunk.

const COLLISION_CACHE_PREFIX := "_CollisionCache_"
const NAVIGATION_OBSTACLE_ROOT_NAME := "_NavigationObstacles"


static func extract(owner: OverworldChunk) -> void:
	if owner.world_y_sort == null:
		push_warning("OverworldChunk: WorldYSort not found, y-sorting won't work")
		return

	for child in owner.get_children():
		if child is TileMapLayer:
			var layer := child as TileMapLayer
			if layer.name.begins_with(COLLISION_CACHE_PREFIX):
				continue
			_extract_layer_tiles(owner, layer)


static func _extract_layer_tiles(owner: OverworldChunk, layer: TileMapLayer) -> void:
	var tile_set := layer.tile_set
	if tile_set == null:
		return

	var is_objects_layer := layer.name == "Objects"
	var has_disable_flag := tile_set.get_custom_data_layer_by_name("disable_y_sort") != -1
	var has_enable_flag := tile_set.get_custom_data_layer_by_name("enable_y_sort") != -1

	var cells_to_remove: Array[Vector2i] = []
	var tileset_tile_size := Vector2(tile_set.tile_size)
	var collision_cache_layer := _get_or_create_collision_cache_layer(owner, layer)

	for cell in layer.get_used_cells():
		var tile_info := _get_tile_info(layer, tile_set, cell)
		if tile_info.is_empty():
			continue

		var should_extract := _should_extract(tile_info.tile_data, is_objects_layer, has_disable_flag, has_enable_flag)
		var has_collision := _tile_has_collision(tile_set, tile_info.tile_data)
		if has_collision and (is_objects_layer or should_extract):
			_create_navigation_obstacle_for_cell(owner, layer, cell, tileset_tile_size)

		if not should_extract:
			continue

		var sprite := _create_y_sorted_sprite(layer, cell, tile_info, tileset_tile_size)
		owner.world_y_sort.add_child(sprite)
		owner._extracted_sprites.append(sprite)
		_copy_cell_to_collision_layer(layer, collision_cache_layer, cell)
		cells_to_remove.append(cell)

	for cell in cells_to_remove:
		layer.erase_cell(cell)


static func _get_or_create_collision_cache_layer(owner: OverworldChunk, source_layer: TileMapLayer) -> TileMapLayer:
	var layer_name := "%s%s" % [COLLISION_CACHE_PREFIX, source_layer.name]
	var existing := owner.get_node_or_null(layer_name) as TileMapLayer
	if existing:
		return existing

	var collision_layer := TileMapLayer.new()
	collision_layer.name = layer_name
	collision_layer.tile_set = source_layer.tile_set
	collision_layer.y_sort_enabled = false
	collision_layer.visible = false
	collision_layer.enabled = true
	owner.add_child(collision_layer)
	collision_layer.owner = null
	return collision_layer


static func _copy_cell_to_collision_layer(source_layer: TileMapLayer, collision_layer: TileMapLayer, cell: Vector2i) -> void:
	if source_layer == null or collision_layer == null:
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


static func _tile_has_collision(tile_set: TileSet, tile_data: TileData) -> bool:
	if tile_set == null or tile_data == null:
		return false

	var physics_layer_count := tile_set.get_physics_layers_count()
	for layer_id in range(physics_layer_count):
		if tile_data.get_collision_polygons_count(layer_id) > 0:
			return true
	return false


static func _get_or_create_navigation_obstacle_root(owner: OverworldChunk) -> Node2D:
	if owner._navigation_obstacle_root and is_instance_valid(owner._navigation_obstacle_root):
		return owner._navigation_obstacle_root

	var existing_root := owner.get_node_or_null(NAVIGATION_OBSTACLE_ROOT_NAME) as Node2D
	if existing_root:
		owner._navigation_obstacle_root = existing_root
		return owner._navigation_obstacle_root

	var root := Node2D.new()
	root.name = NAVIGATION_OBSTACLE_ROOT_NAME
	owner.add_child(root)
	root.owner = null
	owner._navigation_obstacle_root = root
	return owner._navigation_obstacle_root


static func _create_navigation_obstacle_for_cell(
	owner: OverworldChunk,
	layer: TileMapLayer,
	cell: Vector2i,
	tileset_tile_size: Vector2
) -> void:
	var obstacle_root := _get_or_create_navigation_obstacle_root(owner)
	if obstacle_root == null:
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
	owner._navigation_obstacles.append(obstacle)


static func _should_extract(tile_data: TileData, is_objects_layer: bool, has_disable_flag: bool, has_enable_flag: bool) -> bool:
	if is_objects_layer:
		if has_disable_flag:
			var disable_val = tile_data.get_custom_data("disable_y_sort")
			if disable_val is bool and disable_val == true:
				return false
		return true

	if has_enable_flag:
		var enable_val = tile_data.get_custom_data("enable_y_sort")
		if enable_val is bool and enable_val == true:
			return true
	return false


static func _get_tile_info(layer: TileMapLayer, tile_set: TileSet, cell: Vector2i) -> Dictionary:
	var tile_data := layer.get_cell_tile_data(cell)
	if tile_data == null:
		return {}

	var source_id := layer.get_cell_source_id(cell)
	if source_id < 0:
		return {}

	var source := tile_set.get_source(source_id)
	if not (source is TileSetAtlasSource):
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


static func _create_y_sorted_sprite(
	layer: TileMapLayer,
	cell: Vector2i,
	tile_info: Dictionary,
	tileset_tile_size: Vector2
) -> Sprite2D:
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
	sprite.z_index = 0

	if tile_data.transpose:
		sprite.rotation = PI * 0.5

	var cell_center_local := layer.map_to_local(cell)
	var cell_center_global := layer.to_global(cell_center_local)
	var texture_origin := Vector2(tile_data.texture_origin)
	var texture_center := cell_center_global + texture_origin
	var sort_y := cell_center_global.y + tileset_tile_size.y * 0.5

	sprite.position = Vector2(texture_center.x, sort_y)
	sprite.offset.y = texture_center.y - sort_y
	return sprite
