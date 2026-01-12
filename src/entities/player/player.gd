class_name Player
extends Entity
## Player entity that handles player-specific functionality.
## Controls camera setup and references to player components.

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var camera: Camera2D = $Camera2D
@onready var movement: PlayerMovement = $PlayerMovement


func _ready() -> void:
	super._ready()
	entity_name = "Player"
	_setup_camera()
	_setup_navigation_agent()


## Configures the player camera for smooth following
func _setup_camera() -> void:
	camera.enabled = true
	camera.zoom = Vector2(2.0, 2.0)  # Adjust for pixel art scale
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	# Camera limits can be set later when overworld bounds are known
	# camera.limit_left = 0
	# camera.limit_top = 0
	# camera.limit_right = 2000
	# camera.limit_bottom = 2000


## Configures the navigation agent for pathfinding
func _setup_navigation_agent() -> void:
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 5.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.debug_enabled = false  # Set to true for debugging paths


## Override die to handle player death differently
func die() -> void:
	died.emit()
	# Don't queue_free the player - handle death screen/respawn instead
	# For now, just reset health for testing
	current_health = max_health
	health_changed.emit(current_health, max_health)
	push_warning("Player died! (Reset health for testing purposes)")
