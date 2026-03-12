# addons/aethergate_ui_builder/panels/palette/ui_builder_palette.gd
@tool
extends ScrollContainer

const SlotRegistry := preload("res://addons/aethergate_ui_builder/slot_registry.gd")
const LayoutConfig := preload("res://src/Ui/Common/Resources/ui_layout_config.gd")

signal node_drag_requested(scene_path: String)
signal image_requested()  # user wants to pick a texture file

const PRIMITIVES: Array[Dictionary] = [
	{ "label": "Panel",          "type": "Panel" },
	{ "label": "NinePatchRect",  "type": "NinePatchRect" },
	{ "label": "HBoxContainer",  "type": "HBoxContainer" },
	{ "label": "VBoxContainer",  "type": "VBoxContainer" },
	{ "label": "Label",          "type": "Label" },
	{ "label": "Button",         "type": "Button" },
	{ "label": "TextureRect",    "type": "TextureRect" },
]

@onready var _aethergate_list: VBoxContainer = %AethergateList
@onready var _primitives_list: VBoxContainer = %PrimitivesList


func _ready() -> void:
	_populate_aethergate()
	_populate_primitives()
	_add_image_picker()


func _populate_aethergate() -> void:
	for slot: Dictionary in SlotRegistry.SLOTS:
		var config: LayoutConfig = load("res://src/Ui/Common/Resources/ui_layout_config.tres")
		if config == null:
			continue
		var path: String = config.get_scene_path(slot.id, &"windows")
		if path.is_empty():
			continue
		_add_palette_item(_aethergate_list, slot.label, path, false)


func _populate_primitives() -> void:
	for prim: Dictionary in PRIMITIVES:
		_add_palette_item(_primitives_list, prim.label, prim.type, true)


func _add_palette_item(list: VBoxContainer, label: String, payload: String, is_primitive: bool) -> void:
	var btn := Button.new()
	var icon_char: String = "◆ " if not is_primitive else "○ "
	btn.text = icon_char + label
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.flat = true
	btn.custom_minimum_size.y = 26.0
	btn.pressed.connect(_on_item_pressed.bind(payload))
	list.add_child(btn)


func _on_item_pressed(payload: String) -> void:
	# For now emit as scene_path; canvas distinguishes primitive vs scene by checking ResourceLoader
	node_drag_requested.emit(payload)


func _add_image_picker() -> void:
	var sep := HSeparator.new()
	_primitives_list.get_parent().add_child(sep)
	var lbl := Label.new()
	lbl.text = "  IMAGES"
	lbl.add_theme_font_size_override(&"font_size", 11)
	lbl.add_theme_color_override(&"font_color", Color(0.3, 0.65, 0.85, 1.0))
	_primitives_list.get_parent().add_child(lbl)
	var btn := Button.new()
	btn.text = "🖼 Image (PNG)"
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.flat = true
	btn.custom_minimum_size.y = 26.0
	btn.pressed.connect(func(): image_requested.emit())
	_primitives_list.get_parent().add_child(btn)
