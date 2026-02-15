extends Node

## Creature bounded-context events.

signal creature_spawned(creature: Node)
signal creature_died(creature: Node, creature_data: Resource)
signal creature_aggro(creature: Node, target: Node)
signal creature_deaggro(creature: Node)
