class_name OverworldPlayerSpawner
extends Node

## Spawns and registers the player instance for the overworld stage.

const DEFAULT_PLAYER_SKIN_CATALOG := preload(
	"res://src/Entities/Player/Resources/player_skin_catalog.tres"
) as PlayerSkinCatalog

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

	var profile_service: Node = get_node_or_null("/root/PlayerProfileService")
	var resolved_skin_catalog: PlayerSkinCatalog = _resolve_skin_catalog(profile_service)
	var resolved_appearance: PlayerAppearanceData = _resolve_spawn_appearance(
		profile_service,
		resolved_skin_catalog
	)

	player_instance.configure_identity(player_id, owner_peer_id, is_local_player)
	player_instance.prime_spawn_appearance(resolved_appearance, resolved_skin_catalog)
	world_y_sort.add_child(player_instance)
	player_instance.global_position = spawn_point.global_position
	_overworld.register_player(player_instance, player_id, is_local_player)
	player_spawned.emit(player_instance)
	return player_instance


func _resolve_skin_catalog(profile_service: Node) -> PlayerSkinCatalog:
	if profile_service == null:
		push_warning(
			"OverworldPlayerSpawner: PlayerProfileService unavailable, using bundled skin catalog fallback."
		)
		return DEFAULT_PLAYER_SKIN_CATALOG

	if not profile_service.has_method("get_skin_catalog"):
		push_warning(
			"OverworldPlayerSpawner: PlayerProfileService missing get_skin_catalog(), using bundled fallback."
		)
		return DEFAULT_PLAYER_SKIN_CATALOG

	var profile_skin_catalog: PlayerSkinCatalog = profile_service.call("get_skin_catalog") as PlayerSkinCatalog
	if profile_skin_catalog == null:
		push_warning(
			"OverworldPlayerSpawner: profile skin catalog unavailable, using bundled fallback."
		)
		return DEFAULT_PLAYER_SKIN_CATALOG

	return profile_skin_catalog


func _resolve_spawn_appearance(
	profile_service: Node,
	resolved_skin_catalog: PlayerSkinCatalog
) -> PlayerAppearanceData:
	if profile_service == null:
		return _build_default_appearance(resolved_skin_catalog)

	if not profile_service.has_method("get_appearance"):
		push_warning(
			"OverworldPlayerSpawner: PlayerProfileService missing get_appearance(), using default skin appearance."
		)
		return _build_default_appearance(resolved_skin_catalog)

	var appearance: PlayerAppearanceData = profile_service.call("get_appearance") as PlayerAppearanceData
	if appearance != null:
		return appearance

	push_warning(
		"OverworldPlayerSpawner: profile appearance unavailable, using default skin appearance."
	)
	return _build_default_appearance(resolved_skin_catalog)


func _build_default_appearance(resolved_skin_catalog: PlayerSkinCatalog) -> PlayerAppearanceData:
	var appearance := PlayerAppearanceData.new()
	if appearance == null:
		return null

	if resolved_skin_catalog != null:
		var default_skin: PlayerSkinDefinition = resolved_skin_catalog.get_default_skin()
		if default_skin != null:
			if default_skin.skin_id != StringName():
				appearance.skin_id = default_skin.skin_id

	appearance.ensure_defaults()
	return appearance
