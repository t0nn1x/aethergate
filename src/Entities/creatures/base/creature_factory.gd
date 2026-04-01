class_name CreatureFactory
extends RefCounted

## Lightweight factory for creating Creature scene instances from CreatureData.

const Creature = preload("res://src/Entities/creatures/base/creature.gd")
const CreatureData = preload("res://src/Entities/creatures/base/creature_data.gd")

var creature_scene: PackedScene = preload("res://src/Entities/creatures/base/creature.tscn")


func create(creature_data: CreatureData) -> Creature:
	if creature_scene == null:
		push_error("CreatureFactory: creature_scene is not assigned.")
		return null
	if creature_data == null:
		push_warning("CreatureFactory: creature_data is null.")
		return null

	var creature: Creature = creature_scene.instantiate() as Creature
	if creature == null:
		push_error("CreatureFactory: failed to instantiate creature scene as Creature.")
		return null

	creature.creature_data = creature_data
	return creature
