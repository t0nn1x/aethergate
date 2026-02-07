class_name State
extends Node

## Base state class for a generic state machine.
## Override the virtual methods to implement state-specific behavior.

## Reference to the state machine managing this state.
## Untyped to avoid circular dependency with StateMachine.
var state_machine: Node = null

## Called when the state is entered.
func enter() -> void:
	pass

## Called when the state is exited.
func exit() -> void:
	pass

## Called every frame (from _process). Return a state node to transition.
func update(_delta: float) -> State:
	return null

## Called every physics frame (from _physics_process). Return a state node to transition.
func physics_update(_delta: float) -> State:
	return null

## Called when an unhandled input event occurs.
func handle_input(_event: InputEvent) -> State:
	return null
