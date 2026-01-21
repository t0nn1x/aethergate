extends Node

# Combat events
signal enemy_died(enemy: Node)
signal player_damaged(damage: int)
signal skill_used(skill_id: String, caster: Node)

# World events
signal location_entered(location_name: String)
signal chunk_loaded(chunk_pos: Vector2i)

# UI events
signal inventory_opened()
signal item_picked_up(item_id: String, amount: int)

# Player events
signal player_spawned(player: Node)
signal player_moved(position: Vector2)
