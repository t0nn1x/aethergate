class_name UiManager
extends Node

## Scene-local UI coordinator for platform-specific HUD/panel variants and panel interactions.

const SYSTEM_HUD_WINDOWS_SCENE: PackedScene = preload("res://src/Ui/Windows/Hud/SystemHud/system_hud.tscn")
const SYSTEM_HUD_MACOS_SCENE: PackedScene = preload("res://src/Ui/MacOS/Hud/SystemHud/system_hud_macos.tscn")
const SYSTEM_HUD_MOBILE_SCENE: PackedScene = preload("res://src/Ui/Mobile/Hud/SystemHud/system_hud_mobile.tscn")
const DEBUG_OVERLAY_WINDOWS_SCENE: PackedScene = preload("res://src/Ui/Windows/Debug/debug_overlay.tscn")
const DEBUG_OVERLAY_MACOS_SCENE: PackedScene = preload("res://src/Ui/MacOS/Debug/debug_overlay_macos.tscn")
const MAIN_SCREEN_WINDOWS_SCENE: PackedScene = preload("res://src/Ui/Windows/Gui/MainScreen/main_screen.tscn")
const MAIN_SCREEN_MACOS_SCENE: PackedScene = preload("res://src/Ui/MacOS/Gui/MainScreen/main_screen_macos.tscn")
const INVENTORY_PANEL_WINDOWS_SCENE: PackedScene = preload("res://src/Ui/Windows/Inventory/inventory_panel.tscn")
const INVENTORY_PANEL_MACOS_SCENE: PackedScene = preload("res://src/Ui/MacOS/Inventory/inventory_panel_macos.tscn")
const INVENTORY_PANEL_MOBILE_SCENE: PackedScene = preload("res://src/Ui/Mobile/Inventory/inventory_panel_mobile.tscn")
const INVENTORY_CLOSE_ICON: Texture2D = preload(
	"res://src/Ui/Assets/Gui-Hud/Menu Buttons And Switch/Menu Buttons/close_button.png"
)

@export var main_screen_path: NodePath = ^"../MainScreen"
@export var debug_overlay_path: NodePath = ^"../DebugOverlay"
@export var system_hud_path: NodePath = ^"../SystemHud"
@export var inventory_panel_path: NodePath = ^"../InventoryPanel"
@export_range(0, 4, 1) var inventory_hud_slot_index: int = 3

var _main_screen: MainScreen
var _system_hud: SystemHud
var _inventory_panel: InventoryPanel
var _inventory_default_hud_icon: Texture2D


func initialize_ui() -> void:
	_refresh_ui_nodes()
	_apply_platform_ui_variants()
	_refresh_ui_nodes()
	_wire_hud_signals()


func is_menu_visible() -> bool:
	return _main_screen != null and _main_screen.visible


func toggle_inventory() -> void:
	if _inventory_panel == null:
		return
	_inventory_panel.toggle_inventory()


func close_open_panels() -> bool:
	if _inventory_panel and _inventory_panel.visible:
		_inventory_panel.set_inventory_open(false)
		return true
	return false


func bind_inventory_component(component: Node) -> void:
	if _inventory_panel == null:
		return
	if _inventory_panel.has_method("set_inventory_component"):
		_inventory_panel.call("set_inventory_component", component)


func _refresh_ui_nodes() -> void:
	_main_screen = get_node_or_null(main_screen_path) as MainScreen
	_system_hud = get_node_or_null(system_hud_path) as SystemHud
	_inventory_panel = get_node_or_null(inventory_panel_path) as InventoryPanel


func _apply_platform_ui_variants() -> void:
	var ui_profile: StringName = _resolve_ui_profile()
	if OS.is_debug_build():
		print("[UiManager] UI profile: %s" % String(ui_profile))

	_replace_overlay_node(debug_overlay_path, _resolve_debug_overlay_scene(ui_profile))
	var resolved_main_screen: Node = _replace_overlay_node(main_screen_path, _resolve_main_screen_scene(ui_profile))
	var resolved_system_hud: Node = _replace_overlay_node(system_hud_path, _resolve_system_hud_scene(ui_profile))
	var resolved_inventory_panel: Node = _replace_overlay_node(inventory_panel_path, _resolve_inventory_panel_scene(ui_profile))

	if resolved_main_screen:
		_main_screen = resolved_main_screen as MainScreen
	if resolved_system_hud:
		_system_hud = resolved_system_hud as SystemHud
	if resolved_inventory_panel:
		_inventory_panel = resolved_inventory_panel as InventoryPanel


