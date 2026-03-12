@tool
class_name UiLayoutConfig
extends Resource

## Maps slot_id → { "windows": path, "macos": path, "mobile": path }
## Missing platform keys fall back to "windows".
@export var slots: Dictionary = {}


func get_scene_path(slot_id: StringName, platform: StringName) -> String:
	# .tres files store Dictionary keys as String; callers may pass StringName.
	# Try both variants to be safe across Godot versions.
	var slot: Dictionary = slots.get(slot_id, slots.get(str(slot_id), {}))
	if slot.has(platform):
		return slot[platform]
	var plat_str: String = str(platform)
	if slot.has(plat_str):
		return slot[plat_str]
	return slot.get(&"windows", slot.get("windows", ""))
