class_name OverworldCreatureSpawner
extends Node

## Spawns/despawns creatures and binds them to chunk lifecycle.

const CREATURE_FACTORY_SCRIPT: Script = preload("res://src/Entities/Creatures/creature_factory.gd")
const INVALID_CHUNK_COORD: Vector2i = Vector2i(2147483647, 2147483647)

signal creature_spawned(creature: Creature, chunk_coord: Vector2i)
signal creature_despawned(creature: Creature, chunk_coord: Vector2i)

@export var catalog_service_path: NodePath = ^"CreatureCatalogService"
@export var world_y_sort_path: NodePath = ^"WorldYSort"
@export var chunk_manager_path: NodePath = ^"ChunkManager"
@export var player_spawner_path: NodePath = ^"OverworldPlayerSpawner"
@export var creature_scene: PackedScene = preload("res://src/Entities/Creatures/creature.tscn")

var _overworld: Overworld
var _factory
var _catalog_service
var _chunk_manager
var _player_spawner
var _spawned_by_chunk: Dictionary = {}


func _ready() -> void:
	_overworld = get_parent() as Overworld
	assert(_overworld, "OverworldCreatureSpawner must be a child of Overworld.")

	_factory = CREATURE_FACTORY_SCRIPT.new()
	_factory.creature_scene = creature_scene
	_catalog_service = _overworld.get_node_or_null(catalog_service_path)
	if _catalog_service == null:
		push_warning("OverworldCreatureSpawner: CreatureCatalogService is missing.")
	else:
		_catalog_service.call("ensure_catalog_loaded")

	_chunk_manager = _overworld.get_node_or_null(chunk_manager_path)
	if _chunk_manager == null:
		push_warning("OverworldCreatureSpawner: ChunkManager is missing.")
	if _chunk_manager and _chunk_manager.has_signal("chunk_loaded"):
		if not _chunk_manager.chunk_loaded.is_connected(_on_chunk_loaded):
			_chunk_manager.chunk_loaded.connect(_on_chunk_loaded)
	if _chunk_manager and _chunk_manager.has_signal("chunk_unloaded"):
		if not _chunk_manager.chunk_unloaded.is_connected(_on_chunk_unloaded):
			_chunk_manager.chunk_unloaded.connect(_on_chunk_unloaded)

	_player_spawner = _overworld.get_node_or_null(player_spawner_path)
	if _player_spawner and not _player_spawner.player_spawned.is_connected(_on_player_spawned):
		_player_spawner.player_spawned.connect(_on_player_spawned)


func spawn_creature_by_id(creature_id: String, world_position: Vector2, chunk_coord: Vector2i = INVALID_CHUNK_COORD) -> Creature:
	if _catalog_service == null:
		push_warning("OverworldCreatureSpawner: cannot spawn without catalog service.")
		return null

	var creature_data: CreatureData = _catalog_service.call("get_by_id", creature_id) as CreatureData
	if creature_data == null:
		return null

	var world_y_sort: Node2D = _overworld.get_node_or_null(world_y_sort_path) as Node2D
	if world_y_sort == null:
		push_warning("OverworldCreatureSpawner: WorldYSort node is missing.")
		return null

	var creature: Creature = _factory.create(creature_data)
	if creature == null:
		return null

	world_y_sort.add_child(creature)
	creature.global_position = world_position
	_register_chunk_spawn(chunk_coord, creature)
	_assign_local_player_target(creature)
	creature_spawned.emit(creature, chunk_coord)
	return creature


func despawn_chunk_creatures(chunk_coord: Vector2i) -> int:
	if not _spawned_by_chunk.has(chunk_coord):
		return 0
	var spawned: Array = _spawned_by_chunk.get(chunk_coord, []) as Array
	var despawned_count: int = 0
	for node_variant in spawned:
		var creature: Creature = node_variant as Creature
		if creature and is_instance_valid(creature):
			creature_despawned.emit(creature, chunk_coord)
			creature.queue_free()
			despawned_count += 1
	_spawned_by_chunk.erase(chunk_coord)
	return despawned_count


func spawn_chunk_creatures(chunk: OverworldChunk, chunk_coord: Vector2i) -> int:
	if chunk == null:
		return 0
	if not chunk.has_method("get_creature_spawn_markers"):
		return 0

	var markers: Array[Marker2D] = chunk.get_creature_spawn_markers()
	var spawned_count: int = 0
	for marker in markers:
		if marker == null:
			continue
		var creature_id: String = _resolve_marker_creature_id(marker)
		if creature_id.is_empty():
			continue
		if spawn_creature_by_id(creature_id, marker.global_position, chunk_coord):
			spawned_count += 1
	return spawned_count


func clear_all_spawned() -> void:
	for chunk_coord_variant in _spawned_by_chunk.keys():
		var chunk_coord: Vector2i = chunk_coord_variant
		despawn_chunk_creatures(chunk_coord)


func set_target_for_all_creatures(target: Node2D) -> void:
	for chunk_coord_variant in _spawned_by_chunk.keys():
		var spawned: Array = _spawned_by_chunk[chunk_coord_variant] as Array
		for node_variant in spawned:
			var creature: Creature = node_variant as Creature
			if creature and is_instance_valid(creature):
				_set_creature_target(creature, target)


func _register_chunk_spawn(chunk_coord: Vector2i, creature: Creature) -> void:
	if not _spawned_by_chunk.has(chunk_coord):
		_spawned_by_chunk[chunk_coord] = []
	(_spawned_by_chunk[chunk_coord] as Array).append(creature)


func _resolve_marker_creature_id(marker: Marker2D) -> String:
	if marker.has_meta("creature_id"):
		return String(marker.get_meta("creature_id")).strip_edges().to_lower()
	if marker.name.begins_with("Spawn_"):
		return marker.name.trim_prefix("Spawn_").strip_edges().to_lower()
	return ""


func _assign_local_player_target(creature: Creature) -> void:
	var local_player: Player = _overworld.get_local_player()
	if local_player == null:
		return
	_set_creature_target(creature, local_player)


func _set_creature_target(creature: Creature, target: Node2D) -> void:
	var brain: Node = creature.get_node_or_null("CreatureBrainComponent")
	if brain and brain.has_method("set_target"):
		brain.call("set_target", target)

func _on_player_spawned(player: Player) -> void:
	set_target_for_all_creatures(player)


func _on_chunk_loaded(chunk: OverworldChunk, chunk_coord: Vector2i) -> void:
	var spawned_count: int = spawn_chunk_creatures(chunk, chunk_coord)
	if spawned_count > 0:
		print(
			"OverworldCreatureSpawner: chunk %s spawned %d creature(s)."
			% [str(chunk_coord), spawned_count]
		)


func _on_chunk_unloaded(chunk_coord: Vector2i) -> void:
	var despawned_count: int = despawn_chunk_creatures(chunk_coord)
	if despawned_count > 0:
		print(
			"OverworldCreatureSpawner: chunk %s despawned %d creature(s)."
			% [str(chunk_coord), despawned_count]
		)
