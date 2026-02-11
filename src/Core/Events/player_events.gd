extends Node

## Player bounded-context events.

signal player_spawned(player: Node)
signal player_moved(position: Vector2)
signal player_damaged(damage: int)
