class_name PlayerMoveTargetBlockerComponent
extends Node

## Resolves movement targets through a pluggable policy chain.
## Blocker polygons are provided by NavigationBlockerRegistry (no scene polling).

@export var blocker_registry_path: NodePath = ^"../../NavigationBlockerRegistry"
@export var boundary_snap_margin: float = 2.0
@export var prefer_navigation_map_snap: bool = true
@export var blocker_polygon_refresh_interval: float = 0.5  ## Deprecated, kept for backward compatibility.

var _creature: Creature
var _navigation_agent: NavigationAgent2D
var _blocker_registry: NavigationBlockerRegistry
var _cached_blocker_polygons: Array[Polygon2D] = []

var _reject_inside_policy: MoveTargetRejectInsidePolygonPolicy = MoveTargetRejectInsidePolygonPolicy.new()
var _snap_to_nav_map_policy: MoveTargetSnapToNavMapPolicy = MoveTargetSnapToNavMapPolicy.new()
var _snap_to_boundary_policy: MoveTargetSnapToBoundaryPolicy = MoveTargetSnapToBoundaryPolicy.new()


func _ready() -> void:
	_creature = get_parent() as Creature
	assert(_creature, "PlayerMoveTargetBlockerComponent must be a child of a Creature.")
	_navigation_agent = _creature.get_node_or_null("NavigationAgent2D") as NavigationAgent2D
	_resolve_blocker_registry_from_path()
	_refresh_blocker_polygons_from_registry()


func is_world_position_blocked(world_position: Vector2) -> bool:
	return _reject_inside_policy.is_blocked(world_position, _cached_blocker_polygons)


## If the requested position is blocked, return the nearest walkable fallback target.
func resolve_world_target(world_position: Vector2) -> Vector2:
	if not is_world_position_blocked(world_position):
		return world_position

	if prefer_navigation_map_snap:
		var map_rid: RID = _get_navigation_map_rid()
		var nav_candidate: Variant = _snap_to_nav_map_policy.resolve_target(world_position, map_rid)
		if nav_candidate is Vector2 and not is_world_position_blocked(nav_candidate):
			return nav_candidate

	var boundary_candidate: Variant = _snap_to_boundary_policy.resolve_target(
		world_position,
		_cached_blocker_polygons,
		boundary_snap_margin
	)
	if boundary_candidate is Vector2 and not is_world_position_blocked(boundary_candidate):
		return boundary_candidate

	return world_position


func set_blocker_registry(registry: NavigationBlockerRegistry) -> void:
	if _blocker_registry and _blocker_registry.blocker_polygons_changed.is_connected(_on_blocker_polygons_changed):
		_blocker_registry.blocker_polygons_changed.disconnect(_on_blocker_polygons_changed)
	_blocker_registry = registry
	if _blocker_registry and not _blocker_registry.blocker_polygons_changed.is_connected(_on_blocker_polygons_changed):
		_blocker_registry.blocker_polygons_changed.connect(_on_blocker_polygons_changed)
	_refresh_blocker_polygons_from_registry()


func _resolve_blocker_registry_from_path() -> void:
	if blocker_registry_path == NodePath():
		return

	var resolved_registry: NavigationBlockerRegistry = _creature.get_node_or_null(
		blocker_registry_path
	) as NavigationBlockerRegistry
	if resolved_registry == null:
		if OS.is_debug_build():
			push_warning("PlayerMoveTargetBlockerComponent: NavigationBlockerRegistry not found.")
		return
	set_blocker_registry(resolved_registry)


func _refresh_blocker_polygons_from_registry() -> void:
	_cached_blocker_polygons.clear()
	if _blocker_registry == null:
		return
	_cached_blocker_polygons = _blocker_registry.get_blocker_polygons()


func _on_blocker_polygons_changed(_count: int) -> void:
	_refresh_blocker_polygons_from_registry()


func _get_navigation_map_rid() -> RID:
	if _navigation_agent and _navigation_agent.get_navigation_map().is_valid():
		return _navigation_agent.get_navigation_map()
	if _creature and _creature.get_world_2d():
		return _creature.get_world_2d().navigation_map
	return RID()
