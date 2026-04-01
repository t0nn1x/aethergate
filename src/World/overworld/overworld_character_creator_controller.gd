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
	_main_screen = main_screen
	_session_controller = session_controller
	_character_creator_panel = _resolve_character_creator_panel()
	if _character_creator_panel == null and OS.is_debug_build():
		push_warning("OverworldCharacterCreatorController: CharacterCreatorPanel could not be resolved.")
	_wire_signals()


## Public — used by creature selection controller via callback.
func is_visible() -> bool:
	if _character_creator_panel == null:
		return false
	if _character_creator_panel is CanvasItem:
		return (_character_creator_panel as CanvasItem).visible
	return false


func should_open() -> bool:
	var profile_service: Node = _get_player_profile_service()
	if profile_service == null or not profile_service.has_method("has_completed_setup"):
		return true
	return not bool(profile_service.call("has_completed_setup"))


func open_panel() -> void:
	if _character_creator_panel == null:
		if _main_screen != null:
			_main_screen.animate_play_transition()
		return

	if _main_screen:
		if not _main_screen.visible:
			_main_screen.show_menu()
		_main_screen.set_creator_overlay_mode(true)
		if _character_creator_panel.has_method("show_panel"):
			_character_creator_panel.call("show_panel", null)
		if _character_creator_panel is CanvasItem:
			(_character_creator_panel as CanvasItem).visible = false
		_main_screen.animate_play_transition()
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

	if _character_creator_panel and _character_creator_panel.has_method("hide_panel"):
		_character_creator_panel.call("hide_panel")
	if _main_screen:
		_main_screen.hide_menu()
	if _session_controller:
		_session_controller.start_session()


func _on_creation_cancelled() -> void:
	if _main_screen and _main_screen.has_method("animate_creator_cancel"):
		_main_screen.call("animate_creator_cancel")
		return
	if _character_creator_panel and _character_creator_panel.has_method("hide_panel"):
		_character_creator_panel.call("hide_panel")
	if _main_screen:
		if _main_screen.has_method("set_creator_overlay_mode"):
			_main_screen.call("set_creator_overlay_mode", false)
		_main_screen.show_menu()


func _get_player_profile_service() -> Node:
	return get_node_or_null("/root/PlayerProfileService")


func _resolve_character_creator_panel() -> Node:
	if _main_screen != null:
		var panel_from_main_screen: Node = _main_screen.get_node_or_null(_main_screen.creator_panel_path)
		if panel_from_main_screen != null:
			return panel_from_main_screen
	return get_node_or_null(character_creator_panel_path)
