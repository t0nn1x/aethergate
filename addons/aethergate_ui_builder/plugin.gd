# addons/aethergate_ui_builder/plugin.gd
@tool
extends EditorPlugin

# Uses load() (not preload) — the .tscn is created in Task 6.
# preload would fail at parse time if the file doesn't yet exist.
const MAIN_SCREEN_SCENE_PATH: String = \
	"res://addons/aethergate_ui_builder/ui_builder_main_screen.tscn"

var _main_screen: Control


func _enter_tree() -> void:
	var scene: PackedScene = load(MAIN_SCREEN_SCENE_PATH) as PackedScene
	if scene == null:
		push_error("[UiBuilder] Main screen scene not found — complete Task 6 first.")
		return
	_main_screen = scene.instantiate()
	EditorInterface.get_editor_main_screen().add_child(_main_screen)
	_main_screen.setup_undo_redo(get_undo_redo())
	_make_visible(false)


func _exit_tree() -> void:
	if _main_screen:
		_main_screen.queue_free()
		_main_screen = null


func _has_main_screen() -> bool:
	return true


func _make_visible(p_visible: bool) -> void:
	if _main_screen:
		_main_screen.visible = p_visible


func _get_plugin_name() -> String:
	return "UI Builder"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(&"Node2D", &"EditorIcons")
