class_name Overworld
extends Node2D

## Main overworld stage
## Holds stage-level node references. Session orchestration is delegated.

@onready var terrain: Node2D = $Terrain
@onready var navigation_region: NavigationRegion2D = $Navigation/NavigationRegion2D
@onready var entities: Node2D = $Entities
@onready var world_y_sort: Node2D = $WorldYSort
@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var navigation_blocker_registry: NavigationBlockerRegistry = $NavigationBlockerRegistry

var player: Player = null

func _ready() -> void:
	print("Overworld loaded")
	if navigation_blocker_registry:
		navigation_blocker_registry.refresh()
	if chunk_manager and navigation_blocker_registry:
		if not chunk_manager.chunks_changed.is_connected(_on_chunks_changed):
			chunk_manager.chunks_changed.connect(_on_chunks_changed)

## Backward-compatible helper for existing callers.
func spawn_player() -> void:
	var spawner: OverworldPlayerSpawner = get_node_or_null("OverworldPlayerSpawner") as OverworldPlayerSpawner
	if spawner:
		spawner.spawn_player()

func register_player(player_instance: Player) -> void:
	player = player_instance

func get_navigation_region() -> NavigationRegion2D:
	return navigation_region


func get_navigation_blocker_registry() -> NavigationBlockerRegistry:
	return navigation_blocker_registry


func _on_chunks_changed() -> void:
	if navigation_blocker_registry:
		navigation_blocker_registry.refresh()
