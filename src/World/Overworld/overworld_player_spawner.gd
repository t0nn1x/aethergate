class_name OverworldPlayerSpawner
extends Node

## Spawns and registers the player instance for the overworld stage.

signal player_spawned(player: Player)

@export var player_scene: PackedScene = preload("res://src/Entities/Player/player.tscn")
@export var world_y_sort_path: NodePath = ^"WorldYSort"
@export var spawn_point_path: NodePath = ^"SpawnPoints/PlayerSpawnPoint"

var _overworld: Overworld


func _ready() -> void:
	_overworld = get_parent() as Overworld
	assert(_overworld, "OverworldPlayerSpawner must be a child of Overworld.")


func spawn_player() -> Player:
	if _overworld and is_instance_valid(_overworld.player):
		return _overworld.player

	if player_scene == null:
		push_warning("OverworldPlayerSpawner: player_scene is not assigned.")
		return null

	var world_y_sort: Node2D = _overworld.get_node_or_null(world_y_sort_path) as Node2D
	var spawn_point: Marker2D = _overworld.get_node_or_null(spawn_point_path) as Marker2D
	if world_y_sort == null or spawn_point == null:
		push_warning("OverworldPlayerSpawner: required target nodes are missing.")
		return null

	var player_instance: Player = player_scene.instantiate() as Player
	if player_instance == null:
		push_warning("OverworldPlayerSpawner: failed to instantiate player scene as Player.")
		return null

	world_y_sort.add_child(player_instance)
	player_instance.global_position = spawn_point.global_position
	_overworld.register_player(player_instance)
	player_spawned.emit(player_instance)
	return player_instance
