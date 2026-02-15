extends Node

## Deprecated compatibility shim.
## New code should use PlayerEvents / WorldEvents / UIEvents / CreatureEvents directly.

# Legacy combat events
signal enemy_died(enemy: Node)
signal skill_used(skill_id: String, caster: Node)

# Legacy creature events
signal creature_spawned(creature: Node)
signal creature_died(creature: Node, creature_data: Resource)
signal creature_aggro(creature: Node, target: Node)
signal creature_deaggro(creature: Node)

# Legacy world events
signal location_entered(location_name: String)
signal chunk_loaded(chunk_pos: Vector2i)

# Legacy UI events
signal inventory_opened()
signal item_picked_up(item_id: String, amount: int)

# Legacy player events
signal player_spawned(player: Node)
signal player_moved(position: Vector2)
signal player_damaged(damage: int)


func _ready() -> void:
	_bridge_player_events()
	_bridge_world_events()
	_bridge_ui_events()
	_bridge_creature_events()


func _bridge_player_events() -> void:
	var player_events: Node = get_node_or_null("/root/PlayerEvents")
	if player_events == null:
		return

	var spawned_callable: Callable = Callable(self, "_on_player_spawned")
	var moved_callable: Callable = Callable(self, "_on_player_moved")
	var damaged_callable: Callable = Callable(self, "_on_player_damaged")
	if player_events.has_signal("player_spawned") and not player_events.is_connected("player_spawned", spawned_callable):
		player_events.connect("player_spawned", spawned_callable)
	if player_events.has_signal("player_moved") and not player_events.is_connected("player_moved", moved_callable):
		player_events.connect("player_moved", moved_callable)
	if player_events.has_signal("player_damaged") and not player_events.is_connected("player_damaged", damaged_callable):
		player_events.connect("player_damaged", damaged_callable)


func _bridge_world_events() -> void:
	var world_events: Node = get_node_or_null("/root/WorldEvents")
	if world_events == null:
		return

	var location_callable: Callable = Callable(self, "_on_location_entered")
	var chunk_callable: Callable = Callable(self, "_on_chunk_loaded")
	if world_events.has_signal("location_entered") and not world_events.is_connected("location_entered", location_callable):
		world_events.connect("location_entered", location_callable)
	if world_events.has_signal("chunk_loaded") and not world_events.is_connected("chunk_loaded", chunk_callable):
		world_events.connect("chunk_loaded", chunk_callable)


func _bridge_ui_events() -> void:
	var ui_events: Node = get_node_or_null("/root/UIEvents")
	if ui_events == null:
		return

	var inventory_callable: Callable = Callable(self, "_on_inventory_opened")
	var picked_callable: Callable = Callable(self, "_on_item_picked_up")
	if ui_events.has_signal("inventory_opened") and not ui_events.is_connected("inventory_opened", inventory_callable):
		ui_events.connect("inventory_opened", inventory_callable)
	if ui_events.has_signal("item_picked_up") and not ui_events.is_connected("item_picked_up", picked_callable):
		ui_events.connect("item_picked_up", picked_callable)


func _bridge_creature_events() -> void:
	var creature_events: Node = get_node_or_null("/root/CreatureEvents")
	if creature_events == null:
		return

	var spawned_callable: Callable = Callable(self, "_on_creature_spawned")
	var died_callable: Callable = Callable(self, "_on_creature_died")
	var aggro_callable: Callable = Callable(self, "_on_creature_aggro")
	var deaggro_callable: Callable = Callable(self, "_on_creature_deaggro")
	if creature_events.has_signal("creature_spawned") and not creature_events.is_connected("creature_spawned", spawned_callable):
		creature_events.connect("creature_spawned", spawned_callable)
	if creature_events.has_signal("creature_died") and not creature_events.is_connected("creature_died", died_callable):
		creature_events.connect("creature_died", died_callable)
	if creature_events.has_signal("creature_aggro") and not creature_events.is_connected("creature_aggro", aggro_callable):
		creature_events.connect("creature_aggro", aggro_callable)
	if creature_events.has_signal("creature_deaggro") and not creature_events.is_connected("creature_deaggro", deaggro_callable):
		creature_events.connect("creature_deaggro", deaggro_callable)


func _on_player_spawned(player: Node) -> void:
	player_spawned.emit(player)


func _on_player_moved(position: Vector2) -> void:
	player_moved.emit(position)


func _on_player_damaged(damage: int) -> void:
	player_damaged.emit(damage)


func _on_location_entered(location_name: String) -> void:
	location_entered.emit(location_name)


func _on_chunk_loaded(chunk_pos: Vector2i) -> void:
	chunk_loaded.emit(chunk_pos)


func _on_inventory_opened() -> void:
	inventory_opened.emit()


func _on_item_picked_up(item_id: String, amount: int) -> void:
	item_picked_up.emit(item_id, amount)


func _on_creature_spawned(creature: Node) -> void:
	creature_spawned.emit(creature)


func _on_creature_died(creature: Node, creature_data: Resource) -> void:
	creature_died.emit(creature, creature_data)


func _on_creature_aggro(creature: Node, target: Node) -> void:
	creature_aggro.emit(creature, target)


func _on_creature_deaggro(creature: Node) -> void:
	creature_deaggro.emit(creature)
