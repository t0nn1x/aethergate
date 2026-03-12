# addons/aethergate_ui_builder/ui_builder_main_screen.gd
@tool
extends Control

# Explicit preloads — class_name globals are unreliable in @tool addon scripts
# due to editor load order.
const SlotRegistry := preload("res://addons/aethergate_ui_builder/slot_registry.gd")
const LayoutConfig := preload("res://src/Ui/Common/Resources/ui_layout_config.gd")

signal slot_changed(slot_id: StringName, platform: StringName)

@onready var _slot_picker: OptionButton = %SlotPicker
@onready var _platform_toggle: HBoxContainer = %PlatformToggle
@onready var _undo_btn: Button = %UndoBtn
@onready var _redo_btn: Button = %RedoBtn
@onready var _save_btn: Button = %SaveBtn
@onready var _canvas: Control = %Canvas
@onready var _palette: Control = %Palette
@onready var _inspector: Control = %Inspector

var _active_slot_id: StringName = &""
var _active_platform: StringName = &"windows"
var _platform_buttons: Dictionary = {}  # platform → Button
var _undo_redo: EditorUndoRedoManager = null


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Connect signals BEFORE populating so the initial selection triggers handlers.
	_slot_picker.item_selected.connect(_on_slot_selected)
	_undo_btn.pressed.connect(_on_undo_pressed)
	_redo_btn.pressed.connect(_on_redo_pressed)
	_save_btn.pressed.connect(_on_save_pressed)
	slot_changed.connect(_on_slot_platform_changed)
	if _palette.has_signal(&"node_drag_requested"):
		_palette.node_drag_requested.connect(_on_palette_node_requested)
	# Populate last — this emits slot_changed which is now connected.
	_populate_slot_picker()


func setup_undo_redo(undo_redo: EditorUndoRedoManager) -> void:
	_undo_redo = undo_redo
	# Connect canvas signals after undo_redo is available
	if _canvas.has_method(&"connect_move_committed"):
		_canvas.connect_move_committed(self, "_on_move_committed")
	if _canvas.has_method(&"connect_resize_committed"):
		_canvas.connect_resize_committed(self, "_on_resize_committed")
	if _canvas.has_method(&"connect_selection"):
		_canvas.connect_selection(self, "_on_node_selected")


func _populate_slot_picker() -> void:
	_slot_picker.clear()
	for slot: Dictionary in SlotRegistry.SLOTS:
		_slot_picker.add_item(slot.label)
	if SlotRegistry.SLOTS.size() > 0:
		_select_slot(0)


func _select_slot(index: int) -> void:
	var slot: Dictionary = SlotRegistry.SLOTS[index]
	_active_slot_id = slot.id
	_rebuild_platform_buttons(slot.platforms)
	_select_platform(_active_platform if _active_platform in slot.platforms else slot.platforms[0])


func _rebuild_platform_buttons(platforms: Array) -> void:
	for child in _platform_toggle.get_children():
		child.queue_free()
	_platform_buttons.clear()
	for platform: StringName in platforms:
		var btn := Button.new()
		btn.text = platform.capitalize()
		btn.toggle_mode = true
		btn.pressed.connect(_on_platform_pressed.bind(platform))
		_platform_toggle.add_child(btn)
		_platform_buttons[platform] = btn


func _select_platform(platform: StringName) -> void:
	_active_platform = platform
	for p: StringName in _platform_buttons:
		var btn: Button = _platform_buttons[p]
		btn.button_pressed = (p == platform)
	slot_changed.emit(_active_slot_id, _active_platform)


func _on_slot_selected(index: int) -> void:
	_select_slot(index)


func _on_platform_pressed(platform: StringName) -> void:
	_select_platform(platform)


func _on_slot_platform_changed(slot_id: StringName, platform: StringName) -> void:
	if _canvas == null:
		return
	var vp_size: Vector2 = SlotRegistry.PLATFORM_SIZES.get(platform, Vector2(1920, 1080))
	_canvas.set_platform_size(vp_size)
	_load_canvas_scene(slot_id, platform)


func _load_canvas_scene(slot_id: StringName, platform: StringName) -> void:
	var config: LayoutConfig = load("res://src/Ui/Common/Resources/ui_layout_config.tres")
	if config == null:
		_canvas.load_scene(null)
		return
	var path: String = config.get_scene_path(slot_id, platform)
	if path.is_empty() or not ResourceLoader.exists(path):
		_canvas.load_scene(null)
		return
	var packed: PackedScene = load(path) as PackedScene
	_canvas.load_scene(packed)


# --- Undo / Redo ---

func _on_undo_pressed() -> void:
	if _undo_redo:
		_undo_redo.undo()