func _replace_overlay_node(node_path: NodePath, next_scene: PackedScene) -> Node:
	if node_path == NodePath() or next_scene == null:
		return null

	var current_node: Node = get_node_or_null(node_path)
	if current_node == null:
		return null
	if current_node.scene_file_path == next_scene.resource_path:
		return current_node

	var parent: Node = current_node.get_parent()
	if parent == null:
		return current_node

	var replacement: Node = next_scene.instantiate()
	if replacement == null:
		return current_node

	var original_name: String = current_node.name
	var sibling_index: int = current_node.get_index()
	parent.remove_child(current_node)
	current_node.queue_free()

	replacement.name = original_name
	parent.add_child(replacement)
	parent.move_child(replacement, sibling_index)
	return replacement


func _resolve_ui_profile() -> StringName:
	if _is_mobile_platform():
		return &"mobile"
	if OS.has_feature("macos"):
		return &"macos"
	return &"windows"


func _resolve_system_hud_scene(ui_profile: StringName) -> PackedScene:
	match ui_profile:
		&"macos":
			return SYSTEM_HUD_MACOS_SCENE
		&"mobile":
			return SYSTEM_HUD_MOBILE_SCENE
		_:
			return SYSTEM_HUD_WINDOWS_SCENE


func _resolve_debug_overlay_scene(ui_profile: StringName) -> PackedScene:
	match ui_profile:
		&"macos":
			return DEBUG_OVERLAY_MACOS_SCENE
		_:
			return DEBUG_OVERLAY_WINDOWS_SCENE


func _resolve_main_screen_scene(ui_profile: StringName) -> PackedScene:
	match ui_profile:
		&"macos":
			return MAIN_SCREEN_MACOS_SCENE
		_:
			return MAIN_SCREEN_WINDOWS_SCENE


func _resolve_inventory_panel_scene(ui_profile: StringName) -> PackedScene:
	match ui_profile:
		&"macos":
			return INVENTORY_PANEL_MACOS_SCENE
		&"mobile":
			return INVENTORY_PANEL_MOBILE_SCENE
		_:
			return INVENTORY_PANEL_WINDOWS_SCENE


func _wire_hud_signals() -> void:
	if _system_hud == null:
		return
	if not _system_hud.hud_slot_pressed.is_connected(_on_hud_slot_pressed):
		_system_hud.hud_slot_pressed.connect(_on_hud_slot_pressed)
	_wire_inventory_panel_signals()


func _on_hud_slot_pressed(action_id: StringName, slot_index: int) -> void:
	if is_menu_visible():
		return
	if action_id == StringName("inventory") or slot_index == inventory_hud_slot_index:
		toggle_inventory()


func _wire_inventory_panel_signals() -> void:
	if _inventory_panel == null:
		return
	if not _inventory_panel.inventory_toggled.is_connected(_on_inventory_panel_toggled):
		_inventory_panel.inventory_toggled.connect(_on_inventory_panel_toggled)
	_cache_inventory_default_hud_icon()
	_sync_inventory_hud_slot_icon()


func _cache_inventory_default_hud_icon() -> void:
	if _system_hud == null:
		return
	_inventory_default_hud_icon = _system_hud.get_default_slot_icon(inventory_hud_slot_index)


func _sync_inventory_hud_slot_icon() -> void:
	if _system_hud == null:
		return
	if inventory_hud_slot_index < 0:
		return

	var panel_open: bool = _inventory_panel != null and _inventory_panel.visible
	var next_icon: Texture2D = INVENTORY_CLOSE_ICON if panel_open else _inventory_default_hud_icon
	_system_hud.set_slot_icon(inventory_hud_slot_index, next_icon)
	_system_hud.set_slot_active(inventory_hud_slot_index, panel_open)


func _on_inventory_panel_toggled(_is_open: bool) -> void:
	_sync_inventory_hud_slot_icon()


func _is_mobile_platform() -> bool:
	return (
		OS.has_feature("mobile")
		or OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
	)
