class_name NavigationBlockerRegistry
extends Node

## Stage-level registry for navigation blocker polygons.
## Caches polygons once and refreshes on explicit world updates.

signal blocker_polygons_changed(count: int)

@export var search_root_path: NodePath = ^"."
@export var auto_refresh_on_ready: bool = true

var _blocker_polygons: Array[Polygon2D] = []


func _ready() -> void:
	add_to_group("navigation_blocker_registry")
	if auto_refresh_on_ready:
		refresh()


func refresh() -> void:
	_blocker_polygons.clear()

	var root_node: Node = get_node_or_null(search_root_path)
	if root_node == null:
		root_node = get_parent()
	if root_node == null:
		return

	for region_node in root_node.find_children("*", "NavigationRegion2D", true, false):
		var region: NavigationRegion2D = region_node as NavigationRegion2D
		if region == null:
			continue
		for polygon_node in region.find_children("*", "Polygon2D", true, false):
			var polygon: Polygon2D = polygon_node as Polygon2D
			if polygon and polygon.polygon.size() >= 3:
				_blocker_polygons.append(polygon)

	blocker_polygons_changed.emit(_blocker_polygons.size())


func get_blocker_polygons() -> Array[Polygon2D]:
	var valid_polygons: Array[Polygon2D] = []
	for polygon in _blocker_polygons:
		if is_instance_valid(polygon) and polygon.polygon.size() >= 3:
			valid_polygons.append(polygon)
	return valid_polygons
