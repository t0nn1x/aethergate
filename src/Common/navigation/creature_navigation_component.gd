class_name CreatureNavigationComponent
extends Node

## Shared navigation/pathfinding helper for any Creature.
## Requires a NavigationAgent2D child on the creature (auto-created if missing).

@export var navigation_agent_path: NodePath = ^"NavigationAgent2D"
@export var project_config_service_path: NodePath = ^"/root/ProjectConfig"
@export var path_desired_distance: float = 4.0
@export var target_desired_distance: float = 6.0
@export var avoidance_enabled: bool = true
@export var agent_radius: float = 14.0
@export var max_target_snap_distance: float = 2048.0
@export var movement_config = preload("res://src/Entities/player/config/player_movement_config.tres")

var creature: Creature
var navigation_agent: NavigationAgent2D
var _has_active_target: bool = false
var _last_target_reject_reason: String = ""
var _last_safe_velocity: Vector2 = Vector2.ZERO
var _has_safe_velocity: bool = false


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "CreatureNavigationComponent must be a child of a Creature.")

	navigation_agent = creature.get_node_or_null(navigation_agent_path) as NavigationAgent2D
	if navigation_agent == null:
		navigation_agent = NavigationAgent2D.new()
		navigation_agent.name = "NavigationAgent2D"
		creature.add_child(navigation_agent)

	_apply_project_config()
	_apply_movement_config()
	_apply_agent_settings()
	if not navigation_agent.velocity_computed.is_connected(_on_navigation_agent_velocity_computed):
		navigation_agent.velocity_computed.connect(_on_navigation_agent_velocity_computed)


## Set a target world position. Returns false when no reachable snapped target was found.
func set_target_position(world_pos: Vector2) -> bool:
	if not creature or not navigation_agent:
		return false

	var snapped_target: Variant = _get_snapped_target_position(world_pos)
	if snapped_target == null:
		if OS.is_debug_build():
			push_warning("CreatureNavigationComponent: target rejected (%s)." % _last_target_reject_reason)
		return false

	navigation_agent.target_position = snapped_target as Vector2
	_has_active_target = true
	_has_safe_velocity = false
	_last_safe_velocity = Vector2.ZERO
	return true


## Clear the current path target.
func clear_target() -> void:
	_has_active_target = false
	_has_safe_velocity = false
	_last_safe_velocity = Vector2.ZERO
	if creature and navigation_agent:
		navigation_agent.target_position = creature.global_position


## True when a target is currently tracked and still not completed.
func has_active_target() -> bool:
	if not _has_active_target:
		return false
	if not navigation_agent:
		return false
	if navigation_agent.is_navigation_finished():
		_has_active_target = false
		return false
	return true


## True when there is no active target or when the active path was completed.
func is_navigation_finished() -> bool:
	return not has_active_target()


## Returns the normalized movement direction to the next path point.
func get_navigation_direction(current_pos: Vector2) -> Vector2:
	if not has_active_target():
		return Vector2.ZERO

	var next_position: Vector2 = navigation_agent.get_next_path_position()
	var delta: Vector2 = next_position - current_pos
	if delta.length_squared() <= 0.0001:
		return Vector2.ZERO

	var desired_direction: Vector2 = delta.normalized()
	if not navigation_agent.avoidance_enabled:
		return desired_direction

	# Feed desired velocity into avoidance simulation and use the latest safe velocity.
	navigation_agent.velocity = desired_direction
	if _has_safe_velocity and _last_safe_velocity.length_squared() > 0.0001:
		return _last_safe_velocity.normalized()
	return desired_direction


func _apply_agent_settings() -> void:
	if not navigation_agent:
		return
	navigation_agent.path_desired_distance = max(path_desired_distance, 0.0)
	navigation_agent.target_desired_distance = max(target_desired_distance, 0.0)
	navigation_agent.avoidance_enabled = avoidance_enabled
	navigation_agent.radius = max(agent_radius, 0.1)
	if creature:
		navigation_agent.max_speed = max(creature.movement_speed, 1.0)


func _apply_movement_config() -> void:
	if movement_config == null:
		return
	path_desired_distance = movement_config.path_desired_distance
	target_desired_distance = movement_config.target_desired_distance
	avoidance_enabled = movement_config.avoidance_enabled
	agent_radius = movement_config.agent_radius
	max_target_snap_distance = movement_config.max_target_snap_distance


func _apply_project_config() -> void:
	if project_config_service_path == NodePath():
		return

	var project_config_service: ProjectConfigService = _resolve_project_config_service()
	if project_config_service == null:
		if OS.is_debug_build():
			push_warning("CreatureNavigationComponent: ProjectConfig autoload is missing.")
		return

	var project_movement_config = project_config_service.get_player_movement_config()
	if project_movement_config != null:
		movement_config = project_movement_config


func _resolve_project_config_service() -> ProjectConfigService:
	if project_config_service_path == NodePath():
		return null
	return get_node_or_null(project_config_service_path) as ProjectConfigService


func _on_navigation_agent_velocity_computed(safe_velocity: Vector2) -> void:
	_last_safe_velocity = safe_velocity
	_has_safe_velocity = true


func get_last_target_reject_reason() -> String:
	return _last_target_reject_reason


func _get_snapped_target_position(requested_world_pos: Vector2) -> Variant:
	_last_target_reject_reason = ""

	var map_rid: RID = navigation_agent.get_navigation_map()
	if not map_rid.is_valid():
		_last_target_reject_reason = "navigation map RID is invalid"
		return null

	# NavigationServer returns useful closest-point/path data only after at least one sync tick.
	if NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		_last_target_reject_reason = "navigation map not synchronized yet (iteration=0)"
		return null

	var snapped_target: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, requested_world_pos)
	var snap_distance: float = snapped_target.distance_to(requested_world_pos)
	if snap_distance > max_target_snap_distance:
		_last_target_reject_reason = "nearest nav point too far (%.1f > %.1f)" % [snap_distance, max_target_snap_distance]
		return null

	var snapped_origin: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, creature.global_position)
	var path: PackedVector2Array = NavigationServer2D.map_get_path(
		map_rid,
		snapped_origin,
		snapped_target,
		true
	)
	if path.is_empty():
		_last_target_reject_reason = "no path found between snapped origin and target"
		return null

	return snapped_target
