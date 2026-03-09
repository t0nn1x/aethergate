class_name Overworld
extends Node2D

## Main overworld stage
## Holds stage-level node references. Session orchestration is delegated.

@export var debug_overlay_path: NodePath = ^"DebugOverlay"
@export var main_screen_path: NodePath = ^"MainScreen"
@export var character_creator_panel_path: NodePath = ^"CharacterCreatorPanel"
@export var ui_manager_path: NodePath = ^"UiManager"
@export var creature_action_hud_path: NodePath = ^"CreatureActionHud"
@export var session_controller_path: NodePath = ^"OverworldSessionController"
@export var default_local_player_id: int = 1

@onready var terrain: Node2D = $Terrain
@onready var navigation_region: NavigationRegion2D = $Navigation/NavigationRegion2D
@onready var entities: Node2D = $Entities
@onready var world_y_sort: Node2D = $WorldYSort
@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var creature_spawner: OverworldCreatureSpawner = $OverworldCreatureSpawner
@onready var navigation_blocker_registry: NavigationBlockerRegistry = $NavigationBlockerRegistry
@onready var debug_overlay: DebugOverlay = get_node_or_null(debug_overlay_path) as DebugOverlay
@onready var main_screen: MainScreen = get_node_or_null(main_screen_path) as MainScreen
@onready var character_creator_panel: Node = get_node_or_null(
	character_creator_panel_path
) as Node
@onready var ui_manager: Node = get_node_or_null(ui_manager_path)
@onready var creature_action_hud: CreatureActionHud = get_node_or_null(creature_action_hud_path) as CreatureActionHud
@onready var session_controller: OverworldSessionController = get_node_or_null(session_controller_path) as OverworldSessionController

## Backward-compatible local-player reference.
var player: Player = null
var _players_by_id: Dictionary = {}
var _selected_creature: Creature = null


func _ready() -> void:
	print("Overworld loaded")
	if ui_manager:
		ui_manager.initialize_ui()
	_refresh_ui_overlay_references()
	_wire_stage_dependencies()
	_wire_main_screen_signals()
	_wire_character_creator_signals()
	_wire_creature_interaction_signals()
	if navigation_blocker_registry:
		navigation_blocker_registry.refresh()
	if chunk_manager and navigation_blocker_registry:
		if not chunk_manager.chunks_changed.is_connected(_on_chunks_changed):
			chunk_manager.chunks_changed.connect(_on_chunks_changed)
	_start_session_if_menu_is_missing()


func _refresh_ui_overlay_references() -> void:
	debug_overlay = get_node_or_null(debug_overlay_path) as DebugOverlay
	main_screen = get_node_or_null(main_screen_path) as MainScreen
	character_creator_panel = get_node_or_null(character_creator_panel_path) as Node


func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return
	if _is_character_creator_visible():
		return
	if ui_manager and ui_manager.is_menu_visible():
		return
	if _is_desktop_platform() and event.is_action_pressed("ui_cancel"):
		if ui_manager and ui_manager.close_open_panels():
			get_viewport().set_input_as_handled()
			return
	if not event.is_action_pressed("inventory"):
		return
	_toggle_inventory_panel()
	get_viewport().set_input_as_handled()


## Backward-compatible helper for existing callers.
func spawn_player() -> void:
	var spawner: OverworldPlayerSpawner = get_node_or_null("OverworldPlayerSpawner") as OverworldPlayerSpawner
	if spawner:
		spawner.spawn_player(default_local_player_id, true, 1)


func register_player(player_instance: Player, player_id: int = 1, is_local_player: bool = true) -> void:
	if player_instance == null:
		return

	_players_by_id[player_id] = player_instance
	if is_local_player:
		player = player_instance
		_wire_local_player_dependencies(player_instance)
	_wire_shared_player_dependencies(player_instance)


func get_navigation_region() -> NavigationRegion2D:
	return navigation_region


func get_navigation_blocker_registry() -> NavigationBlockerRegistry:
	return navigation_blocker_registry


