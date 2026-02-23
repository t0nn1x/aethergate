class_name ItemData
extends Resource

## Shared item definition used by inventory resources.
const ICON_EXTENSIONS := [".png", ".webp", ".jpg", ".jpeg"]
const PROP_WEAPON_VISUAL_ID: StringName = &"weapon_visual_id"

@export var item_id: String = ""
@export var display_name: String = "Item"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_range(1, 999, 1) var max_stack: int = 1
@export var props: Dictionary = {}


func get_prop(key: StringName, default_value: Variant = null) -> Variant:
	if props.has(String(key)):
		return props[String(key)]
	if props.has(key):
		return props[key]
	return default_value


func is_stackable() -> bool:
	return max_stack > 1


func get_weapon_visual_id() -> StringName:
	return StringName(str(get_prop(PROP_WEAPON_VISUAL_ID, "")))


func get_icon_texture() -> Texture2D:
	if icon:
		return icon

	var auto_icon: Texture2D = _resolve_icon_from_item_folder()
	if auto_icon:
		icon = auto_icon
	return auto_icon


func validate_for_runtime(log_context: String = "") -> bool:
	var context: String = log_context
	if context.is_empty():
		context = display_name

	var is_valid: bool = true
	if item_id.strip_edges().is_empty():
		push_warning("ItemData[%s]: item_id is empty." % context)
		is_valid = false
	if display_name.strip_edges().is_empty():
		push_warning("ItemData[%s]: display_name is empty." % context)
		is_valid = false
	if max_stack <= 0:
		push_warning("ItemData[%s]: max_stack must be > 0." % context)
		is_valid = false
	return is_valid


func _resolve_icon_from_item_folder() -> Texture2D:
	if resource_path.is_empty():
		return null

	var data_folder: String = resource_path.get_base_dir()
	if data_folder.is_empty():
		return null

	var item_folder: String = data_folder.get_base_dir()
	var sprites_folder: String = item_folder.path_join("Sprites")

	var candidate_bases: Array[String] = []
	var display_name_base: String = _to_snake_key(display_name)
	if not display_name_base.is_empty():
		candidate_bases.append(display_name_base)

	var item_id_base: String = _to_snake_key(item_id)
	if not item_id_base.is_empty() and not candidate_bases.has(item_id_base):
		candidate_bases.append(item_id_base)

	var folder_base: String = _to_snake_key(item_folder.get_file())
	if not folder_base.is_empty() and not candidate_bases.has(folder_base):
		candidate_bases.append(folder_base)

	for base in candidate_bases:
		for ext in ICON_EXTENSIONS:
			var icon_texture: Texture2D = _try_load_texture(sprites_folder.path_join("%s_icon%s" % [base, ext]))
			if icon_texture:
				return icon_texture

			icon_texture = _try_load_texture(sprites_folder.path_join("%s%s" % [base, ext]))
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
