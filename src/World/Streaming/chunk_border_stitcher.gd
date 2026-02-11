class_name ChunkBorderStitcher
extends RefCounted

## Runtime border stitching utilities extracted from ChunkManager.

const COLLISION_CACHE_PREFIX := "_CollisionCache_"
const OBJECTS_LAYER_NAME := "Objects"


static func stitch_loaded_chunk_borders(loaded_chunks: Dictionary, chunk_size_tiles: int) -> void:
	for coord in loaded_chunks.keys():
		var chunk := loaded_chunks.get(coord, null) as OverworldChunk
		if chunk == null or not is_instance_valid(chunk):
			continue
		_stitch_chunk_border_layers(loaded_chunks, chunk, chunk_size_tiles)


static func _stitch_chunk_border_layers(loaded_chunks: Dictionary, chunk: OverworldChunk, size: int) -> void:
	for child in chunk.get_children():
		if not (child is TileMapLayer):
			continue
		var layer := child as TileMapLayer
		if layer.name.begins_with(COLLISION_CACHE_PREFIX):
			continue
		if layer.name == OBJECTS_LAYER_NAME:
			continue
		_stitch_layer_border(loaded_chunks, chunk.chunk_coord, layer, size)


static func _stitch_layer_border(
	loaded_chunks: Dictionary,
	coord: Vector2i,
	layer: TileMapLayer,
	size: int
) -> void:
	var max_index := size - 1
	_clear_border_overlap_cells(layer, size)

	var left_layer := _get_chunk_layer(loaded_chunks, coord + Vector2i.LEFT, layer.name)
	var right_layer := _get_chunk_layer(loaded_chunks, coord + Vector2i.RIGHT, layer.name)
	var up_layer := _get_chunk_layer(loaded_chunks, coord + Vector2i(0, 1), layer.name)
	var down_layer := _get_chunk_layer(loaded_chunks, coord + Vector2i(0, -1), layer.name)

	for y in range(size):
		_copy_cell(left_layer, Vector2i(max_index, y), layer, Vector2i(-1, y))
		_copy_cell(right_layer, Vector2i(0, y), layer, Vector2i(size, y))
	for x in range(size):
		_copy_cell(up_layer, Vector2i(x, max_index), layer, Vector2i(x, -1))
		_copy_cell(down_layer, Vector2i(x, 0), layer, Vector2i(x, size))

	var up_left_layer := _get_chunk_layer(loaded_chunks, coord + Vector2i(-1, 1), layer.name)
	var up_right_layer := _get_chunk_layer(loaded_chunks, coord + Vector2i(1, 1), layer.name)
	var down_left_layer := _get_chunk_layer(loaded_chunks, coord + Vector2i(-1, -1), layer.name)
	var down_right_layer := _get_chunk_layer(loaded_chunks, coord + Vector2i(1, -1), layer.name)

	_copy_cell(up_left_layer, Vector2i(max_index, max_index), layer, Vector2i(-1, -1))
	_copy_cell(up_right_layer, Vector2i(0, max_index), layer, Vector2i(size, -1))
	_copy_cell(down_left_layer, Vector2i(max_index, 0), layer, Vector2i(-1, size))
	_copy_cell(down_right_layer, Vector2i(0, 0), layer, Vector2i(size, size))


static func _copy_cell(
	source_layer: TileMapLayer,
	source_cell: Vector2i,
	target_layer: TileMapLayer,
	target_cell: Vector2i
) -> void:
	if source_layer == null or target_layer == null:
		return

	var source_id := source_layer.get_cell_source_id(source_cell)
	if source_id < 0:
		return

	target_layer.set_cell(
		target_cell,
		source_id,
		source_layer.get_cell_atlas_coords(source_cell),
		source_layer.get_cell_alternative_tile(source_cell)
	)


static func _clear_border_overlap_cells(layer: TileMapLayer, size: int) -> void:
	for y in range(size):
		layer.erase_cell(Vector2i(-1, y))
		layer.erase_cell(Vector2i(size, y))
	for x in range(size):
		layer.erase_cell(Vector2i(x, -1))
		layer.erase_cell(Vector2i(x, size))
	layer.erase_cell(Vector2i(-1, -1))
	layer.erase_cell(Vector2i(size, -1))
	layer.erase_cell(Vector2i(-1, size))
	layer.erase_cell(Vector2i(size, size))


static func _get_chunk_layer(loaded_chunks: Dictionary, coord: Vector2i, layer_name: String) -> TileMapLayer:
	var chunk := loaded_chunks.get(coord, null) as OverworldChunk
	if chunk == null or not is_instance_valid(chunk):
		return null
	return chunk.get_node_or_null(layer_name) as TileMapLayer
