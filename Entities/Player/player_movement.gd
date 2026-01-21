class_name PlayerMovement
extends Node

## Handles player movement using WASD input

@onready var player: Player = get_parent()

func _physics_process(_delta: float) -> void:
    if not player:
        return

    var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    player.set_moving(input_vector != Vector2.ZERO)
    if input_vector == Vector2.ZERO:
        player.velocity = Vector2.ZERO
    else:
        player.velocity = input_vector * player.movement_speed

    player.move_and_slide()
    player.global_position = player.global_position.round()

    if input_vector.x != 0.0:
        player.set_facing(input_vector.x)

    if input_vector != Vector2.ZERO:
        EventBus.player_moved.emit(player.global_position)
