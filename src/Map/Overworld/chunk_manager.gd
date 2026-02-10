@tool
class_name ChunkManager
extends Node2D

const PLAYER_GROUP := "player"
const PREVIEW_ROOT_NAME := "_EditorPreviewAll"
const PREVIEW_Z_INDEX := 100
const CHUNK_SCENE_PREFIX := "chunk_"
const CHUNK_TEMPLATE_NAME := "chunk_template.tscn"
const CHUNK_SCENE_EXT := ".tscn"
const COLLISION_CACHE_PREFIX := "_CollisionCache_"
const OBJECTS_LAYER_NAME := "Objects"

@export_dir var chunk_scene_dir: String = "res://src/Map/Overworld/Chunks/Midra": set = _set_chunk_scene_dir
@export var chunk_size_tiles: int = 48: set = _set_chunk_size_tiles
@export var tile_size: Vector2i = Vector2i(48, 48): set = _set_tile_size
@export var load_radius: int = 1: set = _set_load_radius
@export var chunks_root_path: NodePath = ^"../Chunks"
@export var world_y_sort_path: NodePath = ^"../WorldYSort"
@export var preview_all_in_editor: bool = false: set = _set_preview_all_in_editor
@export var refresh_editor_preview: bool = false: set = _set_refresh_editor_preview

var _loaded_chunks: Dictionary = {}
var _current_center: Vector2i = Vector2i(2147483647, 2147483647)
var _player: Node2D = null
var _editor_preview_root: Node2D = null

func _ready() -> void:
	if Engine.is_editor_hint():
		_build_editor_preview()
		return
	call_deferred("_find_player")

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _player:
		_find_player()
		return
	var center = _world_to_chunk(_player.global_position)
	if center != _current_center:
		_current_center = center
		_update_loaded_chunks(center)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group(PLAYER_GROUP)
	if players.size() == 0:
		return
	_player = players[0]
	_current_center = _world_to_chunk(_player.global_position)
	_update_loaded_chunks(_current_center)

func _set_preview_all_in_editor(value: bool) -> void:
	preview_all_in_editor = value
	if Engine.is_editor_hint():
		_build_editor_preview()

func _set_refresh_editor_preview(value: bool) -> void:
	refresh_editor_preview = value
	if Engine.is_editor_hint() and refresh_editor_preview:
		_build_editor_preview()
		refresh_editor_preview = false
		notify_property_list_changed()

func _set_chunk_scene_dir(value: String) -> void:
	chunk_scene_dir = _normalize_dir(value)
	if Engine.is_editor_hint():
		_build_editor_preview()

func _set_chunk_size_tiles(value: int) -> void:
	var sanitized = _coerce_chunk_size(value)
	if chunk_size_tiles == sanitized:
		return
	chunk_size_tiles = sanitized
	if Engine.is_editor_hint():
		_build_editor_preview()

func _set_tile_size(value: Vector2i) -> void:
	var sanitized = _coerce_tile_size(value)
	if tile_size == sanitized:
		return
	tile_size = sanitized
	if Engine.is_editor_hint():
		_build_editor_preview()

func _set_load_radius(value: int) -> void:
	var sanitized = max(value, 0)
	if load_radius == sanitized:
		return
	load_radius = sanitized
	if not Engine.is_editor_hint() and _player:
		_update_loaded_chunks(_current_center)

func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	var chunk_world_size = _chunk_world_size()
	if chunk_world_size.x <= 0.0 or chunk_world_size.y <= 0.0:
		return Vector2i.ZERO
	return Vector2i(
		floor(world_pos.x / chunk_world_size.x),
		-floor(world_pos.y / chunk_world_size.y)
	)

func _chunk_world_size() -> Vector2:
	return Vector2(
		_coerce_chunk_size(chunk_size_tiles) * max(tile_size.x, 1),
		_coerce_chunk_size(chunk_size_tiles) * max(tile_size.y, 1)
	)

func _chunk_scene_path(coord: Vector2i) -> String:
	return chunk_scene_dir.path_join("%s%d_%d%s" % [CHUNK_SCENE_PREFIX, coord.x, coord.y, CHUNK_SCENE_EXT])

