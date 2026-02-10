class_name Player
extends Creature

## The player character.
## A thin shell that extends Creature. All behavior lives in child components:
## - PlayerInputComponent: tap/click target queue
## - PlayerMovementComponent: movement executor
## - CreatureNavigationComponent: pathfinding target/direction provider
## - PlayerVisualComponent: sprite bob, flip, silhouette sync
## - PlayerCameraComponent: zoom controls
## - StateMachine + movement states: mode switching (idle/path)

func _ready() -> void:
	# Set player stats directly (no creature_data resource for the player).
	creature_name = "Player"
	max_health = 100.0
	movement_speed = 100.0
	current_health = max_health

	super._ready()

	# Register with game systems.
	add_to_group("player")
	EventBus.player_spawned.emit(self)

func _on_death() -> void:
	print("Player died!")
	# Don't queue_free — handle respawn instead.
	GameManager.change_state(GameManager.GameState.PAUSED)
