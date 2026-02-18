class_name Overworld
extends Node2D

## Main overworld stage
## Holds stage-level node references. Session orchestration is delegated.

@export var debug_overlay_path: NodePath = ^"DebugOverlay"
@export var main_screen_path: NodePath = ^"MainScreen"
@export var system_hud_path: NodePath = ^"SystemHud"
@export var inventory_panel_path: NodePath = ^"InventoryPanel"
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
@onready var system_hud: SystemHud = get_node_or_null(system_hud_path) as SystemHud
@onready var inventory_panel: InventoryPanel = get_node_or_null(inventory_panel_path) as InventoryPanel
@onready var session_controller: OverworldSessionController = get_node_or_null(session_controller_path) as OverworldSessionController

## Backward-compatible local-player reference.
var player: Player = null
var _players_by_id: Dictionary = {}


func _ready() -> void:
	print("Overworld loaded")
	_wire_stage_dependencies()
	_wire_main_screen_signals()
	_wire_hud_signals()
	if navigation_blocker_registry:
		navigation_blocker_registry.refresh()
	if chunk_manager and navigation_blocker_registry:
		if not chunk_manager.chunks_changed.is_connected(_on_chunks_changed):
			chunk_manager.chunks_changed.connect(_on_chunks_changed)
	_start_session_if_menu_is_missing()


func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return
	if main_screen and main_screen.visible:
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


func _wire_hud_signals() -> void:
	if system_hud == null:
		return
	if not system_hud.hud_slot_pressed.is_connected(_on_hud_slot_pressed):
		system_hud.hud_slot_pressed.connect(_on_hud_slot_pressed)


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
	print("[Overworld] play_started")
	if session_controller:
		session_controller.start_session()


func _on_main_screen_quit_requested() -> void:
	print("[FIX][Quit] quit_requested signal received by Overworld")


func _on_hud_slot_pressed(action_id: StringName, slot_index: int) -> void:
	if main_screen and main_screen.visible:
		return
	if action_id == StringName("inventory") or slot_index == 3:
		_toggle_inventory_panel()


func _toggle_inventory_panel() -> void:
	if inventory_panel == null:
		return
	inventory_panel.toggle_inventory()


func _wire_local_player_dependencies(player_instance: Player) -> void:
	if player_instance == null:
		return

	if chunk_manager:
		chunk_manager.set_tracked_player(player_instance)
	if debug_overlay:
		debug_overlay.set_player_node(player_instance)


func _wire_shared_player_dependencies(player_instance: Player) -> void:
	if player_instance == null:
		return

	var blocker_component: PlayerMoveTargetBlockerComponent = player_instance.get_node_or_null("PlayerMoveTargetBlockerComponent") as PlayerMoveTargetBlockerComponent
	if blocker_component and navigation_blocker_registry:
		blocker_component.set_blocker_registry(navigation_blocker_registry)