func _on_redo_pressed() -> void:
	if _undo_redo:
		_undo_redo.redo()


func _on_move_committed(node: Control, old_pos: Vector2, new_pos: Vector2) -> void:
	if _undo_redo == null:
		return
	_undo_redo.create_action("Move node")
	_undo_redo.add_do_property(node, "position", new_pos)
	_undo_redo.add_undo_property(node, "position", old_pos)
	_undo_redo.commit_action()


func _on_resize_committed(node: Control, old_rect: Rect2, new_rect: Rect2) -> void:
	if _undo_redo == null:
		return
	_undo_redo.create_action("Resize node")
	_undo_redo.add_do_property(node, "position", new_rect.position)
	_undo_redo.add_do_property(node, "size", new_rect.size)
	_undo_redo.add_undo_property(node, "position", old_rect.position)
	_undo_redo.add_undo_property(node, "size", old_rect.size)
	_undo_redo.commit_action()


# --- Node selection (from canvas overlay) ---

func _on_node_selected(node: Control) -> void:
	if _inspector != null and _inspector.has_method(&"inspect"):
		_inspector.inspect(node)


# --- Palette drag → place ---

func _on_palette_node_requested(payload: String) -> void:
	if _canvas == null:
		return
	var node: Control = _create_node(payload)
	if node == null:
		return
	# Place at center of current viewport
	var vp_size: Vector2 = _canvas.get_viewport_size()
	node.position = (vp_size * 0.5 - node.size * 0.5).snapped(Vector2(8.0, 8.0))
	if _undo_redo:
		_undo_redo.create_action("Add node")
		_undo_redo.add_do_method(_canvas, "add_node_to_scene", node)
		_undo_redo.add_undo_method(_canvas, "remove_node_from_scene", node)
		_undo_redo.commit_action()  # applies do-method immediately
	else:
		_canvas.add_node_to_scene(node)


func _create_node(payload: String) -> Control:
	# Scene path
	if ResourceLoader.exists(payload):
		var packed: PackedScene = load(payload) as PackedScene
		return packed.instantiate() as Control if packed else null
	# Primitive type name
	var instance: Object = ClassDB.instantiate(payload)
	var ctrl: Control = instance as Control
	if ctrl == null:
		if instance:
			instance.free()
		return null
	ctrl.size = Vector2(200.0, 80.0)
	return ctrl


# --- Save ---

func _on_save_pressed() -> void:
	if _active_slot_id == &"" or _canvas == null:
		return

	var scene_root: Control = _canvas.get_scene_root()
	if scene_root == null:
		push_warning("[UiBuilder] Nothing on canvas to save.")
		return

	# Determine output path
	var out_path: String = _resolve_output_path(_active_slot_id, _active_platform)
	if out_path.is_empty():
		push_error("[UiBuilder] No output path defined for slot '%s' platform '%s'" % [_active_slot_id, _active_platform])
		return

	# Pack and save scene
	var packed := PackedScene.new()
	var pack_result: int = packed.pack(scene_root)
	if pack_result != OK:
		push_error("[UiBuilder] Failed to pack scene (error %d)" % pack_result)
		return

	var save_result: int = ResourceSaver.save(packed, out_path)
	if save_result != OK:
		push_error("[UiBuilder] Failed to save scene to '%s' (error %d)" % [out_path, save_result])
		return

	# Update ui_layout_config.tres
	var config: LayoutConfig = load("res://src/Ui/Common/Resources/ui_layout_config.tres")
	if config == null:
		config = LayoutConfig.new()

	if not config.slots.has(_active_slot_id):
		config.slots[_active_slot_id] = {}
	config.slots[_active_slot_id][_active_platform] = out_path

	ResourceSaver.save(config, "res://src/Ui/Common/Resources/ui_layout_config.tres")
	print("[UiBuilder] Saved '%s' (%s) → %s" % [_active_slot_id, _active_platform, out_path])


func _resolve_output_path(slot_id: StringName, platform: StringName) -> String:
	# Try existing path from config first
	var config: LayoutConfig = load("res://src/Ui/Common/Resources/ui_layout_config.tres")
	if config != null:
		var existing: String = config.get_scene_path(slot_id, platform)
		if not existing.is_empty():
			return existing

	# Derive a sensible default path
	var slot: Dictionary = SlotRegistry.find_slot(slot_id)
	if slot.is_empty():
		return ""
	var platform_folder: String = SlotRegistry.PLATFORM_FOLDER_NAMES.get(platform, str(platform).capitalize())
	var folder: String = "res://src/Ui/%s/UiBuilder/%s/" % [platform_folder, slot.label]
	return folder + slot_id + "_" + platform + ".tscn"
