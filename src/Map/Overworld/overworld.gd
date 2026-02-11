class_name Overworld
extends Node2D

## Main overworld stage
## Holds stage-level node references. Session orchestration is delegated.

@onready var terrain: Node2D = $Terrain
@onready var navigation_region: NavigationRegion2D = $Navigation/NavigationRegion2D
@onready var entities: Node2D = $Entities
@onready var world_y_sort: Node2D = $WorldYSort

var player: Player = null

func _ready() -> void:
	print("Overworld loaded")

## Backward-compatible helper for existing callers.
func spawn_player() -> void:
	var spawner: OverworldPlayerSpawner = get_node_or_null("OverworldPlayerSpawner") as OverworldPlayerSpawner
	if spawner:
		spawner.spawn_player()

func register_player(player_instance: Player) -> void:
	player = player_instance

func get_navigation_region() -> NavigationRegion2D:
	return navigation_region
