class_name MoveTargetSnapToBoundaryPolicy
extends RefCounted

## Resolves a blocked target by snapping to the nearest polygon boundary point.

const SNAP_STEP_PIXELS: float = 4.0
const SNAP_MAX_STEPS: int = 8


func resolve_target(
	world_position: Vector2,
	blocker_polygons: Array[Polygon2D],
	boundary_snap_margin: float
) -> Variant:
	var best_point: Vector2 = Vector2.ZERO
	var best_center: Vector2 = Vector2.ZERO
	var best_distance_sq: float = INF
	var found: bool = false

	for polygon in blocker_polygons:
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

	var base_offset: float = maxf(boundary_snap_margin, 0.5)
	for step_i in range(SNAP_MAX_STEPS):
		var candidate_offset: float = base_offset + SNAP_STEP_PIXELS * float(step_i)
		var candidate: Vector2 = best_point + outward * candidate_offset
		if not _is_point_in_any_polygon(candidate, blocker_polygons):
			return candidate

	return best_point + outward * base_offset


func _is_point_in_any_polygon(world_position: Vector2, blocker_polygons: Array[Polygon2D]) -> bool:
	for polygon in blocker_polygons:
		if not is_instance_valid(polygon):
			continue
		var local_point: Vector2 = polygon.to_local(world_position)
		if Geometry2D.is_point_in_polygon(local_point, polygon.polygon):
			return true
	return false


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
