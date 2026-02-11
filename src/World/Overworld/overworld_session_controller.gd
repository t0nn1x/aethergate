class_name OverworldSessionController
extends Node

## Orchestrates overworld session startup (state + initial player spawn).

signal session_started()

@export var spawner_path: NodePath = ^"OverworldPlayerSpawner"
@export var auto_start_session_on_ready: bool = true
@export var set_overworld_state_on_session_start: bool = true
@export var spawn_player_on_session_start: bool = true
@export var deferred_player_spawn: bool = true

var _overworld: Overworld
var _spawner: OverworldPlayerSpawner
var _is_session_started: bool = false


func _ready() -> void:
	_overworld = get_parent() as Overworld
	if _overworld == null:
		push_warning("OverworldSessionController must be a child of Overworld.")
		return

	_spawner = _overworld.get_node_or_null(spawner_path) as OverworldPlayerSpawner
	if _spawner == null and OS.is_debug_build():
		push_warning("OverworldSessionController: OverworldPlayerSpawner is missing.")

	if auto_start_session_on_ready:
		start_session()


func start_session() -> void:
	if _is_session_started:
		if OS.is_debug_build():
			print("[OverworldSessionController] start_session ignored: already started.")
		return

	_is_session_started = true
	print("[OverworldSessionController] session_start")

	if set_overworld_state_on_session_start:
		GameManager.change_state(GameManager.GameState.OVERWORLD)

	if not spawn_player_on_session_start:
		session_started.emit()
		return

	if deferred_player_spawn:
		call_deferred("_spawn_player_and_emit")
		return
	_spawn_player_and_emit()


func is_session_started() -> bool:
	return _is_session_started


func _spawn_player_and_emit() -> void:
	_spawn_player()
	session_started.emit()


func _spawn_player() -> void:
	if _spawner == null:
		return
	_spawner.spawn_player()

