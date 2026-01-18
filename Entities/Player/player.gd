class_name Player
extends Organism

## The player character
## Handles player-specific initialization and references

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var movement: PlayerMovement = $PlayerMovement

func _ready() -> void:
    super._ready()

    organism_name = "Player"
    max_health = 100.0
    movement_speed = 200.0
    current_health = max_health

    setup_camera()

    # Register with game systems
    add_to_group("player")
    EventBus.player_spawned.emit(self)

func setup_camera() -> void:
    camera.enabled = true
    camera.zoom = Vector2(2, 2)  # Adjust based on your tile size
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0

func _on_death() -> void:
    print("Player died!")
    # Don't queue_free - handle respawn instead
    GameManager.change_state(GameManager.GameState.PAUSED)
