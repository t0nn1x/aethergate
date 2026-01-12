class_name Overworld
extends Node2D
## Main overworld scene that manages the strategic game layer.
## Handles player spawning and navigation setup.

signal player_spawned(player: Player)

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")

@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var spawn_point: Marker2D = $PlayerSpawnPoint
@onready var entities_container: Node2D = $Entities

var player: Player = null


func _ready() -> void:
	_spawn_player()


## Spawns the player at the designated spawn point
func _spawn_player() -> void:
	if not spawn_point:
		push_error("Overworld: No spawn point defined!")
		return
	
	player = PLAYER_SCENE.instantiate() as Player
	if not player:
		push_error("Overworld: Failed to instantiate player!")
		return
	
	player.global_position = spawn_point.global_position
	entities_container.add_child(player)
	
	# Connect player signals if needed
	player.died.connect(_on_player_died)
	
	player_spawned.emit(player)
	print("Player spawned at: ", player.global_position)


## Returns the navigation region for pathfinding
func get_navigation_region() -> NavigationRegion2D:
	return navigation_region


## Returns the current player instance
func get_player() -> Player:
	return player


## Callback when player dies
func _on_player_died() -> void:
	# Handle player death - respawn, death screen, etc.
	# For now, just log it
	push_warning("Player died in overworld!")
