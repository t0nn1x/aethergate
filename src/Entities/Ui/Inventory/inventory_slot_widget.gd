class_name InventorySlotWidget
extends Button

signal slot_pressed(slot_index: int)

@export var icon_path: NodePath = ^"Icon"
@export var count_label_path: NodePath = ^"CountLabel"
@export var empty_label_path: NodePath = ^"EmptyLabel"

@onready var _icon: TextureRect = get_node_or_null(icon_path) as TextureRect
@onready var _count_label: Label = get_node_or_null(count_label_path) as Label
@onready var _empty_label: Label = get_node_or_null(empty_label_path) as Label

var _slot_index: int = -1
var _slot_data: Resource


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func configure(slot_index: int, slot_data: Resource) -> void:
	_slot_index = slot_index
	_slot_data = slot_data

	if _icon == null or _count_label == null:
		push_warning("InventorySlotWidget: required child nodes are missing.")
		return

	var is_empty: bool = true
	var item: Resource = null
	var amount: int = 0
	if slot_data != null:
		if slot_data.has_method("is_empty"):
			is_empty = bool(slot_data.call("is_empty"))
		item = slot_data.get("item")
		amount = int(slot_data.get("amount"))

	if slot_data == null or is_empty or item == null:
		_icon.texture = null
		_count_label.visible = false
		if _empty_label:
			_empty_label.visible = true
		tooltip_text = "Empty Slot"
		return

	_icon.texture = item.get("icon")
	_count_label.visible = amount > 1
	_count_label.text = str(amount)
	if _empty_label:
		_empty_label.visible = false
	tooltip_text = str(item.get("display_name"))


func _on_pressed() -> void:
	slot_pressed.emit(_slot_index)
