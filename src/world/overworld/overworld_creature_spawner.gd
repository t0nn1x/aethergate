class_name OverworldCreatureSpawner
extends Node

## Spawns/despawns creatures and binds them to chunk lifecycle.
## Supports zone-based runtime spawning with legacy marker fallback.

const Creature = preload("res://src/entities/creatures/base/creature.gd")
const CreatureData = preload("res://src/entities/creatures/base/creature_data.gd")

class ZoneSpawnState:
	extends RefCounted

	var zone: Node = null
	var chunk_coord: Vector2i = Vector2i.ZERO
	var candidate_ids: Array[String] = []
	var alive: Array[Creature] = []
	var spawn_budget: float = 0.0
	var initial_remaining: int = 0


const CREATURE_FACTORY_SCRIPT: Script = preload("res://src/entities/creatures/base/creature_factory.gd")
const INVALID_CHUNK_COORD: Vector2i = Vector2i(2147483647, 2147483647)

signal creature_spawned(creature: Creature, chunk_coord: Vector2i)
signal creature_despawned(creature: Creature, chunk_coord: Vector2i)

@export var catalog_service_path: NodePath = ^"CreatureCatalogService"
@export var world_y_sort_path: NodePath = ^"WorldYSort"
@export var chunk_manager_path: NodePath = ^"ChunkManager"
@export var creature_scene: PackedScene = preload("res://src/entities/creatures/base/creature.tscn")

@export_group("Zone Spawning")
@export var enable_zone_spawning: bool = true
@export var allow_legacy_marker_fallback: bool = true
@export_range(0.05, 5.0, 0.05) var zone_tick_interval_seconds: float = 0.5
@export_range(1, 128, 1) var max_spawn_attempts_per_zone_per_tick: int = 16

var _overworld: Overworld
var _factory
var _catalog_service
var _chunk_manager
var _navigation_blocker_registry: NavigationBlockerRegistry
var _spawned_by_chunk: Dictionary = {}
var _zone_states_by_chunk: Dictionary = {}
var _spawn_tick_accumulator: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _cached_spawn_blocker_polygons: Array[Polygon2D] = []
var _spawn_blocker_reject_policy: MoveTargetRejectInsidePolygonPolicy = MoveTargetRejectInsidePolygonPolicy.new()
var _warned_missing_navigation_blocker_registry: bool = false


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

	call_deferred("_resolve_spawn_blocker_registry")
	_rng.randomize()


func _process(delta: float) -> void:
	if not enable_zone_spawning:
		return
	if _zone_states_by_chunk.is_empty():
		return

	_spawn_tick_accumulator += delta
	if _spawn_tick_accumulator < maxf(zone_tick_interval_seconds, 0.05):
		return

	var tick_delta: float = _spawn_tick_accumulator
	_spawn_tick_accumulator = 0.0
	_tick_zone_spawning(tick_delta)


func spawn_creature_by_id(
	creature_id: String,
	world_position: Vector2,
	chunk_coord: Vector2i = INVALID_CHUNK_COORD
) -> Creature:
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
	_wire_spawned_creature_navigation_dependencies(creature)
	_register_chunk_spawn(chunk_coord, creature)
	creature_spawned.emit(creature, chunk_coord)
	return creature


func despawn_chunk_creatures(chunk_coord: Vector2i) -> int:
	var despawned_count: int = 0
	if _spawned_by_chunk.has(chunk_coord):
		var spawned: Array = _spawned_by_chunk.get(chunk_coord, []) as Array
		for node_variant in spawned:
			if not is_instance_valid(node_variant):
				continue
			var creature: Creature = node_variant as Creature
			if creature and is_instance_valid(creature):
				creature_despawned.emit(creature, chunk_coord)
				creature.queue_free()
				despawned_count += 1
		_spawned_by_chunk.erase(chunk_coord)

	_clear_chunk_zone_states(chunk_coord)
	return despawned_count


func despawn_creature(creature: Creature) -> void:
	if creature == null or not is_instance_valid(creature):
		return
	var found_chunk_coord: Vector2i = INVALID_CHUNK_COORD
	for chunk_coord_variant in _spawned_by_chunk.keys():
		var chunk_coord: Vector2i = chunk_coord_variant as Vector2i
		var spawned: Array = _spawned_by_chunk.get(chunk_coord, []) as Array
		if spawned.has(creature):
			spawned.erase(creature)
			found_chunk_coord = chunk_coord
			break
	creature_despawned.emit(creature, found_chunk_coord)
	creature.queue_free()


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
	_zone_states_by_chunk.clear()


