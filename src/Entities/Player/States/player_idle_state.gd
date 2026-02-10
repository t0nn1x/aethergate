class_name PlayerIdleState
extends State

@export var path_move_state_path: NodePath = ^"../PathMoveState"

var _player: Player
var _input: PlayerInputComponent
var _movement: PlayerMovementComponent
var _navigation
var _path_move_state: State


func enter() -> void:
	_cache_refs()
	if _movement:
		_movement.stop_movement()


func physics_update(_delta: float) -> State:
	_cache_refs()
	if not _is_ready():
		return null
	if not _player.is_alive:
		_movement.stop_movement()
		return null

	var requested_target: Variant = _input.consume_move_target_request()
	if requested_target is Vector2:
		if _navigation and _navigation.set_target_position(requested_target):
			return _path_move_state

	_movement.stop_movement()
	return null


func _cache_refs() -> void:
	if _player == null:
		if state_machine and state_machine.get_parent() is Player:
			_player = state_machine.get_parent() as Player
		else:
			_player = get_parent().get_parent() as Player
	if not _player:
		return

	if _input == null:
		_input = _player.get_node_or_null("PlayerInputComponent") as PlayerInputComponent
	if _movement == null:
		_movement = _player.get_node_or_null("PlayerMovementComponent") as PlayerMovementComponent
	if _navigation == null:
		_navigation = _player.get_node_or_null("CreatureNavigationComponent")
	if _path_move_state == null:
		_path_move_state = get_node_or_null(path_move_state_path) as State


func _is_ready() -> bool:
	return _input != null and _movement != null and _path_move_state != null
