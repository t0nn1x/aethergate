class_name PlayerMovementComponent
extends Node

## Handles WASD movement for the player creature.

var creature: Creature
var visual: PlayerVisualComponent


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerMovementComponent must be a child of a Creature.")

	visual = creature.get_node_or_null("PlayerVisualComponent") as PlayerVisualComponent


func _physics_process(_delta: float) -> void:
	if not creature or not creature.is_alive:
		return

	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_vector != Vector2.ZERO:
		creature.velocity = input_vector * creature.movement_speed
		_apply_movement(true)

		if input_vector.x != 0.0 and visual:
			visual.set_facing(input_vector.x)
	elif creature.velocity != Vector2.ZERO:
		creature.velocity = Vector2.ZERO
		_apply_movement(false)


## Apply movement, snap to pixel grid, emit event.
func _apply_movement(moving: bool) -> void:
	if visual:
		visual.set_moving(moving)

	creature.move_and_slide()
	creature.global_position = creature.global_position.round()

	if moving:
		EventBus.player_moved.emit(creature.global_position)