func get_active_zone_count() -> int:
	var count: int = 0
	for chunk_coord_variant in _zone_states_by_chunk.keys():
		var chunk_coord: Vector2i = chunk_coord_variant
		var states: Array[ZoneSpawnState] = _zone_states_by_chunk.get(chunk_coord, []) as Array[ZoneSpawnState]
		count += states.size()
	return count


func get_alive_creature_count() -> int:
	var count: int = 0
	for chunk_coord_variant in _spawned_by_chunk.keys():
		var chunk_coord: Vector2i = chunk_coord_variant
		var spawned: Array = _spawned_by_chunk.get(chunk_coord, []) as Array
		for node_variant in spawned:
			var creature: Creature = node_variant as Creature
			if creature and is_instance_valid(creature) and not creature.is_queued_for_deletion():
				count += 1
	return count


func get_zone_spawn_debug_lines() -> Array[String]:
	var lines: Array[String] = []
	if _zone_states_by_chunk.is_empty():
		lines.append("SpawnZones: 0")
		return lines

	var total_zones: int = get_active_zone_count()
	lines.append("SpawnZones: %d" % total_zones)

	var chunk_coords: Array[Vector2i] = []
	for chunk_coord_variant in _zone_states_by_chunk.keys():
		chunk_coords.append(chunk_coord_variant as Vector2i)
	chunk_coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	)

	for chunk_coord in chunk_coords:
		var states: Array[ZoneSpawnState] = _zone_states_by_chunk.get(chunk_coord, []) as Array[ZoneSpawnState]
		var alive_count: int = 0
		for state in states:
			alive_count += _count_valid_zone_alive(state)
		lines.append(
			"ZoneChunk (%d,%d): %d zone(s), %d alive"
			% [chunk_coord.x, chunk_coord.y, states.size(), alive_count]
		)
	return lines


func _register_chunk_spawn(chunk_coord: Vector2i, creature: Creature) -> void:
	if not _spawned_by_chunk.has(chunk_coord):
		_spawned_by_chunk[chunk_coord] = []
	(_spawned_by_chunk[chunk_coord] as Array).append(creature)


func _wire_spawned_creature_navigation_dependencies(creature: Creature) -> void:
	if creature == null or _overworld == null:
		return

	var blocker_registry: NavigationBlockerRegistry = _overworld.get_navigation_blocker_registry()
	if blocker_registry == null:
		if OS.is_debug_build():
			print("[CreatureSpawner] blocker registry unavailable for '%s'." % creature.name)
		return

	var blocker_component: PlayerMoveTargetBlockerComponent = creature.get_node_or_null(
		"PlayerMoveTargetBlockerComponent"
	) as PlayerMoveTargetBlockerComponent
	if blocker_component == null:
		if OS.is_debug_build():
			print("[CreatureSpawner] blocker component missing on '%s'." % creature.name)
		return

	blocker_component.set_blocker_registry(blocker_registry)
	if OS.is_debug_build():
		print("[CreatureSpawner] blocker registry wired for '%s'." % creature.name)


func _resolve_marker_creature_id(marker: Marker2D) -> String:
	if marker.has_meta("creature_id"):
		return String(marker.get_meta("creature_id")).strip_edges().to_lower()
	if marker.name.begins_with("Spawn_"):
		return marker.name.trim_prefix("Spawn_").strip_edges().to_lower()
	return ""


func _on_chunk_loaded(chunk: OverworldChunk, chunk_coord: Vector2i) -> void:
	var registered_zone_count: int = _register_chunk_zones(chunk, chunk_coord)
	if registered_zone_count > 0:
		var initial_spawned: int = _spawn_initial_zone_creatures(chunk_coord)
		print(
			"OverworldCreatureSpawner: chunk %s registered %d zone(s), initial spawn %d creature(s)."
			% [str(chunk_coord), registered_zone_count, initial_spawned]
		)
		return

	if not allow_legacy_marker_fallback:
		return

	var spawned_count: int = spawn_chunk_creatures(chunk, chunk_coord)
	if spawned_count > 0:
		print(
			"OverworldCreatureSpawner: chunk %s spawned %d creature(s) from markers."
			% [str(chunk_coord), spawned_count]
		)


