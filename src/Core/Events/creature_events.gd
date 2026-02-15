extends Node

## Creature bounded-context events.

signal creature_spawned(creature: Node)
signal creature_died(creature: Node, creature_data: Resource)
