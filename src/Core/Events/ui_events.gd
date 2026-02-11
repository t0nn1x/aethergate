extends Node

## UI bounded-context events.

signal inventory_opened()
signal item_picked_up(item_id: String, amount: int)
