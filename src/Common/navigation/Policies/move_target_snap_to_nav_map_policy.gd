class_name MoveTargetSnapToNavMapPolicy
extends RefCounted

## Resolves a requested target to the closest point on the navigation map.


func resolve_target(world_position: Vector2, map_rid: RID) -> Variant:
	if not map_rid.is_valid():
		return null
	if NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		return null
	return NavigationServer2D.map_get_closest_point(map_rid, world_position)