func get_player_by_id(player_id: int) -> Player:
	var player_instance: Player = _players_by_id.get(player_id, null) as Player
	if player_instance and is_instance_valid(player_instance):
		return player_instance
	return null


func get_local_player() -> Player:
	return player


func get_registered_player_ids() -> Array[int]:
	var ids: Array[int] = []
	for id_variant in _players_by_id.keys():
		ids.append(int(id_variant))
	return ids


func _on_chunks_changed() -> void:
	if navigation_blocker_registry:
		navigation_blocker_registry.refresh()


func _wire_stage_dependencies() -> void:
	if debug_overlay and chunk_manager:
		debug_overlay.set_chunk_manager(chunk_manager)
	if debug_overlay and creature_spawner:
		debug_overlay.set_creature_spawner(creature_spawner)
	if player:
		_wire_local_player_dependencies(player)


func _wire_main_screen_signals() -> void:
	if main_screen == null:
		if OS.is_debug_build():
			push_warning("Overworld: MainScreen is missing. Session will auto-start.")
		return

	if not main_screen.play_pressed.is_connected(_on_main_screen_play_pressed):
		main_screen.play_pressed.connect(_on_main_screen_play_pressed)
	if not main_screen.quit_requested.is_connected(_on_main_screen_quit_requested):
		main_screen.quit_requested.connect(_on_main_screen_quit_requested)


func _start_session_if_menu_is_missing() -> void:
	if main_screen != null:
		main_screen.show_menu()
		return
	if session_controller:
		session_controller.start_session()


func _on_main_screen_play_pressed() -> void:
	_clear_selected_creature()
	print("[Overworld] play_started")
	if _should_open_character_creator():
		_open_character_creator_panel()
		return
	if main_screen:
		main_screen.hide_menu()
	if session_controller:
		session_controller.start_session()


func _on_main_screen_quit_requested() -> void:
	print("[FIX][Quit] quit_requested signal received by Overworld")


func _toggle_inventory_panel() -> void:
	if ui_manager == null:
		return
	var local_player: Player = get_local_player()
	if local_player:
		_wire_inventory_panel_dependency(local_player)
	ui_manager.toggle_inventory()


func _wire_local_player_dependencies(player_instance: Player) -> void:
	if player_instance == null:
		return

	if chunk_manager:
		chunk_manager.set_tracked_player(player_instance)
	if debug_overlay:
		debug_overlay.set_player_node(player_instance)
	_wire_inventory_panel_dependency(player_instance)


func _wire_shared_player_dependencies(player_instance: Player) -> void:
	if player_instance == null:
		return

	var blocker_component: PlayerMoveTargetBlockerComponent = player_instance.get_node_or_null("PlayerMoveTargetBlockerComponent") as PlayerMoveTargetBlockerComponent
	if blocker_component and navigation_blocker_registry:
		blocker_component.set_blocker_registry(navigation_blocker_registry)


func _wire_inventory_panel_dependency(player_instance: Player) -> void:
	if ui_manager == null or player_instance == null:
		return
	var inventory_component: Node = player_instance.get_node_or_null("PlayerInventoryComponent") as Node
	ui_manager.bind_inventory_component(inventory_component)


func _wire_creature_interaction_signals() -> void:
	var event_source: Node = _get_creature_event_source()
	if event_source:
		var selected_callable: Callable = Callable(self, "_on_creature_selected")
		var deselected_callable: Callable = Callable(self, "_on_creature_deselected")
		if event_source.has_signal("creature_selected") and not event_source.is_connected("creature_selected", selected_callable):
			event_source.connect("creature_selected", selected_callable)
		if event_source.has_signal("creature_deselected") and not event_source.is_connected("creature_deselected", deselected_callable):
			event_source.connect("creature_deselected", deselected_callable)

	if creature_action_hud and not creature_action_hud.fight_pressed.is_connected(_on_creature_action_hud_fight_pressed):
		creature_action_hud.fight_pressed.connect(_on_creature_action_hud_fight_pressed)

	if creature_spawner and not creature_spawner.creature_despawned.is_connected(_on_creature_despawned):
		creature_spawner.creature_despawned.connect(_on_creature_despawned)

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

	if _can_show_creature_action_hud() and creature_action_hud:
		creature_action_hud.show_for_creature(_selected_creature)


