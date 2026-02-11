class_name PlayerIdleState
extends State

@export var path_move_state_path: NodePath = ^"../PathMoveState"

var _context: PlayerContext
var _path_move_state: State


func enter() -> void:
	_cache_context()
	if _context and _context.movement_component:
		_context.movement_component.stop_movement()


func physics_update(_delta: float) -> State:
	_cache_context()
	if not _is_ready():
		return null
	if not _context.player.is_alive:
		_context.movement_component.stop_movement()
		return null

	if _context.navigation_component.has_active_target():
		return _path_move_state

	_context.movement_component.stop_movement()
	return null


func _cache_context() -> void:
	if _context == null:
		var owner: Player = _resolve_player_owner()
		if owner:
			_context = owner.get_node_or_null("PlayerContext") as PlayerContext
			if _context:
				_context.refresh()
			elif OS.is_debug_build():
				push_warning("PlayerIdleState: PlayerContext node is missing.")

	if _path_move_state == null:
		if _context and _context.path_move_state:
			_path_move_state = _context.path_move_state
		else:
			_path_move_state = get_node_or_null(path_move_state_path) as State


func _resolve_player_owner() -> Player:
	if state_machine and state_machine.get_parent() is Player:
		return state_machine.get_parent() as Player
	var parent := get_parent()
	if parent and parent.get_parent() is Player:
		return parent.get_parent() as Player
	return null


func _is_ready() -> bool:
	return _context != null and _context.is_ready_for_player_states() and _path_move_state != null
