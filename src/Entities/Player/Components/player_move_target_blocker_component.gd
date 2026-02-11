class_name PlayerMoveTargetBlockerComponent
extends Node

## Caches navigation blocker polygons and validates move targets against them.

const SNAP_STEP_PIXELS: float = 4.0
const SNAP_MAX_STEPS: int = 8

@export var blocker_polygon_refresh_interval: float = 0.5
@export var boundary_snap_margin: float = 2.0
@export var prefer_navigation_map_snap: bool = true

var _creature: Creature
var _navigation_agent: NavigationAgent2D
var _cached_blocker_polygons: Array[Polygon2D] = []
var _next_blocker_refresh_msec: int = 0


func _ready() -> void:
	_creature = get_parent() as Creature
	assert(_creature, "PlayerMoveTargetBlockerComponent must be a child of a Creature.")
	_navigation_agent = _creature.get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	_refresh_blocker_polygons_cache()


func is_world_position_blocked(world_position: Vector2) -> bool:
	_refresh_blocker_polygons_cache_if_needed()
	return _is_point_in_cached_polygons(world_position)


## If the requested position is blocked, return the nearest walkable fallback target.
func resolve_world_target(world_position: Vector2) -> Vector2:
	if not is_world_position_blocked(world_position):
		return world_position

	if prefer_navigation_map_snap:
		var nav_candidate: Variant = _get_navigation_snap_candidate(world_position)
		if nav_candidate is Vector2 and not _is_point_in_cached_polygons(nav_candidate):
			return nav_candidate

	var boundary_candidate: Variant = _get_boundary_snap_candidate(world_position)
	if boundary_candidate is Vector2 and not _is_point_in_cached_polygons(boundary_candidate):
		return boundary_candidate

	return world_position


func _is_point_in_cached_polygons(world_position: Vector2) -> bool:
	for polygon in _cached_blocker_polygons:
		if not is_instance_valid(polygon):
			continue
		var local_point: Vector2 = polygon.to_local(world_position)
		if Geometry2D.is_point_in_polygon(local_point, polygon.polygon):
			return true
	return false


func _refresh_blocker_polygons_cache_if_needed() -> void:
	var now_msec: int = Time.get_ticks_msec()
	if now_msec < _next_blocker_refresh_msec and not _cached_blocker_polygons.is_empty():
		return
	_refresh_blocker_polygons_cache()


func _refresh_blocker_polygons_cache() -> void:
	_cached_blocker_polygons.clear()
	_next_blocker_refresh_msec = Time.get_ticks_msec() + int(max(blocker_polygon_refresh_interval, 0.05) * 1000.0)

	if _creature == null:
		return
	var tree := _creature.get_tree()
	if tree == null:
		return

	var root: Node = tree.current_scene if tree.current_scene else tree.root
	if root == null:
		return

	for node in root.find_children("*", "NavigationRegion2D", true, false):
		var region := node as NavigationRegion2D
		if region == null:
			continue
		for child in region.find_children("*", "Polygon2D", true, false):
			var polygon := child as Polygon2D
			if polygon and polygon.polygon.size() >= 3:
				_cached_blocker_polygons.append(polygon)


func _get_navigation_snap_candidate(world_position: Vector2) -> Variant:
	var map_rid: RID = _get_navigation_map_rid()
	if not map_rid.is_valid():
		return null
	if NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		return null
	return NavigationServer2D.map_get_closest_point(map_rid, world_position)


func _get_navigation_map_rid() -> RID:
	if _navigation_agent and _navigation_agent.get_navigation_map().is_valid():
		return _navigation_agent.get_navigation_map()
	if _creature and _creature.get_world_2d():
		return _creature.get_world_2d().navigation_map
	return RID()


func _get_boundary_snap_candidate(world_position: Vector2) -> Variant:
	var best_point: Vector2 = Vector2.ZERO
	var best_center: Vector2 = Vector2.ZERO
	var best_distance_sq: float = INF
	var found: bool = false

	for polygon in _cached_blocker_polygons:
		if not is_instance_valid(polygon):
			continue
		if polygon.polygon.size() < 3:
			continue

		var polygon_center_global: Vector2 = polygon.to_global(_compute_polygon_centroid(polygon.polygon))
		var vertex_count: int = polygon.polygon.size()
		for vertex_i in range(vertex_count):
			var next_i: int = (vertex_i + 1) % vertex_count
			var a: Vector2 = polygon.to_global(polygon.polygon[vertex_i])
			var b: Vector2 = polygon.to_global(polygon.polygon[next_i])
			var point_on_edge: Vector2 = _closest_point_on_segment(world_position, a, b)
			var distance_sq: float = world_position.distance_squared_to(point_on_edge)
			if distance_sq < best_distance_sq:
				best_distance_sq = distance_sq
				best_point = point_on_edge
				best_center = polygon_center_global
				found = true

	if not found:
		return null

	var outward: Vector2 = (best_point - best_center).normalized()
	if outward == Vector2.ZERO:
		outward = (world_position - best_center).normalized()
	if outward == Vector2.ZERO:
		outward = Vector2.RIGHT

	var base_offset: float = max(boundary_snap_margin, 0.5)
	for step_i in range(SNAP_MAX_STEPS):
		var candidate_offset: float = base_offset + SNAP_STEP_PIXELS * float(step_i)
		var candidate: Vector2 = best_point + outward * candidate_offset
		if not _is_point_in_cached_polygons(candidate):
			return candidate

	return best_point + outward * base_offset


func _compute_polygon_centroid(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var sum: Vector2 = Vector2.ZERO
	for point in points:
		sum += point
	return sum / float(points.size())


func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var segment: Vector2 = b - a
	var length_sq: float = segment.length_squared()
	if length_sq <= 0.000001:
		return a
	var t: float = clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return a + segment * t
