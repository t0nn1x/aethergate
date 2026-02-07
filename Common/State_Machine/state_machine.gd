class_name StateMachine
extends Node

## Generic state machine. Add State nodes as children.
## Delegates _process, _physics_process, and _unhandled_input to the current state.

## Emitted when the state changes. Passes the old and new state.
signal state_changed(old_state: State, new_state: State)

## The initial state to start in (set in the inspector or assign in code).
@export var initial_state: State

## The currently active state.
var current_state: State = null

func _ready() -> void:
	# Wait for the owner to be ready so components can resolve references.
	await owner.ready

	# Assign state_machine reference to all child states.
	for child in get_children():
		if child is State:
			child.state_machine = self

	# Enter the initial state.
	if initial_state:
		current_state = initial_state
		current_state.enter()

func _process(delta: float) -> void:
	if current_state:
		var next_state: State = current_state.update(delta)
		if next_state:
			_transition_to(next_state)

func _physics_process(delta: float) -> void:
	if current_state:
		var next_state: State = current_state.physics_update(delta)
		if next_state:
			_transition_to(next_state)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		var next_state: State = current_state.handle_input(event)
		if next_state:
			_transition_to(next_state)

## Force a transition to a new state.
func transition_to(target_state: State) -> void:
	_transition_to(target_state)

## Internal transition logic.
func _transition_to(target_state: State) -> void:
	if target_state == current_state:
		return

	var old_state: State = current_state

	if current_state:
		current_state.exit()

	current_state = target_state
	current_state.enter()

	state_changed.emit(old_state, current_state)
