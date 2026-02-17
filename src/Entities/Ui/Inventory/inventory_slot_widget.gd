class_name InventorySlotWidget
extends TextureButton

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
	_cache_nodes()
	focus_mode = Control.FOCUS_ALL
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func configure(slot_index: int, slot_data: Resource) -> void:
	_slot_index = slot_index
	_slot_data = slot_data
	_cache_nodes()

	if _icon == null or _count_label == null:
		push_warning("[FIX:inventory_icon] InventorySlotWidget missing required child nodes.")
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
		_icon.visible = false
		_count_label.visible = false
		if _empty_label:
			_empty_label.visible = true
		tooltip_text = "Empty Slot"
		return

	var icon_texture: Texture2D = _resolve_item_icon(item)
	_icon.texture = icon_texture
	_icon.visible = _icon.texture != null
	_count_label.visible = amount > 1
	_count_label.text = str(amount)
	if _empty_label:
		_empty_label.visible = false
	if icon_texture == null:
		push_warning("[FIX:inventory_icon] icon not found for item '%s' (%s)." % [str(item.get("display_name")), str(item.get("item_id"))])
	tooltip_text = str(item.get("display_name"))


func _on_pressed() -> void:
	slot_pressed.emit(_slot_index)


func _resolve_item_icon(item: Resource) -> Texture2D:
	if item == null:
		return null

	var direct_icon: Variant = item.get("icon")
	if direct_icon is Texture2D:
		return direct_icon as Texture2D

	if item.has_method("get_icon_texture"):
		var resolved: Variant = item.call("get_icon_texture")
		if resolved is Texture2D:
			return resolved as Texture2D

	var auto_icon: Texture2D = _resolve_icon_from_item_resource(item)
	if auto_icon:
		return auto_icon

	return null


func _resolve_icon_from_item_resource(item: Resource) -> Texture2D:
	if item.resource_path.is_empty():
		return null

	var data_folder: String = item.resource_path.get_base_dir()
	if data_folder.is_empty():
		return null

	var item_folder: String = data_folder.get_base_dir()
	var sprites_folder: String = item_folder.path_join("Sprites")

	var candidate_bases: Array[String] = []
	var display_name_base: String = _to_snake_key(str(item.get("display_name")))
	if not display_name_base.is_empty():
		candidate_bases.append(display_name_base)

	var item_id_base: String = _to_snake_key(str(item.get("item_id")))
	if not item_id_base.is_empty() and not candidate_bases.has(item_id_base):
		candidate_bases.append(item_id_base)

	var folder_base: String = _to_snake_key(item_folder.get_file())
	if not folder_base.is_empty() and not candidate_bases.has(folder_base):
		candidate_bases.append(folder_base)

	var extensions: Array[String] = [".png", ".webp", ".jpg", ".jpeg"]
	for base in candidate_bases:
		for ext in extensions:
			var icon_path: String = sprites_folder.path_join("%s_icon%s" % [base, ext])
			var icon_texture: Texture2D = _try_load_texture(icon_path)
			if icon_texture:
				return icon_texture

			icon_path = sprites_folder.path_join("%s%s" % [base, ext])
			icon_texture = _try_load_texture(icon_path)
			if icon_texture:
				return icon_texture

	for fallback in ["icon.png", "item_icon.png", "icon.webp", "item_icon.webp"]:
		var fallback_texture: Texture2D = _try_load_texture(sprites_folder.path_join(fallback))
		if fallback_texture:
			return fallback_texture

	return null


func _to_snake_key(source: String) -> String:
	var normalized: String = source.strip_edges().to_lower()
	var output: String = ""
	var previous_was_separator: bool = false

	for index in range(normalized.length()):
		var code: int = normalized.unicode_at(index)
		var is_digit: bool = code >= 48 and code <= 57
		var is_letter: bool = code >= 97 and code <= 122
		if is_digit or is_letter:
			output += normalized.substr(index, 1)
			previous_was_separator = false
			continue

		if not previous_was_separator and not output.is_empty():
			output += "_"
			previous_was_separator = true

	return output.trim_suffix("_")


func _try_load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _cache_nodes() -> void:
	if _icon == null:
		_icon = get_node_or_null(icon_path) as TextureRect
	if _count_label == null:
		_count_label = get_node_or_null(count_label_path) as Label
	if _empty_label == null:
		_empty_label = get_node_or_null(empty_label_path) as Label
