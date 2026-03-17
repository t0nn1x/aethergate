class_name Overworld
extends Node2D

## Main overworld stage
## Holds stage-level node references. Session orchestration is delegated.

@export var debug_overlay_path: NodePath = ^"DebugOverlay"
@export var main_screen_path: NodePath = ^"MainScreen"
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
@onready var ui_manager: Node = get_node_or_null(ui_manager_path)
@onready var creature_action_hud: CreatureActionHud = get_node_or_null(creature_action_hud_path) as CreatureActionHud
@onready var session_controller: OverworldSessionController = get_node_or_null(session_controller_path) as OverworldSessionController

@export var combat_approach_radius: float = 10.0

## Backward-compatible local-player reference.
var player: Player = null
var _players_by_id: Dictionary = {}
var _creature_in_combat: Creature = null
var _pending_enemy_snapshot: CombatantSnapshot = null
var _is_approaching_for_combat: bool = false
@onready var creature_selection_controller: OverworldCreatureSelectionController = $OverworldCreatureSelectionController
@onready var character_creator_controller: OverworldCharacterCreatorController = $OverworldCharacterCreatorController
@onready var _combat_preview_panel: CombatPreviewPanel = get_node_or_null("CombatPreviewPanel") as CombatPreviewPanel


func _ready() -> void:
	print("Overworld loaded")
	if ui_manager:
		ui_manager.initialize_ui()
	_refresh_ui_overlay_references()
	_wire_stage_dependencies()
	_wire_main_screen_signals()
	_initialize_character_creator_controller()
	_initialize_creature_selection_controller()
	_wire_combat_preview()
	if navigation_blocker_registry:
		navigation_blocker_registry.refresh()
	if chunk_manager and navigation_blocker_registry:
		if not chunk_manager.chunks_changed.is_connected(_on_chunks_changed):
			chunk_manager.chunks_changed.connect(_on_chunks_changed)
	_start_session_if_menu_is_missing()


func _refresh_ui_overlay_references() -> void:
	debug_overlay = get_node_or_null(debug_overlay_path) as DebugOverlay
	main_screen = get_node_or_null(main_screen_path) as MainScreen


func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return
	if character_creator_controller and character_creator_controller.is_visible():
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
	creature_selection_controller.clear_selection()
	print("[Overworld] play_started")
	if character_creator_controller and character_creator_controller.should_open():
		character_creator_controller.open_panel()
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


func _initialize_creature_selection_controller() -> void:
	if creature_selection_controller:
		var overlay_callback: Callable = Callable()
		if character_creator_controller:
			overlay_callback = Callable(character_creator_controller, "is_visible")
		creature_selection_controller.initialize(
			creature_action_hud,
			creature_spawner,
			main_screen,
			overlay_callback
		)


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


func _initialize_character_creator_controller() -> void:
	if character_creator_controller:
		character_creator_controller.initialize(main_screen, session_controller)


func _wire_combat_preview() -> void:
	if not CreatureEvents.creature_fight_requested.is_connected(_on_creature_fight_requested):
		CreatureEvents.creature_fight_requested.connect(_on_creature_fight_requested)
	if not CombatEvents.combat_ended.is_connected(_on_combat_ended):
		CombatEvents.combat_ended.connect(_on_combat_ended)
	if _combat_preview_panel:
		_combat_preview_panel.fight_confirmed.connect(_on_combat_fight_confirmed)
		_combat_preview_panel.dismissed.connect(_on_combat_preview_dismissed)


func _on_creature_fight_requested(creature_node: Node) -> void:
	var creature: Creature = creature_node as Creature
	if creature == null or not is_instance_valid(creature):
		return
	_creature_in_combat = creature
	if _combat_preview_panel:
		_combat_preview_panel.show_for_creature(creature.creature_data)


func _process(_delta: float) -> void:
	if not _is_approaching_for_combat:
		return
	if _creature_in_combat == null or not is_instance_valid(_creature_in_combat):
		_is_approaching_for_combat = false
		_pending_enemy_snapshot = null
		return
	var local_player: Player = get_local_player()
	if local_player == null:
		return
	if local_player.global_position.distance_to(_creature_in_combat.global_position) <= combat_approach_radius:
		_is_approaching_for_combat = false
		_begin_combat()


func _on_combat_fight_confirmed(enemy_snapshot: CombatantSnapshot) -> void:
	_pending_enemy_snapshot = enemy_snapshot
	var local_player: Player = get_local_player()
	if local_player == null or _creature_in_combat == null or not is_instance_valid(_creature_in_combat):
		_begin_combat()
		return
	if local_player.global_position.distance_to(_creature_in_combat.global_position) <= combat_approach_radius:
		_begin_combat()
	else:
		_is_approaching_for_combat = true
		var move_service: PlayerMoveRequestService = local_player.get_node_or_null(
			"PlayerMoveRequestService"
		) as PlayerMoveRequestService
		if move_service:
			move_service.request_move_target(_creature_in_combat.global_position)


func _begin_combat() -> void:
	CombatEvents.pending_player_snapshot = _build_player_snapshot()
	CombatEvents.pending_enemy_snapshot = _pending_enemy_snapshot
	_pending_enemy_snapshot = null
	GameManager.change_state(GameManager.GameState.COMBAT)


func _on_combat_preview_dismissed() -> void:
	_is_approaching_for_combat = false
	_pending_enemy_snapshot = null
	_creature_in_combat = null
	if creature_selection_controller:
		creature_selection_controller.clear_selection()


func _on_combat_ended(result: CombatRoundResult) -> void:
	if result.winner_id == &"player":
		PlayerProfileService.add_xp(50)
		if _creature_in_combat and is_instance_valid(_creature_in_combat):
			creature_spawner.despawn_creature(_creature_in_combat)
	_creature_in_combat = null


func _build_player_snapshot() -> CombatantSnapshot:
	var stats := CombatStats.new()
	stats.max_hp = 100
	stats.max_energy = 100
	var snap := CombatantSnapshot.new()
	snap.combatant_id = &"player"
	snap.display_name = "Player"
	snap.level = PlayerProfileService.get_player_level()
	var weapon_base_damage: float = 0.0  # TODO: replace with equipped weapon base damage
	stats.attack = 10.0 + snap.level * 2.0 + weapon_base_damage
	stats.defense = 5.0
	snap.base_stats = stats
	## TODO: replace with real player gear loadout once player combat component exists.
	snap.skill_loadout = []
	## TODO: replace with real player sprite from PlayerProfileService cosmetics.
	var player_sprite := load("res://src/Entities/Player/Sprites/Parts/Combined/Dude_full_body1.png") as Texture2D
	if player_sprite:
		snap.portrait = player_sprite
		snap.sprite_hframes = 4
		snap.sprite_vframes = 1
		snap.sprite_frame_width = 32
		snap.sprite_frame_height = 32
		snap.sprite_idle_fps = 2.0
		snap.sprite_default_frame = 0
		for vfx_path: String in [
			"res://src/Entities/Systems/Combat/Assets/VFX/Hit Horizontal White.png",
			"res://src/Entities/Systems/Combat/Assets/VFX/Hit Vertical White.png",
		]:
			var tex := load(vfx_path) as Texture2D
			if tex:
				var cfg := CombatVfxConfig.new()
				cfg.texture = tex
				cfg.hframes = 5
				cfg.fps = 18.0
				cfg.impact_frame = 2
				cfg.scale = 2.0
				snap.default_attack_vfx_pool.append(cfg)
	return snap
