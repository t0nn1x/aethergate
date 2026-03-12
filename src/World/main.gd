class_name MainRoot
extends Node

## Main scene root.
## World is rendered directly (no intermediate SubViewport pipeline).


func _ready() -> void:
	if not GameManager.game_state_changed.is_connected(_on_game_state_changed):
		GameManager.game_state_changed.connect(_on_game_state_changed)


func _on_game_state_changed(_old_state: GameManager.GameState, new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.COMBAT:
		get_tree().change_scene_to_file("res://src/World/Combat/combat_scene.tscn")
