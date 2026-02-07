class_name PlayerInputComponent
extends Node

## Placeholder input component for future tap-to-move / mobile input.
## Currently unused — movement is handled by PlayerMovementComponent via WASD.

var creature: Creature


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerInputComponent must be a child of a Creature.")
