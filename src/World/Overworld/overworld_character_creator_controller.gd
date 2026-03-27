class_name OverworldCharacterCreatorController
extends Node

## Manages the in-game character creator flow.
## On first Play: intercepts PlayerEvents.player_spawned, locks movement,
## shows OverworldCreatorHud. On "Begin Adventure": saves appearance, unlocks.

var _creator_hud: OverworldCreatorHud
## Reserved: stored for potential future session coordination (e.g., pausing session during creator).
var _session_controller: OverworldSessionController
var _locked_player: Player
var _creature_hud: CreatureActionHud
var _ui_manager: UiManager


func _ready() -> void:
	_creator_hud = OverworldCreatorHud.new()
	_creator_hud.name = "OverworldCreatorHud"
	add_child(_creator_hud)
	_creator_hud.hidden.connect(_on_creator_hidden)


func initialize(
	session_controller: OverworldSessionController,
	creature_hud: CreatureActionHud,
	ui_manager: UiManager,
) -> void:
	_session_controller = session_controller
	_creature_hud = creature_hud
	_ui_manager = ui_manager
	if not PlayerEvents.player_spawned.is_connected(_on_player_spawned):
		PlayerEvents.player_spawned.connect(_on_player_spawned)


## Used by OverworldCreatureSelectionController to block tap selection while HUD is open.
func is_visible() -> bool:
	return _creator_hud != null and _creator_hud.visible


func should_open() -> bool:
	return not PlayerProfileService.has_completed_setup()


func _on_player_spawned(player: Node) -> void:
	var p := player as Player
	if p == null or not should_open():
		return

	_locked_player = p
	_set_player_input_enabled(p, false)

	var catalog: PlayerCosmeticCatalog = PlayerProfileService.get_catalog() as PlayerCosmeticCatalog
	var appearance: Resource = PlayerProfileService.get_appearance()

	if not _creator_hud.confirmed.is_connected(_on_hud_confirmed):
		_creator_hud.confirmed.connect(_on_hud_confirmed)

	if _creature_hud:
		_creature_hud.visible = false
	if _ui_manager:
		_ui_manager.set_gameplay_ui_visible(false)

	_creator_hud.show_for_player(p, catalog, appearance)


func _on_hud_confirmed(appearance: Resource) -> void:
	PlayerProfileService.set_appearance(appearance, true)

	if _locked_player != null and is_instance_valid(_locked_player):
		_set_player_input_enabled(_locked_player, true)
	_locked_player = null

	_creator_hud.hide_hud()


func _on_creator_hidden() -> void:
	if _creature_hud:
		_creature_hud.visible = true
	if _ui_manager:
		_ui_manager.set_gameplay_ui_visible(true)


func _set_player_input_enabled(player: Player, enabled: bool) -> void:
	var input_comp := player.get_node_or_null("PlayerInputComponent") as PlayerInputComponent
	if input_comp == null:
		return
	input_comp.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
