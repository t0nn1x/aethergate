class_name PlayerMoveRequestService
extends Node

## Applies player move requests: target resolution + nav request + pointer event.

signal move_target_queued(world_position: Vector2, from_hold: bool)

@export var navigation_component_path: NodePath = ^"../CreatureNavigationComponent"
@export var target_blocker_path: NodePath = ^"../PlayerMoveTargetBlockerComponent"
@export var reject_targets_inside_navigation_polygons: bool = true

var _creature: Creature
var _navigation_component: CreatureNavigationComponent
var _target_blocker: PlayerMoveTargetBlockerComponent
var _warned_missing_target_blocker: bool = false


func _ready() -> void:
	_creature = get_parent() as Creature
	assert(_creature, "PlayerMoveRequestService must be a child of a Creature.")

	# Resolve siblings relative to this service node.
	_navigation_component = get_node_or_null(navigation_component_path) as CreatureNavigationComponent
	if _navigation_component == null and _creature:
		_navigation_component = _creature.get_node_or_null("CreatureNavigationComponent") as CreatureNavigationComponent
	if _navigation_component == null and OS.is_debug_build():
		push_warning("PlayerMoveRequestService: CreatureNavigationComponent is missing.")

	_target_blocker = get_node_or_null(target_blocker_path) as PlayerMoveTargetBlockerComponent
	if _target_blocker == null and _creature:
		_target_blocker = _creature.get_node_or_null("PlayerMoveTargetBlockerComponent") as PlayerMoveTargetBlockerComponent
	if _target_blocker == null and reject_targets_inside_navigation_polygons and OS.is_debug_build():
		push_warning("PlayerMoveRequestService: PlayerMoveTargetBlockerComponent is missing.")


## Returns applied (possibly resolved) move target, or null when rejected.
func request_move_target(world_position: Vector2, from_hold: bool = false) -> Variant:
	if not _creature or not _creature.is_alive:
		return null
	if _creature.has_method("has_input_authority") and not bool(_creature.call("has_input_authority")):
		return null
	if _navigation_component == null:
		return null

	var resolved_world_position: Vector2 = _resolve_blocked_world_target(world_position)
	if _is_world_position_in_blocked_polygon(resolved_world_position):
		if OS.is_debug_build():
			print(
				"[FIX][MoveTarget] rejected_blocked requested=%s resolved=%s from_hold=%s"
				% [world_position, resolved_world_position, from_hold]
			)
		return null
	if not _navigation_component.set_target_position(resolved_world_position):
		if OS.is_debug_build():
			print(
				"[FIX][MoveTarget] rejected_navigation requested=%s resolved=%s from_hold=%s reason=%s"
				% [
					world_position,
					resolved_world_position,
					from_hold,
					_navigation_component.get_last_target_reject_reason()
				]
			)
		return null

	if OS.is_debug_build():
		print(
			"[FIX][MoveTarget] queued requested=%s resolved=%s from_hold=%s"
			% [world_position, resolved_world_position, from_hold]
		)
	move_target_queued.emit(resolved_world_position, from_hold)
	return resolved_world_position


func _is_world_position_in_blocked_polygon(world_position: Vector2) -> bool:
	if not reject_targets_inside_navigation_polygons:
		return false
	if _target_blocker == null:
		if not _warned_missing_target_blocker and OS.is_debug_build():
			push_warning("PlayerMoveRequestService: move target blocker unavailable; blocked-target checks are disabled.")
			_warned_missing_target_blocker = true
		return false
	return _target_blocker.is_world_position_blocked(world_position)


func _resolve_blocked_world_target(world_position: Vector2) -> Vector2:
	if not reject_targets_inside_navigation_polygons:
		return world_position
	if _target_blocker == null:
		return world_position
	return _target_blocker.resolve_world_target(world_position)