func _on_chunk_unloaded(chunk_coord: Vector2i) -> void:
	var despawned_count: int = despawn_chunk_creatures(chunk_coord)
	if despawned_count > 0:
		print(
			"OverworldCreatureSpawner: chunk %s despawned %d creature(s)."
			% [str(chunk_coord), despawned_count]
		)


func _register_chunk_zones(chunk: OverworldChunk, chunk_coord: Vector2i) -> int:
	if not enable_zone_spawning:
		return 0
	if chunk == null:
		return 0
	if not chunk.has_method("get_creature_spawn_zones"):
		return 0
	if _catalog_service == null:
		return 0

	var zones: Array = chunk.get_creature_spawn_zones() as Array
	if zones.is_empty():
		return 0

	var states: Array[ZoneSpawnState] = []
	for zone in zones:
		if zone == null:
			continue
		if not _zone_is_config_valid(zone):
			continue

		var candidate_ids: Array[String] = _resolve_zone_candidate_ids(zone)
		if candidate_ids.is_empty():
			push_warning(
				"OverworldCreatureSpawner: zone '%s' in chunk %s has no valid creature candidates."
				% [zone.name, str(chunk_coord)]
			)
			continue

		var state := ZoneSpawnState.new()
		state.zone = zone
		state.chunk_coord = chunk_coord
		state.candidate_ids = candidate_ids
		state.initial_remaining = mini(
			_zone_get_initial_spawn_count(zone),
			_zone_get_effective_max_alive(zone)
		)
		states.append(state)

	if states.is_empty():
		return 0

	_zone_states_by_chunk[chunk_coord] = states
	return states.size()


func _resolve_zone_candidate_ids(zone: Node) -> Array[String]:
	var dedup: Dictionary = {}

	for creature_id in _zone_get_normalized_creature_ids(zone):
		var creature_data: CreatureData = _catalog_service.call("get_by_id", creature_id) as CreatureData
		if creature_data:
			dedup[creature_data.get_effective_creature_id()] = true

	for type_value in _zone_get_sanitized_creature_type_values(zone):
		var by_type: Array[CreatureData] = _catalog_service.call("get_by_type", type_value) as Array[CreatureData]
		for creature_data in by_type:
			if creature_data:
				dedup[creature_data.get_effective_creature_id()] = true

	for category in _zone_get_normalized_source_categories(zone):
		var by_category: Array[CreatureData] = _catalog_service.call(
			"get_by_source_category",
			category
		) as Array[CreatureData]
		for creature_data in by_category:
			if creature_data:
				dedup[creature_data.get_effective_creature_id()] = true

	var candidate_ids: Array[String] = []
	for key in dedup.keys():
		candidate_ids.append(String(key))
	candidate_ids.sort()
	return candidate_ids


func _spawn_initial_zone_creatures(chunk_coord: Vector2i) -> int:
	if not _zone_states_by_chunk.has(chunk_coord):
		return 0

	var states: Array[ZoneSpawnState] = _zone_states_by_chunk.get(chunk_coord, []) as Array[ZoneSpawnState]
	var total_spawned: int = 0
	for state in states:
		if state == null or state.zone == null:
			continue
		if state.initial_remaining <= 0:
			continue
		var spawned: int = _try_spawn_zone_creatures(state, state.initial_remaining)
		state.initial_remaining = maxi(state.initial_remaining - spawned, 0)
		total_spawned += spawned
	return total_spawned


func _tick_zone_spawning(delta: float) -> void:
	var chunk_coords: Array[Vector2i] = []
	for chunk_coord_variant in _zone_states_by_chunk.keys():
		chunk_coords.append(chunk_coord_variant as Vector2i)

	for chunk_coord in chunk_coords:
		var states: Array[ZoneSpawnState] = _zone_states_by_chunk.get(chunk_coord, []) as Array[ZoneSpawnState]
		for state in states:
			if state == null or state.zone == null:
				continue

			_cleanup_zone_alive(state)

			if state.initial_remaining > 0:
				var initial_spawned: int = _try_spawn_zone_creatures(state, state.initial_remaining)
				state.initial_remaining = maxi(state.initial_remaining - initial_spawned, 0)

			var spawn_rate_per_second: float = maxf(_zone_get_spawn_rate_per_minute(state.zone), 0.0) / 60.0
			state.spawn_budget += spawn_rate_per_second * delta
			state.spawn_budget = minf(state.spawn_budget, float(_zone_get_effective_max_alive(state.zone)))

			var budget_spawn_count: int = int(floor(state.spawn_budget))
			if budget_spawn_count <= 0:
				continue
			var spawned_from_budget: int = _try_spawn_zone_creatures(state, budget_spawn_count)
			state.spawn_budget = maxf(state.spawn_budget - float(spawned_from_budget), 0.0)


