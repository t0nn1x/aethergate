@tool
class_name CreatureSpawnZone2D
extends Polygon2D

## Author-time + runtime helper for creature spawn zones.
## Zone geometry comes from Polygon2D.polygon points.

const CreatureData = preload("res://src/entities/creatures/base/creature_data.gd")

@export_group("Spawn")
@export var enabled: bool = true
@export_range(0.0, 600.0, 0.1) var spawn_rate_per_minute: float = 4.0
@export_range(0, 512, 1) var max_alive: int = 3
@export_range(0, 512, 1) var initial_spawn_count: int = 1
@export_range(1, 64, 1) var spawn_attempts_per_tick: int = 6

@export_group("Filters")
## Explicit IDs take precedence and can be combined with type/category filters.
@export var allowed_creature_ids: PackedStringArray = PackedStringArray()
@export var allowed_creature_types: PackedInt32Array = PackedInt32Array()
@export var allowed_source_categories: PackedStringArray = PackedStringArray()

@export_group("Player Distance")
@export_range(0.0, 4096.0, 1.0) var min_distance_to_player: float = 96.0
## 0 disables max-distance validation.
@export_range(0.0, 8192.0, 1.0) var max_distance_to_player: float = 0.0


func is_config_valid(log_prefix: String = "") -> bool:
	var prefix: String = "CreatureSpawnZone2D"
	if not log_prefix.is_empty():
		prefix = log_prefix

	if not enabled:
		return false
	if polygon.size() < 3:
		push_warning("%s: zone '%s' polygon must have at least 3 points." % [prefix, name])
		return false
	if max_alive <= 0:
		push_warning("%s: zone '%s' max_alive must be > 0." % [prefix, name])
		return false
	if spawn_attempts_per_tick <= 0:
		push_warning("%s: zone '%s' spawn_attempts_per_tick must be > 0." % [prefix, name])
		return false
	if max_distance_to_player > 0.0 and max_distance_to_player < min_distance_to_player:
		push_warning(
			"%s: zone '%s' max_distance_to_player must be 0 or >= min_distance_to_player."
			% [prefix, name]
		)
		return false
	if not has_spawn_filters():
		push_warning("%s: zone '%s' has no creature filters configured." % [prefix, name])
		return false
	return true


func has_spawn_filters() -> bool:
	return (
		not get_normalized_creature_ids().is_empty()
		or not get_sanitized_creature_type_values().is_empty()
		or not get_normalized_source_categories().is_empty()
	)


func get_effective_spawn_attempts_per_tick() -> int:
	return maxi(spawn_attempts_per_tick, 1)


func get_effective_max_alive() -> int:
	return maxi(max_alive, 0)


func get_normalized_creature_ids() -> Array[String]:
	var dedup: Dictionary = {}
	for value in allowed_creature_ids:
		var normalized: String = String(value).strip_edges().to_lower()
		if normalized.is_empty():
			continue
		dedup[normalized] = true

	var ids: Array[String] = []
	for key in dedup.keys():
		ids.append(String(key))
	ids.sort()
	return ids


func get_sanitized_creature_type_values() -> Array[int]:
	var dedup: Dictionary = {}
	for type_value in allowed_creature_types:
		var as_int: int = int(type_value)
		if as_int < 0 or as_int >= CreatureData.CreatureType.size():
			continue
		dedup[as_int] = true

	var values: Array[int] = []
	for key in dedup.keys():
		values.append(int(key))
	values.sort()
	return values


func get_normalized_source_categories() -> Array[String]:
	var dedup: Dictionary = {}
	for value in allowed_source_categories:
		var normalized: String = String(value).strip_edges().to_lower()
		if normalized.is_empty():
			continue
		dedup[normalized] = true

	var categories: Array[String] = []
	for key in dedup.keys():
		categories.append(String(key))
	categories.sort()
	return categories


func contains_world_position(world_position: Vector2) -> bool:
	if polygon.size() < 3:
		return false
	var local_point: Vector2 = to_local(world_position)
	return Geometry2D.is_point_in_polygon(local_point, polygon)


func sample_world_position(rng: RandomNumberGenerator, max_attempts: int = 12) -> Variant:
	if polygon.size() < 3:
		return null

	var attempts: int = maxi(max_attempts, 1)
	var bounds: Rect2 = _get_polygon_bounds()
	for _i in attempts:
		var local_point := Vector2(
			rng.randf_range(bounds.position.x, bounds.end.x),
			rng.randf_range(bounds.position.y, bounds.end.y)
		)
		if Geometry2D.is_point_in_polygon(local_point, polygon):
			return to_global(local_point)

	var centroid: Vector2 = _get_polygon_centroid()
	if Geometry2D.is_point_in_polygon(centroid, polygon):
		return to_global(centroid)

	return to_global(polygon[0])


func _get_polygon_bounds() -> Rect2:
	var first: Vector2 = polygon[0]
	var min_x: float = first.x
	var max_x: float = first.x
	var min_y: float = first.y
	var max_y: float = first.y

	for point in polygon:
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)

	return Rect2(
		Vector2(min_x, min_y),
		Vector2(maxf(max_x - min_x, 0.001), maxf(max_y - min_y, 0.001))
	)


func _get_polygon_centroid() -> Vector2:
	if polygon.is_empty():
		return Vector2.ZERO
	var total: Vector2 = Vector2.ZERO
	for point in polygon:
		total += point
	return total / float(polygon.size())
