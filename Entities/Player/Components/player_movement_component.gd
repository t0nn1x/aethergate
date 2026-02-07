class_name PlayerMovementComponent
extends Node

## Executes movement requested by player states.

var creature: Creature
var visual: PlayerVisualComponent


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerMovementComponent must be a child of a Creature.")

	visual = creature.get_node_or_null("PlayerVisualComponent") as PlayerVisualComponent


func apply_navigation_movement(direction: Vector2) -> void:
	if not _can_move():
		return
	if direction == Vector2.ZERO:
		stop_movement()
		return
	_apply_velocity(direction.normalized())


func stop_movement() -> void:
	if not creature:
		return
	if creature.velocity != Vector2.ZERO:
		creature.velocity = Vector2.ZERO
		_apply_movement(false)
	elif visual:
		visual.set_moving(false)


func _can_move() -> bool:
	return creature != null and creature.is_alive


func _apply_velocity(direction: Vector2) -> void:
	creature.velocity = direction * creature.movement_speed
	_apply_movement(true)

	if not visual:
		return
	if direction.x != 0.0:
		visual.set_facing(direction.x)


## Apply movement, snap to pixel grid, emit event.
func _apply_movement(moving: bool) -> void:
	if visual:
		visual.set_moving(moving)

	creature.move_and_slide()
	creature.global_position = creature.global_position.round()

	if moving:
		EventBus.player_moved.emit(creature.global_position)