func _try_spawn_zone_creatures(state: ZoneSpawnState, requested_count: int) -> int:
	if state == null or state.zone == null:
		return 0
	if requested_count <= 0:
		return 0
	if state.candidate_ids.is_empty():
		return 0

	var alive_count: int = _count_valid_zone_alive(state)
	var open_slots: int = max(_zone_get_effective_max_alive(state.zone) - alive_count, 0)
	if open_slots <= 0:
		return 0

	var target_count: int = mini(requested_count, open_slots)
	var attempts_per_spawn: int = mini(
		_zone_get_effective_spawn_attempts_per_tick(state.zone),
		maxi(max_spawn_attempts_per_zone_per_tick, 1)
	)
	var max_attempts: int = maxi(target_count * attempts_per_spawn, target_count)

	var spawned_count: int = 0
	for _attempt in max_attempts:
		if spawned_count >= target_count:
			break

		var sample: Variant = _zone_sample_world_position(state.zone, _rng, attempts_per_spawn)
		if sample is not Vector2:
			continue
		var world_position: Vector2 = sample as Vector2
		if not _is_zone_spawn_position_valid(state.zone, world_position):
			continue

		var creature_id: String = _pick_zone_candidate_id(state)
		if creature_id.is_empty():
			break

		var creature: Creature = spawn_creature_by_id(creature_id, world_position, state.chunk_coord)
		if creature == null:
			continue
		state.alive.append(creature)
		spawned_count += 1

	return spawned_count


func _pick_zone_candidate_id(state: ZoneSpawnState) -> String:
	if state == null or state.candidate_ids.is_empty():
		return ""
	var index: int = _rng.randi_range(0, state.candidate_ids.size() - 1)
	return state.candidate_ids[index]


func _is_zone_spawn_position_valid(zone: Node, world_position: Vector2) -> bool:
	if zone == null:
		return false
	if not _zone_contains_world_position(zone, world_position):
		return false
	if _is_world_position_blocked_for_spawns(world_position):
		return false

	var local_player: Player = _overworld.get_local_player()
	if local_player == null or not is_instance_valid(local_player):
		return true

	var distance_to_player: float = world_position.distance_to(local_player.global_position)
	if distance_to_player < maxf(_zone_get_min_distance_to_player(zone), 0.0):
		return false
	var max_distance_to_player: float = _zone_get_max_distance_to_player(zone)
	if max_distance_to_player > 0.0 and distance_to_player > max_distance_to_player:
		return false
	return true


func _zone_is_config_valid(zone: Node) -> bool:
	if zone == null:
		return false
	if not zone.has_method("is_config_valid"):
		push_warning("OverworldCreatureSpawner: zone '%s' is missing is_config_valid()." % zone.name)
		return false
	return bool(zone.call("is_config_valid", "OverworldCreatureSpawner"))


func _zone_get_effective_max_alive(zone: Node) -> int:
	if zone == null:
		return 0
	if zone.has_method("get_effective_max_alive"):
		return maxi(int(zone.call("get_effective_max_alive")), 0)
	return maxi(int(zone.get("max_alive")), 0)


func _zone_get_initial_spawn_count(zone: Node) -> int:
	if zone == null:
		return 0
	return maxi(int(zone.get("initial_spawn_count")), 0)


func _zone_get_effective_spawn_attempts_per_tick(zone: Node) -> int:
	if zone == null:
		return 1
	if zone.has_method("get_effective_spawn_attempts_per_tick"):
		return maxi(int(zone.call("get_effective_spawn_attempts_per_tick")), 1)
	return maxi(int(zone.get("spawn_attempts_per_tick")), 1)


func _zone_get_spawn_rate_per_minute(zone: Node) -> float:
	if zone == null:
		return 0.0
	return maxf(float(zone.get("spawn_rate_per_minute")), 0.0)


func _zone_get_min_distance_to_player(zone: Node) -> float:
	if zone == null:
		return 0.0
	return maxf(float(zone.get("min_distance_to_player")), 0.0)


