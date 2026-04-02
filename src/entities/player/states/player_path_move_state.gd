class_name PlayerPathMoveState
extends State

@export var idle_state_path: NodePath = ^"../IdleState"

var _context: PlayerContext
var _idle_state: State


func physics_update(_delta: float) -> State:
	_cache_context()
	if not _is_ready():
		return null
	if not _context.player.is_alive:
		_context.navigation_component.clear_target()
		_context.movement_component.stop_movement()
		return null

	if _context.navigation_component.is_navigation_finished():
		_context.navigation_component.clear_target()
		_context.movement_component.stop_movement()
		return _idle_state

	var direction: Vector2 = _context.navigation_component.get_navigation_direction(_context.player.global_position)
	if direction == Vector2.ZERO:
		_context.movement_component.stop_movement()
		return null

	_context.movement_component.apply_navigation_movement(direction)
	return null


func _cache_context() -> void:
	if _context == null:
		var owner: Player = _resolve_player_owner()
		if owner:
			_context = owner.get_node_or_null("PlayerContext") as PlayerContext
			if _context:
				_context.refresh()
			elif OS.is_debug_build():
				push_warning("PlayerPathMoveState: PlayerContext node is missing.")

	if _idle_state == null:
		if _context and _context.idle_state:
			_idle_state = _context.idle_state
		else:
			_idle_state = get_node_or_null(idle_state_path) as State


func _resolve_player_owner() -> Player:
	if state_machine and state_machine.get_parent() is Player:
		return state_machine.get_parent() as Player
	var parent := get_parent()
	if parent and parent.get_parent() is Player:
		return parent.get_parent() as Player
	return null


func _is_ready() -> bool:
	return _context != null and _context.is_ready_for_player_states() and _idle_state != null
