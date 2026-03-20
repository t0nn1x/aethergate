class_name OverworldCharacterCreatorController
extends Node

## Manages the character creator open/confirm/cancel flow.

@export var character_creator_panel_path: NodePath = ^"../CharacterCreatorPanel"

var _character_creator_panel: Node
var _main_screen: MainScreen
var _session_controller: OverworldSessionController


func initialize(
	main_screen: MainScreen,
	session_controller: OverworldSessionController
) -> void:
	_character_creator_panel = get_node_or_null(character_creator_panel_path)
	_main_screen = main_screen
	_session_controller = session_controller
	_wire_signals()


## Public — used by creature selection controller via callback.
func is_visible() -> bool:
	if _character_creator_panel == null:
		return false
	if _character_creator_panel is CanvasItem:
		return (_character_creator_panel as CanvasItem).visible
	return false


func should_open() -> bool:
	return _character_creator_panel != null


func open_panel() -> void:
	if _character_creator_panel == null:
		if _session_controller:
			_session_controller.start_session()
		return

	if _main_screen:
		if not _main_screen.visible:
			_main_screen.show_menu()
		_main_screen.set_creator_overlay_mode(true)
		_main_screen.animate_menu_out(func() -> void:
			_character_creator_panel.call("show_panel", null)
		)
	else:
		_character_creator_panel.call("show_panel", null)


func _wire_signals() -> void:
	if _character_creator_panel == null:
		return

	var confirmed_callable: Callable = Callable(self, "_on_appearance_confirmed")
	var cancelled_callable: Callable = Callable(self, "_on_creation_cancelled")
	if _character_creator_panel.has_signal("appearance_confirmed") and not _character_creator_panel.is_connected("appearance_confirmed", confirmed_callable):
		_character_creator_panel.connect("appearance_confirmed", confirmed_callable)
	if _character_creator_panel.has_signal("creation_cancelled") and not _character_creator_panel.is_connected("creation_cancelled", cancelled_callable):
		_character_creator_panel.connect("creation_cancelled", cancelled_callable)


func _on_appearance_confirmed(appearance: Resource) -> void:
	if appearance == null:
		push_warning("Overworld: creator confirmed without appearance payload.")
		return

	var profile_service: Node = _get_player_profile_service()
	if profile_service and profile_service.has_method("set_appearance"):
		profile_service.call("set_appearance", appearance, true)

	if _main_screen:
		if _main_screen.has_method("set_creator_overlay_mode"):
			_main_screen.call("set_creator_overlay_mode", false)
		_main_screen.hide_menu()
	if _session_controller:
		_session_controller.start_session()


func _on_creation_cancelled() -> void:
	if _character_creator_panel and _character_creator_panel.has_method("hide_panel"):
		_character_creator_panel.call("hide_panel")
	if _main_screen:
		if _main_screen.has_method("set_creator_overlay_mode"):
			_main_screen.call("set_creator_overlay_mode", false)
		_main_screen.show_menu()


func _get_player_profile_service() -> Node:
	return get_node_or_null("/root/PlayerProfileService")
