class_name Overworld
extends Node2D

## Main overworld stage
## Holds stage-level node references. Session orchestration is delegated.

@export var debug_overlay_path: NodePath = ^"DebugOverlay"

@onready var terrain: Node2D = $Terrain
@onready var navigation_region: NavigationRegion2D = $Navigation/NavigationRegion2D
@onready var entities: Node2D = $Entities
@onready var world_y_sort: Node2D = $WorldYSort
@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var navigation_blocker_registry: NavigationBlockerRegistry = $NavigationBlockerRegistry
@onready var debug_overlay: DebugOverlay = get_node_or_null(debug_overlay_path) as DebugOverlay

var player: Player = null

func _ready() -> void:
	print("Overworld loaded")
	_wire_stage_dependencies()
	if navigation_blocker_registry:
		navigation_blocker_registry.refresh()
	if chunk_manager and navigation_blocker_registry:
		if not chunk_manager.chunks_changed.is_connected(_on_chunks_changed):
			chunk_manager.chunks_changed.connect(_on_chunks_changed)

## Backward-compatible helper for existing callers.
func spawn_player() -> void:
	var spawner: OverworldPlayerSpawner = get_node_or_null("OverworldPlayerSpawner") as OverworldPlayerSpawner
	if spawner:
		spawner.spawn_player()

func register_player(player_instance: Player) -> void:
	player = player_instance
	_wire_player_dependencies(player_instance)

func get_navigation_region() -> NavigationRegion2D:
	return navigation_region


func get_navigation_blocker_registry() -> NavigationBlockerRegistry:
	return navigation_blocker_registry


func _on_chunks_changed() -> void:
	if navigation_blocker_registry:
		navigation_blocker_registry.refresh()


func _wire_stage_dependencies() -> void:
	if debug_overlay and chunk_manager:
		debug_overlay.set_chunk_manager(chunk_manager)
	if player:
		_wire_player_dependencies(player)


func _wire_player_dependencies(player_instance: Player) -> void:
	if player_instance == null:
		return

	if chunk_manager:
		chunk_manager.set_tracked_player(player_instance)
	if debug_overlay:
		debug_overlay.set_player_node(player_instance)

	var blocker_component: PlayerMoveTargetBlockerComponent = player_instance.get_node_or_null("PlayerMoveTargetBlockerComponent") as PlayerMoveTargetBlockerComponent
	if blocker_component and navigation_blocker_registry:
		blocker_component.set_blocker_registry(navigation_blocker_registry)
