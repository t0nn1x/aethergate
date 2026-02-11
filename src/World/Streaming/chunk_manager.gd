@tool
class_name ChunkManager
extends Node2D

signal chunks_changed

const PLAYER_GROUP := "player"
const CHUNK_SCENE_PREFIX := "chunk_"
const CHUNK_SCENE_EXT := ".tscn"

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
	var loaded_coords: Array = _loaded_chunks.keys()
	for coord_variant in loaded_coords:
		var coord: Vector2i = coord_variant
		if not needed.has(coord):
			_unload_chunk(coord)
			changed = true
	if changed:
		chunks_changed.emit()
		call_deferred("_stitch_loaded_chunk_borders")

func _load_chunk(coord: Vector2i) -> void:
	var scene: PackedScene = _load_chunk_scene(coord)
	if scene == null:
		return

	var instance: Node = scene.instantiate()
	_configure_loaded_chunk_instance(instance, coord)
	_get_chunks_root().add_child(instance)
	_loaded_chunks[coord] = instance

func _unload_chunk(coord: Vector2i) -> void:
	var instance: Node = _loaded_chunks.get(coord, null) as Node
	if instance and is_instance_valid(instance):
		instance.queue_free()
	_loaded_chunks.erase(coord)

func _build_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	_editor_preview_root = ChunkManagerEditorPreview.rebuild_preview(
		self,
		_editor_preview_root,
		preview_all_in_editor,
		chunk_scene_dir,
		chunk_size_tiles,
		tile_size
	)

func _coerce_chunk_size(value: int) -> int:
	return max(value, 1)

func _coerce_tile_size(value: Vector2i) -> Vector2i:
	return Vector2i(max(value.x, 1), max(value.y, 1))

func _stitch_loaded_chunk_borders() -> void:
	if Engine.is_editor_hint():
		return
	ChunkBorderStitcher.stitch_loaded_chunk_borders(
		_loaded_chunks,
		_coerce_chunk_size(chunk_size_tiles)
	)

func _normalize_dir(value: String) -> String:
	var normalized = value
	while normalized.ends_with("/") or normalized.ends_with("\\"):
		normalized = normalized.substr(0, normalized.length() - 1)
	return normalized

func _load_chunk_scene(coord: Vector2i) -> PackedScene:
	var path := _chunk_scene_path(coord)
	if not ResourceLoader.exists(path):
		return null

	var resource: Resource = load(path)
	return resource as PackedScene

func _configure_loaded_chunk_instance(instance: Node, coord: Vector2i) -> void:
	if instance is not OverworldChunk:
		return

	var chunk: OverworldChunk = instance as OverworldChunk
	chunk.chunk_coord = coord
	chunk.chunk_size_tiles = chunk_size_tiles
	chunk.tile_size = tile_size
	chunk.world_y_sort = get_node_or_null(world_y_sort_path) as Node2D

func _get_chunks_root() -> Node:
	var chunks_root: Node = get_node_or_null(chunks_root_path)
	if chunks_root:
		return chunks_root
	return self

func world_to_chunk(world_pos: Vector2) -> Vector2i:
	return _world_to_chunk(world_pos)

func get_loaded_chunk_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for coord in _loaded_chunks.keys():
		coords.append(coord)
	return coords

func get_loaded_chunk_count() -> int:
	return _loaded_chunks.size()
