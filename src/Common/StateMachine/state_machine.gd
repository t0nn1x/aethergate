class_name StateMachine
extends Node

## Generic state machine. Add State nodes as children.
## Delegates _process, _physics_process, and _unhandled_input to the current state.

## Emitted when the state changes. Passes the old and new state.
signal state_changed(old_state: State, new_state: State)

## The initial state to start in (set in the inspector or assign in code).
@export var initial_state: State

## When enabled, only transitions listed in allowed_transitions are permitted.
@export var enforce_transition_map: bool = false
## Dictionary[StringName -> Array[StringName]].
@export var allowed_transitions: Dictionary = {}

## The currently active state.
var current_state: State = null

func _ready() -> void:
	# Wait for the parent host to be ready so components can resolve references.
	var host: Node = get_parent()
	if host:
		await host.ready

	# Assign state_machine reference to all child states.
	for child in get_children():
		if child is State:
			child.state_machine = self

	var start_state: State = null
	if initial_state != null and initial_state is State:
		start_state = initial_state
	if start_state == null:
		start_state = get_node_or_null("IdleState") as State
	if start_state == null:
		for child in get_children():
			if child is State:
				start_state = child
				break

	# Enter the initial state.
	if start_state:
		initial_state = start_state
		current_state = start_state
		current_state.enter()
	else:
		push_warning("StateMachine: no initial_state assigned and no IdleState child found.")

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
	if target_state == null:
		return
	if target_state == current_state:
		return
	if not _is_transition_allowed(current_state, target_state):
		if OS.is_debug_build():
			var from_name: StringName = current_state.name if current_state else &"<none>"
			push_warning(
				"StateMachine: rejected transition %s -> %s (not in allowed_transitions)." %
				[String(from_name), String(target_state.name)]
			)
		return

	var old_state: State = current_state

	if current_state:
		current_state.exit()

	current_state = target_state
	current_state.enter()

	state_changed.emit(old_state, current_state)


func _is_transition_allowed(from_state: State, to_state: State) -> bool:
	if not enforce_transition_map:
		return true
	if from_state == null:
		return true

	var from_name: String = String(from_state.name)
	if not allowed_transitions.has(from_name):
		return false

	var allowed_state_names: Array[StringName] = _to_state_name_array(allowed_transitions[from_name])
	for allowed_name in allowed_state_names:
		if allowed_name == to_state.name:
			return true
	return false


func _to_state_name_array(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is PackedStringArray:
		for state_name in value:
			result.append(StringName(state_name))
		return result
	if value is Array:
		for state_name_variant in value:
			result.append(StringName(str(state_name_variant)))
	return result