func _update_loaded_chunks(center: Vector2i) -> void:
	var needed := {}
	var changed := false
	for x in range(center.x - load_radius, center.x + load_radius + 1):
		for y in range(center.y - load_radius, center.y + load_radius + 1):
			var coord = Vector2i(x, y)
			needed[coord] = true
			if not _loaded_chunks.has(coord):
				_load_chunk(coord)
				changed = true
	for coord in _loaded_chunks.keys():
		if not needed.has(coord):
			_unload_chunk(coord)
			changed = true
	if changed:
		call_deferred("_stitch_loaded_chunk_borders")

func _load_chunk(coord: Vector2i) -> void:
	var path = _chunk_scene_path(coord)
	if not ResourceLoader.exists(path):
		return
	var scene = load(path)
	if not scene:
		return
	var instance = scene.instantiate()
	if instance is OverworldChunk:
		instance.chunk_coord = coord
		instance.chunk_size_tiles = chunk_size_tiles
		instance.tile_size = tile_size
		instance.world_y_sort = get_node_or_null(world_y_sort_path)
	var chunks_root: Node = get_node_or_null(chunks_root_path)
	if not chunks_root:
		add_child(instance)
	else:
		chunks_root.add_child(instance)
	_loaded_chunks[coord] = instance

func _unload_chunk(coord: Vector2i) -> void:
	var instance = _loaded_chunks.get(coord, null)
	if instance and is_instance_valid(instance):
		instance.queue_free()
	_loaded_chunks.erase(coord)

