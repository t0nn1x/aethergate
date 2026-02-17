class_name ItemData
extends Resource

## Shared item definition used by inventory resources.

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