func _clear_selected_creature() -> void:
	_disconnect_selected_creature_signals()
	_selected_creature = null
	if creature_action_hud:
		creature_action_hud.hide_action()


func _can_show_creature_action_hud() -> bool:
	if creature_action_hud == null:
		return false
	if main_screen and main_screen.visible:
		return false
	if _is_character_creator_visible():
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
		_clear_selected_creature()
		return
	_emit_creature_fight_requested_event(creature_node)


func _emit_creature_fight_requested_event(creature_node: Creature) -> void:
	CreatureEvents.creature_fight_requested.emit(creature_node)


func _on_inventory_toggled(is_open: bool) -> void:
	if is_open:
		_clear_selected_creature()
		return
	if _selected_creature == null:
		return
	if not _can_show_creature_action_hud():
		return
	if creature_action_hud:
		creature_action_hud.show_for_creature(_selected_creature)


func _get_inventory_panel_node() -> Node:
	return get_node_or_null("InventoryPanel")


func _is_desktop_platform() -> bool:
	return not _is_mobile_platform()


func _is_mobile_platform() -> bool:
	return (
		OS.has_feature("mobile")
		or OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
	)


func _wire_character_creator_signals() -> void:
	if character_creator_panel == null:
		return

	var confirmed_callable: Callable = Callable(self, "_on_character_creator_appearance_confirmed")
	var cancelled_callable: Callable = Callable(self, "_on_character_creator_cancelled")
	if character_creator_panel.has_signal("appearance_confirmed") and not character_creator_panel.is_connected("appearance_confirmed", confirmed_callable):
		character_creator_panel.connect("appearance_confirmed", confirmed_callable)
	if character_creator_panel.has_signal("creation_cancelled") and not character_creator_panel.is_connected("creation_cancelled", cancelled_callable):
		character_creator_panel.connect("creation_cancelled", cancelled_callable)


func _should_open_character_creator() -> bool:
	return character_creator_panel != null


func _open_character_creator_panel() -> void:
	if character_creator_panel == null:
		if session_controller:
			session_controller.start_session()
		return

	if main_screen:
		if not main_screen.visible:
			main_screen.show_menu()
		if main_screen.has_method("set_creator_overlay_mode"):
			main_screen.call("set_creator_overlay_mode", true)
		print("[FIX][CreatorFlow] Opened creator with main-screen background/music preserved.")

	# Start from fresh defaults each time while persistence is disabled.
	character_creator_panel.call("show_panel", null)


func _on_character_creator_appearance_confirmed(appearance: Resource) -> void:
	if appearance == null:
		push_warning("Overworld: creator confirmed without appearance payload.")
		return

	var profile_service: Node = _get_player_profile_service()
	if profile_service and profile_service.has_method("set_appearance"):
		profile_service.call("set_appearance", appearance, true)

	if main_screen:
		if main_screen.has_method("set_creator_overlay_mode"):
			main_screen.call("set_creator_overlay_mode", false)
		main_screen.hide_menu()
	if session_controller:
		session_controller.start_session()


func _on_character_creator_cancelled() -> void:
	if character_creator_panel and character_creator_panel.has_method("hide_panel"):
		character_creator_panel.call("hide_panel")
	if main_screen:
		if main_screen.has_method("set_creator_overlay_mode"):
			main_screen.call("set_creator_overlay_mode", false)
		main_screen.show_menu()


func _get_player_profile_service() -> Node:
	return get_node_or_null("/root/PlayerProfileService")


func _is_character_creator_visible() -> bool:
	if character_creator_panel == null:
		return false
	if character_creator_panel is CanvasItem:
		return (character_creator_panel as CanvasItem).visible
	return false
