class_name OverworldPlayerSpawner
extends Node

## Spawns and registers the player instance for the overworld stage.

const DEFAULT_PLAYER_COSMETIC_CATALOG: Resource = preload(
	"res://src/Entities/Player/Resources/player_cosmetic_catalog.tres"
)

signal player_spawned(player: Player)

@export var player_scene: PackedScene = preload("res://src/Entities/Player/player.tscn")
@export var world_y_sort_path: NodePath = ^"WorldYSort"
@export var spawn_point_path: NodePath = ^"SpawnPoints/PlayerSpawnPoint"

var _overworld: Overworld


func _ready() -> void:
	_overworld = get_parent() as Overworld
	assert(_overworld, "OverworldPlayerSpawner must be a child of Overworld.")


func spawn_player(player_id: int = 1, is_local_player: bool = true, owner_peer_id: int = 1) -> Player:
	var existing_player: Player = null
	if _overworld:
		existing_player = _overworld.get_player_by_id(player_id)
	if existing_player and is_instance_valid(existing_player):
		return existing_player

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

	player_instance.configure_identity(player_id, owner_peer_id, is_local_player)
	world_y_sort.add_child(player_instance)
	_apply_player_appearance(player_instance)
	player_instance.global_position = spawn_point.global_position
	_overworld.register_player(player_instance, player_id, is_local_player)
	player_spawned.emit(player_instance)
	return player_instance


func _apply_player_appearance(player_instance: Player) -> void:
	if player_instance == null:
		return

	var profile_service: Node = get_node_or_null("/root/PlayerProfileService")
	var cosmetic_catalog: Resource = DEFAULT_PLAYER_COSMETIC_CATALOG
	var appearance: Resource = null

	if profile_service:
		if profile_service.has_method("get_catalog"):
			var profile_catalog: Resource = profile_service.call("get_catalog") as Resource
			if profile_catalog:
				cosmetic_catalog = profile_catalog
		if profile_service.has_method("get_appearance"):
			appearance = profile_service.call("get_appearance") as Resource

	if appearance == null and cosmetic_catalog and cosmetic_catalog.has_method("get_default_appearance"):
		appearance = cosmetic_catalog.call("get_default_appearance") as Resource

	if appearance == null or cosmetic_catalog == null:
		push_warning("OverworldPlayerSpawner: unable to resolve player appearance, keeping scene defaults.")
		return

	player_instance.apply_appearance(appearance, cosmetic_catalog)
