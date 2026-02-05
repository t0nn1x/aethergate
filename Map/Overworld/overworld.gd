class_name Overworld
extends Node2D

## Main overworld stage
## Handles player spawning and overworld management

@onready var terrain: Node2D = $Terrain
@onready var navigation_region: NavigationRegion2D = $Navigation/NavigationRegion2D
@onready var player_spawn: Marker2D = $SpawnPoints/PlayerSpawnPoint
@onready var entities: Node2D = $Entities
@onready var world_y_sort: Node2D = $WorldYSort

var player: Player = null

func _ready() -> void:
	print("Overworld loaded")
	GameManager.change_state(GameManager.GameState.OVERWORLD)

	# Spawn player
	call_deferred("spawn_player")

func spawn_player() -> void:
	# Load player scene
	var player_scene = preload("res://Entities/Player/player.tscn")
	player = player_scene.instantiate()

	# Add to entities
	world_y_sort.add_child(player)

	# Position at spawn point
	player.global_position = player_spawn.global_position

func get_navigation_region() -> NavigationRegion2D:
	return navigation_region
