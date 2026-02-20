extends Node

## Creature bounded-context events.

signal creature_spawned(creature: Node)
signal creature_died(creature: Node, creature_data: Resource)
signal creature_selected(creature: Node)
signal creature_deselected()
signal creature_fight_requested(creature: Node)
