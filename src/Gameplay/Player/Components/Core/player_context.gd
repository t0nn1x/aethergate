class_name PlayerContext
extends Node

## Centralized typed references for player runtime components and states.
## Keeps player states/components from repeatedly resolving nodes by name.

@export var input_component_path: NodePath = ^"PlayerInputComponent"
@export var move_request_service_path: NodePath = ^"PlayerMoveRequestService"
@export var inventory_component_path: NodePath = ^"PlayerInventoryComponent"
@export var movement_component_path: NodePath = ^"PlayerMovementComponent"
@export var navigation_component_path: NodePath = ^"CreatureNavigationComponent"
@export var state_machine_path: NodePath = ^"StateMachine"
@export var idle_state_path: NodePath = ^"IdleState"
@export var path_move_state_path: NodePath = ^"PathMoveState"

var player: Player
var input_component: PlayerInputComponent
var move_request_service: PlayerMoveRequestService
var inventory_component: Node
var movement_component: PlayerMovementComponent
var navigation_component: CreatureNavigationComponent
var state_machine: StateMachine
var idle_state: State
var path_move_state: State


func _ready() -> void:
	refresh()


func refresh() -> void:
	player = get_parent() as Player
	if player == null:
		push_warning("PlayerContext must be a child of Player.")
		return

	input_component = player.get_node_or_null(input_component_path) as PlayerInputComponent
	move_request_service = player.get_node_or_null(move_request_service_path) as PlayerMoveRequestService
	inventory_component = player.get_node_or_null(inventory_component_path) as Node
	movement_component = player.get_node_or_null(movement_component_path) as PlayerMovementComponent
	navigation_component = player.get_node_or_null(navigation_component_path) as CreatureNavigationComponent
	state_machine = player.get_node_or_null(state_machine_path) as StateMachine

	if state_machine:
		idle_state = state_machine.get_node_or_null(idle_state_path) as State
		path_move_state = state_machine.get_node_or_null(path_move_state_path) as State
	else:
		idle_state = null
		path_move_state = null


func is_ready_for_player_states() -> bool:
	return (
		player != null
		and input_component != null
		and move_request_service != null
		and movement_component != null
		and navigation_component != null
		and idle_state != null
		and path_move_state != null
	)