func _zone_get_max_distance_to_player(zone: Node) -> float:
	if zone == null:
		return 0.0
	return maxf(float(zone.get("max_distance_to_player")), 0.0)


func _zone_get_normalized_creature_ids(zone: Node) -> Array[String]:
	if zone == null or not zone.has_method("get_normalized_creature_ids"):
		return []
	var values: Variant = zone.call("get_normalized_creature_ids")
	if values is Array:
		var typed: Array[String] = []
		for value in values:
			typed.append(String(value))
		return typed
	return []


func _zone_get_sanitized_creature_type_values(zone: Node) -> Array[int]:
	if zone == null or not zone.has_method("get_sanitized_creature_type_values"):
		return []
	var values: Variant = zone.call("get_sanitized_creature_type_values")
	if values is Array:
		var typed: Array[int] = []
		for value in values:
			typed.append(int(value))
		return typed
	return []


func _zone_get_normalized_source_categories(zone: Node) -> Array[String]:
	if zone == null or not zone.has_method("get_normalized_source_categories"):
		return []
	var values: Variant = zone.call("get_normalized_source_categories")
	if values is Array:
		var typed: Array[String] = []
		for value in values:
			typed.append(String(value))
		return typed
	return []


func _zone_sample_world_position(zone: Node, rng: RandomNumberGenerator, max_attempts: int) -> Variant:
	if zone == null or not zone.has_method("sample_world_position"):
		return null
	return zone.call("sample_world_position", rng, max_attempts)


func _zone_contains_world_position(zone: Node, world_position: Vector2) -> bool:
	if zone == null or not zone.has_method("contains_world_position"):
		return false
	return bool(zone.call("contains_world_position", world_position))


func _cleanup_zone_alive(state: ZoneSpawnState) -> void:
	if state == null:
		return
	var valid_alive: Array[Creature] = []
	for creature in state.alive:
		if creature and is_instance_valid(creature) and not creature.is_queued_for_deletion():
			valid_alive.append(creature)
	state.alive = valid_alive


func _count_valid_zone_alive(state: ZoneSpawnState) -> int:
	if state == null:
		return 0
	_cleanup_zone_alive(state)
	return state.alive.size()


func _clear_chunk_zone_states(chunk_coord: Vector2i) -> void:
	if not _zone_states_by_chunk.has(chunk_coord):
		return
	_zone_states_by_chunk.erase(chunk_coord)


func _resolve_spawn_blocker_registry() -> void:
	if _overworld == null:
		return
	var registry: NavigationBlockerRegistry = _overworld.get_navigation_blocker_registry()
	_set_spawn_blocker_registry(registry)
	if registry == null and OS.is_debug_build() and not _warned_missing_navigation_blocker_registry:
		_warned_missing_navigation_blocker_registry = true
		push_warning(
			"OverworldCreatureSpawner: NavigationBlockerRegistry missing; "
			+ "zone spawns will not filter blocked polygons."
		)


func _set_spawn_blocker_registry(registry: NavigationBlockerRegistry) -> void:
	if (
		_navigation_blocker_registry
		and _navigation_blocker_registry.blocker_polygons_changed.is_connected(
			_on_spawn_blocker_polygons_changed
		)
	):
		_navigation_blocker_registry.blocker_polygons_changed.disconnect(
			_on_spawn_blocker_polygons_changed
		)

	_navigation_blocker_registry = registry
	if (
		_navigation_blocker_registry
		and not _navigation_blocker_registry.blocker_polygons_changed.is_connected(
			_on_spawn_blocker_polygons_changed
		)
	):
		_navigation_blocker_registry.blocker_polygons_changed.connect(_on_spawn_blocker_polygons_changed)

	_refresh_spawn_blocker_polygons()


func _refresh_spawn_blocker_polygons() -> void:
	_cached_spawn_blocker_polygons.clear()
	if _navigation_blocker_registry == null:
		return
	_cached_spawn_blocker_polygons = _navigation_blocker_registry.get_blocker_polygons()


func _on_spawn_blocker_polygons_changed(_count: int) -> void:
	_refresh_spawn_blocker_polygons()


func _is_world_position_blocked_for_spawns(world_position: Vector2) -> bool:
	if _navigation_blocker_registry == null:
		_resolve_spawn_blocker_registry()
	if _cached_spawn_blocker_polygons.is_empty():
		return false
	return _spawn_blocker_reject_policy.is_blocked(world_position, _cached_spawn_blocker_polygons)
