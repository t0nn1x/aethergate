class_name PlayerPathMoveState
extends State

@export var idle_state_path: NodePath = ^"../IdleState"

var _player: Player
var _input: PlayerInputComponent
var _movement: PlayerMovementComponent
var _navigation
var _idle_state: State


func physics_update(_delta: float) -> State:
	_cache_refs()
	if not _is_ready():
		if _navigation == null and _idle_state:
			return _idle_state
		return null
	if not _player.is_alive:
		_navigation.clear_target()
		_movement.stop_movement()
		return null

	var requested_target: Variant = _input.consume_move_target_request()
	if requested_target is Vector2:
		_navigation.set_target_position(requested_target)

	if _navigation.is_navigation_finished():
		_navigation.clear_target()
		_movement.stop_movement()
		return _idle_state

	var direction: Vector2 = _navigation.get_navigation_direction(_player.global_position)
	if direction == Vector2.ZERO:
		_movement.stop_movement()
		return null

	_movement.apply_navigation_movement(direction)
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
	if _idle_state == null:
		_idle_state = get_node_or_null(idle_state_path) as State


func _is_ready() -> bool:
	return _input != null and _movement != null and _idle_state != null
