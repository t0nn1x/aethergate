class_name OverworldCreatureSelectionController
extends Node

## Manages creature tap-to-select lifecycle and action HUD.

const Creature = preload("res://src/entities/creatures/base/creature.gd")

var _selected_creature: Creature = null
var _creature_action_hud: CreatureActionHud
var _creature_spawner: OverworldCreatureSpawner
var _main_screen: MainScreen
var _is_overlay_visible_callback: Callable


func initialize(
	creature_action_hud: CreatureActionHud,
	creature_spawner: OverworldCreatureSpawner,
	main_screen: MainScreen,
	overlay_visible_callback: Callable
) -> void:
	_creature_action_hud = creature_action_hud
	_creature_spawner = creature_spawner
	_main_screen = main_screen
	_is_overlay_visible_callback = overlay_visible_callback
	_wire_creature_interaction_signals()


## Public API — clears selection and hides the action HUD.
func clear_selection() -> void:
	var had_selection: bool = _selected_creature != null
	_clear_selected_creature()
	if had_selection:
		_emit_creature_deselected_event()


func _wire_creature_interaction_signals() -> void:
	var event_source: Node = _get_creature_event_source()
	if event_source:
		var selected_callable: Callable = Callable(self, "_on_creature_selected")
		var deselected_callable: Callable = Callable(self, "_on_creature_deselected")
		if event_source.has_signal("creature_selected") and not event_source.is_connected("creature_selected", selected_callable):
			event_source.connect("creature_selected", selected_callable)
		if event_source.has_signal("creature_deselected") and not event_source.is_connected("creature_deselected", deselected_callable):
			event_source.connect("creature_deselected", deselected_callable)

	if _creature_action_hud and not _creature_action_hud.fight_pressed.is_connected(_on_creature_action_hud_fight_pressed):
		_creature_action_hud.fight_pressed.connect(_on_creature_action_hud_fight_pressed)

	if _creature_spawner and not _creature_spawner.creature_despawned.is_connected(_on_creature_despawned):
		_creature_spawner.creature_despawned.connect(_on_creature_despawned)

	var inventory_panel: Node = _get_inventory_panel_node()
	if inventory_panel and inventory_panel.has_signal("inventory_toggled"):
		var toggled_callable: Callable = Callable(self, "_on_inventory_toggled")
		if not inventory_panel.is_connected("inventory_toggled", toggled_callable):
			inventory_panel.connect("inventory_toggled", toggled_callable)


func _get_creature_event_source() -> Node:
	return CreatureEvents


func _on_creature_selected(creature_node: Node) -> void:
	var target_creature: Creature = creature_node as Creature
	if target_creature == null:
		_clear_selected_creature()
		return
	if target_creature.is_in_group("player"):
		_clear_selected_creature()
		return
	if not is_instance_valid(target_creature):
		_clear_selected_creature()
		return
	if target_creature.is_queued_for_deletion():
		_clear_selected_creature()
		return
	if not target_creature.is_alive:
		_clear_selected_creature()
		return
	_set_selected_creature(target_creature)


func _on_creature_deselected() -> void:
	_clear_selected_creature()


func _set_selected_creature(creature_node: Creature) -> void:
	if creature_node == null:
		_clear_selected_creature()
		return

	if _selected_creature != creature_node:
		_disconnect_selected_creature_signals()
		_selected_creature = creature_node
		_connect_selected_creature_signals()

	if _can_initiate_creature_interaction():
		_emit_creature_fight_requested_event(_selected_creature)


func _clear_selected_creature() -> void:
	_disconnect_selected_creature_signals()
	_selected_creature = null
	if _creature_action_hud:
		_creature_action_hud.hide_action()


func _can_initiate_creature_interaction() -> bool:
	if _main_screen and _main_screen.visible:
		return false
	if _is_overlay_visible_callback.is_valid() and _is_overlay_visible_callback.call():
		return false
	var inventory_panel: Node = _get_inventory_panel_node()
	if inventory_panel:
		if inventory_panel.has_method("is_open") and bool(inventory_panel.call("is_open")):
			return false
		if inventory_panel is CanvasItem and (inventory_panel as CanvasItem).is_visible_in_tree():
			return false
	return true


func _connect_selected_creature_signals() -> void:
	if _selected_creature == null:
		return
	if not _selected_creature.died.is_connected(_on_selected_creature_died):
		_selected_creature.died.connect(_on_selected_creature_died)
	var tree_exited_callable: Callable = Callable(self, "_on_selected_creature_tree_exited")
	if not _selected_creature.is_connected("tree_exited", tree_exited_callable):
		_selected_creature.connect("tree_exited", tree_exited_callable)


func _disconnect_selected_creature_signals() -> void:
	if _selected_creature == null:
		return
	if is_instance_valid(_selected_creature):
		if _selected_creature.died.is_connected(_on_selected_creature_died):
			_selected_creature.died.disconnect(_on_selected_creature_died)
		var tree_exited_callable: Callable = Callable(self, "_on_selected_creature_tree_exited")
		if _selected_creature.is_connected("tree_exited", tree_exited_callable):
			_selected_creature.disconnect("tree_exited", tree_exited_callable)


func _on_selected_creature_died() -> void:
	_clear_selected_creature()


func _on_selected_creature_tree_exited() -> void:
	_clear_selected_creature()


func _on_creature_despawned(creature_node: Creature, _chunk_coord: Vector2i) -> void:
	if creature_node == null:
		return
	if creature_node != _selected_creature:
		return
	_clear_selected_creature()


func _on_creature_action_hud_fight_pressed(creature_node: Creature) -> void:
	if creature_node == null or not is_instance_valid(creature_node):
		clear_selection()
		return
	_emit_creature_fight_requested_event(creature_node)


func _emit_creature_fight_requested_event(creature_node: Creature) -> void:
	CreatureEvents.creature_fight_requested.emit(creature_node)


func _emit_creature_deselected_event() -> void:
	CreatureEvents.creature_deselected.emit()


func _on_inventory_toggled(is_open: bool) -> void:
	if is_open:
		clear_selection()


func _get_inventory_panel_node() -> Node:
	return get_parent().get_node_or_null("InventoryPanel") if get_parent() else null