func _build_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	_clear_editor_preview()
	if not preview_all_in_editor:
		return
	_editor_preview_root = Node2D.new()
	_editor_preview_root.name = PREVIEW_ROOT_NAME
	_editor_preview_root.z_index = PREVIEW_Z_INDEX
	_editor_preview_root.owner = null
	add_child(_editor_preview_root)
	var dir = DirAccess.open(chunk_scene_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if _is_chunk_scene(file_name):
			var path = chunk_scene_dir.path_join(file_name)
			var coord = _parse_chunk_coord(file_name)
			var scene = load(path)
			if scene:
				var instance = scene.instantiate()
				instance.name = "_Preview_%s" % file_name.substr(0, file_name.length() - CHUNK_SCENE_EXT.length())
				instance.owner = null
				if instance is OverworldChunk:
					_configure_preview_chunk(instance, coord)
				_editor_preview_root.add_child(instance)
		file_name = dir.get_next()
	dir.list_dir_end()

func _clear_editor_preview() -> void:
	if _editor_preview_root and is_instance_valid(_editor_preview_root):
		_editor_preview_root.queue_free()
	_editor_preview_root = null

func _is_chunk_scene(file_name: String) -> bool:
	if not file_name.begins_with(CHUNK_SCENE_PREFIX) or not file_name.ends_with(CHUNK_SCENE_EXT):
		return false
	if file_name == CHUNK_TEMPLATE_NAME:
		return false
	var prefix_len = CHUNK_SCENE_PREFIX.length()
	var base = file_name.substr(prefix_len, file_name.length() - prefix_len - CHUNK_SCENE_EXT.length())
	var parts = base.split("_")
	if parts.size() != 2:
		return false
	return parts[0].is_valid_int() and parts[1].is_valid_int()

func _parse_chunk_coord(file_name: String) -> Vector2i:
	var prefix_len = CHUNK_SCENE_PREFIX.length()
	var base = file_name.substr(prefix_len, file_name.length() - prefix_len - CHUNK_SCENE_EXT.length())
	var parts = base.split("_")
	return Vector2i(int(parts[0]), int(parts[1]))

func _configure_preview_chunk(instance: OverworldChunk, coord: Vector2i) -> void:
	instance.chunk_coord = coord
	instance.chunk_size_tiles = chunk_size_tiles
	instance.tile_size = tile_size
	instance.preview_neighbors = false
	instance.enforce_bounds_in_editor = false
	instance.cleanup_out_of_bounds = false
	instance.show_bounds = true
	instance.bounds_line_width = max(instance.bounds_line_width, 1.0)
	instance.z_index = PREVIEW_Z_INDEX

func _coerce_chunk_size(value: int) -> int:
	return max(value, 1)

func _coerce_tile_size(value: Vector2i) -> Vector2i:
	return Vector2i(max(value.x, 1), max(value.y, 1))

func _stitch_loaded_chunk_borders() -> void:
	if Engine.is_editor_hint():
		return
	var size := _coerce_chunk_size(chunk_size_tiles)
	for coord in _loaded_chunks.keys():
		var chunk := _loaded_chunks.get(coord, null) as OverworldChunk
		if not chunk or not is_instance_valid(chunk):
			continue
		_stitch_chunk_border_layers(chunk, size)

func _stitch_chunk_border_layers(chunk: OverworldChunk, size: int) -> void:
	for child in chunk.get_children():
		if not (child is TileMapLayer):
			continue
		var layer := child as TileMapLayer
		if layer.name.begins_with(COLLISION_CACHE_PREFIX):
			continue
		if layer.name == OBJECTS_LAYER_NAME:
			continue
		_stitch_layer_border(chunk.chunk_coord, layer, size)

func _stitch_layer_border(coord: Vector2i, layer: TileMapLayer, size: int) -> void:
	var max_index := size - 1
	_clear_border_overlap_cells(layer, size)

	var left_layer := _get_chunk_layer(coord + Vector2i.LEFT, layer.name)
	var right_layer := _get_chunk_layer(coord + Vector2i.RIGHT, layer.name)
	var up_layer := _get_chunk_layer(coord + Vector2i(0, 1), layer.name)
	var down_layer := _get_chunk_layer(coord + Vector2i(0, -1), layer.name)

	for y in range(size):
		_copy_cell(left_layer, Vector2i(max_index, y), layer, Vector2i(-1, y))
		_copy_cell(right_layer, Vector2i(0, y), layer, Vector2i(size, y))
	for x in range(size):
		_copy_cell(up_layer, Vector2i(x, max_index), layer, Vector2i(x, -1))
		_copy_cell(down_layer, Vector2i(x, 0), layer, Vector2i(x, size))

	var up_left_layer := _get_chunk_layer(coord + Vector2i(-1, 1), layer.name)
	var up_right_layer := _get_chunk_layer(coord + Vector2i(1, 1), layer.name)
	var down_left_layer := _get_chunk_layer(coord + Vector2i(-1, -1), layer.name)
	var down_right_layer := _get_chunk_layer(coord + Vector2i(1, -1), layer.name)

	_copy_cell(up_left_layer, Vector2i(max_index, max_index), layer, Vector2i(-1, -1))
	_copy_cell(up_right_layer, Vector2i(0, max_index), layer, Vector2i(size, -1))
	_copy_cell(down_left_layer, Vector2i(max_index, 0), layer, Vector2i(-1, size))
	_copy_cell(down_right_layer, Vector2i(0, 0), layer, Vector2i(size, size))

func _copy_cell(
	source_layer: TileMapLayer,
	source_cell: Vector2i,
	target_layer: TileMapLayer,
	target_cell: Vector2i
) -> void:
	if not source_layer or not target_layer:
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

func _clear_border_overlap_cells(layer: TileMapLayer, size: int) -> void:
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

func _get_chunk_layer(coord: Vector2i, layer_name: String) -> TileMapLayer:
	var chunk := _loaded_chunks.get(coord, null) as OverworldChunk
	if not chunk or not is_instance_valid(chunk):
		return null
	return chunk.get_node_or_null(layer_name) as TileMapLayer

func _normalize_dir(value: String) -> String:
	var normalized = value
	while normalized.ends_with("/") or normalized.ends_with("\\"):
		normalized = normalized.substr(0, normalized.length() - 1)
	return normalized

func world_to_chunk(world_pos: Vector2) -> Vector2i:
	return _world_to_chunk(world_pos)

func get_loaded_chunk_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for coord in _loaded_chunks.keys():
		coords.append(coord)
	return coords

func get_loaded_chunk_count() -> int:
	return _loaded_chunks.size()
