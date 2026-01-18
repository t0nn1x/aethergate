class_name PlayerMovement
extends Node

## Handles player movement using click-to-move with NavigationAgent2D

@export var stopping_distance: float = 5.0

@onready var player: Player = get_parent()

var navigation_agent: NavigationAgent2D
var is_moving: bool = false

func _ready() -> void:
    # NavigationAgent2D will be added when overworld is set up
    call_deferred("setup_navigation")

func setup_navigation() -> void:
    # Create NavigationAgent2D
    navigation_agent = NavigationAgent2D.new()
    player.add_child(navigation_agent)

    # Configure
    navigation_agent.path_desired_distance = 4.0
    navigation_agent.target_desired_distance = stopping_distance
    navigation_agent.avoidance_enabled = true
    navigation_agent.radius = 16.0  # Adjust based on player size

func _input(event: InputEvent) -> void:
    if not navigation_agent:
        return

    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            # Check if clicking on UI
            if is_clicking_ui():
                return

            # Set target
            var target_pos = player.get_global_mouse_position()
            set_target(target_pos)

func _physics_process(_delta: float) -> void:
    if not navigation_agent or not is_moving:
        return

    # Check if reached destination
    if navigation_agent.is_navigation_finished():
        stop_movement()
        return

    # Get next position
    var next_position = navigation_agent.get_next_path_position()
    var direction = (next_position - player.global_position).normalized()

    # Move
    player.velocity = direction * player.movement_speed
    player.move_and_slide()

    # Emit position updates (for multiplayer/chunking)
    EventBus.player_moved.emit(player.global_position)

    # Optional: Update sprite direction
    update_sprite_direction(direction)

func set_target(target_pos: Vector2) -> void:
    if not navigation_agent:
        return

    navigation_agent.target_position = target_pos
    is_moving = true

func stop_movement() -> void:
    is_moving = false
    player.velocity = Vector2.ZERO

func is_clicking_ui() -> bool:
    # Check if mouse is over UI elements
    # For now, simple check - expand when UI is added
    var _mouse_pos = player.get_viewport().get_mouse_position()

    # Check if any UI control has focus or is under mouse
    # This is a placeholder - proper implementation when UI exists
    return false

func update_sprite_direction(direction: Vector2) -> void:
    # Optional: Flip sprite or change animation based on direction
    # Implement in Milestone 2 when animations are added

    # Example for simple left/right flip:
    if direction.x < 0:
        player.sprite.flip_h = true
    elif direction.x > 0:
        player.sprite.flip_h = false
