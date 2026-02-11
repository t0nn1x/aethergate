class_name OverworldSessionController
extends Node

## Orchestrates overworld session startup (state + initial player spawn).

@export var spawner_path: NodePath = ^"OverworldPlayerSpawner"
@export var set_overworld_state_on_ready: bool = true
@export var spawn_player_on_ready: bool = true
@export var deferred_player_spawn: bool = true

var _overworld: Overworld
var _spawner: OverworldPlayerSpawner


func _ready() -> void:
	_overworld = get_parent() as Overworld
	if _overworld == null:
		push_warning("OverworldSessionController must be a child of Overworld.")
		return

	_spawner = _overworld.get_node_or_null(spawner_path) as OverworldPlayerSpawner
	if _spawner == null and OS.is_debug_build():
		push_warning("OverworldSessionController: OverworldPlayerSpawner is missing.")

	if set_overworld_state_on_ready:
		GameManager.change_state(GameManager.GameState.OVERWORLD)

	if not spawn_player_on_ready:
		return

	if deferred_player_spawn:
		call_deferred("_spawn_player")
		return
	_spawn_player()


func _spawn_player() -> void:
	if _spawner == null:
		return
	_spawner.spawn_player()
