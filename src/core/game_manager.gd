extends Node

enum GameState {MAIN_MENU, LOADING, OVERWORLD, LOCATION, COMBAT, PAUSED}

signal game_state_changed(old_state: GameState, new_state: GameState)

var enforce_transition_map: bool = true
var current_state: GameState = GameState.MAIN_MENU
var current_location: String = ""
var allowed_transitions: Dictionary = {
	GameState.MAIN_MENU: PackedInt32Array([GameState.LOADING, GameState.OVERWORLD, GameState.PAUSED]),
	GameState.LOADING: PackedInt32Array([GameState.MAIN_MENU, GameState.OVERWORLD, GameState.LOCATION, GameState.COMBAT]),
	GameState.OVERWORLD: PackedInt32Array([GameState.MAIN_MENU, GameState.LOCATION, GameState.COMBAT, GameState.PAUSED]),
	GameState.LOCATION: PackedInt32Array([GameState.MAIN_MENU, GameState.OVERWORLD, GameState.COMBAT, GameState.PAUSED]),
	GameState.COMBAT: PackedInt32Array([GameState.MAIN_MENU, GameState.OVERWORLD, GameState.LOCATION, GameState.PAUSED]),
	GameState.PAUSED: PackedInt32Array([GameState.MAIN_MENU, GameState.OVERWORLD, GameState.LOCATION, GameState.COMBAT])
}

func _ready() -> void:
	print("GameManager initialized")

func change_state(new_state: GameState) -> bool:
	var old_state: GameState = current_state
	if new_state == old_state:
		return true
	if not _is_transition_allowed(old_state, new_state):
		if OS.is_debug_build():
			push_warning("GameManager: rejected transition %s -> %s." % [_state_name(old_state), _state_name(new_state)])
		return false

	current_state = new_state
	print("Game state: %s -> %s" % [_state_name(old_state), _state_name(new_state)])
	game_state_changed.emit(old_state, new_state)
	return true

func is_in_overworld() -> bool:
	return current_state == GameState.OVERWORLD

func is_in_combat() -> bool:
	return current_state == GameState.COMBAT


func _is_transition_allowed(from_state: GameState, to_state: GameState) -> bool:
	if not enforce_transition_map:
		return true
	if not allowed_transitions.has(from_state):
		return false

	var allowed_to_states: PackedInt32Array = allowed_transitions[from_state] as PackedInt32Array
	for state_value in allowed_to_states:
		if state_value == to_state:
			return true
	return false


func _state_name(state: GameState) -> String:
	return GameState.keys()[state]
