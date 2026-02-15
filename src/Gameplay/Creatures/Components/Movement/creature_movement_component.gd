class_name CreatureMovementComponent
extends Node

## Generic movement executor for Creature instances.

var creature: Creature
var visual_component: Node


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "CreatureMovementComponent must be a child of Creature.")
	visual_component = creature.get_node_or_null("CreatureVisualComponent")


func apply_direction(direction: Vector2) -> void:
	if not _can_move():
		return
	if direction == Vector2.ZERO:
		stop_movement()
		return

	var normalized_direction: Vector2 = direction.normalized()
	creature.velocity = normalized_direction * creature.movement_speed
	creature.move_and_slide()

	if visual_component and visual_component.has_method("set_moving"):
		visual_component.call("set_moving", true)
	if visual_component and visual_component.has_method("set_facing"):
		visual_component.call("set_facing", normalized_direction.x)


func stop_movement() -> void:
	if creature == null:
		return
	creature.velocity = Vector2.ZERO
	if visual_component and visual_component.has_method("set_moving"):
		visual_component.call("set_moving", false)


func _can_move() -> bool:
	if creature == null:
		return false
	return creature.is_alive
