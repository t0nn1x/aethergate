class_name GameManager
extends Node

enum GameState { MAIN_MENU, LOADING, OVERWORLD, LOCATION, COMBAT, PAUSED }

var current_state: GameState = GameState.MAIN_MENU
var current_location: String = ""

func _ready() -> void:
    print("GameManager initialized")

func change_state(new_state: GameState) -> void:
    var old_state = current_state
    current_state = new_state
    print("Game state: %s -> %s" % [
        GameState.keys()[old_state],
        GameState.keys()[new_state]
    ])

func is_in_overworld() -> bool:
    return current_state == GameState.OVERWORLD

func is_in_combat() -> bool:
    return current_state == GameState.COMBAT
