class_name MoveTargetRejectInsidePolygonPolicy
extends RefCounted

## Rejects targets that land inside any blocker polygon.


func is_blocked(world_position: Vector2, blocker_polygons: Array[Polygon2D]) -> bool:
	for polygon in blocker_polygons:
		if not is_instance_valid(polygon):
			continue
		var local_point: Vector2 = polygon.to_local(world_position)
		if Geometry2D.is_point_in_polygon(local_point, polygon.polygon):
			return true
	return false
